---
status: approved
issue: none (issues are disabled on this repo)
intent: intent/2026-09-29-nixos-packaging.md
---

# Spec: Rename to nixarchy-hyprsetting and package for NixOS

## Design

### 1. README (rename in README only)

- Title becomes `# nixarchy-hyprsetting`. First paragraph says it is a
  NixOS/Nixarchy packaging of **Hyprforge by Aziz (AbdulazizAlwabel)**, with a
  link to https://github.com/AbdulazizAlwabel/omarchy-hyprforge.
- "Install" gets a NixOS section (flake input + Home Manager module, below).
  The upstream `omarchy plugin add` line stays, labelled "upstream / non-NixOS".
- New short "Credits" section: original author, original repo link, MIT.
- Everything else (feature names, `omarchy-shell hyprforge …`, paths) is
  unchanged, because the plugin id and IPC name do not change.
- `LICENSE` is not touched (keeps the original copyright line).

### 2. `flake.nix` (+ `flake.lock`)

Inputs: `nixpkgs` (nixos-unstable) only. Outputs, for `x86_64-linux` and
`aarch64-linux`:

- `packages.<sys>.default` — `stdenvNoCC.mkDerivation` that copies the plugin
  files (`manifest.json`, `*.qml`, `*.js`, `baseline.lua`, `icon.svg`,
  `preview.png`, `components/`, `LICENSE`) to `$out`. Tests, docs and Nix
  files are left out. No build step; nothing is patched.
