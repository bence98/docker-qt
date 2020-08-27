#! /bin/bash
#
# This script is licensed under the MIT license:
#
# MIT License
#
# Copyright (c) 2017-2018 Erik Stromdahl <erik.stromdahl@gmail.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
# -----------------------------------------------------------------------------
#
# Script used to build QT creator from source.
# The QT libraries and tools are needed by QT creator and are also built
#
# The content of this script has been derived from the below two pages:
#
# http://wiki.qt.io/Building_Qt_5_from_Git
# http://wiki.qt.io/Building_Qt_Creator_from_Git

SCRIPT_PATH=`readlink -f $0`
SCRIPT_DIR=`dirname $SCRIPT_PATH`

# Configuration env vars will be set to default values if not defined.
[[ -z ${QT_TOP_DIR+x} ]] && QT_TOP_DIR=$SCRIPT_DIR
#[[ -z ${QT_VERSION+x} ]] && QT_VERSION="master"
[[ -z ${QT_J_LEVEL+x} ]] && QT_J_LEVEL=$((`nproc`+1))
[[ -z ${QT_GIT_URL+x} ]] && QT_GIT_URL="https://code.qt.io/qt/qt5.git"
[[ -z ${QT_TAR_URL+x} ]] && QT_TAR_URL="http://download.qt.io/official_releases/qt"
[[ -z ${QT_WORKING_DIR+x} ]] && QT_WORKING_DIR="qt5"
[[ -z ${QT_INIT_REPOSITORY_OPTS+x} ]] && QT_INIT_REPOSITORY_OPTS="--module-subset=default,-qtwebkit,-qtwebkit-examples,-qtwebengine"
[[ -z ${QT_CONFIGURE_OPTS+x} ]] && QT_CONFIGURE_OPTS="-opensource -nomake examples -nomake tests -confirm-license"
[[ -z ${QT_CREATOR_GIT_URL+x} ]] && QT_CREATOR_GIT_URL="https://code.qt.io/qt-creator/qt-creator.git"
[[ -z ${QT_CREATOR_TAR_URL+x} ]] && QT_CREATOR_TAR_URL="http://download.qt.io/official_releases/qtcreator"
#[[ -z ${QT_CREATOR_VERSION+x} ]] && QT_CREATOR_VERSION="master"
[[ -z ${QT_CREATOR_WORKING_DIR+x} ]] && QT_CREATOR_WORKING_DIR="qt-creator"

build_qt(){
mkdir qt-build
cd qt-build
../configure $QT_CONFIGURE_OPTS -prefix "/usr/local"
[ $? -ne 0 ] && >&2 echo "ERROR: ./configure failed" && exit 1
make -j $QT_J_LEVEL
[ $? -ne 0 ] && >&2 echo "ERROR: make failed" && exit 1
make install
}

build_qtcreator(){
mkdir qt-creator-build
cd qt-creator-build
qmake -r ../qtcreator.pro
[ $? -ne 0 ] && >&2 echo "ERROR: QT creator qmake failed" && exit 1
make -j $QT_J_LEVEL
[ $? -ne 0 ] && >&2 echo "ERROR: QT creator make failed" && exit 1
make install
[ $? -ne 0 ] && >&2 echo "ERROR: QT creator make install failed" && exit 1
}

build_qt_git(){
# Enter the top build dir
pushd $QT_TOP_DIR

if [ -n "$QT_VERSION" ]; then
# Clone and build QT
git clone --branch v$QT_VERSION $QT_GIT_URL $QT_WORKING_DIR
[ $? -ne 0 ] && >&2 echo "ERROR: Unable to clone git repo $QT_GIT_URL" && exit 1
pushd $QT_WORKING_DIR
perl init-repository $QT_INIT_REPOSITORY_OPTS
[ $? -ne 0 ] && >&2 echo "ERROR: init-repository failed" && exit 1
build_qt
[ $? -ne 0 ] && >&2 echo "ERROR: make install failed" && exit 1
popd
fi # [ -n "$QT_VERSION" ];

if [ -n "$QT_CREATOR_VERSION" ]; then
# Clone and build QT Creator
git clone --branch v$QT_CREATOR_VERSION --recursive $QT_CREATOR_GIT_URL $QT_CREATOR_WORKING_DIR
[ $? -ne 0 ] && >&2 echo "ERROR: Unable to clone git repo $QT_CREATOR_GIT_URL" && exit 1
pushd $QT_CREATOR_WORKING_DIR
# Make sure no submodules have the latest version, since this could
# cause build errors.
git submodule update --init
build_qtcreator
popd
fi # [ -n "$QT_CREATOR_VERSION" ];

popd #pushd $QT_TOP_DIR
}

build_qt_tar(){

if [ -n "$QT_VERSION" ]; then
# Download and build QT
QT_MINOR=$(cut -d . -f -2 <(echo $QT_VERSION))
mkdir $QT_WORKING_DIR
pushd $QT_WORKING_DIR
wget $QT_TAR_URL/$QT_MINOR/$QT_VERSION/single/qt-everywhere-opensource-src-$QT_VERSION.tar.xz
[ $? -ne 0 ] && >&2 echo "ERROR: Failed to download TAR!" && exit 1
curl $QT_TAR_URL/$QT_MINOR/$QT_VERSION/single/md5sums.txt | grep "tar\\.xz" | md5sum -c
[ $? -ne 0 ] && >&2 echo "ERROR: Non-matching md5sum (broken download?)" && exit 1
tar xf qt-everywhere-opensource-src-$QT_VERSION.tar.xz
pushd qt-everywhere-opensource-src-$QT_VERSION
build_qt
popd
popd # $QT_WORKING_DIR
fi # [ -n "$QT_VERSION" ];

if [ -n "$QT_CREATOR_VERSION" ]; then
# Download and build QT Creator
QT_CREATOR_MINOR=$(cut -d . -f -2 <(echo $QT_CREATOR_VERSION))
mkdir $QT_CREATOR_WORKING_DIR
pushd $QT_CREATOR_WORKING_DIR
wget $QT_CREATOR_TAR_URL/$QT_CREATOR_MINOR/$QT_CREATOR_VERSION/qt-creator-opensource-src-$QT_CREATOR_VERSION.tar.xz
[ $? -ne 0 ] && >&2 echo "ERROR: Failed to download TAR!" && exit 1
curl $QT_CREATOR_TAR_URL/$QT_CREATOR_MINOR/$QT_CREATOR_VERSION/md5sums.txt | grep "tar\\.xz" | md5sum -c
[ $? -ne 0 ] && >&2 echo "ERROR: Non-matching md5sum (broken download?)" && exit 1
tar xf qt-creator-opensource-src-$QT_CREATOR_VERSION.tar.xz
pushd qt-creator-opensource-src-$QT_CREATOR_VERSION
build_qtcreator
popd #qt-creator-opensource-src-$QT_CREATOR_VERSION
popd # $QT_CREATOR_WORKING_DIR
fi # [ -n "$QT_CREATOR_VERSION" ];
}

if [ -n "$QT_BUILD_FROM_TAR" ]; then
build_qt_tar
else
build_qt_git
fi
