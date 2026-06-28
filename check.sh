#!/usr/bin/env bash
# Strict validation gate for the Input Forge addon (Godot 4.6).
#
# Godot's --check-only exit code is unreliable, so the authoritative signal is the
# printed "SCRIPT ERROR / Parse Error" text - we log-scan. With
# untyped_declaration=2 and exclude_addons=false, untyped code prints a
# "Warning treated as error".
set -uo pipefail

GODOT="${GODOT:-$(command -v godot4 || command -v godot || true)}"
[[ -z "$GODOT" ]] && { echo "Godot not found. Install it or set \$GODOT." >&2; exit 1; }

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"
LOG="$(mktemp)"
trap 'rm -f "$LOG"' EXIT INT TERM

# Optional crash-free lint (non-fatal; gdtoolkit can lag bleeding-edge syntax).
if command -v gdlint >/dev/null 2>&1; then
  echo "-> gdformat --check / gdlint (optional, non-fatal)"
  gdformat --check addons test 2>/dev/null || echo "gdformat differences"
  gdlint addons test 2>/dev/null || echo "gdlint findings"
fi

echo "-> import"
"$GODOT" --headless --path . --import >>"$LOG" 2>&1 || true

echo "-> --check-only on every .gd"
while IFS= read -r -d '' f; do
  echo "--- $f" >>"$LOG"
  "$GODOT" --headless --path . --check-only --script "$f" >>"$LOG" 2>&1 || true
done < <(find addons test -name '*.gd' -print0)

if grep -nEi "SCRIPT ERROR|Parse Error|Failed to load script|Cannot open file|Compile Error" "$LOG"; then
  echo "check.sh FAILED (see errors above)" >&2
  exit 1
fi

echo "check.sh passed"
