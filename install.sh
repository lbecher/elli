#!/bin/bash

#
# Parâmetros
#

hname="archlinux" # nome do host
uname="user" # nome de usuário

use_plasma="n"
use_gnome="y"
use_luks="y"

use_intel_gpu="y"
use_amd_gpu="y"
use_nvidia_gpu="y"

pefi="/dev/nvme0n1p1" # partição EFI
pboot="/dev/nvme0n1p2" # partição do GRUB
proot="/dev/nvme0n1p3" # partição do sistema

#
# Configuração
#

loadkeys br-abnt2

echo "Server = http://archlinux.c3sl.ufpr.br/\$repo/os/\$arch" > /etc/pacman.d/mirrorlist
echo "Server = http://mirror.ufam.edu.br/archlinux/\$repo/os/\$arch" >> /etc/pacman.d/mirrorlist
echo "Server = http://mirror.ufscar.br/archlinux/\$repo/os/\$arch" >> /etc/pacman.d/mirrorlist
echo "Server = http://www.caco.ic.unicamp.br/archlinux/\$repo/os/\$arch" >> /etc/pacman.d/mirrorlist

sed -e 's/^#[[:space:]]*ParallelDownloads =.*/ParallelDownloads = 5/' -i /etc/pacman.conf
sed -e '/^#[[:space:]]*\[multilib\]/,/^#[[:space:]]*Include/s/^#[[:space:]]*//' -i /etc/pacman.conf

#
# Instalação
#

if [ "$use_luks" = "y" ]; then
  pluks="$proot"
  
  cryptsetup -s 256 -h sha256 -c aes-xts-plain64 luksFormat "$pluks"
  
  pluks_uuid=$( blkid -o value -s UUID "$pluks" )
  proot="/dev/mapper/luks-$pluks_uuid"
  proot_name="luks-$pluks_uuid"
  
  cryptsetup luksOpen "$pluks" "$proot_name"
fi

mkfs.vfat -n EFI -F32 "$pefi"
mkfs.ext4 -L GRUB "$pboot" 
mkfs.btrfs -L ROOT "$proot"

mount "$proot" /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
umount /mnt

mount -o compress=zstd,subvol=@ "$proot" /mnt
mkdir -p /mnt/home
mount -o compress=zstd,subvol=@home "$proot" /mnt/home

mkdir "/mnt/efi"
mkdir "/mnt/boot"
mount "$pefi" "/mnt/efi"
mount "$pboot" "/mnt/boot"

pacstrap /mnt base base-devel linux linux-headers linux-firmware \
  intel-ucode amd-ucode grub efibootmgr lvm2 cryptsetup btrfs-progs \
  ttf-bitstream-vera ttf-croscore ttf-dejavu ttf-droid \
  ttf-ibm-plex ttf-liberation ttf-linux-libertine ttf-roboto \
  tex-gyre-fonts ttf-ubuntu-font-family cantarell-fonts \
  noto-fonts noto-fonts-emoji noto-fonts-extra awesome-terminal-fonts \
  ttf-fira-code ttf-croscore ttf-opensans gnu-free-fonts \
  avahi cups cups-pdf libcups ghostscript gutenprint foomatic-db-engine \
  foomatic-db foomatic-db-ppds foomatic-db-nonfree foomatic-db-nonfree-ppds \
  foomatic-db-gutenprint-ppds power-profiles-daemon networkmanager \
  bluez bluez-utils networkmanager firewalld git curl wget nano fuse rustup \
  dosfstools exfat-utils ntfs-3g os-prober

genfstab -U /mnt > /mnt/etc/fstab
if [ "$use_luks" = "y" ]; then
  echo "$plvm_name UUID=$pluks_uuid none discard" > /mnt/etc/crypttab
fi

echo "$hname" > /mnt/etc/hostname
echo "LANG=pt_BR.UTF-8" > /mnt/etc/locale.conf
echo "KEYMAP=br-abnt2" > /mnt/etc/vconsole.conf
echo "en_US.UTF-8 UTF-8" > /mnt/etc/locale.gen
echo "pt_BR.UTF-8 UTF-8" >> /mnt/etc/locale.gen

echo "127.0.0.1 localhost.localdomain localhost" > /mnt/etc/hosts
echo "::1 localhost.localdomain localhost" >> /mnt/etc/hosts
echo "127.0.1.1 $hname.localdomain $hname" >> /mnt/etc/hosts

echo "MODULES=()" > /mnt/etc/mkinitcpio.conf
echo "BINARIES=()" >> /mnt/etc/mkinitcpio.conf
echo "FILES=()" >> /mnt/etc/mkinitcpio.conf
echo "HOOKS=(base systemd autodetect keyboard sd-vconsole modconf block sd-encrypt filesystems fsck)" >> /mnt/etc/mkinitcpio.conf

