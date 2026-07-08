package com.cloudforge.pipeline

/**
 * Central place for values that would otherwise be duplicated (and drift)
 * across multiple vars/ scripts: per-environment defaults, and path
 * conventions that tie this library to the repo layout in terraform/ and
 * ansible/. Pure/stateless on purpose (no pipeline `script` steps here)
 * so it's trivially safe under Jenkins' CPS serialization.
 */
class Config implements Serializable {

    static final List<String> VALID_ENVIRONMENTS = ['dev', 'qa', 'uat', 'prod']

    static final Map<String, Map> ENVIRONMENT_DEFAULTS = [
        dev:  [autoApproveAllowed: true,  instanceType: 't3.micro'],
        qa:   [autoApproveAllowed: false, instanceType: 't3.small'],
        uat:  [autoApproveAllowed: false, instanceType: 't3.small'],
        prod: [autoApproveAllowed: false, instanceType: 't3.medium'],
    ]

    static void requireValidEnvironment(String environment) {
        if (!VALID_ENVIRONMENTS.contains(environment)) {
            throw new IllegalArgumentException(
                "Unknown environment '${environment}'. Must be one of: ${VALID_ENVIRONMENTS.join(', ')}"
            )
        }
    }

    static String terraformDir(String environment) {
        requireValidEnvironment(environment)
        return "terraform/environments/${environment}"
    }

    static String ansibleInventoryPath(String environment) {
        requireValidEnvironment(environment)
        return "inventories/${environment}/hosts.yml"
    }

    static String terraformOutputsFile(String environment) {
        return "tf-outputs-${environment}.json"
    }

    static boolean autoApproveAllowed(String environment) {
        return ENVIRONMENT_DEFAULTS[environment]?.autoApproveAllowed ?: false
    }
}
