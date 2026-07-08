#!/usr/bin/env bash
#
# Pre-flight validation for local/manual use: everything the Jenkins
# pipeline checks before it's willing to touch AWS, runnable from a
# terminal. Safe to run repeatedly — nothing here mutates any AWS
# resource or Terraform state.
#
# Usage:
#   scripts/validate.sh <environment>
#
# Example:
#   scripts/validate.sh dev

set -euo pipefail

ENVIRONMENT="${1:?usage: scripts/validate.sh <environment>}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "==> [1/3] Tool/credentials/tfvars validation"
python3 "${REPO_ROOT}/python/cloudforge/validation/validator.py" \
  --environment "${ENVIRONMENT}" \
  --repo-root "${REPO_ROOT}"

echo "==> [2/3] Terraform fmt/validate (modules + wired environments)"
"${REPO_ROOT}/terraform/scripts/validate-all.sh"

echo "==> [3/3] Ansible playbook syntax check"
cd "${REPO_ROOT}/ansible"
# ansible-playbook's YAML inventory plugin only recognizes .yml/.yaml
# extensions; copy the checked-in .example to a real .yml temporarily so
# --syntax-check doesn't spend its output on inventory-parsing warnings
# that have nothing to do with playbook syntax.
TEMP_INVENTORY="inventories/${ENVIRONMENT}/hosts.yml"
if [[ -f "${TEMP_INVENTORY}" ]]; then
  # A real (generated) inventory already exists — never overwrite it.
  INVENTORY_FOR_CHECK="${TEMP_INVENTORY}"
else
  cp "inventories/${ENVIRONMENT}/hosts.yml.example" "${TEMP_INVENTORY}"
  trap 'rm -f "${TEMP_INVENTORY}"' EXIT
  INVENTORY_FOR_CHECK="${TEMP_INVENTORY}"
fi

for playbook in playbooks/*.yml; do
  echo "  -- ${playbook}"
  ansible-playbook --syntax-check -i "${INVENTORY_FOR_CHECK}" "${playbook}"
done

echo "==> All validation checks passed for '${ENVIRONMENT}'"
