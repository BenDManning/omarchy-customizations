#!/usr/bin/env bash
set -euo pipefail

nightlight_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
install -Dm755 "$nightlight_dir/omarchy-solar-nightlight" "$HOME/.local/bin/omarchy-solar-nightlight"
install -Dm644 "$nightlight_dir/omarchy-solar-nightlight.service" "$HOME/.config/systemd/user/omarchy-solar-nightlight.service"
config="$HOME/.config/hypr/hyprsunset.conf"
if [[ -f $config ]] && ! cmp -s "$nightlight_dir/hyprsunset.conf" "$config"; then
  cp --preserve=all "$config" "$config.bak.$(date +%Y%m%d-%H%M%S)"
fi
install -Dm644 "$nightlight_dir/hyprsunset.conf" "$config"
systemctl --user daemon-reload
systemctl --user enable hyprsunset.service omarchy-solar-nightlight.service
systemctl --user stop hyprsunset.service omarchy-solar-nightlight.service 2>/dev/null || true
pkill -x hyprsunset 2>/dev/null || true
systemctl --user reset-failed hyprsunset.service
systemctl --user start hyprsunset.service omarchy-solar-nightlight.service
printf 'Timezone-aware solar night light installed successfully.\n'
