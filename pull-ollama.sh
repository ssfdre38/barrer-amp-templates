#!/usr/bin/env bash
set -euo pipefail

MODEL="${1:-}"
OUTPUT_DIR="${2:-./models}"
OUTPUT_FILE="${3:-}"

if [ -z "$MODEL" ]; then
    echo "Usage: $0 <namespace/model:tag> [output_dir] [output_file]"
    exit 1
fi

if [[ "$MODEL" =~ ^([^/:]+)/([^:]+)(:(.+))?$ ]]; then
    NAMESPACE="${BASH_REMATCH[1]}"
    REPO="${BASH_REMATCH[2]}"
    TAG="${BASH_REMATCH[4]:-latest}"
elif [[ "$MODEL" =~ ^([^:]+)(:(.+))?$ ]]; then
    NAMESPACE="library"
    REPO="${BASH_REMATCH[1]}"
    TAG="${BASH_REMATCH[3]:-latest}"
else
    echo "Invalid Ollama model format: $MODEL"
    exit 1
fi

echo "=========================================="
echo "  Ollama Direct Registry GGUF Downloader  "
echo "=========================================="
echo "Target: $NAMESPACE/$REPO:$TAG"

MANIFEST_URL="https://registry.ollama.ai/v2/$NAMESPACE/$REPO/manifests/$TAG"
echo "Fetching manifest from $MANIFEST_URL..."

MANIFEST_JSON=$(curl -sL -H "Accept: application/vnd.docker.distribution.manifest.v2+json" "$MANIFEST_URL")

DIGEST=$(echo "$MANIFEST_JSON" | grep -A 2 -B 2 "application/vnd.ollama.image.model" | grep "digest" | head -n 1 | sed -E 's/.*"digest": *"([^"]+)".*/\1/')

if [ -z "$DIGEST" ]; then
    echo "Error: Could not locate model layer digest in manifest."
    exit 1
fi

echo "Found model layer: $DIGEST"

mkdir -p "$OUTPUT_DIR"
TARGET_FILE="${OUTPUT_FILE:-$OUTPUT_DIR/$REPO-$TAG.gguf}"
DEFAULT_LINK="$OUTPUT_DIR/model.gguf"

BLOB_URL="https://registry.ollama.ai/v2/$NAMESPACE/$REPO/blobs/$DIGEST"
echo "Streaming GGUF directly from: $BLOB_URL"
echo "Saving to: $TARGET_FILE"

curl -L --progress-bar -o "$TARGET_FILE.downloading" "$BLOB_URL"
mv -f "$TARGET_FILE.downloading" "$TARGET_FILE"
cp -f "$TARGET_FILE" "$DEFAULT_LINK"

echo "Download complete: $TARGET_FILE"
echo "Updated default active model: $DEFAULT_LINK"
