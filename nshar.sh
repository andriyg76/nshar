#!/bin/sh
#
# Makeself version 2.3.x
#  by Stephane Peter <megastep@megastep.org>
#
# Utility to create self-extracting tar.gz archives.
# The resulting archive is a file holding the tar.gz archive with
# a small Shell script stub that uncompresses the archive to a temporary
# directory and then executes a given script from withing that directory.
#
# Makeself home page: http://makeself.io/
#
# Version 2.0 is a rewrite of version 1.0 to make the code easier to read and maintain.
#
# Version history :
# - 0.01: Initial public release, rename and simplify
#
# (C) 2019 By Andriy Gushuley <andriyg@icloud.com>
#   based on Makeself (C) 1998-2018 by Stephane Peter <megastep@megastep.org>
#
# This software is released under the terms of the GNU GPL version 2 and above
# Please read the license at http://www.gnu.org/copyleft/gpl.html
# Self-extracting archives created with this script are explictly NOT released under the term of the GPL
#

set -e

VERSION=0.01
COMMAND="$0"
unset CDPATH

# For Solaris systems
if test -d /usr/xpg4/bin; then
    PATH=/usr/xpg4/bin:$PATH
    export PATH
fi

# Procedures

usage()
{
    echo "Usage: $0 [args --] list of files or dirs"
    echo "params can be one or more of the following :"
    echo "    --version | -v     : Print out Makeself version number and exit"
    echo "    --help | -h        : Print out this help message"
    echo "    --quiet | -q       : Do not print any messages other than errors."
    echo "    --gzip             : Compress using gzip (default if detected)"
    echo "    --compress         : Compress using the UNIX 'compress' command (default if gzip is not detected)"
    echo "    --nocomp           : Do not compress the data"
    echo "    --bzip2            : Compress using bzip2 instead of gzip"
    echo "    --xz               : Compress using xz instead of gzip"
    echo "    --base64           : Encode tar using base64 (default if base64 detected)"
    echo "    --uuencode         : Encode tar using uuencode (default if base64 not detected)"
    echo "    --compat           : Encode archive in uuencode/decode, compress with UNIX 'compress'"
    echo "    --follow           : Follow the symlinks in the archive"
    echo
    exit 1
}

# Default settings
if type gzip 2>&1 > /dev/null; then
    COMPRESS=gzip
else
    COMPRESS=Unix
fi
VERBOSE=y
TAR_ARGS=cv
TAR_EXTRA=""
GPG_EXTRA=""
DU_ARGS=-ks
HEADER=`dirname "$0"`/nshar-header.sh
TARGETDIR=""
DATE=`LC_ALL=C date`
ENCODE=base64

# LSM file stuff
LSM_CMD="echo No LSM."

while true
do
    case "$1" in
    --version | -v)
	echo $COMMAND version $VERSION
	exit 0
	;;
    --bzip2)
	COMPRESS=bzip2
	shift
	;;
    --gzip)
	COMPRESS=gzip
	shift
	;;
    --xz)
	COMPRESS=xz
	shift
	;;
    --compress)
	COMPRESS=Unix
	shift
	;;
    --base64)
	ENCODE=base64
	shift
	;;
    --uuencode)
	ENCODE=uuencode
	shift
	;;
    --nocomp)
	COMPRESS=none
	shift
	;;
    -q | --quiet)
	QUIET=y
	shift
	;;
    -h | --help)
	usage
	;;
    -*)
	echo Unrecognized flag : "$1"
	usage
	;;
    --|*)
	break
	;;
    esac
done

if test $# -lt 1; then
	usage
fi

if test "$QUIET" = "y" || test "$TAR_QUIETLY" = "y"; then
    if test "$TAR_ARGS" = "cv"; then
	TAR_ARGS="c"
    elif test "$TAR_ARGS" = "cvh";then
	TAR_ARGS="ch"
    fi
fi

SCRIPTARGS="$*"

case $COMPRESS in
gzip)
    GZIP_CMD="gzip"
    GUNZIP_CMD="gzip -cd"
    ;;
bzip2)
    GZIP_CMD="bzip2"
    GUNZIP_CMD="bzip2 -d"
    ;;
xz)
    GZIP_CMD="xz"
    GUNZIP_CMD="xz -d"
    ;;
Unix)
    GZIP_CMD="compress -cf"
    GUNZIP_CMD="exec 2>&-; uncompress -c || test \\\$? -eq 2 || gzip -cd"
    ;;
none)
    GZIP_CMD="cat"
    GUNZIP_CMD="cat"
    ;;
esac

case $ENCODE in
base64)
    ENCODE_CMD="base64"
    DECODE_CMD="base64 --decode -i -"
    ;;
uuencode)
    ENCODE_CMD="uuencode -"
    GUNZIP_CMD="uudecode -o - -"
    ENCRYPT="gpg"
    ;;
esac


if test -f "$HEADER"; then
	# Generate a fake header to count its lines
	SKIP=0
    . "$HEADER"
else
    echo "Unable to open header file: $HEADER" >&2
    exit 1
fi

if test "$QUIET" = "n"; then
    USIZE=`du $DU_ARGS "$SCRIPTARGS" | awk '{print $1}'`

   echo About to compress $USIZE KB of data... >&2
   echo Adding files to archive n... >&2
fi

{
    tar $TAR_EXTRA -$TAR_ARGS $SCRIPTARGS | $GZIP_CMD | $ENCODE_CMD
} || {
    echo "ERROR: failed to archive files: $SCRIPTARGS" >&2
    exit 1
}
