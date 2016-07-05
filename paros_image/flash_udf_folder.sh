#!/bin/bash

if [ $# -lt 3 ]
then
	echo "usage: $0 dragonfly_path folder product"
	exit 1
fi

CWD=$PWD
DRAGONFLY_PATH=$1
FOLDER=$2
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

#if [ ! -f parrot-tools-installer-nvidia_5.11.7_all.deb ]
#then
#	wget http://canari/debian/binary-i386/parrot-tools-installer-nvidia_5.11.7_all.deb
#fi
#dpkg -x parrot-tools-installer-nvidia_5.11.7_all.deb $tempdir
#cp $tempdir/usr/local/share/pinst/paros/linux.dtb $DRAGONFLY_PATH/build/pinst/5.11.11/usr/local/share/pinst/paros/
#rm -rf $tempdir

sudo tar -C $FOLDER -cf image.tar .
sudo chown $USER:$USER image.tar

cp image.tar $DRAGONFLY_PATH/out/dragonfly-$PRODUCT/dragonfly-$PRODUCT.tar
export PINST_TMPL=$DRAGONFLY_PATH/build/pinstrc
$DRAGONFLY_PATH/build/pinst/5.11.12/usr/local/bin/pinst_build paros linux installer_fab $DRAGONFLY_PATH/out/dragonfly-$PRODUCT/dragonfly-$PRODUCT.tar
$DRAGONFLY_PATH/build/pinst/5.11.12/usr/local/bin/tegra_flasher paros installer_fab
