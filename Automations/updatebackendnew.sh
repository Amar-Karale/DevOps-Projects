#!/bin/bash
set -euo pipefail

# The application URL is supplied by the deployment environment.
# This script intentionally does not discover or hard-code an EC2 instance IP.

ENV_FILE="../backend/.env.docker"

if [[ -z "${FRONTEND_URL:-}" ]]; then
  echo "ERROR: FRONTEND_URL is not set. Configure it as a Jenkins credential/environment variable."
  exit 1
fi

if [[ ! -f "$ENV_FILE" ]]; then
  echo "ERROR: $ENV_FILE does not exist. Create it from backend/.env.example during deployment."
  exit 1
fi

sed -i "s|^FRONTEND_URL=.*|FRONTEND_URL=\"${FRONTEND_URL}\"|" "$ENV_FILE"
echo "Backend frontend URL updated."
