# Partial backend configuration. The values below are placeholders that
# make `terraform init` work out of the box for local experimentation,
# but real pipelines (see jenkins/Jenkinsfile + shared-library/vars/terraformInit.groovy)
# MUST override bucket/dynamodb_table/region at init time with the outputs
# from terraform/backend, e.g.:
#
#   terraform init \
#     -backend-config="bucket=<state_bucket_name output>" \
#     -backend-config="dynamodb_table=<lock_table_name output>" \
#     -backend-config="region=<aws_region>" \
#     -reconfigure
#
# This keeps the bucket/table names out of version control while still
# giving every environment a consistent, discoverable backend.tf.
terraform {
  backend "s3" {
    key            = "dev/terraform.tfstate"
    bucket         = "cloudforge-terraform-state-REPLACE_ME"
    dynamodb_table = "cloudforge-terraform-lock-REPLACE_ME"
    region         = "us-east-1"
    encrypt        = true
  }
}
