#!/bin/bash
# This script builds a private copy of zlib.
set -e -u -x -o pipefail

source $(cd $(dirname $0) && pwd)/helpers.sh

travis_fold start build_zlib "Building zlib"

REPO_PATH=$1
ZLIB_ORIGIN=https://github.com/madler/zlib.git

mkdir "$REPO_PATH"
cd "$REPO_PATH"
git init
git remote add origin "$ZLIB_ORIGIN"
git fetch origin
git checkout v1.2.11

CROSS_PREFIX=${CROSS_COMPILE:-} ./configure --prefix="$REPO_PATH"/install
make -j$((4*$(nproc)))
make install

travis_fold end build_zlib
