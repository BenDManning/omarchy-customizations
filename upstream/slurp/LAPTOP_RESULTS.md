# Laptop results

Status: pending.

- Laptop:
- Hyprland version:
- Display resolution, scale, and other connected monitors:
- Upstream base: a3998d3ec79fbd85b81911f43010466b032ed0d9
- Build helper result:

| Check | Result / observation |
| --- | --- |
| Unmodified upstream reproduces blocked touch with pointer hover | Pending |
| Hover build permits the same finger drag | Pending |
| Full build: tap selects the smallest center rectangle | Pending |
| Full build: drag replaces the initially selected rectangle | Pending |
| Full build with -r: touch selects a choice | Pending |
| Full build with -p: touch returns a 1×1 point | Pending |
| Mouse drag survives a finger touch and release | Pending |
| Mouse click and drag behave normally | Pending |
| Escape cancels | Pending |
| Second finger release preserves the first finger's drag | Pending |
| Pointer highlight redraw / second monitor, if available | Pending |

The helper saves `manual-results.log` and `environment.txt` beside the builds. Those files contain command outcomes and versions; the observations above are still needed to distinguish the intended gesture from an accidental touch or cancellation.
