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

echo "Server = http://archlinux.c3sl.ufpr.br/\$repo/os/\$arch" > /etc/pacman.d/mirrorlist
echo "Server = http://mirror.ufam.edu.br/archlinux/\$repo/os/\$arch" >> /etc/pacman.d/mirrorlist
echo "Server = http://mirror.ufscar.br/archlinux/\$repo/os/\$arch" >> /etc/pacman.d/mirrorlist
echo "Server = http://www.caco.ic.unicamp.br/archlinux/\$repo/os/\$arch" >> /etc/pacman.d/mirrorlist

sed -e 's/^#[[:space:]]*ParallelDownloads.*/ParallelDownloads = 5/' -i /etc/pacman.conf

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

pacstrap /mnt base base-devel linux linux-headers linux-firmware \
  intel-ucode amd-ucode grub efibootmgr lvm2 cryptsetup xfsprogs \
  networkmanager git curl nano fuse

genfstab -U /mnt > /mnt/etc/fstab
echo "$pluks_name UUID=$pluks_uuid none discard" > /mnt/etc/crypttab

echo "$hname" > /mnt/etc/hostname
echo "LANG=pt_BR.UTF-8" > /mnt/etc/locale.conf
echo "KEYMAP=br-abnt2" > /mnt/etc/vconsole.conf

echo "127.0.0.1 localhost.localdomain localhost" > /mnt/etc/hosts
echo "::1 localhost.localdomain localhost" >> /mnt/etc/hosts
echo "127.0.1.1 $hname.localdomain $hname" >> /mnt/etc/hosts

echo "Server = http://archlinux.c3sl.ufpr.br/\$repo/os/\$arch" > /mnt/etc/pacman.d/mirrorlist
echo "Server = http://mirror.ufam.edu.br/archlinux/\$repo/os/\$arch" >> /mnt/etc/pacman.d/mirrorlist
echo "Server = http://mirror.ufscar.br/archlinux/\$repo/os/\$arch" >> /mnt/etc/pacman.d/mirrorlist
echo "Server = http://www.caco.ic.unicamp.br/archlinux/\$repo/os/\$arch" >> /mnt/etc/pacman.d/mirrorlist

echo "MODULES=()" > /mnt/etc/mkinitcpio.conf
echo "BINARIES=()" >> /mnt/etc/mkinitcpio.conf
echo "FILES=()" >> /mnt/etc/mkinitcpio.conf
echo "HOOKS=(base systemd autodetect keyboard sd-vconsole modconf block sd-encrypt lvm2 filesystems fsck)" >> /mnt/etc/mkinitcpio.conf

echo "GRUB_TIMEOUT=5" > /mnt/etc/default/grub
echo "GRUB_DISTRIBUTOR=\"ArchLinux\"" >> /mnt/etc/default/grub
echo "GRUB_DEFAULT=\"saved\"" >> /mnt/etc/default/grub
echo "GRUB_DISABLE_SUBMENU=true" >> /mnt/etc/default/grub
echo "GRUB_TERMINAL_OUTPUT=\"console\"" >> /mnt/etc/default/grub
echo "GRUB_CMDLINE_LINUX=\"rd.luks.uuid=$pluks_name rhgb quiet\"" >> /mnt/etc/default/grub
echo "GRUB_DISABLE_RECOVERY=true" >> /mnt/etc/default/grub
echo "GRUB_ENABLE_BLSCFG=true" >> /mnt/etc/default/grub

sed -e 's/^#[[:space:]]*ParallelDownloads =.*/ParallelDownloads = 5/' -i /mnt/etc/pacman.conf
sed -e '/^#[[:space:]]*\[multilib\]/,/^#[[:space:]]*Include/s/^#[[:space:]]*//' -i /mnt/etc/pacman.conf
sed -e '/^#[[:space:]]*%wheel ALL=(ALL:ALL) ALL/s/^#[[:space:]]*//' -i /mnt/etc/sudoers
sed -e '/^#[[:space:]]*en_US.UTF-8 UTF-8/,/^#[[:space:]]*pt_BR.UTF-8 UTF-8/s/^#[[:space:]]*//' -i /mnt/etc/locale.gen

ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
hwclock --systohc
locale-gen
mkinitcpio -P
useradd -m -G wheel "$uname"
passwd "$uname"
