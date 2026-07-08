"""Shared helpers used by every cloudforge CLI tool: consistent logging
setup and boto3 session creation, kept in one place so each script isn't
re-implementing the same boilerplate."""

from __future__ import annotations

import json
import logging
import sys
from pathlib import Path
from typing import Any

import boto3


def setup_logging(verbose: bool = False) -> logging.Logger:
    level = logging.DEBUG if verbose else logging.INFO
    logging.basicConfig(
        level=level,
        format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
        stream=sys.stderr,
    )
    return logging.getLogger("cloudforge")


def get_boto3_session(region: str) -> boto3.Session:
    return boto3.Session(region_name=region)


def load_json_file(path: str) -> dict[str, Any]:
    file_path = Path(path)
    if not file_path.is_file():
        raise FileNotFoundError(f"expected file not found: {path}")
    with file_path.open(encoding="utf-8") as f:
        try:
            return json.load(f)
        except json.JSONDecodeError as exc:
            raise ValueError(f"{path} is not valid JSON: {exc}") from exc


def terraform_output_value(outputs: dict[str, Any], key: str) -> Any:
    """Unwraps the `terraform output -json` structure, where every value
    is nested as {"value": ..., "type": ..., "sensitive": bool}."""
    if key not in outputs:
        raise KeyError(f"terraform output '{key}' not found. Available: {sorted(outputs.keys())}")
    return outputs[key]["value"]
