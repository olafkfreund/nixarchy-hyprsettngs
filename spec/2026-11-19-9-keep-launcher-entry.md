---
status: approved
issue: 9
intent: intent/2026-11-19-9-keep-launcher-entry.md
---

# Spec: compare before touching the applications folder

Full spec: [spec/2026-11-19-3107-shell-startup.md](https://github.com/olafkfreund/nixos_config/blob/perf/3107-shell-startup/spec/2026-11-19-3107-shell-startup.md), section 2.

## Design

In `installScript`: if the entry exists, is ours (`X-Hyprforge-Managed=true`)
and equals the wanted text after normalising hyprchroma's
`Icon=<name>` + `X-Omarchroma-Original-Icon=<path>` back to `Icon=<path>`,
exit without touching the folder. Otherwise write via `mktemp` in the same
directory and `mv -fT`. Remove `removeScript` and `Component.onDestruction`.
Update the header comment and the README's launcher paragraph.

## Alternatives rejected

Temp file in `$XDG_RUNTIME_DIR`: a cross-filesystem `mv` is not atomic.
Patching hyprchroma: third-party; this fix ends the loop.

## Risks

A renamed hyprchroma marker brings the rescan back; nothing breaks.

## Verification

`nix flake check` (package, tests, lint); `test/embedded-sh.js`
extraction with `sh -n` and shellcheck; inotifywait over unchanged, themed,
missing, foreign and symlinked entries.
