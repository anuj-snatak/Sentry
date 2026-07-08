"""Summarizes a `terraform output -json` dump into a human-readable
Markdown infrastructure report — VPC/subnet layout, ALB endpoint, ASG
name, and everything else exposed by
terraform/environments/<env>/outputs.tf. Standalone tool: not called by
the Jenkins pipeline itself, but handy for a manual "what does dev
actually look like right now" check, or to attach to a change ticket.
"""

from __future__ import annotations

import argparse
import sys

from cloudforge.common import load_json_file, setup_logging

# Human-readable labels for the outputs worth surfacing prominently.
# Anything else in the outputs file still gets listed in the "Other
# Outputs" section, so this report never silently drops a new output
# someone adds to outputs.tf later.
HEADLINE_OUTPUTS = {
    "vpc_id": "VPC ID",
    "vpc_cidr_block": "VPC CIDR",
    "public_subnet_ids": "Public Subnets",
    "private_subnet_ids": "Private Subnets",
    "alb_dns_name": "Application URL (ALB DNS)",
    "autoscaling_group_name": "Auto Scaling Group",
    "app_kms_key_arn": "Application KMS Key",
    "app_data_bucket_name": "Application S3 Bucket",
    "app_table_name": "Application DynamoDB Table",
    "alerts_topic_arn": "Alerts SNS Topic",
}


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--tf-outputs", required=True)
    parser.add_argument("--environment", default="")
    parser.add_argument("--output", required=True)
    parser.add_argument("-v", "--verbose", action="store_true")
    return parser.parse_args(argv)


def render_markdown(outputs: dict, environment: str) -> str:
    flat = {key: value["value"] for key, value in outputs.items()}

    lines = [f"# Infrastructure Report — {environment or 'unknown environment'}", ""]
    lines.append("## Headline Resources")
    lines.append("")
    lines.append("| Resource | Value |")
    lines.append("|---|---|")
    for key, label in HEADLINE_OUTPUTS.items():
        if key in flat:
            lines.append(f"| {label} | `{flat.pop(key)}` |")

    if flat:
        lines.append("")
        lines.append("## Other Outputs")
        lines.append("")
        lines.append("| Output | Value |")
        lines.append("|---|---|")
        for key, value in sorted(flat.items()):
            lines.append(f"| {key} | `{value}` |")

    return "\n".join(lines) + "\n"


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    logger = setup_logging(args.verbose)

    try:
        outputs = load_json_file(args.tf_outputs)
    except (FileNotFoundError, ValueError) as exc:
        logger.error(str(exc))
        return 1

    report = render_markdown(outputs, args.environment)
    with open(args.output, "w", encoding="utf-8") as f:
        f.write(report)

    logger.info("Wrote infrastructure report to %s", args.output)
    return 0


if __name__ == "__main__":
    sys.exit(main())
