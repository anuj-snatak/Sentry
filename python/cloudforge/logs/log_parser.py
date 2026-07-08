"""Pulls recent CloudWatch Logs events matching a pattern (default:
ERROR) from a log group — e.g. one of the
/<project>/<environment>/{app,nginx-access,nginx-error} groups the
cloudwatch Ansible role creates — and prints a summary. Useful for a
human debugging a failed deployment, or as an extra post-deploy signal
a pipeline could gate on (not wired into the default pipeline: what
counts as a "too many errors" threshold is app-specific).
"""

from __future__ import annotations

import argparse
import sys
from datetime import datetime, timedelta, timezone

from cloudforge.common import get_boto3_session, setup_logging


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--log-group", required=True)
    parser.add_argument("--region", default="us-east-1")
    parser.add_argument("--since-minutes", type=int, default=60)
    parser.add_argument("--pattern", default="ERROR", help="CloudWatch Logs filter pattern")
    parser.add_argument("--max-events", type=int, default=200)
    parser.add_argument("--output", help="Path to write matched events as text. Omit to print to stdout only.")
    parser.add_argument("-v", "--verbose", action="store_true")
    return parser.parse_args(argv)


def fetch_matching_events(logs_client, log_group: str, pattern: str, since_minutes: int, max_events: int) -> list[dict]:
    start_time_ms = int((datetime.now(timezone.utc) - timedelta(minutes=since_minutes)).timestamp() * 1000)

    events: list[dict] = []
    paginator = logs_client.get_paginator("filter_log_events")
    for page in paginator.paginate(
        logGroupName=log_group,
        startTime=start_time_ms,
        filterPattern=pattern,
        PaginationConfig={"MaxItems": max_events},
    ):
        events.extend(page.get("events", []))
        if len(events) >= max_events:
            break

    return events[:max_events]


def format_events(events: list[dict]) -> str:
    lines = []
    for event in events:
        ts = datetime.fromtimestamp(event["timestamp"] / 1000, tz=timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC")
        lines.append(f"[{ts}] {event['message'].rstrip()}")
    return "\n".join(lines)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    logger = setup_logging(args.verbose)

    session = get_boto3_session(args.region)
    logs_client = session.client("logs")

    try:
        events = fetch_matching_events(logs_client, args.log_group, args.pattern, args.since_minutes, args.max_events)
    except logs_client.exceptions.ResourceNotFoundException:
        logger.error("Log group not found: %s", args.log_group)
        return 1

    logger.info(
        "%d event(s) matching '%s' in the last %d minute(s) in %s",
        len(events),
        args.pattern,
        args.since_minutes,
        args.log_group,
    )

    formatted = format_events(events)
    if args.output:
        with open(args.output, "w", encoding="utf-8") as f:
            f.write(formatted + "\n")
        logger.info("Wrote matched events to %s", args.output)
    elif events:
        print(formatted)

    return 0


if __name__ == "__main__":
    sys.exit(main())
