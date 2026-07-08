from setuptools import find_packages, setup

setup(
    name="cloudforge",
    version="1.0.0",
    description="Automation scripts for the CloudForge DevOps platform (inventory generation, health checks, deployment/cost/infrastructure reports, validation, log parsing).",
    packages=find_packages(exclude=["tests", "tests.*"]),
    python_requires=">=3.9",
    install_requires=[
        "boto3>=1.34,<2.0",
        "botocore>=1.34,<2.0",
        "PyYAML>=6.0,<7.0",
    ],
    entry_points={
        "console_scripts": [
            "cloudforge-inventory=cloudforge.inventory.dynamic_inventory:main",
            "cloudforge-tf-output=cloudforge.terraform.output_parser:main",
            "cloudforge-health-check=cloudforge.health.health_check:main",
            "cloudforge-deployment-report=cloudforge.reports.deployment_report:main",
            "cloudforge-infra-report=cloudforge.reports.infrastructure_report:main",
            "cloudforge-cost-report=cloudforge.reports.cost_report:main",
            "cloudforge-validate=cloudforge.validation.validator:main",
            "cloudforge-log-parser=cloudforge.logs.log_parser:main",
        ]
    },
)
