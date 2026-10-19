#!/usr/bin/env python3
import json
import re
from pathlib import Path

root = Path(__file__).resolve().parent.parent
device = root / "devices/Ziyuns-M5-MBP"


def single(pattern, text, source):
    matches = re.findall(pattern, text, re.MULTILINE)
    assert len(matches) == 1, f"expected one {pattern!r} in {source}, got {matches}"
    return matches[0]


# ds4-serve decides where the server listens and how much context it allocates;
# every client catalog that points at it must agree.
launcher = (device / ".local/bin/ds4-serve").read_text()
host = single(r"^\s+--host (\S+) \\$", launcher, "ds4-serve")
port = single(r"^\s+--port (\d+) \\$", launcher, "ds4-serve")
ctx = int(single(r"^\s+--ctx (\d+) \\$", launcher, "ds4-serve"))
base_url = f"http://{host}:{port}/v1"
assert f"http://{host}:{port}." in launcher, "ds4-serve --help names a different address"

# omp samples at temperature 1.0, where ds4 documents --mtp-exact-sampling as the
# faithful MTP mode (docs/SPECULATIVE_DECODING.md); plain --mtp alone is greedier.
single(r"^\s+(--mtp) \\$", launcher, "ds4-serve")
single(r"^\s+(--mtp-exact-sampling) \\$", launcher, "ds4-serve")

pi = json.loads((device / ".pi/agent/models.json").read_text())["providers"]["ds4"]
assert pi["baseUrl"] == base_url, f"Pi ds4 baseUrl {pi['baseUrl']} != {base_url}"
assert pi["models"], "Pi ds4 provider lists no models"
for model in pi["models"]:
    assert model["contextWindow"] == ctx, f"Pi {model['id']} contextWindow {model['contextWindow']} != {ctx}"

# omp's catalog is YAML and only holds the ds4 provider; read its two fields directly.
omp = (device / ".omp/agent/models.yml").read_text()
omp_url = single(r"^\s+baseUrl: (\S+)$", omp, "omp models.yml")
omp_ctx = int(single(r"^\s+contextWindow: (\d+)$", omp, "omp models.yml"))
assert omp_url == base_url, f"omp ds4 baseUrl {omp_url} != {base_url}"
assert omp_ctx == ctx, f"omp ds4 contextWindow {omp_ctx} != {ctx}"

print("ok - ds4 client catalogs match the ds4-serve launcher")
