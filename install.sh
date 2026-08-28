#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
build_dir=$(mktemp -d)
trap 'rm -rf "$build_dir"' EXIT

if ! command -v omarchy >/dev/null; then
  printf 'This installer must be run from an Omarchy installation.\n' >&2
  exit 1
fi

omarchy pkg add base-devel git meson ninja cairo wayland wayland-protocols libxkbcommon

git clone --depth 1 --branch v1.5.0 https://github.com/emersion/slurp.git "$build_dir/slurp"
git -C "$build_dir/slurp" apply "$repo_dir/patches/slurp-1.5.0-touchscreen.patch"

meson setup "$build_dir/slurp/build" "$build_dir/slurp" -Dman-pages=disabled
meson compile -C "$build_dir/slurp/build"

install -Dm755 "$build_dir/slurp/build/slurp" \
  "$HOME/.local/lib/omarchy-touchscreen/slurp"
install -Dm644 "$repo_dir/hypr/touchscreen-screenshot.lua" \
  "$HOME/.config/hypr/touchscreen-screenshot.lua"

hyprland_config="$HOME/.config/hypr/hyprland.lua"
require_line='require("hypr.touchscreen-screenshot")'
if ! grep -Fqx "$require_line" "$hyprland_config"; then
  printf '\n-- Touchscreen screenshot selection override.\n%s\n' "$require_line" >> "$hyprland_config"
fi

hyprctl reload
config_errors=$(hyprctl configerrors)
if [[ -n "$config_errors" ]]; then
  printf '%s\n' "$config_errors" >&2
  exit 1
fi

printf 'Touchscreen screenshot support installed successfully.\n'

"$repo_dir/nightlight/install.sh"