echo "GRUB_TIMEOUT=5" > /mnt/etc/default/grub
echo "GRUB_DISTRIBUTOR=\"ArchLinux\"" >> /mnt/etc/default/grub
echo "GRUB_DEFAULT=\"saved\"" >> /mnt/etc/default/grub
echo "GRUB_DISABLE_SUBMENU=true" >> /mnt/etc/default/grub
echo "GRUB_TERMINAL_OUTPUT=\"console\"" >> /mnt/etc/default/grub
if [ "$use_luks" = "y" ]; then
  echo "GRUB_CMDLINE_LINUX=\"rd.luks.uuid=$proot_name rhgb quiet\"" >> /mnt/etc/default/grub
else
  echo "GRUB_CMDLINE_LINUX=\"rhgb quiet\"" >> /mnt/etc/default/grub
fi
echo "GRUB_DISABLE_RECOVERY=true" >> /mnt/etc/default/grub
echo "GRUB_ENABLE_BLSCFG=true" >> /mnt/etc/default/grub
echo "GRUB_DISABLE_OS_PROBER=false" >> /mnt/etc/default/grub

arch-chroot /mnt ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
arch-chroot /mnt hwclock --systohc
arch-chroot /mnt locale-gen

sed -e '/^#[[:space:]]*%wheel ALL=(ALL:ALL) ALL/s/^#[[:space:]]*//' -i /mnt/etc/sudoers

arch-chroot /mnt useradd -m -G wheel "$uname"
echo "Defina uma senha para o usuário criado."
arch-chroot /mnt passwd "$uname"

echo "Server = http://archlinux.c3sl.ufpr.br/\$repo/os/\$arch" > /mnt/etc/pacman.d/mirrorlist
echo "Server = http://mirror.ufam.edu.br/archlinux/\$repo/os/\$arch" >> /mnt/etc/pacman.d/mirrorlist
echo "Server = http://mirror.ufscar.br/archlinux/\$repo/os/\$arch" >> /mnt/etc/pacman.d/mirrorlist
echo "Server = http://www.caco.ic.unicamp.br/archlinux/\$repo/os/\$arch" >> /mnt/etc/pacman.d/mirrorlist

sed -e 's/^#[[:space:]]*ParallelDownloads =.*/ParallelDownloads = 5/' -i /mnt/etc/pacman.conf
sed -e '/^#[[:space:]]*\[multilib\]/,/^#[[:space:]]*Include/s/^#[[:space:]]*//' -i /mnt/etc/pacman.conf

if [ "$use_intel_gpu" = "y" ]; then
  arch-chroot /mnt pacman -Syu \
    mesa lib32-mesa vulkan-icd-loader lib32-vulkan-icd-loader \
    vulkan-intel lib32-vulkan-intel
fi

if [ "$use_amd_gpu" = "y" ]; then
  arch-chroot /mnt pacman -Syu \
    mesa lib32-mesa vulkan-icd-loader lib32-vulkan-icd-loader \
    vulkan-radeon lib32-vulkan-radeon
fi

if [ "$use_nvidia_gpu" = "y" ]; then
  arch-chroot /mnt pacman -Syu \
    egl-wayland vulkan-icd-loader lib32-vulkan-icd-loader \
    nvidia nvidia-settings nvidia-utils lib32-nvidia-utils
fi

arch-chroot /mnt pacman -Syu \
  pipewire pipewire-alsa pipewire-pulse pipewire-jack \
  sshfs gvfs gvfs-afc gvfs-goa gvfs-google gvfs-gphoto2 gvfs-mtp gvfs-nfs gvfs-smb

if [ "$use_plasma" = "y" ]; then
  arch-chroot /mnt pacman -Syu \
    plasma-meta xdg-desktop-portal xdg-desktop-portal-kde \
    sddm sddm-kcm kde-gtk-config print-manager kdeconnect partitionmanager \
    konsole dolphin ark kcalc spectacle gwenview okular

  arch-chroot /mnt systemctl enable sddm
fi

if [ "$use_gnome" = "y" ]; then
  arch-chroot /mnt pacman -Syu \
    gnome xdg-desktop-portal xdg-desktop-portal-gnome
    
  arch-chroot /mnt systemctl enable gdm
fi

arch-chroot /mnt pacman -Syu \
  gnome-keyring ffmpeg vlc firefox libreoffice-still-pt-br foliate qbittorrent \

arch-chroot /mnt systemctl enable NetworkManager
arch-chroot /mnt systemctl enable firewalld
arch-chroot /mnt systemctl enable bluetooth
arch-chroot /mnt systemctl enable cups.socket

arch-chroot /mnt firewall-cmd --permanent --add-service=kdeconnect

arch-chroot /mnt mkinitcpio -P

arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=ArchLinux
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg

arch-chroot /mnt gpasswd -a "$uname" audio
