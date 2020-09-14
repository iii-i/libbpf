#!/bin/bash
# This script builds a private copy of qemu.
set -e -u -x -o pipefail

source $(cd $(dirname $0) && pwd)/helpers.sh

travis_fold start build_qemu "Building qemu"

REPO_PATH=$1
case "$LIBBPF_ARCH" in
s390x)
	QEMU_ORIGIN=https://github.com/cohuck/qemu.git
	QEMU_BRANCH=s390-next
	QEMU_COMMIT=d3da0eac2734
	QEMU_TARGET=s390x-softmmu
	;;
*)
	echo "LIBBPF_ARCH=$LIBBPF_ARCH is not supported" 2>&1
	exit 1
	;;
esac

mkdir -p "$REPO_PATH"
cd "$REPO_PATH"
git init
git fetch "$QEMU_ORIGIN" "$QEMU_BRANCH"
git checkout "$QEMU_COMMIT"

./configure --prefix="$REPO_PATH"/install --target-list="$QEMU_TARGET"
make -j$((4*$(nproc)))
make install

travis_fold end build_qemu
