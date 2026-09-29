---
name: hyprforge
description: Change how Hyprland looks and behaves on an Omarchy / Nixarchy desktop through the Hyprforge plugin (aziz.hyprforge, packaged as nixarchy-hyprsetting). It covers gaps, borders and border colors, rounding, opacity, dimming, blur, shadow and glow, animations and their speed, layouts, input, cursor, gestures, whole-desktop "looks", motion presets, and saved profiles. Use it when the user asks things like "make my windows rounder", "more blur", "turn off animations", "switch to my Gaming profile" or "save this setup", and Hyprforge is installed. Changes go through Hyprforge's validation, dry-run, history and undo instead of hand-edited config. For hand-editing ~/.config/hypr files, keybindings or monitors, use the nixarchy skill instead.
---

# Hyprforge from the command line

Hyprforge is a settings panel for Hyprland, written by Aziz (AbdulazizAlwabel):
<https://github.com/AbdulazizAlwabel/omarchy-hyprforge>. It keeps its
settings in `~/.config/hypr/hyprforge/state.json` and renders them to
`~/.config/hypr/hyprforge.lua`. Every change is type-checked and dry-run
through `hyprctl eval` before anything is written, and it's recorded in
history. Its IPC lets you make those same checked changes without the
panel.

## First: is it installed and connected?

```bash
omarchy-shell shell listPlugins | jq -r '.[] | select(.id=="aziz.hyprforge") | .enabled'   # true
grep -q '"hypr.hyprforge"' ~/.config/hypr/hyprland.lua && echo connected
```

- If it's not listed, not enabled, or `omarchy-shell` is missing: Hyprforge
  isn't available. Use the `nixarchy` skill for hand edits, or offer to
  install it (the Home Manager option is
  `programs.nixarchy-hyprsetting.enable`).
- If it's not connected, Hyprland isn't loading its file, so changes are
  saved but have no effect. The user connects it once in the panel (Connect
  button). It adds one line to `hyprland.lua`, with a backup. Don't add
  that line yourself.

## Rules

- **Use the IPC, not files.** Never edit `hyprforge.lua` (it's regenerated)
  or `state.json` (the panel and service own it).
- **Before a large change, take a restore point:**
  `omarchy-shell hyprforge saveProfile "before-<task>"`.
- **Verify every change** (see below). `ok` doesn't mean it was applied.

## Commands

All are `omarchy-shell hyprforge <command> [args]`.

| Command | Does |
|---|---|
| `open` / `close` / `toggle` | Show or hide the panel (these print nothing) |
| `section <id>` | Open the panel at a section. Ids: `home windows borders corners opacity dimming blur shadow glow animations layout groups input cursor gestures behavior rules profiles all` |
| `look <id>` | Replace all look settings (gaps, borders, corners, opacity, blur, shadow, glow) with a preset. Overrides the user made in those sections are dropped, so take a restore point first: `stock` (Omarchy), `glass` (Frosted glass), `neon`, `soft` (Soft & rounded), `flat` (Flat & sharp), `zen` (Zen focus), `compact`, `retro`, `performance` |
| `motion <id>` | Apply an animation preset: `omarchy`, `snappy`, `smooth`, `bouncy`, `slide`, `fade`, `minimal` |
| `set <key> <value>` | Set one option (see below) |
| `unset <key>` | Drop an override, going back to Omarchy's or the user's own value |
| `reset` | Drop every override (back to stock Omarchy). Profiles are kept |
| `saveProfile <name>` | Save the current settings as a profile |
| `profile <name>` | Apply a saved profile |
| `cycleProfile` | Apply the next profile, alphabetically |
| `listProfiles` | Profile names, one per line (see the caveat below) |

### `set` values

- A value is parsed as JSON when it can be, and taken as a string
  otherwise: `true`, `0.8`, `12`, `[0,4]`,
  `'{"slots":["accent","magenta"],"alpha":255,"angle":45}'`.
- Hyprland keys use Hyprland's names, for example `decoration:rounding`,
  `general:gaps_in`, `general:border_size`, `decoration:blur:size`,
  `general:col.active_border`. The key is checked with
  `hyprctl getoption` first, and an unknown key is refused.
- Colors go by **theme palette names** (`accent`, `cyan`, `magenta`, …), so
  they follow `omarchy theme set`. A fixed `#hex` is also accepted.
- Hyprforge's own `hf:` keys:

| Key | Type | Meaning |
|---|---|---|
| `hf:smart_gaps` | bool | No gaps when a workspace has a single tiled window |
| `hf:smart_borders` | bool | No border or rounding on a lone tiled window |
| `hf:border_rotate` | bool | Spin the focused border's gradient (renders every frame, so it costs some power) |
| `hf:border_rotate_speed` | float | Seconds per full turn |
| `hf:base_active` | float | Omarchy's base focused opacity (0.985 stock; 1 = fully opaque) |
| `hf:base_inactive` | float | Omarchy's base unfocused opacity (0.96 stock) |
| `hf:shell_blur` | bool | Frosted glass behind the Omarchy bar, menus and notifications |
| `hf:shell_blur_alpha` | float | Ignore pixels more transparent than this when blurring the shell |
| `hf:anim_speed` | float | Global animation speed multiplier (2 = twice as fast) |

## Behaviour to know

- **`ok` means queued, not applied.** Commands run one at a time in the
  background. The outcome (success, "not applied: …", or an unknown option)
  arrives as a desktop notification, which you can't see. So always verify.
- **Unknown ids do nothing, silently.** `look nope`, `motion nope` and
  `unset` on a key that isn't set all return `ok` and change nothing.
- **Refused while the panel is saving.** If the user is dragging a slider
  at that moment, your command is dropped with a notification. Wait a
  second and retry.
- **`listProfiles` can miss recent panel saves.** It answers from what the
  service last read, and a profile saved in the panel isn't there until the
  service's next operation. Call it twice (the first call triggers a
  re-read), or read the file:
  `jq -r '.profiles | keys[]' ~/.config/hypr/hyprforge/state.json`.
- **Omarchy toggles win.** Toggles such as "opinionated looks" or "no gaps"
  load after Hyprforge on purpose. A correct change can look ineffective
  because a toggle overrides it. If the saved value is right but the live
  value isn't, check `~/.local/state/omarchy/toggles/hypr/`.

## Verify a change

```bash
sleep 3                                                     # the op is async
jq '.cfg.options' ~/.config/hypr/hyprforge/state.json       # saved?
hyprctl getoption decoration:rounding -j                    # live value
hyprctl configerrors                                        # should print nothing / "no errors"
```

A look or motion sets many keys at once. Compare `.cfg.options` (looks) or
`.cfg.anims` (motions) before and after.

## Undo

- One key: `unset <key>`.
- Back to the restore point: `profile "before-<task>"`.
- Everything: `reset`.
- The panel's **Profiles & History** section can restore any earlier
  change. Offer `section profiles` to the user.
