#!/usr/bin/env bash
set -euo pipefail

# Vendors the Envoy Gateway CRDs (group gateway.envoyproxy.io) into this folder.
#
# The gateway-helm chart ships these CRDs in its crds/ directory together with
# the Gateway API CRDs, where Helm applies everything unconditionally and the
# crds.gatewayAPI.enabled value has no effect. Those Gateway API CRDs are
# experimental channel and get rejected by the
# safe-upgrades.gateway.networking.k8s.io ValidatingAdmissionPolicy that ships
# with our standard channel install. So the chart install keeps crds: Skip and we
# vendor the Envoy Gateway CRDs from the release here instead, leaving
# flux/3/gateway-api/standard-install.yaml the only owner of
# gateway.networking.k8s.io CRDs.
#
# The version is read from the gateway-helm OCIRepository so the CRDs always
# match the chart Renovate bumps. Pass a version explicitly to override.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
ASSET_NAME="envoy-gateway-crds.yaml"
DEST="$SCRIPT_DIR/$ASSET_NAME"

VERSION="${1:-$(yq '.spec.ref.tag' "$REPO_ROOT/flux/4/envoy-gateway/helm-repository.yaml")}"

if [[ -z "$VERSION" || "$VERSION" == "null" ]]; then
  echo "Failed to determine Envoy Gateway version" >&2
  exit 1
fi

ASSET_URL="https://github.com/envoyproxy/gateway/releases/download/${VERSION}/${ASSET_NAME}"

echo "Downloading $ASSET_URL"
curl -fsSL "$ASSET_URL" -o "$DEST"

echo "Updated $DEST to $VERSION"
