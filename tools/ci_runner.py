#!/usr/bin/env python3
"""
CI Runner for Wolf of Hoh Xil — Godot 4.6 headless test executor.

Maintained by: ci-judge agent
Purpose: Run Godot headless tests, capture stderr, classify errors.

Usage:
    python tools/ci_runner.py [--project PATH] [--test-script res://tests/run_all.gd]
"""

import subprocess
import sys
import re
import json
import hashlib
import os
from pathlib import Path
from datetime import datetime
from typing import Optional


# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

GODOT_EXECUTABLE = "godot"
DEFAULT_PROJECT = "."
DEFAULT_TEST_SCRIPT = "res://tests/run_all.gd"
CACHE_DIR = ".claude/agent-memory/ci-judge"
CACHE_FILE = "error_cache.json"
MAX_RETRIES = 3


# ---------------------------------------------------------------------------
# Error classification patterns
# ---------------------------------------------------------------------------

STRUCTURAL_PATTERNS = [
    (re.compile(r"Node not found:\s*\"(.+?)\""), "NODE_NOT_FOUND"),
    (re.compile(r"Attempt to connect signal\s*'(\w+)'\s*to nonexistent method"), "SIGNAL_MISMATCH"),
    (re.compile(r"Scene\s*'(.+?)'\s*failed to instantiate"), "SCENE_LOAD_FAILURE"),
    (re.compile(r"Cannot get path of node as it is not in the scene tree"), "NODE_NOT_IN_TREE"),
    (re.compile(r"Resource file not found:\s*'(.+?)'"), "RESOURCE_NOT_FOUND"),
    (re.compile(r"Invalid call\.\s*Nonexistent function\s*'(.+?)'\s*in base"), "FUNC_NOT_FOUND"),
    (re.compile(r"Parent node is busy setting up children"), "READY_ORDER_ERROR"),
]

IMPLEMENTATION_PATTERNS = [
    (re.compile(r"Parser Error:\s*(.+)"), "SYNTAX"),
    (re.compile(r"TypeError:\s*(.+)"), "TYPE_MISMATCH"),
    (re.compile(r"Division by zero"), "DIV_BY_ZERO"),
    (re.compile(r"Invalid operands\s*'(.+?)'\s*and\s*'(.+?)'\s*for operator"), "OPERAND_MISMATCH"),
    (re.compile(r"Index\s*\d+\s*out of bounds"), "INDEX_BOUNDS"),
    (re.compile(r"Invalid call to function\s*'(.+?)'.*expected\s*(\d+)\s*arguments"), "ARG_COUNT_MISMATCH"),
    (re.compile(r"assert\(\).*failed"), "ASSERT_FAILED"),
    (re.compile(r"Invalid access to property or key"), "INVALID_ACCESS"),
    (re.compile(r"Nonexistent function"), "FUNC_NOT_FOUND_IMPL"),
    (re.compile(r"Attempt to call function\s*'(.+?)'\s*in base"), "CALL_ERROR"),
]

WARNING_PATTERNS = [
    re.compile(r"WARNING:\s*(.+)"),
    re.compile(r"W\s*\d+-\d+-\d+\s+\d+:\d+:\d+:\d+\s+(.+)"),  # Godot warning format
]


# ---------------------------------------------------------------------------
# Error cache management
# ---------------------------------------------------------------------------

class ErrorCache:
    """Persistent error tracking to detect 3-strike BLOCKED conditions."""

    def __init__(self, project_root: str):
        self.cache_dir = Path(project_root) / CACHE_DIR
        self.cache_path = self.cache_dir / CACHE_FILE
        self.data = self._load()

    def _load(self) -> dict:
        if self.cache_path.exists():
            try:
                return json.loads(self.cache_path.read_text(encoding="utf-8"))
            except (json.JSONDecodeError, OSError):
                pass
        return {"history": []}

    def _save(self) -> None:
        self.cache_dir.mkdir(parents=True, exist_ok=True)
        self.cache_path.write_text(json.dumps(self.data, indent=2, ensure_ascii=False), encoding="utf-8")

    def hash_error(self, error_type: str, file: str, line: str, raw: str) -> str:
        raw_truncated = raw[:200] if raw else ""
        content = f"{error_type}|{file}|{line}|{raw_truncated}"
        return hashlib.sha256(content.encode()).hexdigest()[:16]

    def record(self, error_type: str, owner: str, file: str, line: str, raw: str) -> dict:
        error_hash = self.hash_error(error_type, file, line, raw)

        # Find existing entry
        for entry in self.data["history"]:
            if entry["hash"] == error_hash:
                entry["count"] += 1
                entry["last_seen"] = datetime.now().isoformat()
                self._save()
                return entry

        # New entry
        entry = {
            "hash": error_hash,
            "owner": owner,
            "type": error_type,
            "file": file,
            "line": line,
            "raw_preview": raw[:100] if raw else "",
            "count": 1,
            "first_seen": datetime.now().isoformat(),
            "last_seen": datetime.now().isoformat(),
        }
        self.data["history"].append(entry)
        self._save()
        return entry

    def is_blocked(self, error_type: str, file: str, line: str, raw: str) -> bool:
        error_hash = self.hash_error(error_type, file, line, raw)
        for entry in self.data["history"]:
            if entry["hash"] == error_hash and entry["count"] >= MAX_RETRIES:
                return True
        return False

    def clear(self) -> None:
        self.data = {"history": []}
        self._save()


