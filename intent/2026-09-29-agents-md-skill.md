---
status: draft
issue: none (issues are disabled on this repo)
author: olafkfreund
---

# Intent: AGENTS.md and a Hyprforge skill for AI agents

## Problem

Two kinds of agent meet this repo, and neither has anything written for it:

1. **Agents working on the code** (Claude Code, Codex, others). The things
   they must know are spread across the README, commit history and this
   session:
   - how to run the tests (devenv, `nix flake check`), and that
     `test/live.js` needs a live Hyprland;
   - the invariants a change must not break: the plugin id and state paths;
     the eval → write → reload → rollback order; SafeWriter's never-follow-a-
     symlink rule; the bounded reads; the one-line hook;
   - that QML is cached by URL (`omarchy restart shell`);
   - the repo's intent → spec → plan workflow.

   An agent that doesn't know these can quietly weaken the safety code.
2. **Agents operating a user's desktop.** The `omarchy-shell hyprforge …`
   commands let an agent change the Hyprland look safely: validated,
   dry-run, and with history and undo. But an agent asked to "make my
   windows rounder" doesn't know these commands exist, so it will edit
   `looknfeel.lua` or the hyprland files directly, bypassing every check.
   The command list lives only in the README.

## Proposed outcome

- `AGENTS.md` at the repo root: a short, accurate guide for agents changing
  this code. It covers commands, layout, invariants, the workflow and what
  not to touch. Tools that read `CLAUDE.md` find the same content.
- A skill (`SKILL.md` format) that teaches an agent to drive Hyprforge
  through its IPC:
  - every command, with its real arguments and outputs, checked against
    `Service.qml` and the panel (`listProfiles` exists but isn't documented;
    `section` needs checking);
  - when to use it instead of editing config files;
  - how to verify a change and how to undo it.
- The skill ships with this repo and can be installed declaratively.

## Affected users and systems

- This repo: new `AGENTS.md`, new skill directory, README pointer, and
  possibly `flake.nix` if the HM module installs the skill.
- The user's agents on Nixarchy hosts, if the skill is installed.
- No runtime change to the plugin.

## Constraints

- Every command and path in the docs must be verified against the code or a
  live run, not copied from the README. The README already lists `toggle` and
  `section`, which aren't service IPC functions.
- Keep the upstream credit (Aziz / AbdulazizAlwabel) in AGENTS.md as well.
- The skill must tell agents to use the IPC and not hand-edit `hyprforge.lua`
  (it's generated) or `state.json` (the panel and service own it).
- It must not duplicate the existing `nixarchy` skill, which covers
  hand-editing `~/.config/hypr/`. It should point to it instead.

## Open questions

1. Skill location: only in this repo (`skills/hyprforge/SKILL.md`), or also
   installed by the HM module into `~/.claude/skills/hyprforge`, behind an
   option such as `programs.nixarchy-hyprsetting.skill.enable`?
2. `CLAUDE.md`: a symlink to `AGENTS.md`, a one-line `@AGENTS.md` import, or
   skip it?
3. Ordering with the pending CI intent: two follow-up branches now build on PR #1
   (`ci/checks-lint-test`, this one). Should I keep them as separate PRs, or
   combine them into one follow-up PR?
