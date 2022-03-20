#!/bin/bash

gname=$( cat /root/elli/conf/gname.conf );
hname=$( cat /root/elli/conf/hname.conf );

pluks=$( cat /root/elli/conf/pluks.conf );
pluks_uuid=$( blkid -o value -s UUID /dev/${pluks} );

grub_p1=$( cat /root/elli/conf/grub_p1.conf );
grub_p2=$( cat /root/elli/conf/grub_p2.conf );

echo "Setup root password:";
passwd;

echo "pt_BR.UTF-8 UTF-8" > /etc/locale.gen;
locale-gen;
echo "LANG=pt_BR.UTF-8" > /etc/locale.conf;
echo "KEYMAP=br-abnt2" > /etc/vconsole.conf;
ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime;
hwclock --systohc;

echo "${hname}" > /etc/hostname;
echo -e "127.0.0.1 localhost.localdomain localhost\n::1 localhost.localdomain localhost\n127.0.1.1 ${hname}.localdomain ${hname}" > /etc/hosts;

rm /etc/mkinitcpio.conf;
cp /root/elli/conf/mkinitcpio.conf /etc/mkinitcpio.conf;
chown root:root /etc/mkinitcpio.conf;
chmod 644 /etc/mkinitcpio.conf;
mkinitcpio -P;

grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB;
echo $grub_p1 > /etc/default/grub;
echo "GRUB_CMDLINE_LINUX=\"cryptdevice=UUID=${pluks_uuid}:${pluks}_crypt root=/dev/${gname}/root\"" >> /etc/default/grub
echo $grub_p2 >> /etc/default/grub;
grub-mkconfig -o /boot/grub/grub.cfg;
