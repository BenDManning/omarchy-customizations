#!/usr/bin/env bash
set -euo pipefail

nightlight_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
install -Dm755 "$nightlight_dir/omarchy-solar-nightlight" "$HOME/.local/bin/omarchy-solar-nightlight"
install -Dm644 "$nightlight_dir/omarchy-solar-nightlight.service" "$HOME/.config/systemd/user/omarchy-solar-nightlight.service"
plugin_dir="$HOME/.config/omarchy/plugins/local.solar-nightlight"
mkdir -p "$plugin_dir"
cp -a "$nightlight_dir/plugin/." "$plugin_dir/"

shell_config="$HOME/.config/omarchy/shell.json"
cp --preserve=all "$shell_config" "$shell_config.bak.$(date +%Y%m%d-%H%M%S)"
jq '
  .bar.layout |= with_entries(
    .value |= (
      map(if .id == "omarchy.indicators" then
        .items = ((.items // ["Dictation", "ScreenRecording", "Reminder", "NightLight", "Dnd", "StayAwake"]) - ["NightLight"])
      else . end)
      | if any(.[]; .id == "local.solar-nightlight") then .
        else reduce .[] as $item ([]; . + [$item] + (if $item.id == "omarchy.indicators" then [{"id":"local.solar-nightlight"}] else [] end))
        end
    )
  )
' "$shell_config" > "$shell_config.tmp"
mv "$shell_config.tmp" "$shell_config"
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
omarchy-shell shell rescanPlugins >/dev/null
printf 'Timezone-aware solar night light installed successfully.\n'
