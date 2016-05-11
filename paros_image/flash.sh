#!/bin/bash

if [ $# -lt 1 ]
then
	echo "usage: $0 dragonfly_path image.tar"
	exit 1
fi

CWD=$PWD
DRAGONFLY_PATH=$1
IMAGE=$2

rm -rf $DRAGONFLY_PATH/build/pinst/5.11.8

if [ -f $CWD/parrot-tools-installer-nvidia-flashtools_5.11.8_all.deb ]
then
	mkdir -p $DRAGONFLY_PATH/build/pinst/5.11.8
	dpkg -x $CWD/parrot-tools-installer-nvidia-flashtools_5.11.8_all.deb $DRAGONFLY_PATH/build/pinst/5.11.8
else
	echo "error: you need to download parrot-tools-installer-nvidia-flashtools_5.11.8_all.deb"
	exit 1
fi

if [ -f $CWD/parrot-tools-installer-nvidia_5.11.8_all.deb ]
then
	mkdir -p $DRAGONFLY_PATH/build/pinst/5.11.8
	dpkg -x $CWD/parrot-tools-installer-nvidia_5.11.8_all.deb $DRAGONFLY_PATH/build/pinst/5.11.8
else
	echo "error: you need to download parrot-tools-installer-nvidia-flashtools_5.11.8_all.deb"
	exit 1
fi

if [ ! -f $CWD/parrot-tools-bootloaders-nvidia_5.11.6_all.deb ]
then
	wget http://canari/debian/binary-i386/parrot-tools-bootloaders-nvidia_5.11.6_all.deb
fi

dpkg -x $CWD/parrot-tools-bootloaders-nvidia_5.11.6_all.deb $DRAGONFLY_PATH/build/pinst/5.11.8

tempdir=$(mktemp -d)

if [ ! -f http://canari/debian/binary-i386/parrot-tools-installer-nvidia_5.11.7_all.deb ]
then
	wget http://canari/debian/binary-i386/parrot-tools-installer-nvidia_5.11.7_all.deb
fi
dpkg -x parrot-tools-installer-nvidia_5.11.7_all.deb $tempdir
cp $tempdir/usr/local/share/pinst/paros/linux.dtb $DRAGONFLY_PATH/build/pinst/5.11.8/usr/local/share/pinst/paros/
rm -rf $tempdir

cp $IMAGE $DRAGONFLY_PATH/out/dragonfly-x1/dragonfly-x1.tar
export PINST_TMPL=$DRAGONFLY_PATH/build/pinstrc
$DRAGONFLY_PATH/build/pinst/5.11.8/usr/local/bin/pinst_build paros linux installer_fab $DRAGONFLY_PATH/out/dragonfly-x1/dragonfly-x1.tar
$DRAGONFLY_PATH/build/pinst/5.11.8/usr/local/bin/tegra_flasher paros installer_fab
