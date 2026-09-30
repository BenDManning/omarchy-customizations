# slurp touchscreen PR preparation

Ready for laptop testing. The focused upstream change is eight added lines and one changed line in slurp's `main.c`. Physical touchscreen testing is still pending.

## Start on the laptop

Use a separate checkout for this preparation:

~~~sh
git clone --branch prep/slurp-touchscreen https://github.com/BenDManning/omarchy-customizations.git omarchy-touchscreen-test
cd omarchy-touchscreen-test
./upstream/slurp/prepare.sh
./upstream/slurp/try.sh full
~~~

If the build helper reports missing dependencies, it prints the Omarchy/Arch install command. Run that command, then run `prepare.sh` again.

The helper builds in `~/.cache/slurp-touchscreen-review/run.*`. It does not install a binary or change Hyprland bindings. Each run gets a fresh directory. Set `SLURP_REVIEW_ROOT` to choose a different location; use the same setting for both helpers.

## Short hardware check

The selector shows three nested rectangles on the focused monitor. They are labelled `screen`, `large`, and `small` in the terminal output. The smallest box is centered on that monitor. These are synthetic choices, so the test works independently of Omarchy's screenshot app.

Run each command again for another selection:

| Command | Action | Expected result |
| --- | --- | --- |
| `./upstream/slurp/try.sh upstream` | Leave the mouse over the focused monitor; drag with a finger | Reproduce the blocked-touch behavior |
| `./upstream/slurp/try.sh hover` | Repeat the same touch drag | Finger-defined rectangle is returned |
| `./upstream/slurp/try.sh full` | Tap the center box; repeat and drag from there | Tap returns the printed small-box geometry; drag returns a custom rectangle |
| `./upstream/slurp/try.sh full -r` | Tap the center box | Small-box geometry is returned on touch-down |
| `./upstream/slurp/try.sh full -p` | Touch anywhere on the monitor | A 1×1 point at the touch position |
| `./upstream/slurp/try.sh hover` | Start a mouse drag, then tap and release a finger while still holding the mouse button | The mouse drag stays active and finishes when its button is released |
| `./upstream/slurp/try.sh full` | Try ordinary mouse click/drag, Escape, and a second finger during a touch drag | Mouse selection and Escape work; releasing the second finger does not finish the first finger's drag |

If you only have a few minutes, do the first three rows and the active-mouse-drag row first. Finish the remaining checks before describing the contribution as fully tested on hardware.

If another monitor is available, repeat the hover handoff with the pointer on one display and touch on the other. Check for a leftover highlight. Display scaling, touch movement during a nominal tap, and compositor event ordering need physical verification.

`try.sh` records geometry, exit status, options, and stderr in `manual-results.log` beside the builds. Escape normally exits with status 1; that is an expected cancellation. Add your observations to [LAPTOP_RESULTS.md](LAPTOP_RESULTS.md). A short clip of the failing and fixed drag would be useful, but written results are enough to proceed with review.

## What is in each build?

All three variants use upstream commit [a3998d3](https://github.com/emersion/slurp/commit/a3998d3ec79fbd85b81911f43010466b032ed0d9).

| Build | Contents | Purpose |
| --- | --- | --- |
| `upstream` | Unmodified pinned upstream | Reproduction and comparison |
| `hover` | The two patches in `patches/` | The proposed upstream PR |
| `full` | `hover` plus the two patches in `integration/` | Complete tap-to-select and drag behavior |

The proposed PR:

1. Finishes a touch only when the released contact ID is the tracked one.
2. Uses the pressed mouse-button state to protect active mouse drags, while clearing and redrawing an idle pointer highlight when touch begins.

Tap-to-select is already proposed in [slurp PR #141](https://github.com/emersion/slurp/pull/141). Its commit [531c4ab](https://github.com/emersion/slurp/commit/531c4abf317d5ecc356859e94ae0c484f969bdcd) is included separately for integration testing, preserving Willow Barraco's authorship. The second integration patch requests a redraw after selecting a choice by touch.

The `hover` build deliberately tests the independent fix. Touch taps on predefined boxes and `-r` are features of the `full` integration build. The focused PR can be reviewed without including the existing author's unmerged change.

## Preparation and validation

- [PR_DRAFT.md](PR_DRAFT.md): proposed upstream description; hardware results still need filling in.
- [VALIDATION.md](VALIDATION.md): completed build and callback checks.
- `prepare.sh`: fetch, build, and check all three pinned variants.
- `check.sh` and `test-input.c`: run the actual input callbacks without a compositor.
- `try.sh`: manual comparison on Hyprland.
- [SLURP_LICENSE](SLURP_LICENSE): upstream MIT license for the patch context.

The callback harness checks state transitions and returned rectangles. It does not render a Wayland surface or generate physical touch events. The six `XFAIL` results in the unmodified baseline are intentional reproductions; patched builds should report zero unexpected failures.

## Turning the candidate into a PR

After the laptop results are recorded, apply only `patches/*.patch`, in filename order, to a new branch in a slurp fork based on the pinned upstream commit. Use `git am` to preserve the commit messages and authorship. Rebase and rebuild if upstream has advanced, then use the draft description.

Keep `integration/` separate: it is a comparison build of the existing #141 work plus a redraw follow-up. Report its results on #141 when ready, without claiming its tap-selection implementation as new work.

Current Omarchy development routes screenshots through Omasnap, while release v4.0.4 uses slurp. These helpers call the test binaries directly, so the laptop's installed screenshot backend does not affect the comparison.
