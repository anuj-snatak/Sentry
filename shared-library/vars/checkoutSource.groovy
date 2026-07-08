/**
 * Checks out the repository revision that triggered this build. Thin on
 * purpose — the Jenkinsfile stays a one-line call, and there is nothing
 * environment-specific here to push into src/.
 *
 * Named checkoutSource, not checkout: a vars/ script named identically
 * to a built-in pipeline step (checkout) creates an ambiguous symbol —
 * Groovy's CPS compiler resolved calls to the built-in step's signature
 * (which requires a mandatory `scm` parameter) instead of this zero-arg
 * wrapper, failing with "Missing required parameter: scm" even though
 * this function was never actually reached.
 */
def call() {
    echo '==> Checking out source'
    checkout scm
}
