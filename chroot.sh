#!/bin/bash

gname="archlvm"
hname="a515-54g"

pluks="/dev/nvme0n1p3"
pluks_uuid=$( blkid -o value -s UUID ${pluks} )
pluks_name="luks-$pluks_uuid"

#proot="/dev/archlvm/root"
#proot_uuid=$( blkid -o value -s UUID ${proot} )

grub_p1=$( cat /root/elli/conf/grub_p1.conf )
grub_p2=$( cat /root/elli/conf/grub_p2.conf )
mkicpio=$( cat /root/elli/conf/mkinitcpio.conf )

echo -e "pt_BR.UTF-8 UTF-8\nen_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=pt_BR.UTF-8" > /etc/locale.conf
echo "KEYMAP=br-abnt2" > /etc/vconsole.conf
ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
hwclock --systohc

echo "$hname" > /etc/hostname
echo -e "127.0.0.1 localhost.localdomain localhost\n::1 localhost.localdomain localhost\n127.0.1.1 $hname.localdomain $hname" > /etc/hosts

cp conf/
echo "$pluks_name UUID=$pluks_uuid none discard" > /etc/crypttab

echo "${mkicpio}" > /etc/mkinitcpio.conf
mkinitcpio -P

#cp dracut-install.sh /usr/local/bin/
#cp dracut-remove.sh /usr/local/bin/
#chmod +x /usr/local/bin/dracut-install.sh
#chmod +x /usr/local/bin/dracut-remove.sh

#mkdir /etc/pacman.d/hooks
#cp "90-dracut-install.hook" /etc/pacman.d/hooks/
#cp "60-dracut-remove.hook" /etc/pacman.d/hooks/
#ln -sf /dev/null /etc/pacman.d/hooks/90-mkinitcpio-install.hook
#ln -sf /dev/null /etc/pacman.d/hooks/60-mkinitcpio-remove.hook
#pacman -Sy linux

grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=ArchLinux
grub-mkconfig -o /boot/grub/grub.cfg
echo "${grub_p1}" > /etc/default/grub
echo "GRUB_CMDLINE_LINUX=\"rd.luks.uuid=$pluks_name rhgb quiet\"" >> /etc/default/grub
echo "${grub_p2}" >> /etc/default/grub;
grub-mkconfig -o /boot/grub/grub.cfg;

systemctl enable NetworkManager;
systemctl enable cups.socket;
systemctl enable bluetooth.service;
