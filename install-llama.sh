#!/usr/bin/env bash
set -euo pipefail

TARGET_DIR="${1:-.}"
mkdir -p "$TARGET_DIR"
cd "$TARGET_DIR"

echo "Resolving llama.cpp release tag..."
TAG=""
if command -v curl >/dev/null 2>&1; then
    TAG=$(curl -sL https://github.com/ggml-org/llama.cpp/releases/download/v0.9.0/nightly-tag.txt 2>/dev/null | tr -d '\r\n[:space:]' || true)
fi

if [ -z "$TAG" ] || [ "${#TAG}" -lt 2 ]; then
    TAG="b12277"
fi

echo "Selected release: $TAG"
TARBALL="llama-${TAG}-bin-ubuntu-x64.tar.gz"
URL="https://github.com/ggml-org/llama.cpp/releases/download/${TAG}/${TARBALL}"

echo "Downloading $URL..."
if command -v curl >/dev/null 2>&1; then
    curl -sL "$URL" -o "$TARBALL"
elif command -v wget >/dev/null 2>&1; then
    wget -q "$URL" -O "$TARBALL"
fi

if [ -f "$TARBALL" ] && [ -s "$TARBALL" ]; then
    echo "Extracting $TARBALL..."
    tar -xzf "$TARBALL" --strip-components=1 2>/dev/null || tar -xzf "$TARBALL"
    rm -f "$TARBALL"
fi

if [ -d llama-b* ]; then
    cp -rn llama-b*/* . 2>/dev/null || true
    rm -rf llama-b*
fi

chmod +x llama-server llama-cli llama-bench 2>/dev/null || true

# Ensure libgomp is available in root if found in system
if [ -f /usr/lib/x86_64-linux-gnu/libgomp.so.1 ] && [ ! -f libgomp.so.1 ]; then
    cp -a /usr/lib/x86_64-linux-gnu/libgomp.so.1* . 2>/dev/null || true
fi

echo "llama.cpp $TAG installed successfully in $TARGET_DIR"
