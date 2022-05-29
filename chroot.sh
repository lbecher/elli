#!/bin/bash

user="luiz"

gname="archlvm"
hname="arch"

pluks="sda2"
pluks_uuid=$( blkid -o value -s UUID /dev/${pluks} )

grub_p1=$( cat /root/elli/conf/grub_p1.conf )
grub_p2=$( cat /root/elli/conf/grub_p2.conf )

useradd -m -G wheel $user

echo "Set root password:"
passwd

echo "Set $user password:"
passwd $user

echo -e "pt_BR.UTF-8 UTF-8\nen_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=pt_BR.UTF-8" > /etc/locale.conf
echo "KEYMAP=br-abnt2" > /etc/vconsole.conf
ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
hwclock --systohc

echo "$hname" > /etc/hostname
echo -e "127.0.0.1 localhost.localdomain localhost\n::1 localhost.localdomain localhost\n127.0.1.1 $hname.localdomain $hname" > /etc/hosts

echo "luks-$pluks_uuid UUID=$pluks_uuid none discard" > /etc/crypttab

cp dracut-install.sh /usr/local/bin/
cp dracut-remove.sh /usr/local/bin/
chmod +x /usr/local/bin/dracut-install.sh
chmod +x /usr/local/bin/dracut-remove.sh

mkdir /etc/pacman.d/hooks
cp "90-dracut-install.hook" /etc/pacman.d/hooks/
cp "60-dracut-remove.hook" /etc/pacman.d/hooks/
ln -sf /dev/null /etc/pacman.d/hooks/90-mkinitcpio-install.hook
ln -sf /dev/null /etc/pacman.d/hooks/60-mkinitcpio-remove.hook

pacman -Sy linux

grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
echo "${grub_p1}" > /etc/default/grub
echo "GRUB_CMDLINE_LINUX=\"rd.luks.uuid=luks-$pluks_uuid rhgb quiet\"" >> /etc/default/grub
echo "${grub_p2}" >> /etc/default/grub;
grub-mkconfig -o /boot/grub/grub.cfg;

systemctl enable NetworkManager;
