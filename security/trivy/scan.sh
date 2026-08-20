#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BACKEND_IMAGE="${1:-amarkarale/wanderlust-backend-beta:latest}"
FRONTEND_IMAGE="${2:-amarkarale/wanderlust-frontend-beta:latest}"

cd "$ROOT_DIR"

echo "[1/3] Trivy filesystem scan"
trivy fs \
  --scanners vuln,misconfig,secret \
  --severity HIGH,CRITICAL \
  --ignore-unfixed \
  .

echo "[2/3] Trivy backend image scan"
trivy image \
  --scanners vuln,misconfig,secret \
  --severity HIGH,CRITICAL \
  --ignore-unfixed \
  "$BACKEND_IMAGE"

echo "[3/3] Trivy frontend image scan"
trivy image \
  --scanners vuln,misconfig,secret \
  --severity HIGH,CRITICAL \
  --ignore-unfixed \
  "$FRONTEND_IMAGE"
