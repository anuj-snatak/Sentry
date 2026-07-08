package com.cloudforge.pipeline

/**
 * Wraps every Terraform invocation this pipeline makes. Centralizing
 * this here (rather than duplicating `dir(...) { sh "terraform ..." }`
 * blocks across terraformInit/Plan/Apply/Destroy in vars/) means the
 * working-directory convention and flag set (-input=false, etc.) only
 * has to be correct in one place.
 *
 * `script` is the pipeline run's own `this` (passed in from a vars/
 * script), which is how a plain Groovy class gets access to CPS-
 * transformed pipeline steps like sh/dir/echo.
 */
class TerraformRunner implements Serializable {

    private final def script
    private final String environment

    TerraformRunner(script, String environment) {
        Config.requireValidEnvironment(environment)
        this.script = script
        this.environment = environment
    }

    private String workDir() {
        return Config.terraformDir(environment)
    }

    private static String varArgs(Map vars) {
        return vars.collect { k, v -> "-var '${k}=${v}'" }.join(' ')
    }

    void init(String stateBucket, String lockTable, String region) {
        script.sh "terraform/scripts/init-backend.sh ${environment} ${stateBucket} ${lockTable} ${region}"
    }

    void validate() {
        script.dir(workDir()) {
            script.sh 'terraform validate'
        }
    }

    void plan(Map vars = [:]) {
        script.dir(workDir()) {
            script.sh "terraform plan -input=false -out=tfplan ${varArgs(vars)}"
        }
    }

    void apply() {
        script.dir(workDir()) {
            script.sh 'terraform apply -input=false -auto-approve tfplan'
        }
    }

    void destroy(Map vars = [:]) {
        script.dir(workDir()) {
            script.sh "terraform destroy -input=false -auto-approve ${varArgs(vars)}"
        }
    }

    void writeOutputsJson(String destPath) {
        script.dir(workDir()) {
            script.sh "terraform output -json > ${script.env.WORKSPACE}/${destPath}"
        }
    }

    String output(String name) {
        return script.dir(workDir()) {
            script.sh(script: "terraform output -raw ${name}", returnStdout: true)
        }.trim()
    }
}
