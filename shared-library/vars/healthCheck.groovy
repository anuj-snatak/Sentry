import com.cloudforge.pipeline.Config

/**
 * Two-tier check: a fast ALB-level smoke test (does the load balancer
 * serve 2xx at all), then a deeper per-instance check via
 * python/cloudforge/health/health_check.py, which inspects each
 * instance individually over SSM (app container running, node_exporter
 * reachable, CloudWatch agent active) — catching partial failures a
 * healthy-looking ALB can hide when only some targets are actually good.
 *
 * config: [environment, albDnsName, region (optional, falls back to
 * AWS_DEFAULT_REGION set by the enclosing withAWS() block), healthPath
 * (optional, default /health)]
 */
def call(Map config) {
    def environment = config.environment
    def albDnsName = config.albDnsName
    def healthPath = config.healthPath ?: '/health'
    def region = config.region ?: env.AWS_DEFAULT_REGION

    echo "==> Smoke test: http://${albDnsName}${healthPath}"
    sh """
        set -euo pipefail
        for i in \$(seq 1 10); do
          code=\$(curl -fsS -o /dev/null -w '%{http_code}' "http://${albDnsName}${healthPath}" || echo 000)
          if [ "\${code:0:1}" = "2" ]; then
            echo "Smoke test passed (HTTP \${code})"
            exit 0
          fi
          echo "Attempt \$i/10 got HTTP \${code}, retrying in 15s..."
          sleep 15
        done
        echo "Smoke test FAILED after 10 attempts" >&2
        exit 1
    """

    echo "==> Per-instance health check"
    sh "python3 python/cloudforge/health/health_check.py --environment ${environment} --region ${region} --tf-outputs ${Config.terraformOutputsFile(environment)}"
}
