import com.cloudforge.pipeline.AwsUtils

/**
 * Redeploys the last known-good application image tag recorded by
 * generateReport (see python/cloudforge/reports/deployment_report.py,
 * which persists one record per successful deploy to the environment's
 * S3 data bucket). Intended for the ACTION=rollback / ROLLBACK=true
 * pipeline path — no Terraform involved, this only touches the running
 * application.
 *
 * config: [environment, appImage, albDnsName, healthPath (optional), historyBucket (optional)]
 */
def call(Map config) {
    def environment = config.environment
    def historyBucket = config.historyBucket ?: AwsUtils.appDataBucketName(
        env.CLOUDFORGE_AWS_ACCOUNT_ID ?: '', env.CLOUDFORGE_PROJECT_NAME ?: 'cloudforge', environment
    )

    echo "==> Determining last known-good image tag for ${environment}"
    def lastGoodTag = sh(
        script: "python3 python/cloudforge/reports/deployment_report.py --environment ${environment} --history-bucket ${historyBucket} --print-last-good-tag",
        returnStdout: true
    ).trim()

    if (!lastGoodTag) {
        error "rollback: no previous known-good deployment recorded for ${environment}; nothing to roll back to."
    }

    echo "==> Rolling back ${environment} to image tag: ${lastGoodTag}"
    dockerDeploy(environment: environment, appImage: config.appImage, appImageTag: lastGoodTag)
    healthCheck(environment: environment, albDnsName: config.albDnsName, healthPath: config.healthPath)
}
