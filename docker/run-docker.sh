#!/bin/bash

TOP_DIR=$(cd $(dirname $0) && pwd)

if [ "$1" != "" ]
then
	TOP_DIR=$1
fi

if [ -n "$XAUTHORITY" ]
then
	XAUTH="-e XAUTHORITY -v ${XAUTHORITY}:${XAUTHORITY}"
fi


docker run -v ${TOP_DIR}:${TOP_DIR} \
	-v $HOME/parrot:$HOME/parrot \
	-v /opt:/opt \
	-e KCONFIG_USE_INSTALLED=1 \
	-e DISPLAY \
	${XAUTH} \
	--net=host \
	-w ${TOP_DIR} \
	-i \
	-t \
	--privileged \
	-u 1000 \
	snappy1604_1
