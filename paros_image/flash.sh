#!/bin/bash

if [ "$DFLY" == "" ]
then
	DFLY=$HOME/dev/workspace2
fi

if [ "$1" != "" ]
then
	PREINSTALLED_SNAP="--install=$1"
fi

if [ "$SKIP_IMG" != "1" ]
then
	sudo rm -rf final_image system-boot
	sudo /sbin/losetup -d /dev/loop0
	rm -f paros.img
	rm -f ../../../paros_1.0_all.snap
	cd ../../../
	cp $DFLY/out/dragonfly-x1/final/boot/tegra210-paros*.dtb paros_gadget/boot-assets/
	snapcraft snap paros_gadget
	cd -
	sudo -E ./ubuntu-device-flash --verbose core 16 -o paros.img --channel edge --gadget ../../../paros_1.0_all.snap --kernel ../../../paros_kernel/paros-kernel_3.10.97_armhf.snap --os ubuntu-core --developer-mode --enable-ssh $PREINSTALLED_SNAP
fi
./flash_udf_img.sh $DFLY ./paros.img x1
