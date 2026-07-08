import com.cloudforge.pipeline.Notifier

/**
 * config: [recipients, subject, body]
 * Requires the Email Extension Plugin (emailext step) to be configured
 * on the Jenkins controller (SMTP settings under Manage Jenkins).
 */
def call(Map config) {
    new Notifier(this).email(config.recipients, config.subject, config.body)
}
