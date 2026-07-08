#!/usr/bin/env bash
#
# Full local deploy: terraform init/plan/apply (with a confirmation
# prompt), inventory generation, Ansible bootstrap + application
# deployment, monitoring, and a health check — the same sequence the
# Jenkins pipeline runs, for when you need to deploy without Jenkins
# (initial testing, a one-off environment, disaster recovery).
#
# Requires TF_STATE_BUCKET and TF_LOCK_TABLE in the environment (see
# scripts/bootstrap.sh's output).
#
# Usage:
#   scripts/deploy.sh <environment> <region> <app_image> <app_image_tag>
#
# Example:
#   TF_STATE_BUCKET=cloudforge-terraform-state-8f2a TF_LOCK_TABLE=terraform-state-lock \
#     scripts/deploy.sh dev us-east-1 123456789012.dkr.ecr.us-east-1.amazonaws.com/cloudforge-app latest

set -euo pipefail

ENVIRONMENT="${1:?usage: scripts/deploy.sh <environment> <region> <app_image> <app_image_tag>}"
AWS_REGION="${2:?region is required}"
APP_IMAGE="${3:?app_image is required}"
APP_IMAGE_TAG="${4:?app_image_tag is required}"

: "${TF_STATE_BUCKET:?TF_STATE_BUCKET must be set (see scripts/bootstrap.sh output)}"
: "${TF_LOCK_TABLE:?TF_LOCK_TABLE must be set (see scripts/bootstrap.sh output)}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TF_DIR="${REPO_ROOT}/terraform/environments/${ENVIRONMENT}"

echo "==> [1/6] Pre-flight validation"
"${SCRIPT_DIR}/validate.sh" "${ENVIRONMENT}"

echo "==> [2/6] terraform init"
"${REPO_ROOT}/terraform/scripts/init-backend.sh" "${ENVIRONMENT}" "${TF_STATE_BUCKET}" "${TF_LOCK_TABLE}" "${AWS_REGION}"

echo "==> [3/6] terraform plan + apply"
terraform -chdir="${TF_DIR}" plan -input=false -out=tfplan
read -r -p "Apply the plan above to '${ENVIRONMENT}'? [y/N] " confirm
if [[ "${confirm}" != "y" && "${confirm}" != "Y" ]]; then
  echo "Aborted."
  rm -f "${TF_DIR}/tfplan"
  exit 1
fi
terraform -chdir="${TF_DIR}" apply -input=false -auto-approve tfplan
rm -f "${TF_DIR}/tfplan"

echo "==> [4/6] Generating Ansible inventory"
"${SCRIPT_DIR}/generate-inventory.sh" "${ENVIRONMENT}" "${AWS_REGION}"

echo "==> [5/6] Ansible bootstrap + application deployment"
cd "${REPO_ROOT}/ansible"
ansible-galaxy collection install -r requirements.yml
ansible-playbook -i "inventories/${ENVIRONMENT}/hosts.yml" playbooks/bootstrap.yml
ansible-playbook -i "inventories/${ENVIRONMENT}/hosts.yml" playbooks/deploy-app.yml \
  -e "app_image=${APP_IMAGE}" -e "app_image_tag=${APP_IMAGE_TAG}"
ansible-playbook -i "inventories/${ENVIRONMENT}/hosts.yml" playbooks/monitoring.yml

echo "==> [6/6] Health check"
"${SCRIPT_DIR}/healthcheck.sh" "${ENVIRONMENT}" "${AWS_REGION}"

echo "==> Deploy complete for '${ENVIRONMENT}'"
