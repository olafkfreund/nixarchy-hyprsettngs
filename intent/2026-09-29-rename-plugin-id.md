---
status: draft
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

1. Branch/PR: this builds on PR #4 (display name), since it touches the
   same strings. Stack it on #4, or fold it into #4?
2. `shell.json` migration for existing users: document the two commands
   (`omarchy plugin disable aziz.hyprforge`, then
   `omarchy plugin enable nixarchy.hyprlandsettings`), or have the plugin's
   service detect the old entry on first start and tell the user
   (notification)? It can't safely edit `shell.json` itself.
3. Should the IPC target also move to the new name (for example
   `omarchy-shell hyprlandsettings …`), with `hyprforge` kept as an alias?
   Default: keep only `hyprforge`, since that's what the user's bindings
   use.
