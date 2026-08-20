#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="${1:-wanderlust}"
DEPLOYMENT="${2:-backend-deployment}"
REVISION="${3:-}"

echo "Rollback target: namespace=${NAMESPACE}, deployment=${DEPLOYMENT}"
echo
echo "Available rollout history:"
kubectl -n "$NAMESPACE" rollout history "deployment/${DEPLOYMENT}"

echo
if [[ -n "$REVISION" ]]; then
  echo "Rolling back to revision ${REVISION}..."
  kubectl -n "$NAMESPACE" rollout undo "deployment/${DEPLOYMENT}" --to-revision="$REVISION"
else
  echo "Rolling back to the previous revision..."
  kubectl -n "$NAMESPACE" rollout undo "deployment/${DEPLOYMENT}"
fi

echo
echo "Waiting for rollout to complete..."
kubectl -n "$NAMESPACE" rollout status "deployment/${DEPLOYMENT}" --timeout=180s

echo
echo "Rollback complete."
