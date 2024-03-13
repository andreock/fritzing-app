#!/bin/bash

# Fritzing builder for MacOS

FRITZING_DIR=$(pwd)
BUILD_DIR=$FRITZING_DIR/../

brew install wget

cd "$BUILD_DIR" || exit 255

wget https://github.com/libgit2/libgit2/archive/refs/tags/v1.7.1.zip -O libgit2-1.7.1.zip
unzip libgit2-1.7.1.zip
cd libgit2-1.7.1 || exit 255
mkdir build && cd build
cmake .. -DCMAKE_INSTALL_LIBDIR=../lib -DCMAKE_INSTALL_BINDIR=../bin \
    -DCMAKE_INSTALL_PREFIX=../prefix/ -DLINK_WITH_STATIC_LIBRARIES=OFF \
    -DBUILD_SHARED_LIBS=OFF -DCMAKE_OSX_DEPLOYMENT_TARGET=11.0
cmake --build . --target install

cd "$BUILD_DIR" || exit 255

BOOST_VERSION=1_81_0  # Last boost version supported by Fritzing
BOOST_VERSION_URL=1.81.0
wget https://boostorg.jfrog.io/artifactory/main/release/$BOOST_VERSION_URL/source/boost_$BOOST_VERSION.tar.gz
tar -xvzf boost_1_81_0.tar.gz

cd "$BUILD_DIR" || exit 255

# Use GNU readline from brew to avoid issues with Xcode one
brew install readline
sudo ln -s /opt/homebrew/opt/readline/ /usr/local/opt

# Download ng-spice
NGSPICE_VERSION=40
wget https://sourceforge.net/projects/ngspice/files/ng-spice-rework/old-releases/$NGSPICE_VERSION/ngspice-$NGSPICE_VERSION.tar.gz/download -O ngspice-$NGSPICE_VERSION.tar.gz
tar -xvf ngspice-$NGSPICE_VERSION.tar.gz
cd ngspice-$NGSPICE_VERSION || exit 255

# Patch ng-spice building script to build a statically linked library
sed '55 c\
    ../configure --with-ngshared --enable-xspice --enable-cider --with-readline=/usr/local/opt/readline CFLAGS="-m64 -O0 -g -Wall -I/opt/X11/include/freetype2 -I/usr/local/opt/readline/include" LDFLAGS="-m64 -g -L/usr/local/opt/readline/lib -L/opt/X11/lib"
' compile_macos_clang.sh > compile_macos_clang_static_55.sh
sed '62 c\
    ../configure --with-ngshared --enable-xspice --enable-cider --with-readline=/usr/local/opt/readline --disable-debug  CFLAGS="-m64 -O2 -I/opt/X11/include/freetype2 -I/usr/local/opt/readline/include -I/usr/local/opt/ncurses/include" LDFLAGS="-m64 -L/usr/local/opt/readline/lib -L/usr/local/opt/ncurses/lib -L/opt/X11/lib"
' compile_macos_clang_static_55.sh > compile_macos_clang_static.sh
rm -rf compile_macos_clang_static_55.sh
# Build ng-spice
sudo bash compile_macos_clang_static.sh

cd "$BUILD_DIR" || exit 255
git clone https://github.com/svgpp/svgpp.git
mv svgpp svgpp-1.3.0

# Install more necessary libraries
brew install quazip
sudo port install polyclipping

cd "$FRITZING_DIR" || exit 255

# Build fritzing
qmake
make -j$(sysctl -n hw.ncpu)

