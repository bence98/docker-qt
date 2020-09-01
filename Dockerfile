FROM ubuntu:20.04

ENV QT_VERSION 5.15.0
#ENV QT_CREATOR_VERSION 4.3.1
ENV QT_BUILD_FROM_TAR 1

# fix tzdata https://serverfault.com/a/1016972
ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Budapest

# Build prerequisites
RUN apt-get -y update && apt-get -y install qtbase5-dev \
	libxcb-xinerama0-dev \
	build-essential \
	python

# Other useful tools
RUN apt-get -y update && apt-get -y install tmux \
	wget \
	curl \
	zip \
	git \
	vim

# Simple root password in case we want to customize the container
RUN echo "root:root" | chpasswd

RUN useradd -G video -ms /bin/bash user

RUN mkdir -p /qt/build

WORKDIR /qt/build

ADD build_qt.sh /qt/build/build_qt.sh
RUN QT_VERSION=$QT_VERSION QT_CREATOR_VERSION=$QT_CREATOR_VERSION /qt/build/build_qt.sh

USER user

WORKDIR /qt

CMD ["bash"]
