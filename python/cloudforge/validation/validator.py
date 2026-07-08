"""Pre-flight validation run before a pipeline (or a developer) touches
any real infrastructure: required CLI tools are installed, AWS
credentials actually resolve to an identity, and the target
environment's tfvars file exists. Fails loud with a full list of every
problem found in one pass, rather than stopping at the first one, so
a fix-and-retry loop doesn't have to run this five times to discover
five separate issues.
"""

from __future__ import annotations

import argparse
import shutil
import subprocess
import sys
from pathlib import Path

from cloudforge.common import setup_logging

REQUIRED_TOOLS = ["terraform", "ansible-playbook", "aws", "python3", "docker"]


def check_tools_installed(logger) -> list[str]:
    problems = []
    for tool in REQUIRED_TOOLS:
        if shutil.which(tool) is None:
            problems.append(f"required tool not found on PATH: {tool}")
        else:
            logger.debug("found %s at %s", tool, shutil.which(tool))
    return problems


def check_aws_credentials(logger) -> list[str]:
    try:
        result = subprocess.run(
            ["aws", "sts", "get-caller-identity"],
            capture_output=True,
            text=True,
            timeout=15,
            check=False,
        )
    except (FileNotFoundError, subprocess.TimeoutExpired) as exc:
        return [f"could not run 'aws sts get-caller-identity': {exc}"]

    if result.returncode != 0:
        return [f"AWS credentials are not valid/configured: {result.stderr.strip()}"]

    logger.debug("aws sts get-caller-identity: %s", result.stdout.strip())
    return []


def check_environment_tfvars(environment: str, repo_root: Path) -> list[str]:
    tfvars_path = repo_root / "terraform" / "environments" / environment / "terraform.tfvars"
    if not tfvars_path.is_file():
        return [f"missing tfvars file for environment '{environment}': {tfvars_path}"]
    return []


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--environment", required=True)
    parser.add_argument("--repo-root", default=".", help="Path to the repository root")
    parser.add_argument("--skip-aws", action="store_true", help="Skip the AWS credentials check")
    parser.add_argument("-v", "--verbose", action="store_true")
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    logger = setup_logging(args.verbose)
    repo_root = Path(args.repo_root).resolve()

    problems: list[str] = []
    problems += check_tools_installed(logger)
    problems += check_environment_tfvars(args.environment, repo_root)
    if not args.skip_aws:
        problems += check_aws_credentials(logger)

    if problems:
        logger.error("Validation FAILED with %d problem(s):", len(problems))
        for problem in problems:
            logger.error("  - %s", problem)
        return 1

    logger.info("Validation passed: environment='%s', repo_root='%s'", args.environment, repo_root)
    return 0


if __name__ == "__main__":
    sys.exit(main())
