#!/usr/bin/env bash
# Exercise slurp directly against known nested rectangles on the focused monitor.
set -euo pipefail
variant=${1:-full}
if (($#)); then shift; fi
case "$variant" in upstream|hover|full) ;; *)
  printf 'Usage: try.sh [upstream|hover|full] [slurp options]\n' >&2; exit 2 ;;
esac
cache_root=${SLURP_REVIEW_ROOT:-${XDG_CACHE_HOME:-$HOME/.cache}/slurp-touchscreen-review}
[[ -f "$cache_root/latest-run" ]] || {
  printf 'Run upstream/slurp/prepare.sh first.\n' >&2; exit 1;
}
run=$(<"$cache_root/latest-run")
binary="$run/$variant/build/slurp"
[[ -x "$binary" ]] || { printf 'Missing build: %s\n' "$binary" >&2; exit 1; }
command -v hyprctl >/dev/null || {
  printf 'Run this interactive helper inside your Hyprland session.\n' >&2; exit 1;
}
hyprctl -j monitors >"$run/monitors.json"
python3 - "$run/monitors.json" >"$run/choices.txt" <<'PY'
import json, sys
monitors = json.load(open(sys.argv[1]))
if not monitors:
    raise SystemExit("Hyprland did not report a monitor")
monitor = next((m for m in monitors if m.get("focused")), monitors[0])
width, height = monitor["width"], monitor["height"]
if monitor.get("transform", 0) % 2:
    width, height = height, width
width, height = int(width / monitor["scale"]), int(height / monitor["scale"])
x, y = monitor["x"], monitor["y"]
print(f"{x},{y} {width}x{height} screen")
print(f"{x+width//5},{y+height//5} {width*3//5}x{height*3//5} large")
print(f"{x+width*2//5},{y+height*2//5} {width//5}x{height//5} small")
PY
printf 'Variant: %s\nNested choices on the focused monitor:\n' "$variant"
cat "$run/choices.txt"
printf '\nMove the mouse onto that monitor before starting.\n'
printf 'Tap its center for the small box, or drag any region. Escape cancels.\n'
read -r -p 'Press Enter to open the selector... ' _
status=0
output=$("$binary" -d -f '%x,%y %wx%h %l' "$@" \
  <"$run/choices.txt" 2>"$run/last-selector-stderr.txt") || status=$?
{
  printf '\n%s variant=%s status=%s args=' "$(date -u +%FT%TZ)" "$variant" "$status"
  printf '%q ' "$@"
  printf '\n%s\n' "$output"
  cat "$run/last-selector-stderr.txt"
} | tee -a "$run/manual-results.log"
printf 'Results recorded in %s/manual-results.log\n' "$run"
exit "$status"
