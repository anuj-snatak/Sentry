import com.cloudforge.pipeline.AnsibleRunner

/**
 * Generic playbook runner used by both the bootstrap stage and (via
 * dockerDeploy) the application deployment stage.
 *
 * config: [environment, playbook, extraVars (optional map)]
 */
def call(Map config) {
    def environment = config.environment
    def playbook = config.playbook
    def extraVars = config.extraVars ?: [:]

    echo "==> ansible-playbook ${playbook} (${environment})"
    def runner = new AnsibleRunner(this, environment)
    runner.installRequirements()
    runner.runPlaybook(playbook, extraVars)
}
