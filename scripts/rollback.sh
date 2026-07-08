#!/usr/bin/env bash
#
# Rolls the application back to the last known-good image tag, without
# touching Terraform-managed infrastructure. Mirrors
# shared-library/vars/rollback.groovy for use outside Jenkins.
#
# Usage:
#   scripts/rollback.sh <environment> <region> <app_image> [history_bucket]
#
# If history_bucket is omitted, it's derived as
# <project_name>-<environment>-app-data-<account_id> (the same
# convention Terraform and the Jenkins pipeline use) using
# CLOUDFORGE_PROJECT_NAME (default "cloudforge") and the caller's
# current AWS account.

set -euo pipefail

ENVIRONMENT="${1:?usage: scripts/rollback.sh <environment> <region> <app_image> [history_bucket]}"
AWS_REGION="${2:?region is required}"
APP_IMAGE="${3:?app_image is required}"
PROJECT_NAME="${CLOUDFORGE_PROJECT_NAME:-cloudforge}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

if [[ -n "${4:-}" ]]; then
  HISTORY_BUCKET="$4"
else
  ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
  HISTORY_BUCKET="${PROJECT_NAME}-${ENVIRONMENT}-app-data-${ACCOUNT_ID}"
fi

echo "==> Looking up last known-good image tag in s3://${HISTORY_BUCKET}"
LAST_GOOD_TAG="$(python3 "${REPO_ROOT}/python/cloudforge/reports/deployment_report.py" \
  --environment "${ENVIRONMENT}" \
  --region "${AWS_REGION}" \
  --history-bucket "${HISTORY_BUCKET}" \
  --print-last-good-tag)"

if [[ -z "${LAST_GOOD_TAG}" ]]; then
  echo "No known-good deployment recorded for '${ENVIRONMENT}'; nothing to roll back to." >&2
  exit 1
fi

echo "==> Rolling back '${ENVIRONMENT}' to image tag: ${LAST_GOOD_TAG}"
cd "${REPO_ROOT}/ansible"
ansible-galaxy collection install -r requirements.yml
ansible-playbook -i "inventories/${ENVIRONMENT}/hosts.yml" playbooks/deploy-app.yml \
  -e "app_image=${APP_IMAGE}" -e "app_image_tag=${LAST_GOOD_TAG}"

echo "==> Post-rollback health check"
"${SCRIPT_DIR}/healthcheck.sh" "${ENVIRONMENT}" "${AWS_REGION}"
