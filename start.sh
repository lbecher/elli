#!/bin/bash

gname="archlvm"

pefi="/dev/nvme0n1p1"
pboot="/dev/nvme0n1p2"
pluks="/dev/nvme0n1p3"

phome_enabled=true
phome_size="80GB"

pswap_enabled=true
pswap_size="8GB"


mkfs.ext4 $pluks
pluks_uuid=$( blkid -o value -s UUID $pluks )
plvm="/dev/mapper/luks-$pluks_uuid"
plvm_name="luks-$pluks_uuid"

cryptsetup -s 256 -h sha256 -c aes-xts-plain64 luksFormat $pluks
cryptsetup luksOpen $pluks $plvm_name

pvcreate $plvm
vgcreate $gname $plvm

mkfs.vfat -F32 $pefi
mkfs.ext4 $pboot

if [ "$pswap_enabled" = "true" ]; then
  lvcreate -C y -L $pswap_size -n swap $gname
  mkswap /dev/$gname/swap
fi
if [ "$phome_enabled" = "true" ]; then
  lvcreate -C n -L $proot_size -n home $gname
  mkfs.ext4 /dev/$gname/home
fi

lvcreate -C n -l 100%FREE -n root $gname
mkfs.ext4 /dev/$gname/root
mount /dev/$gname/root /mnt
mkdir /mnt/boot
mkdir /mnt/efi
mount $pboot /mnt/boot
mount $pefi /mnt/efi

if [ "$pswap_enabled" = "true" ]; then
  swapon /dev/$gname/swap
fi
if [ "$phome_enabled" = "true" ]; then
  mkdir /mnt/home
  mount /dev/$gname/home /mnt/home
fi

pacstrap /mnt base base-devel linux linux-headers linux-firmware grub \
  efibootmgr lvm2 cryptsetup amd-ucode intel-ucode git nano

genfstab -U /mnt > /mnt/etc/fstab
