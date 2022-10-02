#!/bin/bash

pefi="/dev/nvme0n1p1"
pboot="/dev/nvme0n1p2"
pluks="/dev/nvme0n1p3"

mkfs.ext4 $pluks

pluks_uuid=$( blkid -o value -s UUID $pluks )
plvm="/dev/mapper/luks-$pluks_uuid"
plvm_name="luks-$pluks_uuid"

proot_size="24GB"

gname="archlvm"

cryptsetup -s 256 -h sha256 -c aes-xts-plain64 luksFormat $pluks
cryptsetup luksOpen $pluks $plvm_name

pvcreate $plvm
vgcreate $gname $plvm
lvcreate -C n -L $proot_size -n root $gname
lvcreate -C n -l 100%FREE -n home $gname

mkfs.vfat -F32 $pefi
mkfs.ext4 $pboot
mkfs.ext4 /dev/$gname/root
mkfs.ext4 /dev/$gname/home

mount /dev/$gname/root /mnt
mkdir /mnt/home
mkdir /mnt/boot
mkdir /mnt/efi
mount /dev/$gname/home /mnt/home
mount $pboot /mnt/boot
mount $pefi /mnt/efi

fonts="ttf-bitstream-vera ttf-croscore ttf-dejavu ttf-droid gnu-free-fonts ttf-ibm-plex ttf-liberation ttf-linux-libertine noto-fonts ttf-roboto tex-gyre-fonts ttf-ubuntu-font-family cantarell-fonts ttf-opensans ttf-croscore"
midia="mesa wayland pipewire pipewire-alsa pipewire-pulse pipewire-jack gstreamer gstreamer-vaapi gst-plugin-pipewire ffmpeg libva-mesa-driver"
printer="avahi cups cups-pdf libcups ghostscript gutenprint foomatic-db-engine foomatic-db foomatic-db-ppds foomatic-db-nonfree foomatic-db-nonfree-ppds foomatic-db-gutenprint-ppds"
bluetooth="bluez bluez-utils"
cpu="amd-ucode power-profiles-daemon"
base="base base-devel linux linux-headers linux-firmware grub efibootmgr dbus lvm2 cryptsetup networkmanager git nano"

pacstrap /mnt $fonts $midia $printer $bluetooth $cpu $base;

genfstab -U /mnt > /mnt/etc/fstab