- `homeManagerModules.default` — option `programs.nixarchy-hyprsetting`:
  - `enable` (bool)
  - `package` (defaults to this flake's package)
  - Sets `xdg.configFile."omarchy/plugins/aziz.hyprforge".source = cfg.package;`
    so the plugin dir is one symlink into the store. The URL Quickshell sees
    stays `~/.config/omarchy/plugins/aziz.hyprforge/…`, so `pluginDir`, the
    launcher icon path and QML caching behave as today.
  - `home.packages = [ pkgs.lua ]` is **not** added: `lua` is already a
    Hyprland dependency (README requirement). Documented, not duplicated.
  - Does **not** edit `~/.config/omarchy/shell.json`: that file is owned and
    rewritten by Omarchy's own tools. Enabling stays a one-time
    `omarchy plugin enable aziz.hyprforge` (already done on the current host).
- `checks.<sys>.default` — runs `node test/run.js` offline in the sandbox
  (needs `nodejs` and `lua`).

Read-only store is safe: the plugin only writes under `~/.config/hypr`,
`~/.cache/hyprforge` and `~/.local/share/applications` (verified: `pluginDir`
is only read — `baseline.lua` and `icon.svg`).

### 3. devenv shell

Plain devenv files (not flake-integrated devenv, which needs `--impure`):

- `devenv.nix`: `packages = [ pkgs.nodejs pkgs.lua ];`,
  `scripts.test.exec = "node test/run.js";`, and
  `scripts.test-live.exec = "node test/live.js";`.
- `devenv.yaml`, `devenv.lock` and devenv's `.gitignore` are committed.
- `.envrc` is not added: on Nixarchy the `devenv hook` activates on `cd`.
  First use needs `devenv allow` (user's consent, not automated).

### 4. Review fixes (every confirmed finding)

Bugs:

| # | Where | Fix |
|---|---|---|
| B1 | `test/run.js`, `test/live.js` | Read `looknfeel.lua` from `$OMARCHY_PATH`, falling back to `/usr/share/omarchy`; if missing, skip the baseline check with a message instead of failing. Currently fails on NixOS. |
| B2 | `Service.qml` `historyReady` + `writer.onWritten` | Stop the op on the first failed write: if state or history fails, drop the queued Lua write and end the op, so `hyprforge.lua` never gets ahead of `state.json`. |
| B3 | `Service.qml` `set()` | Route `set` through the existing `withState` queue instead of the single `pendingSet` slot, so two quick `set` calls can't overwrite each other or restart a running `checkProc`. |
| B4 | Service ↔ Panel | Read-modify-write race on `state.json`: the service refuses an IPC change while the panel is committing (notifies "Hyprforge is saving, try again"), and the panel defers its commit while a service op is in flight (retries via its existing `again` flag after `stateWritten`). If both happen, the service's change wins and the panel re-reads it. |
| B5 | `baseline.lua` | Malformed `points`, or a non-table curve spec, is skipped instead of throwing outside `pcall` (which gave empty output and a silently empty baseline). |
| B6 | `baseline.lua` `num()` | `±inf` → `null`, so the output is always valid JSON. |
| B7 | `Service.qml` `baselineProc` | Empty or invalid output → notify and end the op instead of rendering without animation context. |
| B8 | `Panel.qml` `hookScript` | `trap` removes the `$new` temp file if writing it fails. |

Efficiency / quality:

| # | Where | Fix |
|---|---|---|
| E1 | `Engine.renderFile` | Add `wrapFile(body)`; `Service.finish` and `Panel.persistNow` render the body once and wrap it, instead of rendering 2–3 times. |
| E2 | `Engine.normalize` | Return the input as is when it's already well formed. The callers that mutate (`copyCfg`, the service mutators) clone explicitly. This removes the JSON round-trip per call on hot paths. |
| E3 | `SafeWriter.qml` | `${1%/*}`/`${1##*/}` instead of `dirname`/`basename`; run the stale-temp `find` only on a writer's first write. |
| E4 | `Panel.qml` `typeOf` | Replace the linear scan of `allItemsCache` with a `key → type` map built in `buildAllItems`. |
| E5 | `Panel.qml` `activeLook`/`activeMotion` | Precompute the presets' canonical strings once. |
| E6 | `Panel.qml` `computeRows` ("all" view) | Cache a lowercase search string per item when `allItemsCache` is built. |
| E7 | `capped()` | Move the duplicate in `Panel.qml` and `Service.qml` to a single `Engine.capped`. |

### 5. Keybindings (addendum, 2026-09-29, requested during implementation)

The module manages Hyprforge's own Hyprland config and nothing else. It uses
the pattern this machine already uses for meet-binds and plugin-browser-binds:

- New HM options:
  - `programs.nixarchy-hyprsetting.keybindings.open`, default
    `"SUPER + ALT + H"`;
  - `programs.nixarchy-hyprsetting.keybindings.cycleProfile`, default
    `"SUPER + ALT + SHIFT + P"`;
  - either can be set to `null` to leave that key out.
- When `enable` is set, HM writes `~/.config/hypr/hyprforge-binds.lua`, a
  Nix-owned, read-only symlink containing the two `o.bind(...)` lines:
  `omarchy-shell shell toggle aziz.hyprforge '{}'` and
  `omarchy-shell hyprforge cycleProfile`.
- `bindings.lua` gets one line, once:
  `pcall(require, "hypr.hyprforge-binds")`. With `pcall`, a generation
  without the file skips it and Hyprland doesn't break. HM does **not** edit
  `bindings.lua`. The README documents the line, and on this host I add it
  once, with a backup.
- SUPER+ALT+P (upstream's suggestion) is not used, because it is already
  taken. Both default keys are free in `hyprctl binds`.

### 6. Existing keybinding clashes on this host (addendum)

`hyprctl binds` shows three keys that each fire two actions. The add-on
binding moves; the Omarchy default and your own GitLab binding stay:

| Key | Keeps | Moves | New key (free) | File |
|---|---|---|---|---|
| SUPER+ALT+P | GitLab Pipelines | Omgato: place camera | SUPER+ALT+SHIFT+O | `~/.config/hypr/omgato-bindings.lua` |
| SUPER+SHIFT+C | Calendar | Omgato: camera fullscreen | SUPER+ALT+SHIFT+C | `~/.config/hypr/omgato-bindings.lua` |
| SUPER+SHIFT+M | Music | Meeting record/transcribe | SUPER+CTRL+SHIFT+M | `~/.config/nixos/hosts/common/nixos/omarchy-meet-binds.nix` (HM-managed; needs a rebuild) |

These are host dotfile changes outside this repo. `omarchy-meet-binds.nix`
lives in your NixOS config repo and is committed there, following that
repo's own rules.

## Alternatives rejected

- **Home Manager writes `shell.json` to enable the plugin.** Omarchy rewrites
  that file itself; HM owning it would fight `omarchy plugin enable/disable`
  and the bar editor.
- **`home.file` with `recursive = true`** (per-file symlinks). Gives nothing
  over one directory symlink and leaves stale links on file removal.
- **Flake devShell instead of devenv.** Asked for devenv, and on Nixarchy it
  activates on `cd` with no `.envrc`.
- **Review items not fixed** (checked, not real):
  - `hyprctl getoption -j` regex: the output is flat JSON (checked on
    Hyprland here: gaps, gradient and bool options), so the regex works.
  - "Duplicate undo step on drag end": `pushUndo` returns early while
    `editing` is true, so the drag-end call doesn't push.
  - `refreshLive` batching every option: it's one `hyprctl --batch` process
    per reload or theme change, which is cheap.
  - `.bak.hyprforge-*` pruning on each Connect/Disconnect: kept on purpose.
    Those backups are the safety net for the user's `hyprland.lua`.

- **HM appends the lines to `bindings.lua` from an activation script.** That
  is an imperative edit of a file Omarchy also writes, and you asked for the
  module to control only its own config.

## Risks

- **Existing copied install**: `~/.config/omarchy/plugins/aziz.hyprforge` is a
  real directory, so Home Manager refuses to replace it. It must be moved
  aside once (`mv … aziz.hyprforge.bak`) before the first switch. The user's
  state lives in `~/.config/hypr/hyprforge/`, so nothing is lost.
- **QML cache**: after a switch that changes the store path, the shell needs
  `omarchy restart shell` (same as upstream after editing).
- **B4/E2 touch the commit pipeline** that guards Hyprland from bad config.
  A regression could write a Lua file that wasn't dry-run. Mitigation: the
  eval → write → reload → rollback order is not changed. Only the
  cloning/render counts and the op gating change.
- **Scope**: only this Nixarchy host.

- Keybindings: if the `pcall(require, ...)` line is missing, the keys do
  nothing, silently. The README says to add it.

## Verification

- `nix flake check`: evaluates the package and the HM module, and runs
  `node test/run.js` in the sandbox.
- `nix build .#default`: `$out` contains `manifest.json` and no `test/`,
  `intent/`, `spec/`, `plan/` or Nix files.
- `devenv shell -- node test/run.js`: passes on NixOS, where the baseline
  check currently fails.
- `node test/live.js` against the running Hyprland: every preset dry-runs
  clean.
- Runtime: enable the HM module, run `home-manager switch` and
  `omarchy restart shell`, then:
  - open the panel and change a slider, then check that `state.json` and
    `hyprforge.lua` both update;
  - run `omarchy-shell hyprforge set decoration:rounding 12` twice quickly,
    then check that both calls apply;
  - run `omarchy-shell hyprforge profile X` while dragging, then check that
    no update is lost and a notice is shown.
