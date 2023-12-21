#!/bin/bash

#
# Parâmetros
#

gname="archlvm" # nome do grupo de volume

pefi="/dev/nvme0n1p1"
pboot="/dev/nvme0n1p2"
pluks="/dev/nvme0n1p3"

use_swap="n" # usar volume dedicado para swap
use_home="n" # usar volume dedicado para home

swap_size="8GB" # afeta somente se você usar volume dedicado para swap
root_size="64GB" # afeta somente se você usar volume dedicado para home

#
# Configuração
#

mirrorlist=$( cat conf/mirrorlist )

echo "${mirrorlist}" > /etc/pacman.d/mirrorlist

nano /etc/pacman.conf

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

pacstrap /mnt base base-devel \
  linux linux-headers linux-firmware \
  intel-ucode amd-ucode \
  grub efibootmgr lvm2 cryptsetup xfsprogs \
  networkmanager git curl \
  nano fuse

genfstab -U /mnt > /mnt/etc/fstab
