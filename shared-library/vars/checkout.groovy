/**
 * Checks out the repository revision that triggered this build. Thin on
 * purpose — the Jenkinsfile stays a one-line call, and there is nothing
 * environment-specific here to push into src/.
 */
def call() {
    echo '==> Checking out source'
    checkout scm
}
