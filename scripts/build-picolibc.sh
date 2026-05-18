#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

PICOLIBC_SRC="${REPO_ROOT}/external/picolibc/picolibc"
PICOLIBC_OUT="${REPO_ROOT}/external/picolibc"
CROSS_FILE="scripts/cross-clang-thumbv7em-none-eabi-miso-rtx.txt"
BUILD_DIR="./build"
OPT_LEVEL="2"

cd "$PICOLIBC_SRC"

echo "Configuring picolibc..."
meson setup \
    --cross-file "$CROSS_FILE" \
    --optimization "$OPT_LEVEL" \
    "$BUILD_DIR" \
    --wipe

echo "Building picolibc..."
ninja -C "$BUILD_DIR"

STAGING_DIR="$(mktemp -d)"
trap 'rm -rf "$STAGING_DIR"' EXIT

echo "Installing into staging area..."
meson install -C "$BUILD_DIR" --destdir "$STAGING_DIR" --quiet

echo "Copying libc.a to ${PICOLIBC_OUT}..."
cp "${BUILD_DIR}/newlib/libc.a" "$PICOLIBC_OUT/libc.a"

echo "Copying headers to ${PICOLIBC_OUT}/include/..."
rm -rf "$PICOLIBC_OUT/include"
cp -r "${STAGING_DIR}/usr/local/include" "$PICOLIBC_OUT/include"

echo "Done."
