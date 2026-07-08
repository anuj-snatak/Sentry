import com.cloudforge.pipeline.TerraformRunner

/**
 * config: [environment, region, stateBucket, lockTable]
 */
def call(Map config) {
    echo "==> terraform init (${config.environment})"
    new TerraformRunner(this, config.environment).init(config.stateBucket, config.lockTable, config.region)
}
