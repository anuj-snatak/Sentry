#!/usr/bin/env bash
#
# Runs `terraform fmt -check`, `terraform validate`, and `tflint` (if
# installed) across every module and every wired environment. Intended
# for both local pre-commit use and the Jenkins pipeline's validate stage
# (see shared-library/vars/terraformValidate.groovy).
#
# Usage:
#   terraform/scripts/validate-all.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

FAILED=0

echo "==> terraform fmt -check -recursive (whole terraform/ tree)"
if ! terraform fmt -check -recursive -diff "${TERRAFORM_ROOT}"; then
  echo "error: one or more files are not terraform-fmt formatted (run 'terraform fmt -recursive')" >&2
  FAILED=1
fi

echo "==> terraform validate (modules)"
while IFS= read -r -d '' module_dir; do
  echo "  -- validating module: ${module_dir#"${TERRAFORM_ROOT}"/}"
  terraform -chdir="${module_dir}" init -backend=false -input=false >/dev/null
  if ! terraform -chdir="${module_dir}" validate; then
    FAILED=1
  fi
done < <(find "${TERRAFORM_ROOT}/modules" -mindepth 1 -type d -exec test -e '{}/main.tf' \; -print0)

echo "==> terraform validate (wired environments)"
for env_dir in "${TERRAFORM_ROOT}"/environments/*/; do
  if [[ -f "${env_dir}/main.tf" ]]; then
    echo "  -- validating environment: $(basename "${env_dir}")"
    terraform -chdir="${env_dir}" init -backend=false -input=false >/dev/null
    if ! terraform -chdir="${env_dir}" validate; then
      FAILED=1
    fi
  else
    echo "  -- skipping $(basename "${env_dir}") (not wired yet)"
  fi
done

if command -v tflint >/dev/null 2>&1; then
  echo "==> tflint"
  (cd "${TERRAFORM_ROOT}" && tflint --recursive) || FAILED=1
else
  echo "==> tflint not installed, skipping (recommended: https://github.com/terraform-linters/tflint)"
fi

if [[ "${FAILED}" -ne 0 ]]; then
  echo "==> Validation FAILED" >&2
  exit 1
fi

echo "==> Validation passed"
