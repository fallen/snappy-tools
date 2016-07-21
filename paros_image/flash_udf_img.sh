#!/bin/bash
if [ $# -lt 3 ]
then
	echo "usage: $0 dragonfly_path paros.img product"
	exit 1
fi

CWD=$PWD
DRAGONFLY_PATH=$1
IMAGE=$2
PRODUCT=$3

rm -rf $DRAGONFLY_PATH/build/pinst/5.11.8 DRAGONFLY_PATH/build/pinst/5.11.12

if [ -f $CWD/parrot-tools-installer-nvidia-flashtools_5.11.12_all.deb ]
then
	mkdir -p $DRAGONFLY_PATH/build/pinst/5.11.12
	dpkg -x $CWD/parrot-tools-installer-nvidia-flashtools_5.11.12_all.deb $DRAGONFLY_PATH/build/pinst/5.11.12
else
	echo "error: you need to download parrot-tools-installer-nvidia-flashtools_5.11.12_all.deb"
	exit 1
fi

if [ -f $CWD/parrot-tools-installer-nvidia_5.11.12_all.deb ]
then
	mkdir -p $DRAGONFLY_PATH/build/pinst/5.11.12
	dpkg -x $CWD/parrot-tools-installer-nvidia_5.11.12_all.deb $DRAGONFLY_PATH/build/pinst/5.11.12
else
	echo "error: you need to download parrot-tools-installer-nvidia_5.11.12_all.deb"
	exit 1
fi

if [ ! -f $CWD/parrot-tools-bootloaders-nvidia_5.11.9_all.deb ]
then
	wget http://canari/debian/binary-i386/parrot-tools-bootloaders-nvidia_5.11.9_all.deb
fi

dpkg -x $CWD/parrot-tools-bootloaders-nvidia_5.11.9_all.deb $DRAGONFLY_PATH/build/pinst/5.11.12

tempdir=$(mktemp -d)

system_boot_offset=$(echo -e "p\nq\n" | sudo fdisk $IMAGE | grep img1 | awk '{print $3;}')
echo $system_boot_offset

writable_offset=$(echo -e "p\nq\n" | sudo fdisk $IMAGE | grep img2 | awk '{print $2;}')
echo $writable_offset

system_boot_dev=$(sudo /sbin/losetup -f)
sudo losetup -o $((512*${system_boot_offset})) $system_boot_dev $IMAGE
writable_dev=$(sudo /sbin/losetup -f)
sudo losetup -o $((512*${writable_offset})) $writable_dev $IMAGE

mkdir -p system-boot
mkdir -p writable
mkdir -p final_image

sudo mount $system_boot_dev system-boot
sudo mount $writable_dev writable

kernel_snap=$(basename $(ls writable/system-data/var/lib/snapd/snaps/paros-kernel*.snap))
os_snap=$(basename $(ls writable/system-data/var/lib/snapd/snaps/ubuntu-core*.snap))

sudo mkdir -p system-boot/extlinux
# FIXME: product x1 is hardcoded because x1_snappy inheritates from it and has therefore no skel
sudo cp $DRAGONFLY_PATH/products/dragonfly/x1/skel/boot/extlinux/extlinux.conf system-boot/extlinux/
sudo sed -i -e 's@/boot/@/@g' system-boot/extlinux/extlinux.conf
sudo sed -i -e 's@/boot@/@g' system-boot/extlinux/extlinux.conf
sudo sed -i -e "s@LINUX.*@LINUX /$kernel_snap/vmlinuz@g" system-boot/extlinux/extlinux.conf
sudo sed -i -e 's@root=[^ ]*@root=/dev/disk/by-label/writable@g' system-boot/extlinux/extlinux.conf 
sudo sed -i -e "s@APPEND \(.*\)@APPEND \1 init=/lib/systemd/systemd snappy_os=$os_snap snappy_kernel=$kernel_snap net.ifnames=0@g" system-boot/extlinux/extlinux.conf
sudo sed -i -e "s@APPEND \(.*\)@APPEND \1\n\tINITRD /$kernel_snap/initrd.img@" system-boot/extlinux/extlinux.conf

sudo cp -ra writable/system-data final_image
sudo cp -r system-boot final_image/
sudo mkdir -p final_image/data
./ptmx_hack.sh ./final_image/
sudo tar -C final_image -cf image.tar .
sudo chown $USER:$USER image.tar

# cleanup
sudo umount writable
sudo umount system-boot
sudo losetup -d $system_boot_dev
sudo losetup -d $writable_dev
rmdir writable
rmdir system-boot

cp image.tar $DRAGONFLY_PATH/out/dragonfly-$PRODUCT/dragonfly-$PRODUCT.tar
cp $HOME/dev/utils/packages2/parrot_bootloaders/host/parrotboot/bin/paros/* $DRAGONFLY_PATH/build/pinst/5.11.12/usr/local/share/pinst/paros/
export PINST_TMPL=$DRAGONFLY_PATH/build/pinstrc
$DRAGONFLY_PATH/build/pinst/5.11.12/usr/local/bin/pinst_build paros linux installer_fab $DRAGONFLY_PATH/out/dragonfly-$PRODUCT/dragonfly-$PRODUCT.tar
$DRAGONFLY_PATH/build/pinst/5.11.12/usr/local/bin/tegra_flasher paros installer_fab
