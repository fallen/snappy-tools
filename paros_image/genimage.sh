#!/bin/bash

if [ $# -lt 2 ]
then
	echo "usage: $0 dragonfly_path u-boot_path"
	echo "for u-boot: git clone ssh://gerrit.parrot.biz/os/bootloader/tegra/u-boot.git"
	exit 1
fi

CWD=$PWD

udf_hash=$(sha512sum ./ubuntu-device-flash | cut -d' ' -f1)
mkdir -p $HOME/.cache/ubuntu-image
cp ubuntu-device-flash $HOME/.cache/ubuntu-image/blob.$udf_hash

echo "let's build normal dragonfly Paros firmware"
DRAGONFLY_PATH=$1
UBOOT_PATH=$2
if [ "$NOBUILD" != "1" ]
then
	cd $DRAGONFLY_PATH
	./build.sh -p x1 -t all -j6
	cd -
fi
echo "let's download RPI2 ubuntu-core image"
echo -e "pi2\ndevel\n" | ./ubuntu-image

system_boot_offset=$(echo -e "p\nq\n" | sudo fdisk pi2-devel.img | grep img1 | awk '{print $3;}')
echo $system_boot_offset

writable_offset=$(echo -e "p\nq\n" | sudo fdisk pi2-devel.img | grep img2 | awk '{print $2;}')
echo $writable_offset

system_boot_dev=$(losetup -f)
sudo losetup -o $((512*${system_boot_offset})) $system_boot_dev pi2-devel.img
writable_dev=$(losetup -f)
sudo losetup -o $((512*${writable_offset})) $writable_dev pi2-devel.img

mkdir -p rpi2_system_boot
mkdir -p rpi2_writable
mkdir -p system-boot
mkdir -p writable

sudo mount $system_boot_dev rpi2_system_boot
sudo mount $writable_dev rpi2_writable

sudo cp -a $DRAGONFLY_PATH/out/dragonfly-x1/final/boot/. system-boot/
sudo cp -ra rpi2_writable/system-data writable/

echo "Preparing Snappy initrd..."

tempinit=$(mktemp -d)
cp rpi2_system_boot/canonical-pi2-linux*.snap/initrd.img $tempinit
cd $tempinit
lzcat initrd.img | cpio -idv
rm initrd.img
rm -rf lib/firmware
mkdir -p lib/firmware
cp -r $DRAGONFLY_PATH/out/dragonfly-x1/final/lib/firmware ./lib/
rm -rf lib/modules
cp -r $DRAGONFLY_PATH/out/dragonfly-x1/final/lib/modules ./lib/
find . ! -name . | cpio -o -H newc -v > ../initrd.img
lzma ../initrd.img
cd -
sudo cp $tempinit/../initrd.img.lzma system-boot/initrd.img
rm $tempinit/../initrd.img.lzma
rm -rf $tempinit

echo "Copying Paros kernel..."

sudo cp $DRAGONFLY_PATH/out/dragonfly-x1/final/boot/Image system-boot/

echo "Removing RPI2 kernel modules and putting in Paros kernel modules"

kernel_snap=$(basename $(ls rpi2_writable/system-data/var/lib/snapd/snaps/canonical-pi2-linux*.snap))
os_snap=$(basename $(ls rpi2_writable/system-data/var/lib/snapd/snaps/ubuntu-core*.snap))

tempdir=$(mktemp -d)
sudo cp rpi2_writable/system-data/var/lib/snapd/snaps/$kernel_snap $tempdir/
cd $tempdir
sudo unsquashfs $kernel_snap
sudo rm -rf squashfs-root/lib/modules
sudo cp -r $DRAGONFLY_PATH/out/dragonfly-x1/final/lib/modules squashfs-root/lib/
sudo rm -f $kernel_snap
sudo mksquashfs squashfs-root $kernel_snap -comp xz
sudo cp $kernel_snap $CWD/writable/system-data/var/lib/snapd/snaps/
cd -
sudo rm -rf $tempdir

echo "Updating uboot config"

sudo sed -i -e 's@/boot/@/@g' system-boot/extlinux/extlinux.conf
sudo sed -i -e 's@/boot@/@g' system-boot/extlinux/extlinux.conf
sudo sed -i -e 's@mmcblk0p1@disk/by-label/writable@g' system-boot/extlinux/extlinux.conf 
sudo sed -i -e "s@APPEND \(.*\)@APPEND \1 init=/lib/systemd/systemd snappy_os=$os_snap snappy_kernel=$kernel_snap@g" system-boot/extlinux/extlinux.conf
sudo sed -i -e 's@INITRD.*@INITRD /initrd.img@g' system-boot/extlinux/extlinux.conf
echo "Generating uboot.env"

cd $UBOOT_PATH
git checkout u-boot-x1-parrot
export ARCH=arm
export CROSS_COMPILE=/opt/arm-2014.11-aarch64-linaro/bin/aarch64-linux-gnu-
make paros_defconfig
make
cd tools

./mkenvimage -s 2600 -o uboot.env $CWD/uboot.txt
sudo cp uboot.env $CWD/system-boot/
cd $CWD

echo "Building final image.tar archive"

sudo cp -r system-boot writable/
sudo tar -C writable -cf image.tar .
sudo chown $USER:$USER image.tar

# cleanup
sudo umount rpi2_writable
sudo umount rpi2_system_boot
sudo losetup -d  $system_boot_dev
sudo losetup -d  $writable_dev
sudo rm -rf system-boot
sudo rm -rf writable
rmdir rpi2_writable
rmdir rpi2_system_boot
