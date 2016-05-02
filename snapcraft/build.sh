#!/bin/bash
export TARGET_ARCH='arm'
export TARGET_LIBC='eglibc'
export TARGET_OS='parrot'
#export TARGET_CPU='tegrax1' # Tegra X1
export TARGET_CPU='armv7a'    # Raspi
export USE_CONFIG_CHECK=1
export NO_CLONE=1
export ALCHEMY_TARGET_SCAN_ADD_DIRS=$HOME/parrot/packages/
export ALCHEMY_PATH=$HOME/parrot/build/alchemy 
#export TARGET_CROSS=/opt/arm-2014.11-linaro/bin/arm-linux-gnueabihf-
export TARGET_FLOAT_ABI=hard
export TARGET_TEST=1


~/.local/bin/snapcraft snap
