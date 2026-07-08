#!/usr/bin/env bash
#
# Tears down every Terraform-managed resource in an environment.
# Destructive and irreversible — requires typing the environment name
# back to confirm, on top of Terraform's own -auto-approve being
# deliberately NOT used here.
#
# Usage:
#   scripts/destroy.sh <environment> <region>

set -euo pipefail

ENVIRONMENT="${1:?usage: scripts/destroy.sh <environment> <region>}"
AWS_REGION="${2:?region is required}"

: "${TF_STATE_BUCKET:?TF_STATE_BUCKET must be set (see scripts/bootstrap.sh output)}"
: "${TF_LOCK_TABLE:?TF_LOCK_TABLE must be set (see scripts/bootstrap.sh output)}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TF_DIR="${REPO_ROOT}/terraform/environments/${ENVIRONMENT}"

echo "==> terraform init"
"${REPO_ROOT}/terraform/scripts/init-backend.sh" "${ENVIRONMENT}" "${TF_STATE_BUCKET}" "${TF_LOCK_TABLE}" "${AWS_REGION}"

echo "==> terraform plan -destroy"
terraform -chdir="${TF_DIR}" plan -destroy -input=false -out=destroy.tfplan

echo
echo "This will DESTROY every Terraform-managed resource in '${ENVIRONMENT}'."
read -r -p "Type the environment name (${ENVIRONMENT}) to confirm: " confirm
if [[ "${confirm}" != "${ENVIRONMENT}" ]]; then
  echo "Confirmation did not match. Aborted."
  rm -f "${TF_DIR}/destroy.tfplan"
  exit 1
fi

terraform -chdir="${TF_DIR}" apply -input=false destroy.tfplan
rm -f "${TF_DIR}/destroy.tfplan"

echo "==> '${ENVIRONMENT}' destroyed"
