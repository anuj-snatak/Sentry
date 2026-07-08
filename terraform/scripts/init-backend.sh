#!/usr/bin/env bash
#
# Runs `terraform init` for a given environment, wiring the real S3
# backend bucket/DynamoDB lock table in via -backend-config instead of
# hardcoding them into backend.tf. Used both by developers locally and
# by the Jenkins shared library (see shared-library/vars/terraformInit.groovy).
#
# Usage:
#   terraform/scripts/init-backend.sh <environment> <state-bucket-name> <lock-table-name> <aws-region>
#
# Example:
#   terraform/scripts/init-backend.sh dev cloudforge-terraform-state-1234 terraform-state-lock us-east-1

set -euo pipefail

ENVIRONMENT="${1:?environment is required, e.g. dev}"
STATE_BUCKET="${2:?state bucket name is required}"
LOCK_TABLE="${3:?dynamodb lock table name is required}"
AWS_REGION="${4:?aws region is required}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_DIR="${SCRIPT_DIR}/../environments/${ENVIRONMENT}"

if [[ ! -d "${ENV_DIR}" ]]; then
  echo "error: no such environment directory: ${ENV_DIR}" >&2
  exit 1
fi

if [[ ! -f "${ENV_DIR}/backend.tf" ]]; then
  echo "error: ${ENV_DIR}/backend.tf not found; this environment is not wired yet" >&2
  exit 1
fi

echo "==> Initializing Terraform backend for environment '${ENVIRONMENT}'"

terraform -chdir="${ENV_DIR}" init \
  -backend-config="bucket=${STATE_BUCKET}" \
  -backend-config="dynamodb_table=${LOCK_TABLE}" \
  -backend-config="region=${AWS_REGION}" \
  -backend-config="key=${ENVIRONMENT}/terraform.tfstate" \
  -reconfigure \
  -input=false

echo "==> Backend initialized for '${ENVIRONMENT}'"
