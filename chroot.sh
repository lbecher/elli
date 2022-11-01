#!/bin/bash

gname="archlvm"
hname="arch"

pluks="/dev/nvme0n1p3"
pluks_uuid=$( blkid -o value -s UUID ${pluks} )
pluks_name="luks-$pluks_uuid"

grub_p1=$( cat /root/elli/conf/grub_p1.conf )
grub_p2=$( cat /root/elli/conf/grub_p2.conf )
mkicpio=$( cat /root/elli/conf/mkinitcpio.conf )

echo "LANG=pt_BR.UTF-8" > /etc/locale.conf
echo "KEYMAP=br-abnt2" > /etc/vconsole.conf
echo "pt_BR.UTF-8 UTF-8" > /etc/locale.gen
ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
hwclock --systohc
locale-gen

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

pacman -Syu plasma-meta konsole kwrite dolphin ark sddm sddm-kcm plasma-wayland-session egl-wayland kde-gtk-config kdeconnect firefox

systemctl enable sddm
systemctl enable bluetooth
systemctl enable NetworkManager
systemctl enable cups.socket
