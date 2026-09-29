---
status: approved
issue: none (issues are disabled on this repo)
author: olafkfreund
---

# Intent: Rename the plugin id to `nixarchy.hyprlandsettings`

## Problem

The plugin shows as "Nixarchy Hyprland Settings" (PR #4), but its id is
still the upstream author's `aziz.hyprforge`. The id is what Omarchy uses
to identify the plugin:
- in `shell.json`, to enable it;
- for the plugin directory name;
- in `omarchy-shell shell toggle <id>` (keybindings, menu entries, the
  launcher's `Exec=`);
- in `omarchy plugin remove <id>`.

The user wants this fork to carry its own id, in the `nixarchy.*`
namespace their other Nixarchy plugins use (`nixarchy.rebuild`,
`nixarchy.menu`). Checked: `nixarchy.hyprlandsettings` is not used, and
only `omarchy.*` is reserved.

## Proposed outcome

- `manifest.json` `id` becomes `nixarchy.hyprlandsettings`.
- The Home Manager module links to
  `~/.config/omarchy/plugins/nixarchy.hyprlandsettings`. Its generated
  keybindings toggle the new id.
- Existing installs keep all their settings, profiles and history. The
  **state paths don't change** (`~/.config/hypr/hyprforge*`): they aren't
  derived from the id.
- A user who had `aziz.hyprforge` enabled ends up with the new id enabled,
  the old entry gone, and no copy of the old plugin left for Omarchy to
  discover.

## Affected users and systems

- This repo:
  - `manifest.json`;
  - the `pluginId` fallbacks in `Service.qml` and `Panel.qml`;
  - `flake.nix` (the link path, keybindings, comments);
  - `README.md`, `AGENTS.md` and the skill (PR #3);
  - the `Engine.js` header text;
  - tests that mention the id, if any.
- This host:
  - `~/.config/omarchy/shell.json` (enabled-plugin entry);
  - the plugin dir;
  - the launcher file, whose `Exec=` is rewritten by the service through
    its marker.
- Anyone's own keybindings or menu entries that call
  `omarchy-shell shell toggle aziz.hyprforge`. Those need editing by hand.

## Constraints

- **Unchanged:**
  - the state paths;
  - the IPC target `hyprforge` (`omarchy-shell hyprforge …`), which is
    separate from the id and is in users' bindings;
  - the Lua module `hypr.hyprforge` and the hook;
  - `X-Hyprforge-Managed`, `hyprforgeProfile` and `hf:*`.
- The HM module still must not write `shell.json`. Enabling the new id stays
  a one-time `omarchy plugin enable`, documented.
- The switch-over must not leave two plugins that both own the `hyprforge`
  IPC target and the same state files. Found today: a leftover copy is
  still discovered.
- Doing the migration on this host must not take the shell down. It must
  avoid the `omarchy restart shell` race found today (separate intent,
  `2026-09-29-shell-restart-safety`).

## Open questions

Resolved at approval (2026-09-29): the user approved with the suggested answers:

1. Stacked on PR #4 as its own PR.
2. Documented migration: `omarchy plugin disable aziz.hyprforge`, then `omarchy plugin enable nixarchy.hyprlandsettings`. No automatic detection.
3. The IPC target stays `hyprforge` only. No alias.

## Addendum (2026-09-29, the user's instruction in chat: "yes do that and rewrite this to be nixos focused")

- The README is **rewritten as a whole, NixOS-first**, in this PR, and it
  gains a "What this fork adds" section. This PR is the last one to touch
  the README, so doing the rewrite here avoids conflicts with #1–#4.
- The README text from the sibling PRs (#2: `nix flake check`/`nix fmt`;
  #3: "For AI agents", `skill.enable`, `open`/`close`/`listProfiles`) is
  carried into the rewrite.
- The approved restart-safety outcome for the README (don't tell users to
  restart the shell after a switch; wait for it to answer instead) is
  written into this rewrite rather than as a separate README edit.
