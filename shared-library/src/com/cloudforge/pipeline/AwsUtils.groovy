package com.cloudforge.pipeline

/**
 * Small, pure helpers for AWS resource naming conventions used across the
 * pipeline. Deliberately holds no credentials and makes no AWS API calls
 * itself — actual authentication is handled by the "Pipeline: AWS Steps"
 * plugin's withAWS() step in the Jenkinsfile (role assumption via
 * jenkins-deploy-role, never static access keys). This class only knows
 * how those resources are *named*, so that naming convention lives in
 * exactly one place instead of being copy-pasted into every vars/ script.
 */
class AwsUtils implements Serializable {

    static String jenkinsDeployRoleArn(String accountId, String projectName) {
        return "arn:aws:iam::${accountId}:role/${projectName}-jenkins-deploy"
    }

    static String stateObjectKey(String environment) {
        return "${environment}/terraform.tfstate"
    }

    static String ecrRepositoryUrl(String accountId, String region, String repositoryName) {
        return "${accountId}.dkr.ecr.${region}.amazonaws.com/${repositoryName}"
    }

    // Must match terraform/environments/<env>/main.tf's
    // module.app_data_bucket bucket_name expression exactly:
    // "${local.name_prefix}-app-data-${data.aws_caller_identity.current.account_id}"
    // where local.name_prefix = "${project_name}-${environment}". Computed
    // here rather than read back from `terraform output` so generateReport
    // and rollback don't need a live Terraform outputs file to run.
    static String appDataBucketName(String accountId, String projectName, String environment) {
        return "${projectName}-${environment}-app-data-${accountId}"
    }
}
