---
status: approved
issue: none (issues are disabled on this repo)
author: olafkfreund
---

# Intent: Rename to nixarchy-hyprsetting and package for NixOS

## Problem

This repo is a fork of the Omarchy plugin "Hyprforge". Its README still
presents it under the upstream name and tells users to install it with
`omarchy plugin add <upstream GitHub URL>`, which copies an unpinned checkout
into `~/.config/omarchy/plugins/aziz.hyprforge`. On Nixarchy (Omarchy on
NixOS) that install is imperative: it is not in the flake, not reproducible,
and not rolled back with a generation.

There is also no development environment: the tests (`node test/run.js`,
`node test/live.js`) need `node` and `lua` on PATH, and nothing declares them.

The code has had no efficiency/quality review since the fork's recent
safety commits (SafeWriter, bounded input).

## Proposed outcome

- README title and install text say **nixarchy-hyprsetting** and describe the
  NixOS install.
- README keeps a visible link to the original repo,
  https://github.com/AbdulazizAlwabel/omarchy-hyprforge, and credits its
  creator, Aziz (AbdulazizAlwabel), as the original author of Hyprforge.
- `flake.nix` exposes the plugin as a package and a way to install it
  declaratively on a Nixarchy machine, so a rebuild puts it in place.
- `devenv` shell: `cd` into the repo gives `node` and `lua`, and the offline
  test suite runs.
- A written review of efficiency and quality issues, with the confirmed ones
  fixed (each fix listed in the plan).

## Affected users and systems

- This repo: README.md, new flake.nix / flake.lock, devenv.nix / devenv.yaml /
  .envrc, possibly QML/JS fixes from the review.
- The Nixarchy host that currently has `~/.config/omarchy/plugins/aziz.hyprforge`
  installed by copy.

## Constraints

- Must not change the plugin id `aziz.hyprforge`, its IPC name
  (`omarchy-shell hyprforge`) or its state paths (`~/.config/hypr/hyprforge*`),
  or existing users lose their profiles and the Connect line breaks.
- Must keep the MIT license (including the original copyright line), the link
  to the original repo, and credit to the original creator.
- The plugin must still work when installed from the Nix store (read-only):
  anything it writes must go under `~/.config`/`~/.cache`, not its own dir.
- Review fixes must not weaken the existing file-safety or input-bounding code.

## Open questions

Resolved at approval (2026-09-29):

1. Name: rename in README only. `manifest.json`, launcher entry and all ids
   stay as they are.
2. Install mechanism: a Home Manager module.
3. Review scope: fix every confirmed finding (bugs, efficiency and quality).
