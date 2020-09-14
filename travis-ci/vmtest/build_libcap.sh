#!/bin/bash
# This script builds a private copy of libcap.
set -e -u -x -o pipefail

source $(cd $(dirname $0) && pwd)/helpers.sh

travis_fold start build_libcap "Building libcap"

REPO_PATH=$1
LIBCAP_ORIGIN=https://git.kernel.org/pub/scm/libs/libcap/libcap.git

mkdir -p "$REPO_PATH"
cd "$REPO_PATH"
git init
git fetch "$LIBCAP_ORIGIN" --tags
git checkout v0.2.43

# libcap Makefiles are broken w.r.t. cross-compilation in two significant ways.
# Fortunately, we can work around that.
# 1) CC will take into account CROSS_COMPILE only if it isn't defined by make
#    yet. Therefore use --no-builtin-variables.
# 2) Unless we define BUILD_CC, it will be the same as CC.
EXTRA_MFLAGS=(
	"--no-builtin-variables"
	"BUILD_CC=gcc"
	"PAM_CAP=no"
	"prefix=$REPO_PATH/install"
)
make "${EXTRA_MFLAGS[@]}" -j$((4*$(nproc)))
make "${EXTRA_MFLAGS[@]}" install

travis_fold end build_libcap
