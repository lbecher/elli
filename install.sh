#!/bin/bash

#
# Parâmetros
#

gname="archlinux" # nome do grupo de volume
hname="archlinux" # nome do host
uname="user" # nome de usuário

use_intel_gpu="n"
use_amd_gpu="y"
use_nvidia_gpu="n"

pefi="/dev/nvme0n1p1" # partição EFI
pboot="/dev/nvme0n1p2" # partição do GRUB
pluks="/dev/nvme0n1p3" # partição do sistema de arquivos criptografado

use_swap="n" # usar volume lógico dedicado para swap
use_home="n" # usar volume lógico dedicado para /home

swap_size="8GB" # afeta somente se você usar volume dedicado para swap
root_size="64GB" # afeta somente se você usar volume dedicado para /home

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

cryptsetup -s 256 -h sha256 -c aes-xts-plain64 luksFormat "$pluks"

pluks_uuid=$( blkid -o value -s UUID "$pluks" )
plvm="/dev/mapper/luks-$pluks_uuid"
plvm_name="luks-$pluks_uuid"

cryptsetup luksOpen "$pluks" "$plvm_name"

pvcreate "$plvm"
vgcreate "$gname" "$plvm"

if [ "$use_swap" = "y" ]; then
  lvcreate -C y -L "$swap_size" -n swap $gname
  mkswap /dev/$gname/swap
  swapon /dev/$gname/swap
fi

if [ "$use_home" = "y" ]; then
  lvcreate -C n -L "$root_size" -n root "$gname"
  lvcreate -C n -l 100%FREE -n home "$gname"
  
  mkfs.xfs "/dev/$gname/root"
  mkfs.xfs "/dev/$gname/home"

  mount "/dev/$gname/root" "/mnt"
  
  mkdir "/mnt/home"
  mount "/dev/$gname/home" "/mnt/home"
else
  lvcreate -C n -l 100%FREE -n root "$gname"
  mkfs.xfs "/dev/$gname/root"
  mount "/dev/$gname/root" "/mnt"
fi

mkfs.vfat -F32 "$pefi"
mkfs.ext4 "$pboot"

mkdir "/mnt/efi"
mkdir "/mnt/boot"

mount "$pefi" "/mnt/efi"
mount "$pboot" "/mnt/boot"

pacstrap /mnt base base-devel linux linux-headers linux-firmware \
  intel-ucode amd-ucode grub efibootmgr lvm2 cryptsetup xfsprogs \
  ttf-bitstream-vera ttf-croscore ttf-dejavu ttf-droid \
  ttf-ibm-plex ttf-liberation ttf-linux-libertine ttf-roboto \
  tex-gyre-fonts ttf-ubuntu-font-family cantarell-fonts \
  noto-fonts noto-fonts-emoji noto-fonts-extra awesome-terminal-fonts \
  ttf-fira-code ttf-croscore ttf-opensans gnu-free-fonts \
  avahi cups cups-pdf libcups ghostscript gutenprint foomatic-db-engine \
  foomatic-db foomatic-db-ppds foomatic-db-nonfree foomatic-db-nonfree-ppds \
  foomatic-db-gutenprint-ppds power-profiles-daemon networkmanager \
  bluez bluez-utils networkmanager firewalld git curl wget nano fuse rustup \
  dosfstools exfat-utils ntfs-3g

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

genfstab -U /mnt > /mnt/etc/fstab
echo "$plvm_name UUID=$pluks_uuid none discard" > /mnt/etc/crypttab

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
echo "HOOKS=(base systemd autodetect keyboard sd-vconsole modconf block sd-encrypt lvm2 filesystems fsck)" >> /mnt/etc/mkinitcpio.conf

echo "GRUB_TIMEOUT=5" > /mnt/etc/default/grub
echo "GRUB_DISTRIBUTOR=\"ArchLinux\"" >> /mnt/etc/default/grub
echo "GRUB_DEFAULT=\"saved\"" >> /mnt/etc/default/grub
echo "GRUB_DISABLE_SUBMENU=true" >> /mnt/etc/default/grub
echo "GRUB_TERMINAL_OUTPUT=\"console\"" >> /mnt/etc/default/grub
echo "GRUB_CMDLINE_LINUX=\"rd.luks.uuid=$plvm_name rhgb quiet\"" >> /mnt/etc/default/grub
echo "GRUB_DISABLE_RECOVERY=true" >> /mnt/etc/default/grub
echo "GRUB_ENABLE_BLSCFG=true" >> /mnt/etc/default/grub

arch-chroot /mnt ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
arch-chroot /mnt hwclock --systohc
arch-chroot /mnt locale-gen

sed -e '/^#[[:space:]]*%wheel ALL=(ALL:ALL) ALL/s/^#[[:space:]]*//' -i /mnt/etc/sudoers

arch-chroot /mnt useradd -m -G wheel "$uname"
echo "Defina uma senha para o usuário criado."
arch-chroot /mnt passwd "$uname"

arch-chroot /mnt pacman -Syu \
  plasma-meta xdg-desktop-portal gnome-keyring \
  pipewire pipewire-alsa pipewire-pulse pipewire-jack \
  sddm sddm-kcm kde-gtk-config print-manager kdeconnect partitionmanager \
  konsole dolphin ark kcalc spectacle gwenview okular \
  gvfs sshfs gvfs-afc gvfs-goa gvfs-google gvfs-gphoto2 gvfs-mtp gvfs-nfs gvfs-smb \
  ffmpeg vlc firefox libreoffice-still-pt-br foliate qbittorrent 

arch-chroot /mnt systemctl enable NetworkManager
arch-chroot /mnt systemctl enable firewalld
arch-chroot /mnt systemctl enable bluetooth
arch-chroot /mnt systemctl enable cups.socket
arch-chroot /mnt systemctl enable sddm

arch-chroot /mnt firewall-cmd --permanent --add-service=kdeconnect

arch-chroot /mnt mkinitcpio -P

arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=ArchLinux
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg

arch-chroot /mnt gpasswd -a "$uname" audio
