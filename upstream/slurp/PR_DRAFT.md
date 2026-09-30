# Allow touch input while the pointer hovers over a choice box

Draft description for the two commits in `patches/`. Hardware verification is pending; fill in the results below before submitting.

---

An idle pointer highlight prevents touch selections from starting. In `touch_handle_down()`, `pointer_selection.has_selection` is used to reject touch input, but this flag is also set when the pointer merely hovers over a supplied choice box.

This is easy to hit on a convertible laptop: run `slurp -o`, leave the pointer over an output, and try to drag a selection with a finger while the mouse button is released.

This change uses the pressed-button state to preserve active mouse drags and clears the passive pointer highlight when accepting the first touch point. The old highlight's output is marked dirty so it can be removed.

The first commit also makes `touch_handle_up()` match the tracked touch ID, as the motion handler already does. A release from an ignored second finger, or from a touch rejected during a mouse drag, must not finish the current selection.

## Reproduction

1. Run `slurp -o` on a device with a touchscreen and a pointer.
2. Leave the pointer inside an output's choice rectangle, with the mouse button released.
3. Touch and drag a region.

Before: the touch-down is rejected because of the pointer highlight. The subsequent release finalizes an untracked touch.

After: the touch drag starts normally and returns the finger-defined rectangle.

Also check that touching and releasing a finger during a mouse drag leaves that mouse drag active, and that releasing an ignored second finger does not finish the tracked finger's selection.

## Relationship to #141

Related to https://github.com/emersion/slurp/pull/141.

This PR addresses pointer/touch arbitration and tracked-contact release. #141 supplies the separate choice-box lookup needed for tap selection. The proposed commits apply independently of #141. I prepared a separate integration build of both changes for compatibility testing, preserving the existing commit's authorship.

## Validation

Base: `a3998d3ec79fbd85b81911f43010466b032ed0d9`.

- Meson/Ninja builds completed for unmodified upstream, this patch series, and a separate integration with #141 plus a touch-down redraw.
- Upstream's warnings-as-errors setting remained enabled.
- A harness calling the actual slurp callbacks reproduced six failing scenarios in unmodified upstream.
- This patch series passed all 15 applicable callback checks.
- The separate integration passed all 18 checks, including smallest-choice taps, restricted selection, and dragging after a choice is selected.
- The harness covers two-output handoff and dirty flags, ordinary mouse selection, active mouse drags, untracked touch releases, second-finger releases, single-point selection, and cancellation paths.
- This was not a compositor or hardware test.

Hardware verification: **pending**.

Add the laptop model, Hyprland version, display scale/layout, command lines, observed results, and optionally a short before/after recording here.
