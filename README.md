# Omarchy Customizations

Personal Omarchy improvements packaged for reproducible installation after a fresh setup.

## Install

```bash
gh auth login
gh repo clone BenDManning/omarchy-customizations
cd omarchy-customizations
./install.sh
```

The top-level installer installs both features. Each feature also has its own installer.

## Touchscreen Screenshots

Patches `slurp` 1.5.0 so a touchscreen tap selects the smallest window under the
finger, a drag selects a freeform region, and an idle mouse highlight does not
block touch input. The installer builds the patched binary and adds an isolated
Hyprland Lua override that Omarchy updates will not overwrite.

## Solar Night Light

- Gets representative coordinates from the active IANA system timezone through
  the local `tzdata` tables; there is no fixed city or network lookup.
- Recalculates sunrise and sunset daily.
- Fades between 4000K and 6500K over 30 minutes centered on each solar event.
- Preserves the stock Omarchy hotbar toggle. A manual override lasts until the
  user changes it again. Off stays off indefinitely; on follows the selected schedule.
- Runs as an enabled systemd user service and follows timezone changes.
- Replaces only the stock Night Light indicator with a user-owned widget. Left-click
  is the persistent master switch; right-click opens settings for automatic or
  custom scheduling, fade duration, warmth, and automatic or manual location.

Set the host timezone normally with `timedatectl set-timezone Region/City`.

## Remove

Touchscreen files:

```bash
rm -f ~/.local/lib/omarchy-touchscreen/slurp
rm -f ~/.config/hypr/touchscreen-screenshot.lua
```

Then remove `require("hypr.touchscreen-screenshot")` from
`~/.config/hypr/hyprland.lua`.

Solar night-light files:

```bash
systemctl --user disable --now omarchy-solar-nightlight.service
rm -f ~/.local/bin/omarchy-solar-nightlight
rm -f ~/.config/systemd/user/omarchy-solar-nightlight.service
systemctl --user daemon-reload
```
