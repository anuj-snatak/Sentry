#!/usr/bin/env bash
#
# Runs the same two-tier health check the Jenkins pipeline runs after a
# deploy (ALB smoke test, then per-instance SSM check), on demand from
# a terminal. Useful right after a manual scripts/deploy.sh run, or to
# check whether "is prod actually healthy right now" without waiting
# for the next pipeline run.
#
# Usage:
#   scripts/healthcheck.sh <environment> <region>

set -euo pipefail

ENVIRONMENT="${1:?usage: scripts/healthcheck.sh <environment> <region>}"
AWS_REGION="${2:?region is required}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TF_DIR="${REPO_ROOT}/terraform/environments/${ENVIRONMENT}"
TF_OUTPUTS_FILE="${REPO_ROOT}/tf-outputs-${ENVIRONMENT}.json"

ALB_DNS_NAME="$(terraform -chdir="${TF_DIR}" output -raw alb_dns_name)"
HEALTH_PATH="${HEALTH_PATH:-/health}"

echo "==> Smoke test: http://${ALB_DNS_NAME}${HEALTH_PATH}"
for i in $(seq 1 10); do
  code="$(curl -fsS -o /dev/null -w '%{http_code}' "http://${ALB_DNS_NAME}${HEALTH_PATH}" || echo 000)"
  if [[ "${code:0:1}" == "2" ]]; then
    echo "Smoke test passed (HTTP ${code})"
    break
  fi
  echo "Attempt ${i}/10 got HTTP ${code}, retrying in 15s..."
  sleep 15
  if [[ "${i}" == "10" ]]; then
    echo "Smoke test FAILED after 10 attempts" >&2
    exit 1
  fi
done

echo "==> Per-instance health check"
terraform -chdir="${TF_DIR}" output -json > "${TF_OUTPUTS_FILE}"
trap 'rm -f "${TF_OUTPUTS_FILE}"' EXIT

python3 "${REPO_ROOT}/python/cloudforge/health/health_check.py" \
  --environment "${ENVIRONMENT}" \
  --region "${AWS_REGION}" \
  --tf-outputs "${TF_OUTPUTS_FILE}"
