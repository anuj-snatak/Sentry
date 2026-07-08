import com.cloudforge.pipeline.TerraformRunner

/**
 * Applies the plan file produced by terraformPlan in this same
 * workspace/build — never a fresh, unreviewed plan — so what gets
 * approved is exactly what gets applied.
 */
def call(String environment) {
    echo "==> terraform apply (${environment})"
    new TerraformRunner(this, environment).apply()
}
