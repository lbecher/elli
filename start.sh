#!/bin/bash

gname=$( cat /root/elli/conf/gname.conf );
pboot=$( cat /root/elli/conf/pboot.conf );
pluks=$( cat /root/elli/conf/pluks.conf );

pswap_size=$( cat /root/elli/conf/pswap_size.conf );
phome_size=$( cat /root/elli/conf/phome_size.conf );

mkfs.vfat -F32 /dev/${pboot}
cryptsetup -s 256 -h sha256 -c aes-xts-plain64 luksFormat /dev/${pluks};
cryptsetup luksOpen /dev/${pluks} ${pluks}_crypt;

pvcreate /dev/mapper/${pluks}_crypt;
vgcreate ${gname} /dev/mapper/${pluks}_crypt;
lvcreate -C y -L ${pswap_size} -n swap ${gname};
lvcreate -C n -L ${phome_size} -n home ${gname};
lvcreate -C n -l 100%FREE -n root ${gname};

mkfs.ext4 /dev/${gname}/root;
mkfs.ext4 /dev/${gname}/home;
mkswap /dev/${gname}/swap;
swapon /dev/${gname}/swap;

mount /dev/${gname}/root /mnt;
mkdir /mnt/home;
mkdir /mnt/boot;
mount /dev/${gname}/home /mnt/home;
mount /dev/${pboot} /mnt/boot;

pacstrap /mnt base base-devel linux linux-firmware grub efibootmgr ucode-intel dbus lvm2 cryptsetup networkmanager avahi power-profiles-daemon mesa vulkan-intel intel-media-driver intel-compute-runtime ocl-icd opencl-headers pepiwire pipewire-alsa pipewire-pulse pipewire-jack wayland libcups cups cups-pdf ghostscript sane sane-airscan ipp-usb nano ttf-bitstream-vera ttf-croscore ttf-dejavu ttf-droid gnu-free-fonts ttf-ibm-plex ttf-liberation ttf-linux-libertine noto-fonts ttf-roboto tex-gyre-fonts ttf-ubuntu-font-family cantarell-fonts ttf-opensans ttf-croscore;

genfstab -U /mnt > /mnt/etc/fstab;

cp -r /root/elli /mnt/root/;

arch-chroot /mnt /root/elli/chroot.sh;
