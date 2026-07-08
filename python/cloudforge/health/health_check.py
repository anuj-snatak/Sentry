"""Per-instance deep health check, run over SSM (no SSH, no open ports
needed) against every InService instance in the app Auto Scaling Group.
Complements the ALB-level smoke test in
shared-library/vars/healthCheck.groovy: the ALB can report "healthy"
based on just a majority of targets, which can hide a partially broken
deployment. This checks every instance individually and fails loud if
any one of them isn't actually serving correctly.
"""

from __future__ import annotations

import argparse
import sys
import time
from typing import Any

from cloudforge.common import get_boto3_session, load_json_file, setup_logging, terraform_output_value
from cloudforge.inventory.dynamic_inventory import get_in_service_instance_ids

# Every check must pass for an instance to be considered healthy. Kept as
# one shell script per instance (one SSM command covers every check) so
# a single command's output tells us exactly which sub-check failed.
CHECK_SCRIPT_TEMPLATE = """
set -uo pipefail
fail=0

if ! docker ps --filter "status=running" --format '{{{{.Names}}}}' | grep -q '^{app_name}$'; then
    echo "FAIL: application container '{app_name}' is not running"
    fail=1
fi

if ! curl -fsS -o /dev/null "http://127.0.0.1:{app_port}{health_path}"; then
    echo "FAIL: application health endpoint http://127.0.0.1:{app_port}{health_path} did not return 2xx"
    fail=1
fi

if ! systemctl is-active --quiet node_exporter; then
    echo "FAIL: node_exporter service is not active"
    fail=1
fi

if ! systemctl is-active --quiet amazon-cloudwatch-agent; then
    echo "FAIL: amazon-cloudwatch-agent service is not active"
    fail=1
fi

if [ "$fail" -eq 0 ]; then
    echo "PASS: all checks green"
fi
exit $fail
"""


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--environment", required=True)
    parser.add_argument("--region", required=True)
    parser.add_argument("--tf-outputs", required=True)
    parser.add_argument("--app-name", default="cloudforge-app")
    parser.add_argument("--app-port", type=int, default=8080)
    parser.add_argument("--health-path", default="/health")
    parser.add_argument("--poll-interval-seconds", type=int, default=5)
    parser.add_argument("--poll-timeout-seconds", type=int, default=120)
    parser.add_argument("-v", "--verbose", action="store_true")
    return parser.parse_args(argv)


def send_check_command(ssm_client: Any, instance_ids: list[str], script: str) -> str:
    response = ssm_client.send_command(
        InstanceIds=instance_ids,
        DocumentName="AWS-RunShellScript",
        Comment="cloudforge per-instance health check",
        Parameters={"commands": [script]},
    )
    return response["Command"]["CommandId"]


def wait_for_invocation(
    ssm_client: Any,
    command_id: str,
    instance_id: str,
    poll_interval_seconds: int,
    poll_timeout_seconds: int,
    logger,
) -> dict:
    """Polls get_command_invocation until the command reaches a terminal
    state, retrying through the transient InvocationDoesNotExist error
    that's normal for the first second or two after send_command."""
    deadline = time.monotonic() + poll_timeout_seconds
    terminal_states = {"Success", "Failed", "Cancelled", "TimedOut"}

    while time.monotonic() < deadline:
        try:
            invocation = ssm_client.get_command_invocation(CommandId=command_id, InstanceId=instance_id)
        except ssm_client.exceptions.InvocationDoesNotExist:
            time.sleep(poll_interval_seconds)
            continue

        if invocation["Status"] in terminal_states:
            return invocation

        logger.debug("instance %s: still %s, polling again...", instance_id, invocation["Status"])
        time.sleep(poll_interval_seconds)

    raise TimeoutError(f"instance {instance_id}: health check did not complete within {poll_timeout_seconds}s")


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    logger = setup_logging(args.verbose)

    try:
        outputs = load_json_file(args.tf_outputs)
        asg_name = terraform_output_value(outputs, "autoscaling_group_name")
    except (FileNotFoundError, ValueError, KeyError) as exc:
        logger.error(str(exc))
        return 1

    session = get_boto3_session(args.region)
    asg_client = session.client("autoscaling")
    ssm_client = session.client("ssm")

    try:
        instance_ids = get_in_service_instance_ids(asg_client, asg_name)
    except ValueError as exc:
        logger.error(str(exc))
        return 1

    if not instance_ids:
        logger.error("No InService instances found in '%s'; cannot run health checks.", asg_name)
        return 1

    logger.info("Running health check on %d instance(s): %s", len(instance_ids), ", ".join(instance_ids))

    script = CHECK_SCRIPT_TEMPLATE.format(
        app_name=args.app_name, app_port=args.app_port, health_path=args.health_path
    )
    command_id = send_check_command(ssm_client, instance_ids, script)

    all_healthy = True
    for instance_id in instance_ids:
        try:
            invocation = wait_for_invocation(
                ssm_client, command_id, instance_id, args.poll_interval_seconds, args.poll_timeout_seconds, logger
            )
        except TimeoutError as exc:
            logger.error(str(exc))
            all_healthy = False
            continue

        if invocation["Status"] == "Success":
            logger.info("instance %s: HEALTHY", instance_id)
        else:
            all_healthy = False
            logger.error(
                "instance %s: UNHEALTHY (status=%s)\n%s",
                instance_id,
                invocation["Status"],
                invocation.get("StandardOutputContent", "").strip(),
            )

    if not all_healthy:
        logger.error("Health check FAILED for one or more instances in '%s'", args.environment)
        return 1

    logger.info("Health check PASSED for all instances in '%s'", args.environment)
    return 0


if __name__ == "__main__":
    sys.exit(main())
