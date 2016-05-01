FROM ubuntu:16.04

ENV TERM xterm
ENV DEBIAN_FRONTEND noninteractive

# install apt-add-repository
RUN apt-get update && apt-get -y install software-properties-common

# install snappy-dev/tools repository
RUN apt-add-repository -y ppa:snappy-dev/tools

# install snappy-tools
RUN apt-get update && apt-get -y install ubuntu-snappy snapcraft

RUN adduser --disabled-password --gecos "Patrick Boettcher,,," pboettch

RUN apt-get -y install strace
RUN apt-get -y install python3-pip python3-setuptools
RUN apt-get -y install vim bsdmainutils pkg-config
RUN apt-get -y install curl git python
RUN apt-get -y install python3-pyelftools
RUN apt-get -y install autoconf automake autopoint autotools-dev cmake cmake-data libarchive13 libcurl3 libjsoncpp1 libsigsegv2 libtool m4
RUN apt-get -y install wget

# ubuntu-device-flash deps
RUN apt-get -y install parted kpartx dosfstools

# FROM https://github.com/ubuntu-core/snappy-jenkins/blob/master/containers/jenkins-slave-xenial/Dockerfile

# ubuntu-device-flash uses parts of snappy that try to reload udev rules when
# processing oem snaps, which this is not needed at build time; udev is not
# not available in the container, making a symlink solves the dependency without
# affecting the build process
RUN ln -s /bin/true /usr/local/bin/udevadm

# Patch ubuntu-device-flash to generate all-snaps images.
RUN wget https://people.canonical.com/~mvo/all-snaps/ubuntu-device-flash && \
  chmod +x ubuntu-device-flash && \
  mv ubuntu-device-flash /usr/bin/ubuntu-device-flash

RUN echo "pboettch ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

ADD id_rsa /home/pboettch/.ssh/id_rsa
ADD config /home/pboettch/.ssh/config

RUN mkdir ~/bin; curl https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo; chmod a+x ~/bin/repo
RUN git config --global user.name "Patrick Boettcher" && git config --global user.email "patrick.boettcher@posteo.de"
#RUN mkdir $HOME/dev && cd ~/dev && PATH=$HOME/bin:$PATH repo init -u ssh://gerrit.parrot.biz/drones/dragonfly/manifest.git && PATH=$HOME/bin:$PATH repo sync


CMD /bin/bash
