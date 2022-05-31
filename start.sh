#!/bin/bash

pboot="$1"
pluks="$2"
pluks_uuid=$( blkid -o value -s UUID $pluks )
proot_size="$3"
gname="$4"

cryptsetup -s 256 -h sha256 -c aes-xts-plain64 luksFormat $pluks
cryptsetup luksOpen $pluks luks-$pluks_uuid

pvcreate /dev/mapper/luks-$pluks_uuid
vgcreate $gname /dev/mapper/luks-$pluks_uuid
lvcreate -C n -L $proot_size -n root $gname
lvcreate -C n -l 100%FREE -n home $gname

mkfs.vfat -F32 $pboot
mkfs.ext4 /dev/$gname/root
mkfs.ext4 /dev/$gname/home

mount /dev/$gname/root /mnt
mkdir /mnt/home
mkdir /mnt/boot
mount /dev/$gname/home /mnt/home
mount $pboot /mnt/boot

extra="intel-ucode amd-ucode power-profiles-daemon mesa vulkan-intel intel-media-driver pipewire pipewire-alsa pipewire-pulse pipewire-jack wayland avahi libcups cups cups-pdf dbus-python gobject-introspection-runtime python-cairo python-gobject python-pycups python-pycurl ghostscript foomatic-db-gutenprint-ppds foomatic-db-engine sane sane-airscan ipp-usb nano ttf-bitstream-vera ttf-croscore ttf-dejavu ttf-droid gnu-free-fonts ttf-ibm-plex ttf-liberation ttf-linux-libertine noto-fonts ttf-roboto tex-gyre-fonts ttf-ubuntu-font-family cantarell-fonts ttf-opensans ttf-croscore bluez bluez-utils ffmpeg gst-libav gstreamer-vaapi"

pacstrap /mnt base base-devel linux linux-headers linux-firmware grub efibootmgr dracut dbus lvm2 cryptsetup networkmanager python3 git nano $extra;

genfstab -U /mnt > /mnt/etc/fstab

cp -r ./elli /mnt/root
