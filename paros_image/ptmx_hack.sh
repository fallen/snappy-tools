#!/bin/bash
FINAL_IMAGE=$1

tmpdir=$(mktemp -d)
uc=$(find $FINAL_IMAGE -name ubuntu-core*.snap)

sudo cp $uc $tmpdir/
cd $tmpdir
snap_name=$(basename $uc)
sudo chown $USER:$USER $snap_name
sudo unsquashfs $snap_name
sudo rm -f $snap_name
sudo sed -i -e 's@\(.*ptmx.*\)$@\1\n\    mount options=(rw bind) /dev/pts/ptmx/ -> /dev/ptmx/,   # for bind mounting@g' squashfs-root/etc/apparmor.d/usr.bin.ubuntu-core-launcher
sudo mksquashfs squashfs-root $snap_name -comp xz
cd -
sudo cp $tmpdir/$snap_name $uc
sudo rm -rf $tmpdir
