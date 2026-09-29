---
status: approved
issue: none (issues are disabled on this repo)
intent: intent/2026-09-29-agents-md-skill.md
---

# Spec: AGENTS.md and a Hyprforge skill for AI agents

## Design

### 1. `AGENTS.md` (repo root), for agents changing this code

Short sections, each fact checked against the code:

- **What this is.** Hyprforge by Aziz (AbdulazizAlwabel), with a link to
  upstream, packaged for NixOS. Upstream plugin bugs go upstream.
- **Commands:**
  - `devenv shell -- test` (offline);
  - `devenv shell -- test-live` (needs a running Omarchy; briefly changes
    the look);
  - `nix flake check`, `nix build .#default`, and `nix fmt` once the CI PR
    lands;
  - `omarchy restart shell` after any QML edit (QML is cached by URL).
- **Layout:** a one-line table per file (manifest, Panel, Service, Schema,
  Engine, SafeWriter, BoundedRead, baseline.lua, components/, test/, flake,
  devenv).
- **Invariants.** Never weaken these; each has a pointer to its code:
  1. The id `aziz.hyprforge`, the IPC target `hyprforge` and the paths
     `~/.config/hypr/hyprforge{.lua,/state.json,/history.json}` are a
     contract with existing installs.
  2. The commit order is validate → `hyprctl eval` dry-run → write
     state/history/Lua → reload → roll back on a reload error. Nothing
     reaches `hyprforge.lua` unless eval accepted it.
  3. Every write goes through `SafeWriter` (mktemp + rename, never through a
     symlink, backup before overwrite).
  4. Every read goes through `BoundedRead`, and every command's output goes
     through `Engine.capped`.
  5. Values reach the shell only via argv (`sh -c script sh "$@"`), never by
     string interpolation.
  6. `hyprland.lua` is touched only by Connect/Disconnect: one optional
     `require` line, checksum-guarded, with a backup.
  7. Panel and service serialize on `state.json` (`panelBusy`/`opBusy`).
  8. `Engine.normalize` returns a copy (snapshots rely on it). `Engine.shape`
     doesn't copy and is for read-only use.
- **Workflow:** multi-file changes follow `intent/` → `spec/` → `plan/`,
  each approved by the user.
- **Don'ts:**
  - don't hand-edit the generated `hyprforge.lua`;
  - don't commit `result` or `.devenv`;
  - don't make the flake write `shell.json`;
  - don't add runtime dependencies (the plugin needs only `lua` and
    `hyprctl`).

`CLAUDE.md` is one line, `@AGENTS.md`.

### 2. Skill `skills/hyprforge/SKILL.md`, for agents operating a desktop

Frontmatter `name: hyprforge`, plus a `description` whose triggers cover
changing Hyprland's look or feel on an Omarchy/Nixarchy desktop: gaps,
borders, rounding, blur, shadow, opacity, animations, profiles, looks and
"make windows rounder". Body:

- **When to use it rather than editing files.** If `aziz.hyprforge` is
  installed (`omarchy-shell shell listPlugins` shows it enabled), use it for
  appearance settings: it validates, dry-runs against Hyprland, keeps history
  and undo, and follows the theme. Hand-editing `looknfeel.lua` or
  `bindings.lua` is the `nixarchy` skill's job. Never edit `hyprforge.lua` or
  `state.json`.
- **Command reference** (all verified in `Service.qml`):
  - panel: `open`, `close`, `toggle`, and `section <id>`, where the ids are
    home windows borders corners opacity dimming blur shadow glow animations
    layout groups input cursor gestures behavior rules profiles all;
  - `look <id>`: stock glass neon soft flat zen compact retro performance;
  - `motion <id>`: omarchy snappy smooth bouncy slide fade minimal;
  - `set <key> <value>`: the value is JSON when it parses (`true`, `0.8`,
    `[0,4]`, `{"slots":["accent"],"alpha":255}`) and a string otherwise.
    Real Hyprland keys are checked with `hyprctl getoption` first. `hf:*`
    keys are Hyprforge's own (the list with their meaning comes from
    `Schema.js`);
  - `unset <key>`, `reset`;
  - `saveProfile <name>`, `profile <name>`, `cycleProfile`, `listProfiles`.
- **Semantics an agent must know:**
  - Changing commands return `ok` when the change is **queued**, not when it
    is applied. The outcome is a desktop notification, which the agent can't
    see.
  - `look`/`motion` with an unknown id, or `unset` on an unset key, do
    nothing, and still return `ok`.
  - Changes are refused while the panel is saving (you get a notification;
    retry).
  - `listProfiles` returns the list from the previous state read, so it can
    be stale or empty right after a shell restart. Read the list reliably
    with `jq -r '.profiles | keys[]' ~/.config/hypr/hyprforge/state.json`.
  - Omarchy toggles (for example "opinionated looks") load after Hyprforge
    and win, so a correct change can look ineffective. Seen on this host
    with border and rounding.
- **Verify after every change:**
  - `sleep 3`;
  - `jq '.cfg.options' ~/.config/hypr/hyprforge/state.json`;
  - `hyprctl getoption <key> -j` for the live value;
  - `hyprctl configerrors` should be empty.

  If the state is right but the live value isn't, check the toggles first.
- **Undo:** `unset <key>`, `reset`, or tell the user to open
  Profiles & History in the panel. Before a large change, take
  `saveProfile "before-<task>"` as a restore point.

### 3. Installing the skill with the HM module

- A new option `programs.nixarchy-hyprsetting.skill.enable`, default
  `false`. When true, it sets
  `home.file.".claude/skills/hyprforge".source = ./skills/hyprforge`.
- The package's fileset doesn't change: the skill isn't part of the plugin.

### 4. README

Add a short "For AI agents" section that points to `AGENTS.md` and the
skill option. Also document the IPC commands missing from the scripting
list: `open`, `close`, `listProfiles`.

## Alternatives rejected

- **Skill inside the plugin package**, so `omarchy plugin add` users get it:
  Omarchy has no skill mechanism, and it would ship docs into the shell's
  plugin dir.
- **`CLAUDE.md` as a symlink**: a one-line import is plainer, and works
  wherever the repo is checked out.
- **Fixing the `listProfiles` staleness here**: that's a code change, and
  this task is docs only. It's documented as a known issue, with a
  workaround, for a follow-up.
- **Skill enabled by default**: the module would write into `~/.claude` for
  every user. Opt-in instead.

## Risks

- **Docs drift from the code.** Mitigation: every command in the skill is
  exercised live once (step in the plan). AGENTS.md points to files and
  functions, not line numbers.
- **The skill triggers too eagerly** on generic Hyprland questions.
  Mitigation: the description requires the plugin to be installed, and the
  body's first step checks for it.
- **The live exercise changes the user's desktop.** It uses reversible
  commands only, and restores from a backup of `state.json`, as was done in
  PR #1's step 11.

## Verification

- `nix flake check` passes. Evaluating the module with
  `skill.enable = true` shows the `.claude/skills/hyprforge` entry, and with
  `false` it's absent.
- Every command in the skill is run once on this host:
  - `open`/`close`/`toggle`/`section blur`;
  - `look glass` then `look stock`;
  - `motion snappy` then `motion omarchy`;
  - `set`/`unset`;
  - `saveProfile`/`listProfiles`/`profile`/`cycleProfile`, with a temp
    profile removed afterwards.

  Then check that `state.json` and `hyprforge.lua` are byte-identical to the
  backup.
- AGENTS.md: every path and function it names exists
  (`grep` for each, done as a plan step).
