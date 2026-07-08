import com.cloudforge.pipeline.TerraformRunner

def call(String environment) {
    echo "==> terraform validate (${environment})"
    new TerraformRunner(this, environment).validate()
}
