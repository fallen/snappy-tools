#!/bin/bash
#export TARGET_ARCH='arm'
#export TARGET_LIBC='eglibc'
#export TARGET_OS='linux'
#export TARGET_OS_FLAVOUR='parrot'
#export TARGET_CPU='tegrax1'
#export USE_CONFIG_CHECK=1
#export NO_CLONE=1
#export ALCHEMY_TARGET_SCAN_ADD_DIRS=~/dev/dragonfly/packages/
#export TARGET_CROSS=/opt/arm-2014.11-linaro/bin/arm-linux-gnueabihf- 
#export TARGET_CUDA_ROOT_DIR := /opt/cuda-7.0
#export TARGET_NVCC := $(TARGET_CUDA_ROOT_DIR)/bin/nvcc
#export ALCHEMY_WORKSPACE_DIR=$PWD
#export ALCHEMY_TARGET_CONFIG_DIR=$PWD
#
#touch global.config
#ALCHEMY_DIR=$HOME/dev/dragonfly/build/alchemy
#ALCHEMAKE=$ALCHEMY_DIR/scripts/alchemake.py
#
#$ALCHEMAKE -f $ALCHEMY_DIR/main.mk -C $ALCHEMY_WORKSPACE_DIR wifid-fakedriver wifid-cli wifid-bcmdriver bcm43602 libnetmon-bcm43526b dnsmasq final
set -x
DFLY=~/dev/dragonfly
OUT=$DFLY/out/dragonfly-x1/final
PACKAGES="wifid-fakedriver wifid-cli wifid-bcmdriver bcm43602 libnetmon-bcm43526b dnsmasq final"
cd $DFLY
./build.sh -p x1 -A $PACKAGES -j8
cd -

dynloader_wrapper.py $OUT
mkdir -p $OUT/meta
cp snapcraft.yaml $OUT/meta/snap.yaml
snapcraft snap $OUT