# ---------------------------------------------------------------------------
# Godot headless execution
# ---------------------------------------------------------------------------

def find_godot() -> Optional[str]:
    """Locate the Godot executable."""
    # Try the configured executable first
    try:
        result = subprocess.run(
            [GODOT_EXECUTABLE, "--version"],
            capture_output=True, text=True, timeout=10
        )
        if result.returncode == 0:
            return GODOT_EXECUTABLE
    except (FileNotFoundError, subprocess.TimeoutExpired):
        pass

    # Common paths
    candidates = [
        "godot",
        "godot4",
        "Godot_v4.6-stable_win64.exe",
        "/usr/local/bin/godot",
        "/Applications/Godot.app/Contents/MacOS/Godot",
    ]
    for candidate in candidates:
        try:
            result = subprocess.run(
                [candidate, "--version"],
                capture_output=True, text=True, timeout=10
            )
            if result.returncode == 0:
                return candidate
        except (FileNotFoundError, subprocess.TimeoutExpired):
            continue

    return None


def run_godot_headless(project_path: str, test_script: str) -> tuple[int, str, str]:
    """
    Run Godot in headless mode with the test script.
    Returns (exit_code, stdout, stderr).
    """
    godot = find_godot()
    if godot is None:
        return -1, "", "FATAL: Godot executable not found. Please install Godot 4.6 or add it to PATH."

    cmd = [godot, "--headless", "--path", project_path, "--script", test_script]

    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=120,
            cwd=project_path,
        )
        return result.returncode, result.stdout, result.stderr
    except subprocess.TimeoutExpired:
        return -1, "", "FATAL: Godot headless test timed out after 120 seconds."
    except Exception as e:
        return -1, "", f"FATAL: Failed to run Godot: {e}"


# ---------------------------------------------------------------------------
# Error classification
# ---------------------------------------------------------------------------

def classify_errors(stderr: str, cache: ErrorCache) -> list[dict]:
    """Parse stderr and classify each error as STRUCTURAL or IMPLEMENTATION."""
    errors = []
    lines = stderr.split("\n")

    for i, line in enumerate(lines):
        if not line.strip():
            continue

        # Extract file:line if present
        file_match = re.search(r"(.+?\.gd):(\d+)", line)
        file_name = file_match.group(1) if file_match else "unknown"
        line_num = file_match.group(2) if file_match else "0"

        # Check structural patterns
        for pattern, error_type in STRUCTURAL_PATTERNS:
            m = pattern.search(line)
            if m:
                entry = cache.record(error_type, "structural-architect", file_name, line_num, line)
                errors.append({
                    "classification": "STRUCTURAL",
                    "owner": "structural-architect",
                    "type": error_type,
                    "file": file_name,
                    "line": line_num,
                    "raw": line.strip(),
                    "retry_count": entry["count"],
                    "blocked": entry["count"] >= MAX_RETRIES,
                })
                break
        else:
            # Check implementation patterns
            for pattern, error_type in IMPLEMENTATION_PATTERNS:
                m = pattern.search(line)
                if m:
                    entry = cache.record(error_type, "gdscript-geek", file_name, line_num, line)
                    errors.append({
                        "classification": "IMPLEMENTATION",
                        "owner": "gdscript-geek",
                        "type": error_type,
                        "file": file_name,
                        "line": line_num,
                        "raw": line.strip(),
                        "retry_count": entry["count"],
                        "blocked": entry["count"] >= MAX_RETRIES,
                    })
                    break
            else:
                # Check if it's a warning
                is_warning = any(p.search(line) for p in WARNING_PATTERNS)
                if is_warning:
                    errors.append({
                        "classification": "WARNING",
                        "owner": "both",
                        "type": "WARNING",
                        "file": file_name,
                        "line": line_num,
                        "raw": line.strip(),
                        "retry_count": 0,
                        "blocked": False,
                    })
                elif line.strip():
                    # Unknown error — flag as implementation by default
                    errors.append({
                        "classification": "UNKNOWN",
                        "owner": "gdscript-geek",
                        "type": "UNKNOWN",
                        "file": file_name,
                        "line": line_num,
                        "raw": line.strip(),
                        "retry_count": 0,
                        "blocked": False,
                    })

    return errors


# ---------------------------------------------------------------------------
# Verdict generation
# ---------------------------------------------------------------------------

