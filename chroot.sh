#!/bin/bash

gname="archlvm"
hname="arch"

username="user"

pluks="/dev/nvme0n1p3"
pluks_uuid=$( blkid -o value -s UUID ${pluks} )
pluks_name="luks-$pluks_uuid"

grub_p1=$( cat conf/grub_p1.conf )
grub_p2=$( cat conf/grub_p2.conf )
mkicpio=$( cat conf/mkinitcpio.conf )
mirrorlist=$( cat conf/mirrorlist )

echo "${mirrorlist}" > /etc/pacman.d/mirrorlist

echo "LANG=pt_BR.UTF-8" > /etc/locale.conf
echo "KEYMAP=br-abnt2" > /etc/vconsole.conf
echo -e "en_US.UTF-8 UTF-8\npt_BR.UTF-8 UTF-8" > /etc/locale.gen
ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
hwclock --systohc
locale-gen

nano /etc/pacman.conf

useradd -m -G wheel $username
passwd $username
EDITOR=nano visudo

echo "$hname" > /etc/hostname
echo -e "127.0.0.1 localhost.localdomain localhost\n::1 localhost.localdomain localhost\n127.0.1.1 $hname.localdomain $hname" > /etc/hosts
echo "$pluks_name UUID=$pluks_uuid none discard" > /etc/crypttab
echo "${mkicpio}" > /etc/mkinitcpio.conf
mkinitcpio -P

grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=ArchLinux
grub-mkconfig -o /boot/grub/grub.cfg
echo "${grub_p1}" > /etc/default/grub
echo "GRUB_CMDLINE_LINUX=\"rd.luks.uuid=$pluks_name rhgb quiet\"" >> /etc/default/grub
echo "${grub_p2}" >> /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

pacman -Syu ttf-bitstream-vera ttf-croscore ttf-dejavu ttf-droid gnu-free-fonts \
  ttf-ibm-plex ttf-liberation ttf-linux-libertine ttf-roboto ttf-fira-code \
  tex-gyre-fonts ttf-ubuntu-font-family cantarell-fonts ttf-opensans ttf-croscore \
  noto-fonts noto-fonts-emoji noto-fonts-extra awesome-terminal-fonts

pacman -Syu power-profiles-daemon networkmanager bluez bluez-utils
systemctl enable NetworkManager
systemctl enable bluetooth

pacman -Syu avahi cups cups-pdf libcups ghostscript gutenprint foomatic-db-engine \
  foomatic-db foomatic-db-ppds foomatic-db-nonfree foomatic-db-nonfree-ppds \
  foomatic-db-gutenprint-ppds
systemctl enable cups.socket

<<plasmade
pacman -Syu plasma-wayland-session plasma-meta egl-wayland \
  pipewire pipewire-alsa pipewire-pulse pipewire-jack \
  sddm sddm-kcm kde-gtk-config print-manager kdeconnect \
  konsole dolphin ark kcalc spectacle gwenview okular kate
systemctl enable sddm
plasmade

pacman -Syu gdm gnome gnome-console \
  pipewire pipewire-alsa pipewire-pulse pipewire-jack \
  packagekit gnome-packagekit archlinux-appstream-data
ln -s /dev/null /etc/udev/rules.d/61-gdm.rules
systemctl enable gdm

sudo pacman -Syu gvfs gvfs-afc gvfs-goa gvfs-google gvfs-gphoto2 gvfs-mtp gvfs-nfs gvfs-smb

pacman -Syu vulkan-intel lib32-vulkan-intel lib32-mesa vulkan-icd-loader lib32-vulkan-icd-loader wine lutris
#pacman -Syu vulkan-radeon lib32-vulkan-radeon lib32-mesa vulkan-icd-loader lib32-vulkan-icd-loader wine lutris
pacman -Syu nvidia nvidia-settings nvidia-utils lib32-nvidia-utils vulkan-icd-loader lib32-vulkan-icd-loader wine lutris
pacman -Syu nvidia-prime switcheroo-control
systemctl enable switcheroo-control

pacman -Syu vlc firefox libreoffice-still-pt-br flatpak ffmpeg gnome-keyring
