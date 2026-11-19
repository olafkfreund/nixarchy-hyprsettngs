---
status: approved
issue: 9
author: olafkfreund
---

# Intent: service start and stop must not make the shell rescan every desktop entry

Part of olafkfreund/nixos_config#3107; the full intent is
[intent/2026-11-19-3107-shell-startup.md](https://github.com/olafkfreund/nixos_config/blob/perf/3107-shell-startup/intent/2026-11-19-3107-shell-startup.md).

## Problem

`Service.qml` creates a temp file in `~/.local/share/applications` at every
service start, and deletes `hyprforge.desktop` at every service stop.
Quickshell rescans all ~600 desktop entries on any create, delete or rename
there, on the shell's main thread. hyprchroma rewrites our `Icon=`, so the
existing `cmp` never matches either.

## Proposed outcome

A service start leaves the folder untouched when the entry is already
current (also after hyprchroma's rewrite); a stop leaves it in place.

## Constraints

Never touch a symlink or a foreign entry; keep the atomic same-directory
`mv`. No new runtime dependency.

## Decisions (owner, 2026-11-19)

The entry is kept across service restarts; a stale launcher entry after
disabling the plugin is accepted. Artifacts pre-approved by the owner for
this task ("review and research and implement").
