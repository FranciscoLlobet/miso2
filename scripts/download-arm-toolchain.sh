#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

VERSION="15.2.rel1"
TOOL_FILE="arm-gnu-toolchain-${VERSION}-x86_64-arm-none-eabi.tar.xz"
TOOL_URL="https://developer.arm.com/-/media/Files/downloads/gnu/${VERSION}/binrel/${TOOL_FILE}"
DOWNLOAD_DIR="${REPO_ROOT}/arm-toolchain"
EXTRACT_DIR="${DOWNLOAD_DIR}/arm-gnu-toolchain-${VERSION}-x86_64-arm-none-eabi"

mkdir -p "$DOWNLOAD_DIR"

if [ ! -f "${DOWNLOAD_DIR}/${TOOL_FILE}" ]; then
    echo "Downloading ARM GNU Toolchain ${VERSION}..."
    curl -LSf -o "${DOWNLOAD_DIR}/${TOOL_FILzE}" "${TOOL_URL}"
else
    echo "Archive already present: ${DOWNLOAD_DIR}/${TOOL_FILE}"
fi

if [ ! -d "${EXTRACT_DIR}" ]; then
    echo "Extracting toolchain to ${EXTRACT_DIR}..."
    mkdir -p "${EXTRACT_DIR}"
    tar -xf "${DOWNLOAD_DIR}/${TOOL_FILE}" -C "${EXTRACT_DIR}" --strip-components=1
    echo "Toolchain installed: ${EXTRACT_DIR}"
else
    echo "Toolchain already extracted: ${EXTRACT_DIR}"
fi

echo "Done. GDB path: ${EXTRACT_DIR}/bin/arm-none-eabi-gdb"