def generate_verdict(errors: list[dict], exit_code: int, stdout: str, stderr: str) -> tuple[str, int]:
    """
    Generate the CI verdict.
    Returns (verdict_text, exit_code_for_ci).
    """
    if exit_code == 0 and not errors:
        return (
            "## CI VERDICT: PASS\n\n"
            "Console clean. No errors, no warnings. Implementation pipeline complete.\n"
        ), 0

    structural = [e for e in errors if e["classification"] == "STRUCTURAL"]
    implementation = [e for e in errors if e["classification"] == "IMPLEMENTATION"]
    warnings = [e for e in errors if e["classification"] == "WARNING"]
    unknown = [e for e in errors if e["classification"] == "UNKNOWN"]
    blocked_errors = [e for e in errors if e.get("blocked")]

    lines = []

    if blocked_errors:
        lines.append("## CI VERDICT: BLOCKED\n")
        lines.append(f"**{len(blocked_errors)} error(s) have reached the 3-retry limit.**\n")
        lines.append("Automatic fix has failed. Human intervention required.\n")
        for e in blocked_errors:
            lines.append(f"- **Owner**: {e['owner']}")
            lines.append(f"  - Type: {e['type']}")
            lines.append(f"  - File: {e['file']}:{e['line']}")
            lines.append(f"  - Retries: {e['retry_count']}")
            lines.append(f"  - Error: `{e['raw']}`")
            lines.append("")
        return "\n".join(lines), 2  # exit code 2 = BLOCKED

    if structural and implementation:
        lines.append("## CI VERDICT: REJECT — MIXED\n")
    elif structural:
        lines.append("## CI VERDICT: REJECT — STRUCTURAL ERROR\n")
        lines.append(f"**违规人**: structural-architect\n")
    elif implementation:
        lines.append("## CI VERDICT: REJECT — IMPLEMENTATION ERROR\n")
        lines.append(f"**违规人**: gdscript-geek\n")

    lines.append(f"\n**Error summary**: {len(structural)} structural + {len(implementation)} implementation + {len(warnings)} warnings + {len(unknown)} unknown\n")

    if structural:
        lines.append("\n### Structural Errors (→ structural-architect)\n")
        for e in structural:
            lines.append(f"- [{e['type']}] {e['file']}:{e['line']}")
            lines.append(f"  - `{e['raw']}`")
            lines.append(f"  - Retry #{e['retry_count']}")
            lines.append("")

    if implementation:
        lines.append("\n### Implementation Errors (→ gdscript-geek)\n")
        for e in implementation:
            lines.append(f"- [{e['type']}] {e['file']}:{e['line']}")
            lines.append(f"  - `{e['raw']}`")
            lines.append(f"  - Retry #{e['retry_count']}")
            lines.append("")

    if warnings:
        lines.append("\n### Warnings (must be resolved)\n")
        for e in warnings:
            lines.append(f"- [{e['type']}] {e['file']}:{e['line']}")
            lines.append(f"  - `{e['raw']}`")
            lines.append("")

    if unknown:
        lines.append("\n### Unknown Errors (default → gdscript-geek)\n")
        for e in unknown:
            lines.append(f"- {e['file']}:{e['line']}: `{e['raw']}`")
            lines.append("")

    return "\n".join(lines), 1


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    import argparse

    parser = argparse.ArgumentParser(description="Wolf of Hoh Xil — CI Runner")
    parser.add_argument("--project", default=DEFAULT_PROJECT, help="Godot project path")
    parser.add_argument("--test-script", default=DEFAULT_TEST_SCRIPT, help="Test script resource path")
    parser.add_argument("--clear-cache", action="store_true", help="Clear the error retry cache")
    args = parser.parse_args()

    project_path = os.path.abspath(args.project)

    if args.clear_cache:
        cache = ErrorCache(project_path)
        cache.clear()
        print("Error cache cleared.")
        sys.exit(0)

    # Check if test script exists
    test_path = os.path.join(project_path, args.test_script.replace("res://", ""))
    if not os.path.exists(test_path):
        print(
            f"## CI VERDICT: SKIPPED\n\n"
            f"Test script not found: {test_path}\n"
            f"Create `{args.test_script}` to enable CI testing.\n"
        )
        sys.exit(0)

    print(f"Running: godot --headless --path {project_path} --script {args.test_script}")
    print("-" * 60)

    exit_code, stdout, stderr = run_godot_headless(project_path, args.test_script)

    cache = ErrorCache(project_path)
    errors = classify_errors(stderr, cache)

    verdict, ci_exit_code = generate_verdict(errors, exit_code, stdout, stderr)

    print(verdict)

    if stdout.strip():
        print("-" * 60)
        print("### stdout")
        # Truncate very long output
        stdout_out = stdout[:2000] if len(stdout) > 2000 else stdout
        print(stdout_out)
        if len(stdout) > 2000:
            print(f"... (truncated, full output has {len(stdout)} chars)")

    sys.exit(ci_exit_code)


if __name__ == "__main__":
    main()
