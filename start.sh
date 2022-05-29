#!/bin/bash

gname="archlvm"

pboot="sda1"
pluks="sda2"
pluks_uuid=$( blkid -o value -s UUID /dev/$pluks )
proot_size="20G"

cryptsetup -s 256 -h sha256 -c aes-xts-plain64 luksFormat /dev/$pluks
cryptsetup luksOpen /dev/$pluks luks-$pluks_uuid

pvcreate /dev/mapper/luks-$pluks_uuid
vgcreate $gname /dev/mapper/luks-$pluks_uuid
lvcreate -C n -L $proot_size -n root $gname
lvcreate -C n -l 100%FREE -n home $gname

mkfs.vfat -F32 /dev/$pboot
mkfs.ext4 /dev/$gname/root
mkfs.ext4 /dev/$gname/home

mount /dev/$gname/root /mnt
mkdir /mnt/home
mkdir /mnt/boot
mount /dev/$gname/home /mnt/home
mount /dev/$pboot /mnt/boot

#extra="avahi power-profiles-daemon mesa vulkan-intel intel-media-driver pipewire pipewire-alsa pipewire-pulse pipewire-jack wayland libcups cups cups-pdf dbus-python gobject-introspection-runtime python-cairo python-gobject python-pycups python-pycurl ghostscript foomatic-db-gutenprint-ppds foomatic-db-engine sane sane-airscan ipp-usb nano ttf-bitstream-vera ttf-croscore ttf-dejavu ttf-droid gnu-free-fonts ttf-ibm-plex ttf-liberation ttf-linux-libertine noto-fonts ttf-roboto tex-gyre-fonts ttf-ubuntu-font-family cantarell-fonts ttf-opensans ttf-croscore bluez bluez-utils flac wavpack libmad opus libvorbis faac faad2 jasper libwebp libavif libheif aom libdv x265 x264 libmpeg2 libtheora libvpx gst-libav gstreamer-vaapi handbrake-cli"

pacstrap /mnt base base-devel linux linux-headers linux-firmware grub efibootmgr dracut dbus lvm2 cryptsetup networkmanager python3 git nano;

genfstab -U /mnt > /mnt/etc/fstab

cp -r /root/elli /mnt/root/
