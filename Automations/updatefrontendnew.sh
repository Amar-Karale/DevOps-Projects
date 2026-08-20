#!/bin/bash
set -euo pipefail

# The frontend API URL is supplied by the deployment environment.
# This script intentionally does not discover or hard-code an EC2 instance IP.

ENV_FILE="../frontend/.env.docker"

if [[ -z "${VITE_API_PATH:-}" ]]; then
  echo "ERROR: VITE_API_PATH is not set. Configure it as a Jenkins credential/environment variable."
  exit 1
fi

if [[ ! -f "$ENV_FILE" ]]; then
  echo "ERROR: $ENV_FILE does not exist. Create it from frontend/.env.example during deployment."
  exit 1
fi

sed -i "s|^VITE_API_PATH=.*|VITE_API_PATH=\"${VITE_API_PATH}\"|" "$ENV_FILE"
echo "Frontend API URL updated."
