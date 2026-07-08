import com.cloudforge.pipeline.TerraformRunner

/**
 * config: [environment, instanceType (optional)]
 */
def call(Map config) {
    echo "==> terraform destroy (${config.environment})"
    def vars = [:]
    if (config.instanceType) {
        vars['instance_type'] = config.instanceType
    }
    new TerraformRunner(this, config.environment).destroy(vars)
}
