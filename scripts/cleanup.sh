#!/usr/bin/env bash
#
# Local workspace housekeeping: removes build artifacts (Terraform plan
# files, generated Terraform output dumps, Ansible retry files, Python
# bytecode caches). Touches nothing in AWS — safe to run anytime.
#
# Usage:
#   scripts/cleanup.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${REPO_ROOT}"

echo "==> Removing Terraform plan files"
find terraform -maxdepth 3 -name "*.tfplan" -delete
find terraform -maxdepth 3 -name "tfplan" -delete

echo "==> Removing generated Terraform output dumps"
rm -f tf-outputs-*.json

echo "==> Removing Ansible retry files"
find ansible -name "*.retry" -delete

echo "==> Removing Python bytecode caches"
find python -name "__pycache__" -type d -prune -exec rm -rf {} +
find python -name "*.pyc" -delete

echo "==> Cleanup complete"
