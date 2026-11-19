---
status: approved
issue: 9
spec: spec/2026-11-19-9-keep-launcher-entry.md
coders:
  1: codex   # quoting-sensitive sh inside a QML JS string array
---

# Plan: compare before touching the applications folder

Decisions: see the spec; the entry survives service restarts (owner).

## Steps

1. `Service.qml` ~63-89: compare-first install script, drop
   `removeScript`, `installed` and `Component.onDestruction`; update the
   header comment (~9-10) and `README.md` (~277-278).
   → verify: `nix flake check`; `test/embedded-sh.js` + `sh -n` +
   shellcheck; inotifywait: 0 events for an unchanged and a themed entry,
   foreign entry and symlink untouched, missing or changed entry rewritten.

## Rollback

Revert the commit; the next service start rewrites the entry as before.
