# Omarchy Touchscreen Screenshot Fix

Private backup of the touchscreen work used on Omarchy with Hyprland.

The stock `slurp` 1.5.0 lets an idle mouse selection block touchscreen input.
This patch hands selection control to the touchscreen, allowing:

- A tap to select the smallest window under the finger.
- A drag to create a freeform screenshot region.
- The mouse cursor's idle window highlight to stop blocking touch input.

The original working binary was built from upstream commit
`fc921b603ee02afff42aba9eb073e82fab900048` (tag `v1.5.0`). Its SHA-256 was
`ab10015c1e9c471ab7353e933edae7cf80805436fc6f9871be77f3df4454316a`.

## Restore After Reinstalling Omarchy

```bash
gh auth login
gh repo clone BenDManning/omarchy-touchscreen-backup
cd omarchy-touchscreen-backup
./install.sh
```

The installer:

1. Installs the required Arch packages through `omarchy pkg add`.
2. Clones upstream `slurp` v1.5.0 and applies `patches/slurp-1.5.0-touchscreen.patch`.
3. Builds the patched binary into `~/.local/lib/omarchy-touchscreen/slurp`.
4. Installs `~/.config/hypr/touchscreen-screenshot.lua`.
5. Adds one `require` line to `~/.config/hypr/hyprland.lua` if needed.
6. Reloads and validates the Hyprland configuration.

The override is isolated from `/usr/share/omarchy`, so an Omarchy update will
not overwrite it. Re-run the installer if the local binary is removed.

## Files

- `patches/slurp-1.5.0-touchscreen.patch`: exact source change recovered from the original build session.
- `hypr/touchscreen-screenshot.lua`: Print Screen binding that puts the patched `slurp` first in `PATH` for Omarchy's screenshot command.
- `install.sh`: reproducible build and Omarchy configuration installer.

## Remove

```bash
rm -f ~/.local/lib/omarchy-touchscreen/slurp
rm -f ~/.config/hypr/touchscreen-screenshot.lua
```

Then remove this line from `~/.config/hypr/hyprland.lua`:

```lua
require("hypr.touchscreen-screenshot")
```
