import com.cloudforge.pipeline.TerraformRunner

/**
 * config: [environment, instanceType (optional)]
 */
def call(Map config) {
    echo "==> terraform plan (${config.environment})"
    def vars = [:]
    if (config.instanceType) {
        vars['instance_type'] = config.instanceType
    }
    new TerraformRunner(this, config.environment).plan(vars)
}
