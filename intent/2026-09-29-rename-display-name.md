---
status: draft
issue: none (issues are disabled on this repo)
author: olafkfreund
---

# Intent: Show the plugin as "Nixarchy Hyprland Settings"

## Problem

PR #1 renamed only the README (decided at the time: "README only"). The
running plugin still calls itself **Hyprforge** everywhere a user sees it,
while the project is now nixarchy-hyprsetting. The user now wants the name
inside the plugin to be **Nixarchy Hyprland Settings**. This supersedes that
part of PR #1's intent, for display text only.

## Proposed outcome

Everything a user reads in the running plugin says "Nixarchy Hyprland
Settings". Everything a machine matches on keeps working unchanged. The
places found so far, from a review of every `Hyprforge` string:

- **User-visible (change):**
  - `manifest.json` `name` and `description`;
  - the panel title (`Panel.qml` `text: "Hyprforge"`);
  - the launcher entry `Name=` (`Service.qml`);
  - the notification app name (`notify-send -a`);
  - the "is saving" notice;
  - the Connect banner;
  - the clipboard error messages;
  - the Profiles view subtitles;
  - the header comment of the generated `hyprforge.lua`;
  - the hook line's trailing comment;
  - README/AGENTS wording where it names the running plugin.
- **Contract (keep), because existing installs and user files depend on
  them:**
  - the plugin id `aziz.hyprforge`;
  - the IPC target (`omarchy-shell hyprforge …`), which is in users'
    keybindings;
  - the paths `~/.config/hypr/hyprforge{.lua,/}`, `~/.cache/hyprforge` and
    `hyprforge.desktop`;
  - the Lua module `hypr.hyprforge`, which the hook is matched on;
  - the `X-Hyprforge-Managed` marker, which the launcher uses to recognise
    its own file;
  - the `hyprforgeProfile` key in shared profile JSON (profiles people
    already copied must still import);
  - `hf:*` option keys.
- Upstream credit stays: "based on Hyprforge by Aziz (AbdulazizAlwabel)" in
  the README, AGENTS.md and the manifest description.

## Affected users and systems

- This repo: `manifest.json`, `Panel.qml`, `Service.qml`, `Engine.js`,
  `components/ProfilesView.qml`, the README, and possibly tests that assert
  on the header text.
- Existing installs: after updating, the panel, launcher entry and
  notifications show the new name. The launcher file is rewritten in place
  (same path, same marker). No state migration.

## Constraints

- No change to any contract item above. `test/run.js`'s hook round-trip must
  still pass.
- The rename must not break the checks from PR #2 (QML syntax, embedded
  scripts).
- Keep the MIT copyright and the credit.

## Open questions

1. Comments in the code (for example `// Hyprforge engine: …`): rename them
   too, or leave them? They're invisible to users and keep the diff small.
2. IPC name: keep only `omarchy-shell hyprforge` (recommended, since it's in
   users' keybindings), or also add a second, new-name alias?
3. The notification app name changes to "Nixarchy Hyprland Settings", which
   is long for a notification header. Is that OK, or should it be a shorter
   form such as "Hyprland Settings"?
4. The generated `hyprforge.lua` header says "SUPER+SPACE › Hyprforge". It
   should name the launcher entry as it will then appear, "Nixarchy Hyprland
   Settings". Confirm.
