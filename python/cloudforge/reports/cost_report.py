"""Pulls actual spend for this project/environment from AWS Cost
Explorer, grouped by service, for the trailing N days. Uses Cost
Explorer's tag-based filtering against the Project/Environment tags
every module in this repo applies (see each Terraform module's `tags`
variable) — no separate cost-allocation setup needed beyond enabling
those tags as cost allocation tags once in the Billing console.

Standalone/manual tool; not part of the deploy pipeline. Cost Explorer
itself is a paid API (small per-request cost), which is why this isn't
run on every build.
"""

from __future__ import annotations

import argparse
import sys
from datetime import date, timedelta

from botocore.exceptions import ClientError

from cloudforge.common import get_boto3_session, setup_logging


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project", default="cloudforge", help="Value of the Project tag to filter on")
    parser.add_argument("--environment", required=True, help="Value of the Environment tag to filter on")
    parser.add_argument("--days", type=int, default=30)
    parser.add_argument("--region", default="us-east-1", help="Cost Explorer is a global API but boto3 still needs a region")
    parser.add_argument("--output", help="Path to write a Markdown report. Omit to print to stdout only.")
    parser.add_argument("-v", "--verbose", action="store_true")
    return parser.parse_args(argv)


def fetch_cost_by_service(ce_client, project: str, environment: str, days: int) -> list[dict]:
    end = date.today()
    start = end - timedelta(days=days)

    response = ce_client.get_cost_and_usage(
        TimePeriod={"Start": start.isoformat(), "End": end.isoformat()},
        Granularity="MONTHLY",
        Metrics=["UnblendedCost"],
        Filter={
            "And": [
                {"Tags": {"Key": "Project", "Values": [project]}},
                {"Tags": {"Key": "Environment", "Values": [environment]}},
            ]
        },
        GroupBy=[{"Type": "DIMENSION", "Key": "SERVICE"}],
    )

    totals: dict[str, float] = {}
    for result in response.get("ResultsByTime", []):
        for group in result.get("Groups", []):
            service = group["Keys"][0]
            amount = float(group["Metrics"]["UnblendedCost"]["Amount"])
            totals[service] = totals.get(service, 0.0) + amount

    return sorted(
        ({"service": service, "cost_usd": round(cost, 2)} for service, cost in totals.items() if cost > 0),
        key=lambda row: row["cost_usd"],
        reverse=True,
    )


def render_markdown(rows: list[dict], project: str, environment: str, days: int) -> str:
    total = round(sum(row["cost_usd"] for row in rows), 2)
    lines = [
        f"# Cost Report — {project}/{environment} (last {days} days)",
        "",
        "| Service | Cost (USD) |",
        "|---|---|",
    ]
    lines += [f"| {row['service']} | ${row['cost_usd']:.2f} |" for row in rows]
    lines += ["", f"**Total: ${total:.2f}**"]
    return "\n".join(lines) + "\n"


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    logger = setup_logging(args.verbose)

    session = get_boto3_session(args.region)
    ce_client = session.client("ce")

    try:
        rows = fetch_cost_by_service(ce_client, args.project, args.environment, args.days)
    except ClientError as exc:
        logger.error("Cost Explorer request failed: %s", exc)
        return 1

    report = render_markdown(rows, args.project, args.environment, args.days)
    if args.output:
        with open(args.output, "w", encoding="utf-8") as f:
            f.write(report)
        logger.info("Wrote cost report to %s", args.output)
    else:
        print(report)

    return 0


if __name__ == "__main__":
    sys.exit(main())
