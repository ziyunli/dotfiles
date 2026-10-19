#!/usr/bin/env python3
import re
from pathlib import Path

root = Path(__file__).resolve().parent.parent
path = root / "devices/Ziyuns-M5-MBP/.config/skillshare/config.yaml"
lines = path.read_text().splitlines()

FROM_ENV_INLINE = re.compile(r"^\{fromEnv: [A-Za-z_][A-Za-z0-9_]*\}$")
FROM_ENV_LINE = re.compile(r"^\s+fromEnv: [A-Za-z_][A-Za-z0-9_]*$")


def indent(line):
    return len(line) - len(line.lstrip(" "))


def nested(i):
    """Indices of the non-blank lines nested under line i."""
    found = []
    for j in range(i + 1, len(lines)):
        if not lines[j].strip():
            continue
        if indent(lines[j]) <= indent(lines[i]):
            break
        found.append(j)
    return found


def assert_env_reference(i, what):
    value = lines[i].split(":", 1)[1].strip()
    if value:
        assert FROM_ENV_INLINE.match(value), f"line {i + 1}: {what} is not a fromEnv reference: {lines[i].strip()}"
        return
    inner = nested(i)
    assert len(inner) == 1 and FROM_ENV_LINE.match(lines[inner[0]]), \
        f"line {i + 1}: {what} is not a fromEnv reference: {[lines[j].strip() for j in [i] + inner]}"


# This file is tracked in a public repo and skillshare writes MCP definitions
# into it, so every credential-bearing value must be a {fromEnv: VAR} reference.
# skillshare writes one as `KEY:` followed by a nested `fromEnv: VAR` line.
for i, line in enumerate(lines):
    match = re.match(r"^\s*(env|headers|bearerToken):(.*)$", line)
    if not match:
        continue
    key = match.group(1)
    if key == "bearerToken":
        assert_env_reference(i, "bearerToken")
        continue
    assert not match.group(2).strip(), f"line {i + 1}: inline {key} map; write one entry per line: {line.strip()}"
    inner = nested(i)
    if not inner:
        continue
    entry_indent = indent(lines[inner[0]])
    for j in inner:
        if indent(lines[j]) == entry_indent:
            assert_env_reference(j, f"{key} entry")

print("ok - tracked skillshare config holds only fromEnv credential references")
