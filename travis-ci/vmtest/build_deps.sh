#!/bin/bash
# This script builds private copies of all dependencies.
set -e -u -x -o pipefail

config_sh=$1

# Build zlib.
ZLIB_REPO_PATH="travis-ci/vmtest/zlib"
if [[ ! -d "$REPO_ROOT/$ZLIB_REPO_PATH/install" ]]; then
	"$(dirname "$0")"/build_zlib.sh "$REPO_ROOT/$ZLIB_REPO_PATH"
fi

# Build elfutils.
ELFUTILS_REPO_PATH="travis-ci/vmtest/elfutils"
if [[ ! -d "$REPO_ROOT/$ELFUTILS_REPO_PATH/install" ]]; then
	"$(dirname "$0")"/build_elfutils.sh \
		"$REPO_ROOT/$ELFUTILS_REPO_PATH" \
		"$REPO_ROOT/$ZLIB_REPO_PATH/install"
fi

# Build libcap.
LIBCAP_REPO_PATH="travis-ci/vmtest/libcap"
if [[ ! -d "$REPO_ROOT/$LIBCAP_REPO_PATH/install" ]]; then
	"$(dirname "$0")"/build_libcap.sh "$REPO_ROOT/$LIBCAP_REPO_PATH"
fi

# Print EXTRA_MFLAGS that the caller can use.
cflags="-I$REPO_ROOT/$ZLIB_REPO_PATH/install/include \
-I$REPO_ROOT/$ELFUTILS_REPO_PATH/install/include \
-I$REPO_ROOT/$LIBCAP_REPO_PATH/install/include"
ldflags="-L$REPO_ROOT/$ZLIB_REPO_PATH/install/lib \
-Wl,-rpath-link=$REPO_ROOT/$ZLIB_REPO_PATH/install/lib \
-L$REPO_ROOT/$ELFUTILS_REPO_PATH/install/lib \
-L$REPO_ROOT/$LIBCAP_REPO_PATH/install/lib64"
EXTRA_MFLAGS=(
	# Abuse SAN_CFLAGS to pass the right linker flags.
	# In an ideal world Makefile should honor EXTRA_CFLAGS and LDFLAGS.
	"SAN_CFLAGS=$cflags $ldflags"
	"EXTRA_CFLAGS=$cflags"
	"LDFLAGS=$ldflags"
)
typeset -p EXTRA_MFLAGS >"$config_sh"
