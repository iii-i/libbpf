#!/bin/bash
# This script builds a private copy of elfutils.
set -e -u -x -o pipefail

source $(cd $(dirname $0) && pwd)/helpers.sh

travis_fold start build_elfutils "Building elfutils"

REPO_PATH=$1
ZLIB_PATH=$2
ELFUTILS_URL=http://sourceware.org/pub/elfutils/0.177/elfutils-0.177.tar.bz2

mkdir "$REPO_PATH"
cd "$REPO_PATH"
curl "$ELFUTILS_URL" | tar -xj --strip-components=1

if [[ -z ${CROSS_COMPILE+x} ]]; then
	host=()
else
	host=("--host=${CROSS_COMPILE::-1}")
fi
./configure \
	"${host[@]}" \
	--prefix="$REPO_PATH"/install \
	CFLAGS="-I$ZLIB_PATH/include" \
	LDFLAGS="-L$ZLIB_PATH/lib -Wl,-rpath-link=$ZLIB_PATH/lib"
make -j$((4*$(nproc)))
make install

travis_fold end build_elfutils
