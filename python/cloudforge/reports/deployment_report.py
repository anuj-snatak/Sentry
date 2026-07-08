"""Generates a per-build Markdown deployment report and, on success,
persists a small JSON record of the deployment to S3 so a later
`--print-last-good-tag` call (used by shared-library/vars/rollback.groovy)
can find the most recent known-good application image tag to roll back
to. This is the platform's entire "deployment history" — deliberately
just timestamped JSON objects in S3, not a database, since that's all
rollback actually needs.
"""

from __future__ import annotations

import argparse
import json
import sys
from datetime import datetime, timezone

from cloudforge.common import get_boto3_session, setup_logging

HISTORY_PREFIX = "deployments"


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--environment", required=True)
    parser.add_argument("--region", default="us-east-1")
    parser.add_argument("--history-bucket", help="S3 bucket to read/write deployment history records")
    parser.add_argument("--build-number", default="")
    parser.add_argument("--build-url", default="")
    parser.add_argument("--status", default="unknown", choices=["success", "failure", "unknown"])
    parser.add_argument("--app-image-tag", default="")
    parser.add_argument("--output", help="Path to write the Markdown report (omit with --print-last-good-tag)")
    parser.add_argument(
        "--print-last-good-tag",
        action="store_true",
        help="Instead of generating a report, print the most recent status=success image tag and exit",
    )
    parser.add_argument("-v", "--verbose", action="store_true")
    return parser.parse_args(argv)


def history_key(environment: str, timestamp: str, build_number: str) -> str:
    return f"{HISTORY_PREFIX}/{environment}/{timestamp}-{build_number or 'unknown'}.json"


def persist_record(s3_client, bucket: str, record: dict, logger) -> None:
    key = history_key(record["environment"], record["timestamp"], record["build_number"])
    s3_client.put_object(
        Bucket=bucket,
        Key=key,
        Body=json.dumps(record, indent=2).encode("utf-8"),
        ContentType="application/json",
    )
    logger.info("Persisted deployment record to s3://%s/%s", bucket, key)


def find_last_good_tag(s3_client, bucket: str, environment: str, logger) -> str | None:
    prefix = f"{HISTORY_PREFIX}/{environment}/"
    paginator = s3_client.get_paginator("list_objects_v2")
    keys: list[str] = []
    for page in paginator.paginate(Bucket=bucket, Prefix=prefix):
        keys.extend(obj["Key"] for obj in page.get("Contents", []))

    # Keys are "<prefix><ISO-8601 timestamp>-<build number>.json"; a plain
    # lexicographic sort is a correct chronological sort for ISO-8601.
    for key in sorted(keys, reverse=True):
        obj = s3_client.get_object(Bucket=bucket, Key=key)
        record = json.loads(obj["Body"].read())
        if record.get("status") == "success" and record.get("app_image_tag"):
            logger.info("Last known-good record: %s (tag=%s)", key, record["app_image_tag"])
            return record["app_image_tag"]

    logger.warning("No status=success deployment record with an image tag found under s3://%s/%s", bucket, prefix)
    return None


def render_markdown(record: dict) -> str:
    status_emoji = {"success": "✅", "failure": "❌", "unknown": "❓"}.get(record["status"], "❓")
    return f"""# Deployment Report — {record['environment']}

| Field | Value |
|---|---|
| Status | {status_emoji} {record['status']} |
| Environment | {record['environment']} |
| Build number | {record['build_number'] or 'n/a'} |
| Build URL | {record['build_url'] or 'n/a'} |
| Application image tag | {record['app_image_tag'] or 'n/a'} |
| Timestamp (UTC) | {record['timestamp']} |
"""


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    logger = setup_logging(args.verbose)

    session = get_boto3_session(args.region)
    s3_client = session.client("s3") if args.history_bucket else None

    if args.print_last_good_tag:
        if not s3_client:
            logger.error("--history-bucket is required with --print-last-good-tag")
            return 1
        tag = find_last_good_tag(s3_client, args.history_bucket, args.environment, logger)
        if tag:
            print(tag)
            return 0
        return 1

    record = {
        "environment": args.environment,
        "status": args.status,
        "build_number": args.build_number,
        "build_url": args.build_url,
        "app_image_tag": args.app_image_tag,
        "timestamp": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    }

    if args.output:
        with open(args.output, "w", encoding="utf-8") as f:
            f.write(render_markdown(record))
        logger.info("Wrote report to %s", args.output)

    if args.status == "success" and s3_client:
        persist_record(s3_client, args.history_bucket, record, logger)
    elif args.status == "success" and not s3_client:
        logger.warning("--history-bucket not provided; this successful deployment will not be rollback-able.")

    return 0


if __name__ == "__main__":
    sys.exit(main())
