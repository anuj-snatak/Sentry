/**
 * Removes workspace-local build artifacts left behind by a run (plan
 * files, generated Terraform output dumps, Ansible retry files). Does
 * not touch anything in AWS — this is purely local housekeeping, safe
 * to call unconditionally from a post{} block regardless of build result.
 */
def call() {
    echo '==> Cleaning up workspace-local build artifacts'
    sh '''
        rm -f tfplan
        rm -f tf-outputs-*.json
        find . -name "*.retry" -delete 2>/dev/null || true
    '''
}
