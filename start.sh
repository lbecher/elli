#!/bin/bash

gname=$( cat /root/elli/conf/gname.conf );
pboot=$( cat /root/elli/conf/pboot.conf );
pluks=$( cat /root/elli/conf/pluks.conf );
pluks_uuid=$( blkid -o value -s UUID /dev/${pluks} );

pswap_size=$( cat /root/elli/conf/pswap_size.conf );
proot_size=$( cat /root/elli/conf/proot_size.conf );

mkfs.vfat -F32 /dev/${pboot}
cryptsetup -s 256 -h sha256 -c aes-xts-plain64 luksFormat /dev/${pluks};
cryptsetup luksOpen /dev/${pluks} ${pluks_uuid}_crypt;

pvcreate /dev/mapper/${pluks_uuid}_crypt;
vgcreate ${gname} /dev/mapper/${pluks_uuid}_crypt;
lvcreate -C y -L ${pswap_size} -n swap ${gname};
lvcreate -C n -L ${proot_size} -n root ${gname};
lvcreate -C n -l 100%FREE -n home ${gname};

mkfs.ext4 /dev/${gname}/root;
mkfs.ext4 /dev/${gname}/home;
mkswap /dev/${gname}/swap;
#swapon /dev/${gname}/swap;

mount /dev/${gname}/root /mnt;
mkdir /mnt/home;
mkdir /mnt/boot;
mount /dev/${gname}/home /mnt/home;
mount /dev/${pboot} /mnt/boot;

pacstrap /mnt base base-devel linux linux-headers linux-firmware grub efibootmgr intel-ucode dbus lvm2 cryptsetup networkmanager avahi power-profiles-daemon mesa vulkan-intel intel-media-driver intel-compute-runtime ocl-icd opencl-headers pipewire pipewire-alsa pipewire-pulse pipewire-jack wayland libcups cups cups-pdf dbus-python gobject-introspection-runtime python-cairo python-gobject python-pycups python-pycurl ghostscript foomatic-db-gutenprint-ppds foomatic-db-engine sane sane-airscan ipp-usb nano ttf-bitstream-vera ttf-croscore ttf-dejavu ttf-droid gnu-free-fonts ttf-ibm-plex ttf-liberation ttf-linux-libertine noto-fonts ttf-roboto tex-gyre-fonts ttf-ubuntu-font-family cantarell-fonts ttf-opensans ttf-croscore bluez bluez-utils flac wavpack libmad opus libvorbis faac faad2 jasper libwebp libavif libheif aom libdv x265 x264 libmpeg2 libtheora libvpx gst-libav gstreamer-vaapi handbrake-cli python3 git;

genfstab -U /mnt > /mnt/etc/fstab;

cp -r /root/elli /mnt/root/;
