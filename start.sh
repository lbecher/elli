#!/bin/bash

# Configure

gname="archlvm"

pefi="/dev/nvme0n1p1"
pboot="/dev/nvme0n1p2"
pluks="/dev/nvme0n1p3"

use_swap="y"
use_home="y"

# Install

cryptsetup -s 256 -h sha256 -c aes-xts-plain64 luksFormat "$pluks"

pluks_uuid=$( blkid -o value -s UUID "$pluks" )
plvm="/dev/mapper/luks-$pluks_uuid"
plvm_name="luks-$pluks_uuid"

mirrorlist=$( cat conf/mirrorlist )

echo "${mirrorlist}" > /etc/pacman.d/mirrorlist

nano /etc/pacman.conf

cryptsetup luksOpen "$pluks" "$plvm_name"

pvcreate "$plvm"
vgcreate "$gname" "$plvm"

mkfs.vfat -F32 "$pefi"
mkfs.xfs "$pboot"

if [ "$use_swap" = "y" ]; then
  lvcreate -C y -L 16GB -n swap $gname
  mkswap /dev/$gname/swap
  swapon /dev/$gname/swap
fi

if [ "$use_home" = "y" ]; then
  lvcreate -C n -L 64GB -n root "$gname"
  lvcreate -C n -l 100%FREE -n home "$gname"
  
  mkfs.xfs "/dev/$gname/root"
  mkfs.xfs "/dev/$gname/home"

  mount "/dev/$gname/root" "/mnt"

  mkdir -p "/mnt/efi"
  mkdir -p "/mnt/boot"
  mkdir -p "/mnt/home"

  mount "$pefi" "/mnt/efi"
  mount "$pboot" "/mnt/boot"
  mount "/dev/$gname/home" "/mnt/home"
else
  lvcreate -C n -l 100%FREE -n root "$gname"
  mkfs.xfs "/dev/$gname/root"
  mount "/dev/$gname/root" "/mnt"

  mkdir -p "/mnt/efi"
  mkdir -p "/mnt/boot"

  mount "$pefi" "/mnt/efi"
  mount "$pboot" "/mnt/boot"
fi

pacstrap /mnt base base-devel \
  linux linux-headers linux-firmware \
  intel-ucode amd-ucode \
  grub efibootmgr lvm2 cryptsetup xfsprogs \
  networkmanager git nano

genfstab -U /mnt > /mnt/etc/fstab
