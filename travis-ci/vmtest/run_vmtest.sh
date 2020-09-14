#!/bin/bash

set -eu

source $(cd $(dirname $0) && pwd)/helpers.sh

if [[ -z ${LIBBPF_ARCH+x} ]]; then
	echo "LIBBPF_ARCH: x86_64"
	LIBBPF_ARCH=x86_64
	export LIBBPF_ARCH
elif [[ "$LIBBPF_ARCH" == s390x ]]; then
	echo "LIBBPF_ARCH: s390x"
	sudo apt-get install -y \
		gcc-s390x-linux-gnu \
		libc6-dev-s390x-cross \
		libglib2.0-dev \
		libpixman-1-dev
	ARCH=s390
	CROSS_COMPILE=s390x-linux-gnu-
	export ARCH CROSS_COMPILE
else
	echo "Unsupported LIBBPF_ARCH: ${LIBBPF_ARCH}"
	exit 1
fi

VMTEST_SETUPCMD="PROJECT_NAME=${PROJECT_NAME} ./${PROJECT_NAME}/travis-ci/vmtest/run_selftests.sh"

echo "KERNEL: $KERNEL"
echo

# Build latest pahole
${VMTEST_ROOT}/build_pahole.sh travis-ci/vmtest/pahole

travis_fold start install_clang "Installing Clang/LLVM"

# Install required packages
wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | sudo apt-key add -
echo "deb http://apt.llvm.org/bionic/ llvm-toolchain-bionic main" | sudo tee -a /etc/apt/sources.list
sudo apt-get update
sudo apt-get -y install clang-12 lld-12 llvm-12
sudo apt-get -y install python-docutils # for rst2man

travis_fold end install_clang

# Build selftests (and latest kernel, if necessary)
KERNEL="${KERNEL}" ${VMTEST_ROOT}/prepare_selftests.sh travis-ci/vmtest/bpf-next

# Escape whitespace characters.
setup_cmd=$(sed 's/\([[:space:]]\)/\\\1/g' <<< "${VMTEST_SETUPCMD}")

sudo adduser "${USER}" kvm

if [[ "${KERNEL}" = 'LATEST' ]]; then
  sudo -E sudo -E -u "${USER}" "${VMTEST_ROOT}/run.sh" -b travis-ci/vmtest/bpf-next -o -d ~ -s "${setup_cmd}" ~/root.img;
else
  sudo -E sudo -E -u "${USER}" "${VMTEST_ROOT}/run.sh" -k "${KERNEL}*" -o -d ~ -s "${setup_cmd}" ~/root.img;
fi
