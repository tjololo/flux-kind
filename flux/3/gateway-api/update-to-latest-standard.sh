#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="kubernetes-sigs/gateway-api"
ASSET_NAME="standard-install.yaml"
DEST="$SCRIPT_DIR/$ASSET_NAME"

echo "Fetching latest stable release of $REPO..."
RELEASE_JSON="$(curl -sSL "https://api.github.com/repos/$REPO/releases/latest")"

TAG="$(echo "$RELEASE_JSON" | jq -r '.tag_name')"
ASSET_URL="$(echo "$RELEASE_JSON" | jq -r --arg name "$ASSET_NAME" '.assets[] | select(.name == $name) | .browser_download_url')"

if [[ -z "$TAG" || "$TAG" == "null" ]]; then
  echo "Failed to determine latest release tag" >&2
  exit 1
fi

if [[ -z "$ASSET_URL" || "$ASSET_URL" == "null" ]]; then
  echo "Could not find asset '$ASSET_NAME' in release $TAG" >&2
  exit 1
fi

echo "Latest release: $TAG"
echo "Downloading $ASSET_URL"
curl -sSL "$ASSET_URL" -o "$DEST"

echo "Updated $DEST to $TAG"
