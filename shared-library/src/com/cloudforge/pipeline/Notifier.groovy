package com.cloudforge.pipeline

/**
 * Builds and sends Slack/email notifications. The Slack webhook URL is
 * always pulled from a Jenkins credential ID at send time — it is never
 * a literal in this repo (see resources/.../slack-message-template.json
 * for the payload shape this fills in).
 */
class Notifier implements Serializable {

    private static final Map<String, String> STATUS_COLORS = [
        success: 'good',
        failure: 'danger',
        warning: 'warning',
        info: '#439FE0',
    ]

    private final def script

    Notifier(script) {
        this.script = script
    }

    void slack(String webhookCredentialId, String status, String message) {
        def color = STATUS_COLORS[status] ?: STATUS_COLORS['info']
        def template = script.libraryResource('com/cloudforge/pipeline/slack-message-template.json')

        def payload = template
            .replace('__COLOR__', color)
            .replace('__MESSAGE__', message.replace('"', '\\"').replace('\n', '\\n'))
            .replace('__JOB_NAME__', script.env.JOB_NAME ?: 'cloudforge')
            .replace('__BUILD_URL__', script.env.BUILD_URL ?: '')

        script.withCredentials([script.string(credentialsId: webhookCredentialId, variable: 'SLACK_WEBHOOK_URL')]) {
            script.writeFile file: '.slack-payload.json', text: payload
            script.sh 'curl -fsS -X POST -H "Content-Type: application/json" -d @.slack-payload.json "$SLACK_WEBHOOK_URL"'
            script.sh 'rm -f .slack-payload.json'
        }
    }

    void email(String recipients, String subject, String body) {
        if (!recipients?.trim()) {
            script.echo 'notifyEmail: no recipients configured, skipping.'
            return
        }
        script.emailext(
            to: recipients,
            subject: subject,
            body: body,
            mimeType: 'text/html'
        )
    }
}
