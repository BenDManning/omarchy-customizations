#!/usr/bin/env bash
set -euo pipefail
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source_dir=$(cd -- "${1:?Usage: check.sh SOURCE_DIR [--baseline|--with-tap]}" && pwd)
mode=${2:-}
build_dir="$source_dir/build"
objects=()
for object in "$build_dir"/slurp.p/*.o; do
  [[ -f "$object" ]] || { printf 'Build slurp before running check.sh\n' >&2; exit 1; }
  [[ "$object" == */main.c.o ]] || objects+=("$object")
done
read -r -a flags <<< "$(pkg-config --cflags --libs cairo wayland-client wayland-cursor xkbcommon)"
"${CC:-cc}" -std=c11 -Wall -Wextra -Werror -Wno-unused-parameter \
  -I"$source_dir" -I"$source_dir/include" -I"$build_dir/slurp.p" \
  "$script_dir/test-input.c" "${objects[@]}" "${flags[@]}" -lrt \
  -o "$build_dir/test-input"
args=()
[[ -z "$mode" ]] || args+=("$mode")
"$build_dir/test-input" "${args[@]}"
