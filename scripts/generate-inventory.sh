#!/usr/bin/env bash
#
# Regenerates ansible/inventories/<environment>/hosts.yml from the
# environment's current Terraform state, without running a full deploy.
# Handy after a manual scaling event or when Ansible needs to target
# whatever's running right now.
#
# Usage:
#   scripts/generate-inventory.sh <environment> <region>

set -euo pipefail

ENVIRONMENT="${1:?usage: scripts/generate-inventory.sh <environment> <region>}"
AWS_REGION="${2:?region is required}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TF_OUTPUTS_FILE="${REPO_ROOT}/tf-outputs-${ENVIRONMENT}.json"

echo "==> Reading Terraform outputs for '${ENVIRONMENT}'"
terraform -chdir="${REPO_ROOT}/terraform/environments/${ENVIRONMENT}" output -json > "${TF_OUTPUTS_FILE}"

echo "==> Generating ansible/inventories/${ENVIRONMENT}/hosts.yml"
python3 "${REPO_ROOT}/python/cloudforge/inventory/dynamic_inventory.py" \
  --environment "${ENVIRONMENT}" \
  --region "${AWS_REGION}" \
  --tf-outputs "${TF_OUTPUTS_FILE}" \
  --output "${REPO_ROOT}/ansible/inventories/${ENVIRONMENT}/hosts.yml"

rm -f "${TF_OUTPUTS_FILE}"
echo "==> Done"
