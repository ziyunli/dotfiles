#!/usr/bin/env bash
#
# merge-json.sh - Deep merge two JSON files
#
# Merges a base JSON file with an overlay JSON file:
#   - Objects: recursively merged
#   - Arrays: concatenated and deduplicated (union)
#   - Scalars: overlay value wins (conflicts reported to stderr)
#
# Usage:
#   ./merge-json.sh <base> <overlay>
#
# Arguments:
#   base      Path to the base JSON file (e.g., shared dotfiles settings)
#   overlay   Path to the overlay JSON file (e.g., existing local settings)
#
# Output:
#   stdout    Merged JSON
#   stderr    Conflict reports (one per line)
#
# Exit codes:
#   0         Success
#   1         Missing arguments or files
#   2         jq not found
#
set -euo pipefail

if [[ $# -lt 2 ]]; then
    echo "Usage: $0 <base> <overlay>" >&2
    exit 1
fi

BASE="$1"
OVERLAY="$2"

if [[ ! -f "$BASE" ]]; then
    echo "Error: base file not found: $BASE" >&2
    exit 1
fi

if ! command -v jq &>/dev/null; then
    echo "Error: jq is required but not found" >&2
    exit 2
fi

# If no overlay file exists, output the base as-is
if [[ ! -f "$OVERLAY" ]]; then
    jq '.' "$BASE"
    exit 0
fi

# Deep merge with conflict detection
# Pass base as $base via --slurpfile so the jq program receives both inputs
jq --slurpfile base "$BASE" '

# Recursively deep merge two values. overlay wins for scalar conflicts.
# path tracks the current JSON path for conflict reporting.
def deepmerge(base; overlay; path):
  if (base | type) == "object" and (overlay | type) == "object" then
    (base | keys_unsorted) as $bkeys |
    (overlay | keys_unsorted) as $okeys |
    ($bkeys + $okeys) | unique |
    map(. as $k |
      if (base | has($k)) and (overlay | has($k)) then
        { ($k): (null | deepmerge(base[$k]; overlay[$k]; path + "." + $k)) }
      elif (overlay | has($k)) then
        { ($k): overlay[$k] }
      else
        { ($k): base[$k] }
      end
    ) | add // {}
  elif (base | type) == "array" and (overlay | type) == "array" then
    (base + overlay) | unique
  elif base == overlay then
    overlay
  else
    # Scalar conflict: overlay wins, report to stderr
    (path + ": shared=" + (base | tojson) + ", local=" + (overlay | tojson) + " (keeping local)") | debug |
    overlay
  end;

. as $overlay | null | deepmerge($base[0]; $overlay; "")

' "$OVERLAY" 2> >(
    # Transform jq debug output into readable conflict lines
    while IFS= read -r line; do
        # jq debug outputs: ["DEBUG:","message"]
        msg="${line#*\"DEBUG:\",\"}"
        msg="${msg%\"]*}"
        if [[ -n "$msg" ]]; then
            echo "CONFLICT at $msg" >&2
        fi
    done
)
