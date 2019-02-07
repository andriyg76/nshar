#!/bin/sh
#
# nshar 0.1
#  by Andriy Gushuley <andriyg@icloud.com>
#
# Utility to create self-extracting archives, which can be passed by plaintext, or by.
# The resulting archive is a script file holding extracting part and encoded by text packed tar
# with payload.
#
# Makeself home page: http://nshar.io/
#
# Version history :
# - 0.01: Initial public release, rename makeself to nshar and simplify
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
    cat << __USAGE__ >&2
Usage: $0 [args --] list of files or dirs
        params can be one or more of the following :
    --version | -v     : Print out Makeself version number and exit
    --help | -h        : Print out this help message
    --quiet | -q       : Do not print any messages other than errors.
    --gzip             : Compress using gzip (default if detected)
    --compress         : Compress using the UNIX 'compress' command (default if gzip is not detected)
    --nocomp           : Do not compress the data
    --bzip2            : Compress using bzip2 instead of gzip
    --xz               : Compress using xz instead of gzip
    --base64           : Encode tar using base64 (default if base64 detected)
    --uuencode         : Encode tar using uuencode (default if base64 not detected)
    --compat           : Encode archive in uuencode/decode, compress with UNIX 'compress'
    --follow           : Follow the symlinks in the archive
    
__USAGE__
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
__EOF_MARK__=__END_OF_ARCHIVE__

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
	--compat)
	ENCODE=uuencode
	COMPRESS=Unix
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
    -*|--*)
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
echo $__EOF_MARK__
