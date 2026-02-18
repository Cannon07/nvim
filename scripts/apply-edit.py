#!/usr/bin/env python3
"""Apply a single Edit (old_string -> new_string) to a file and write the result.

Usage:
    python3 apply-edit.py <file_path> <old_string> <new_string> <replace_all> <output_path>
"""
import sys


def main():
    file_path = sys.argv[1]
    old_string = sys.argv[2]
    new_string = sys.argv[3]
    replace_all = sys.argv[4] == "true"
    output_path = sys.argv[5]

    try:
        with open(file_path, "r") as f:
            content = f.read()
    except FileNotFoundError:
        content = ""

    if replace_all:
        result = content.replace(old_string, new_string)
    else:
        result = content.replace(old_string, new_string, 1)

    with open(output_path, "w") as f:
        f.write(result)


if __name__ == "__main__":
    main()
