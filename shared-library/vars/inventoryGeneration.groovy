import com.cloudforge.pipeline.Config
import com.cloudforge.pipeline.TerraformRunner

/**
 * Turns fresh `terraform output -json` into ansible/inventories/<env>/hosts.yml,
 * via python/cloudforge/inventory/dynamic_inventory.py (Phase 6). This is
 * the pipeline's bridge between "infrastructure exists" and "Ansible has
 * something to configure" — it must run after terraformApply and before
 * any ansibleDeploy call.
 *
 * config: [environment, region]
 */
def call(Map config) {
    def environment = config.environment
    echo "==> Generating Ansible inventory for ${environment}"

    def outputsFile = Config.terraformOutputsFile(environment)
    new TerraformRunner(this, environment).writeOutputsJson(outputsFile)

    sh """
        set -euo pipefail
        PYTHONPATH=python python3 python/cloudforge/inventory/dynamic_inventory.py \\
          --environment ${environment} \\
          --region ${config.region} \\
          --tf-outputs ${outputsFile} \\
          --output ansible/${Config.ansibleInventoryPath(environment)}
    """
}
