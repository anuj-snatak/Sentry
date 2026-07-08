#!/usr/bin/env bash
#
# Selects (creating if necessary) the Terraform workspace matching the
# given environment. Each environments/<env> directory already isolates
# state via a distinct backend key, so workspaces here are a second,
# belt-and-suspenders layer of isolation that also lets `terraform
# workspace show` self-document which environment a shell is pointed at.
#
# Usage:
#   terraform/scripts/select-workspace.sh <environment>

set -euo pipefail

ENVIRONMENT="${1:?environment is required, e.g. dev}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_DIR="${SCRIPT_DIR}/../environments/${ENVIRONMENT}"

if [[ ! -d "${ENV_DIR}" ]]; then
  echo "error: no such environment directory: ${ENV_DIR}" >&2
  exit 1
fi

echo "==> Selecting Terraform workspace '${ENVIRONMENT}'"

if terraform -chdir="${ENV_DIR}" workspace list | grep -qE "[[:space:]]${ENVIRONMENT}\$"; then
  terraform -chdir="${ENV_DIR}" workspace select "${ENVIRONMENT}"
else
  terraform -chdir="${ENV_DIR}" workspace new "${ENVIRONMENT}"
fi

echo "==> Active workspace: $(terraform -chdir="${ENV_DIR}" workspace show)"
