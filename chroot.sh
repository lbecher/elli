#!/bin/bash

gname="archlvm"
hname="arch-linux"

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
  ttf-ibm-plex ttf-liberation ttf-linux-libertine noto-fonts ttf-roboto \
  tex-gyre-fonts ttf-ubuntu-font-family cantarell-fonts ttf-opensans ttf-croscore

pacman -Syu power-profiles-daemon networkmanager
systemctl enable NetworkManager

pacman -Syu avahi cups cups-pdf libcups ghostscript gutenprint foomatic-db-engine \
  foomatic-db foomatic-db-ppds foomatic-db-nonfree foomatic-db-nonfree-ppds \
  foomatic-db-gutenprint-ppds
systemctl enable cups.socket

<<kde
pacman -Syu egl-wayland plasma-meta konsole kwrite dolphin ark sddm \
  sddm-kcm plasma-wayland-session pipewire pipewire-alsa pipewire-pulse \
  pipewire-jack kde-gtk-config kdeconnect bluez bluez-utils \
systemctl enable sddm
systemctl enable bluetooth
kde

pacman -Syu gnome gdm gnome-console bluez bluez-utils packagekit gnome-software-packagekit-plugin
systemctl enable gdm
systemctl enable bluetooth

pacman -Syu firefox vlc ffmpeg gnome-keyring
