#!/bin/bash

if [ "$1" != "" ]
then
	PREINSTALLED_SNAP="--install=$1"
fi

if [ "$SKIP_IMG" != "1" ]
then
	sudo rm -rf final_image system-boot
	sudo /sbin/losetup -d /dev/loop0
	rm -f paros.img
	sudo -E ./ubuntu-device-flash --verbose core 16 -o paros.img --channel edge --gadget ../../../paros_1.0_all.snap --kernel ../../../paros_kernel/paros-kernel_3.10.97_armhf.snap --os ubuntu-core --developer-mode --enable-ssh $PREINSTALLED_SNAP
fi
./flash_udf_img.sh ~/dev/workspace/ ./paros.img x1
