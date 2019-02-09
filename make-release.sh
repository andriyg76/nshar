#!/bin/sh -e
#
# Create a distributable archive of the current version of Makeself

SOURCE_DIR="$(dirname $(realpath $0))"
VER=`cat VERSION`
TMP_DIR=/tmp/nshar-$VER
rm -Rvf $TMP_DIR || true
mkdir $TMP_DIR
cp -a nshar* README.md COPYING VERSION $TMP_DIR/
cd $TMP_DIR
./nshar.sh . > "$SOURCE_DIR/nshar-$VER.shar" && chmod +x "$SOURCE_DIR/nshar-$VER.shar"
