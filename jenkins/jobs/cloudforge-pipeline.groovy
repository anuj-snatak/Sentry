// Job DSL seed script: creates the CloudForge pipeline job from code
// instead of manual "New Item" clicking, so the job definition itself
// is versioned. Run this from a one-time "seed job" that has the Job
// DSL plugin installed and points at this file
// (jenkins/jobs/cloudforge-pipeline.groovy).
//
// This is optional — a Multibranch Pipeline job pointed at jenkins/Jenkinsfile
// works just as well and needs no seed job at all. Use whichever fits
// your Jenkins setup; this file exists for teams that already run a
// Job-DSL-based "jobs as code" pattern.

pipelineJob('cloudforge-deploy') {
    description('One-click CloudForge infrastructure + application deployment. Parameters select environment, action, and what to deploy.')

    parameters {
        // Mirrors jenkins/Jenkinsfile's `parameters {}` block. Job DSL
        // doesn't need to redeclare these for the pipeline to work (the
        // Jenkinsfile is authoritative), but pre-declaring them here
        // means the very first run's parameter form is already populated
        // instead of needing one throwaway run first.
        choiceParam('ENVIRONMENT', ['dev', 'qa', 'uat', 'prod'], 'Target environment')
        stringParam('AWS_REGION', 'us-east-1', 'AWS region')
        choiceParam('ACTION', ['apply', 'plan', 'destroy'], 'Terraform action')
        booleanParam('DEPLOY_APPLICATION', true, 'Run the Ansible application deployment stage')
        booleanParam('DEPLOY_MONITORING', true, 'Apply the monitoring role stack')
        stringParam('INSTANCE_TYPE', '', 'Override instance_type for this run only')
        booleanParam('AUTO_APPROVE', false, 'Skip manual approval (dev only — see Config.groovy)')
        stringParam('APP_IMAGE', '', 'Container image to deploy')
        stringParam('APP_IMAGE_TAG', 'latest', 'Image tag to deploy')
        booleanParam('ROLLBACK', false, 'Roll back to the last known-good image tag')
    }

    properties {
        pipelineTriggers {
            triggers {
                githubPush()
            }
        }
    }

    definition {
        cpsScm {
            scm {
                git {
                    remote {
                        // Replace with this repository's actual clone URL.
                        url('https://github.com/your-org/cloudforge.git')
                        credentials('github-credentials')
                    }
                    branch('*/main')
                }
            }
            scriptPath('jenkins/Jenkinsfile')
            lightweight(true)
        }
    }

    logRotator {
        numToKeep(30)
    }
}
