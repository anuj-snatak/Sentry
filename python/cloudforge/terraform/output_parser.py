"""Parses a `terraform output -json` dump and prints either a single
value or the full flattened set. Used both as a library (by
dynamic_inventory.py and health_check.py) and as a standalone CLI —
e.g. from a Bash script that just needs one output value without
juggling `terraform -chdir=... output -raw ...` itself.
"""

from __future__ import annotations

import argparse
import json
import sys

from cloudforge.common import load_json_file, setup_logging, terraform_output_value


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--tf-outputs", required=True, help="Path to a `terraform output -json` dump")
    parser.add_argument("--key", help="Print only this output's value. Omit to print all outputs as flat JSON.")
    parser.add_argument("-v", "--verbose", action="store_true")
    return parser.parse_args(argv)


def flatten_outputs(outputs: dict) -> dict:
    return {key: value["value"] for key, value in outputs.items()}


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    logger = setup_logging(args.verbose)

    try:
        outputs = load_json_file(args.tf_outputs)
        if args.key:
            value = terraform_output_value(outputs, args.key)
            print(value if isinstance(value, str) else json.dumps(value))
        else:
            print(json.dumps(flatten_outputs(outputs), indent=2))
        return 0
    except (FileNotFoundError, ValueError, KeyError) as exc:
        logger.error(str(exc))
        return 1


if __name__ == "__main__":
    sys.exit(main())
