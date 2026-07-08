import com.cloudforge.pipeline.Notifier

/**
 * config: [status (success|failure|warning|info), message, webhookCredentialId (optional)]
 * webhookCredentialId defaults to a Jenkins "Secret text" credential
 * named "cloudforge-slack-webhook" — the webhook URL itself is never
 * checked into this repo.
 */
def call(Map config) {
    def status = config.status ?: 'info'
    def message = config.message ?: ''
    def webhookCredentialId = config.webhookCredentialId ?: 'cloudforge-slack-webhook'

    new Notifier(this).slack(webhookCredentialId, status, message)
}
