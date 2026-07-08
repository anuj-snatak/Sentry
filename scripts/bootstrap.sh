#!/usr/bin/env bash
#
# One-time, per-AWS-account bootstrap: creates the S3 state bucket, the
# DynamoDB lock table, and (optionally) the Jenkins deploy IAM role, by
# applying terraform/backend. Run this exactly once before any
# environment's `terraform init` can succeed — every environment's
# backend.tf points at the bucket/table this creates.
#
# Usage:
#   scripts/bootstrap.sh <project_name> <state_bucket_name> <aws_region> [jenkins_trusted_principal_arn]
#
# Example:
#   scripts/bootstrap.sh cloudforge cloudforge-terraform-state-8f2a us-east-1
#   scripts/bootstrap.sh cloudforge cloudforge-terraform-state-8f2a us-east-1 arn:aws:iam::123456789012:role/jenkins-agent

set -euo pipefail

PROJECT_NAME="${1:?usage: scripts/bootstrap.sh <project_name> <state_bucket_name> <aws_region> [jenkins_trusted_principal_arn]}"
STATE_BUCKET_NAME="${2:?state_bucket_name is required}"
AWS_REGION="${3:?aws_region is required}"
JENKINS_TRUSTED_PRINCIPAL_ARN="${4:-}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
BACKEND_DIR="${REPO_ROOT}/terraform/backend"

echo "==> Validating AWS credentials"
aws sts get-caller-identity >/dev/null

echo "==> terraform init (local state — this run creates the remote backend itself)"
terraform -chdir="${BACKEND_DIR}" init -input=false

TF_VARS=(-var "project_name=${PROJECT_NAME}" -var "state_bucket_name=${STATE_BUCKET_NAME}" -var "aws_region=${AWS_REGION}")
if [[ -n "${JENKINS_TRUSTED_PRINCIPAL_ARN}" ]]; then
  TF_VARS+=(-var "jenkins_trusted_principal_arns=[\"${JENKINS_TRUSTED_PRINCIPAL_ARN}\"]")
fi

echo "==> terraform plan"
terraform -chdir="${BACKEND_DIR}" plan -input=false "${TF_VARS[@]}" -out=bootstrap.tfplan

read -r -p "Apply the plan above and create these account-level resources? [y/N] " confirm
if [[ "${confirm}" != "y" && "${confirm}" != "Y" ]]; then
  echo "Aborted."
  rm -f "${BACKEND_DIR}/bootstrap.tfplan"
  exit 1
fi

echo "==> terraform apply"
terraform -chdir="${BACKEND_DIR}" apply -input=false bootstrap.tfplan
rm -f "${BACKEND_DIR}/bootstrap.tfplan"

echo
echo "==> Bootstrap complete. Record these values (needed by every environment's init):"
terraform -chdir="${BACKEND_DIR}" output
echo
echo "Configure TF_STATE_BUCKET and TF_LOCK_TABLE (from the outputs above) as global"
echo "Jenkins environment variables, or export them locally before running scripts/deploy.sh."
