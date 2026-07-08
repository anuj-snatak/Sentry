import com.cloudforge.pipeline.AwsUtils

/**
 * Generates and archives a per-build deployment report (via
 * python/cloudforge/reports/deployment_report.py), and — on a successful
 * apply/deploy — persists a record of it to S3 so rollback() has
 * something to roll back to. Always safe to call from a post{} block:
 * the python script itself decides whether this run counts as a
 * "known-good" record based on the --status you pass in.
 *
 * config: [environment, status, appImageTag (optional), historyBucket (optional)]
 */
def call(Map config) {
    def environment = config.environment
    def reportFile = "report-${environment}-${env.BUILD_NUMBER}.md"
    def historyBucket = config.historyBucket ?: AwsUtils.appDataBucketName(
        env.CLOUDFORGE_AWS_ACCOUNT_ID ?: '', env.CLOUDFORGE_PROJECT_NAME ?: 'cloudforge', environment
    )

    echo "==> Generating deployment report for ${environment}"
    sh """
        python3 python/cloudforge/reports/deployment_report.py \\
          --environment ${environment} \\
          --build-number ${env.BUILD_NUMBER} \\
          --build-url '${env.BUILD_URL ?: ""}' \\
          --status '${config.status ?: "unknown"}' \\
          --app-image-tag '${config.appImageTag ?: ""}' \\
          --history-bucket ${historyBucket} \\
          --output ${reportFile}
    """

    archiveArtifacts artifacts: reportFile, allowEmptyArchive: true
}
