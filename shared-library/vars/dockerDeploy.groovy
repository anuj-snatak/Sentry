/**
 * Deploys (or redeploys) the application container via the
 * ansible/playbooks/deploy-app.yml playbook's application role. Named
 * "dockerDeploy" to match the requested pipeline vocabulary; the actual
 * Docker work happens inside the application Ansible role, not here —
 * this function's job is just wiring image/tag through correctly.
 *
 * config: [environment, appImage, appImageTag]
 */
def call(Map config) {
    def environment = config.environment
    def appImage = config.appImage
    def appImageTag = config.appImageTag ?: 'latest'

    if (!appImage?.trim()) {
        error 'dockerDeploy: appImage must be set (the APP_IMAGE build parameter).'
    }

    echo "==> Deploying ${appImage}:${appImageTag} to ${environment}"
    ansibleDeploy(
        environment: environment,
        playbook: 'deploy-app.yml',
        extraVars: [app_image: appImage, app_image_tag: appImageTag]
    )
}
