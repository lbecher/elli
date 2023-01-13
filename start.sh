#!/bin/bash

gname="archlvm"

pefi="/dev/nvme0n1p1"
pboot="/dev/nvme0n1p2"
pluks="/dev/nvme0n1p3"

mkfs.ext4 $pluks
pluks_uuid=$( blkid -o value -s UUID $pluks )
plvm="/dev/mapper/luks-$pluks_uuid"
plvm_name="luks-$pluks_uuid"

mirrorlist=$( cat conf/mirrorlist )

echo "${mirrorlist}" > /etc/pacman.d/mirrorlist

nano /etc/pacman.conf

cryptsetup -s 256 -h sha256 -c aes-xts-plain64 luksFormat $pluks
cryptsetup luksOpen $pluks $plvm_name

pvcreate $plvm
vgcreate $gname $plvm

mkfs.vfat -F32 $pefi
mkfs.ext4 $pboot

lvcreate -C y -L 8GB -n swap $gname
mkswap /dev/$gname/swap

lvcreate -C n -l 100%FREE -n root $gname
mkfs.ext4 /dev/$gname/root

mount /dev/$gname/root /mnt

mkdir /mnt/boot
mkdir /mnt/efi

mount $pboot /mnt/boot
mount $pefi /mnt/efi

swapon /dev/$gname/swap

pacstrap /mnt base base-devel linux linux-headers linux-firmware grub efibootmgr lvm2 cryptsetup intel-ucode git nano

genfstab -U /mnt > /mnt/etc/fstab
