# Validation record

Prepared on 2026-09-30. Upstream base: `a3998d3ec79fbd85b81911f43010466b032ed0d9`.

## Completed

| Variant | Meson/Ninja build | Callback results |
| --- | --- | --- |
| Unmodified upstream | Passed | 9 passed; 6 expected failures reproduced; 0 unexpected |
| Focused hover fix | Passed | 15 passed; 0 unexpected |
| Combined touchscreen integration | Passed | 18 passed; 0 unexpected |

All builds retained upstream's `werror=true`. Patch application and whitespace checks passed. All helper scripts passed `bash -n`.

The baseline failures cover touch after pointer hover, a touch release interrupting a mouse drag, a mouse press before its first motion event, releasing a second finger, releasing an untracked touch, and single-point touch after pointer hover.

The test harness includes the actual checked-out `main.c` and links against the built support objects. It supplies synthetic events and output identities. A pending-frame sentinel keeps the dirty-state checks from issuing Wayland requests. This verifies callback behavior and geometry, not rendering or a compositor session.

## Build environment

| Component | Version |
| --- | --- |
| Distribution | Ubuntu 24.04.3 |
| Compiler | GCC 13.3.0 |
| Meson | 1.12.1 |
| Ninja package | 1.13.2 |
| Wayland | 1.22.0 |
| wayland-protocols | 1.34 |
| Cairo | 1.18.0 |
| xkbcommon | 1.6.0 |

Development packages were extracted into a temporary build prefix; runtime shared libraries came from the environment. The laptop helper uses its normally installed dependencies.

## Remaining

Physical touchscreen checks, visible highlight redraw, real Hyprland event ordering, and scaled or multi-monitor behavior are pending. The manual helper itself still needs to be exercised in a real Hyprland session.

There is no claim of comprehensive input testing. For example, cancellation after a touch has already moved and mouse clicks during an unfinished touch are outside the focused automated checks. Record any unexpected behavior during hardware testing rather than assuming it is caused or fixed by this patch.
