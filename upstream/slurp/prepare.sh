#!/usr/bin/env bash
# Build review variants in a fresh cache directory; install nothing.
set -euo pipefail
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
base=a3998d3ec79fbd85b81911f43010466b032ed0d9
cache_root=${SLURP_REVIEW_ROOT:-${XDG_CACHE_HOME:-$HOME/.cache}/slurp-touchscreen-review}
missing=()
for command_name in git meson ninja pkg-config cc python3; do
  command -v "$command_name" >/dev/null || missing+=("$command_name")
done
if ((${#missing[@]})) || ! pkg-config --exists cairo wayland-client wayland-cursor \
    xkbcommon wayland-scanner 'wayland-protocols >= 1.32'; then
  printf 'Missing build dependencies. On Omarchy/Arch, install:\n\n' >&2
  printf 'sudo pacman -S --needed base-devel git meson ninja pkgconf cairo wayland wayland-protocols libxkbcommon python\n' >&2
  exit 1
fi
mkdir -p "$cache_root"
cache_root=$(cd -- "$cache_root" && pwd)
run=$(mktemp -d "$cache_root/run.XXXXXX")
printf 'Build directory: %s\n' "$run"
git clone --quiet --no-checkout https://github.com/emersion/slurp.git "$run/repo"
git -C "$run/repo" cat-file -e "$base^{commit}"

for variant in upstream hover full; do
  source_dir="$run/$variant"
  git -C "$run/repo" worktree add --quiet --detach "$source_dir" "$base"
  if [[ "$variant" != upstream ]]; then
    for patch_file in "$script_dir"/patches/*.patch; do
      git -C "$source_dir" apply --check "$patch_file"
      git -C "$source_dir" apply "$patch_file"
    done
  fi
  if [[ "$variant" == full ]]; then
    for patch_file in "$script_dir"/integration/*.patch; do
      git -C "$source_dir" apply --check "$patch_file"
      git -C "$source_dir" apply "$patch_file"
    done
  fi
  git -C "$source_dir" diff --check
  printf 'Building %s...\n' "$variant"
  if ! {
    meson setup "$source_dir/build" "$source_dir" -Dman-pages=disabled
    meson compile -C "$source_dir/build"
  } >"$run/$variant-build.log" 2>&1; then
    cat "$run/$variant-build.log" >&2
    exit 1
  fi
  mode=()
  case "$variant" in
    upstream) mode=(--baseline) ;;
    full) mode=(--with-tap) ;;
  esac
  "$script_dir/check.sh" "$source_dir" "${mode[@]}" 2>&1 | tee "$run/$variant-tests.log"
done

{
  printf 'Upstream base: %s\n' "$base"
  printf 'Prepared UTC: %s\n' "$(date -u +%FT%TZ)"
  uname -srmo
  cc --version | head -n 1
  meson --version
  pkg-config --modversion wayland-client wayland-protocols cairo xkbcommon
  if command -v hyprctl >/dev/null; then
    hyprctl version || true
  fi
} >"$run/environment.txt"
printf '%s\n' "$run" >"$cache_root/latest-run"
printf '\nAll three builds and callback checks completed.\n'
printf 'Try the combined touchscreen version:\n  %q full\n' "$script_dir/try.sh"
printf 'Builds and logs: %s\n' "$run"
