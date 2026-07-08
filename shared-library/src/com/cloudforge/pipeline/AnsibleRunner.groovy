package com.cloudforge.pipeline

/**
 * Wraps every ansible-playbook invocation. See TerraformRunner for why
 * this lives in src/ instead of being inlined into vars/ansibleDeploy.
 */
class AnsibleRunner implements Serializable {

    private final def script
    private final String environment

    // See TerraformRunner's constructor comment: no library method calls
    // here, to avoid Jenkins' CPS constructor-transform mismatch.
    // Validation still happens on every real use, via runPlaybook() ->
    // Config.ansibleInventoryPath() -> Config.requireValidEnvironment().
    AnsibleRunner(script, String environment) {
        this.script = script
        this.environment = environment
    }

    private static String extraVarArgs(Map extraVars) {
        return extraVars.collect { k, v -> "-e ${k}='${v}'" }.join(' ')
    }

    void installRequirements() {
        script.dir('ansible') {
            script.sh 'ansible-galaxy collection install -r requirements.yml'
        }
    }

    void runPlaybook(String playbook, Map extraVars = [:]) {
        def inventory = Config.ansibleInventoryPath(environment)
        script.dir('ansible') {
            script.sh "ansible-playbook -i ${inventory} playbooks/${playbook} ${extraVarArgs(extraVars)}"
        }
    }
}
