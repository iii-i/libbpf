#!/bin/bash

set -euo pipefail

source $(cd $(dirname $0) && pwd)/helpers.sh

travis_fold start prepare_selftests "Building selftests"

LLVM_VER=12
LIBBPF_PATH="${REPO_ROOT}"
REPO_PATH="travis-ci/vmtest/bpf-next"

PREPARE_SELFTESTS_SCRIPT=${VMTEST_ROOT}/prepare_selftests-${KERNEL}.sh
if [ -f "${PREPARE_SELFTESTS_SCRIPT}" ]; then
	(cd "${REPO_ROOT}/${REPO_PATH}/tools/testing/selftests/bpf" && ${PREPARE_SELFTESTS_SCRIPT})
fi

if [[ "${KERNEL}" = 'LATEST' ]]; then
	VMLINUX_H=
else
	VMLINUX_H=${VMTEST_ROOT}/vmlinux.h
fi

if [[ "$LIBBPF_ARCH" == s390x ]]; then
	"$VMTEST_ROOT"/build_deps.sh "$VMTEST_ROOT"/config.sh
	source "$VMTEST_ROOT"/config.sh
	EXTRA_MFLAGS+=(test_verifier)
else
	EXTRA_MFLAGS=()
fi

make \
	CLANG=clang-${LLVM_VER} \
	LLC=llc-${LLVM_VER} \
	LLVM_STRIP=llvm-strip-${LLVM_VER} \
	VMLINUX_BTF="${VMLINUX_BTF}" \
	VMLINUX_H=${VMLINUX_H} \
	-C "${REPO_ROOT}/${REPO_PATH}/tools/testing/selftests/bpf" \
	-j $((2*$(nproc))) \
	"${EXTRA_MFLAGS[@]}"
mkdir ${LIBBPF_PATH}/selftests
cp -R "${REPO_ROOT}/${REPO_PATH}/tools/testing/selftests/bpf" \
	${LIBBPF_PATH}/selftests
cd ${LIBBPF_PATH}
rm selftests/bpf/.gitignore
git add selftests

git add "${VMTEST_ROOT}/configs/blacklist"

travis_fold end prepare_selftests
