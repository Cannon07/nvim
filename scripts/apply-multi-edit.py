#!/usr/bin/env python3
"""Apply a MultiEdit (multiple old_string -> new_string edits) to a file.

Usage:
    python3 apply-multi-edit.py <hook_json> <output_path>

Reads the full hook JSON as argv[1], extracts edits from tool_input,
and applies them sequentially.
"""
import json
import sys


def main():
    input_json = json.loads(sys.argv[1])
    file_path = input_json["tool_input"]["file_path"]
    edits = input_json["tool_input"].get("edits", [])
    output_path = sys.argv[2]

    try:
        with open(file_path, "r") as f:
            content = f.read()
    except FileNotFoundError:
        content = ""

    for edit in edits:
        old = edit.get("old_string", "")
        new = edit.get("new_string", "")
        if old == "":
            content = new + content
        else:
            content = content.replace(old, new, 1)

    with open(output_path, "w") as f:
        f.write(content)


if __name__ == "__main__":
    main()
