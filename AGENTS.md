# AGENTS.md

Guide for AI agents changing this repository. For *using* the plugin on a
desktop (changing gaps, blur, profiles…), see the skill in
[`skills/hyprforge/SKILL.md`](skills/hyprforge/SKILL.md) instead.

## What this is

**Hyprforge**, a Hyprland settings panel for Omarchy, written by **Aziz
([AbdulazizAlwabel](https://github.com/AbdulazizAlwabel))**. The original
project is at
[omarchy-hyprforge](https://github.com/AbdulazizAlwabel/omarchy-hyprforge).
This repo packages it for NixOS/Nixarchy and adds fixes. Bugs in the plugin
itself also belong upstream.

It's a Quickshell plugin, in QML plus plain JS (`.pragma library`). There's
no build step, and nothing is compiled.

## Commands

```bash
devenv shell -- test        # node test/run.js: offline, no Hyprland needed
devenv shell -- test-live   # node test/live.js: needs a running Omarchy; briefly changes the look
nix flake check             # package + tests + lint (what CI runs)
nix build .#default         # the plugin as the Home Manager module installs it
omarchy restart shell       # after any QML change: plugin QML is cached by URL
```

Run `devenv allow` once in a fresh clone.

## Layout

| Path | What |
|---|---|
| `manifest.json` | Plugin id `nixarchy.hyprlandsettings`, kinds panel + service |
| `Panel.qml` | The UI, the live-preview/commit pipeline, keyboard, Connect/Disconnect hook |
| `Service.qml` | Headless half: launcher entry, and the `omarchy-shell hyprforge …` IPC |
| `Schema.js` | The curated option catalogue (sections, items, `hf:*` synthetic keys) |
| `Engine.js` | Validation, the Lua renderer, presets (LOOKS/MOTIONS), curves, hook text |
| `SafeWriter.qml` | The only way files are written |
| `BoundedRead.qml` | The only way files are read |
| `baseline.lua` | Reads Omarchy's stock animations using recording stubs |
| `components/` | View components (OptionRow, PreviewCanvas, CurveEditor, …) |
| `test/` | `run.js` (offline), `live.js` (live), `embedded-sh.js`, fixtures |
| `flake.nix` | Package, Home Manager module (`programs.nixarchy-hyprsetting`), checks |
| `devenv.nix` | node + lua for the tests |
| `intent/` `spec/` `plan/` | Design records, one set per task |

## Invariants: do not weaken these

1. **Contract with existing installs.** The id `nixarchy.hyprlandsettings` (it replaced
   `aziz.hyprforge`; see the README's migration steps), the IPC
   target `hyprforge`, the Lua module `hypr.hyprforge`, the paths
   `~/.config/hypr/hyprforge.lua`, `~/.config/hypr/hyprforge/`
   (`state.json`, `history.json`) and `~/.cache/hyprforge/`, the
   `X-Hyprforge-Managed` launcher marker and the `hyprforgeProfile` clipboard
   key are all matched by users' files and keybindings.
2. **Nothing reaches `hyprforge.lua` unless Hyprland accepted it first.**
   The order is `Engine.validate` → `hyprctl eval` dry-run → write state,
   history, Lua → `hyprctl reload` → roll back to `lastGood` if a reload
   error names hyprforge. See `persistNow`/`commitChecked`/`afterReload` in
   `Panel.qml` and `finish`/`historyReady` in `Service.qml`. A reload-time
   config error can freeze some compositors, which is why the dry-run exists.
3. **Every write goes through `SafeWriter`:** a mktemp file renamed into
   place, never written through a symlink, with an optional `.bak` first.
   A failed `state.json` write aborts the rest of the op (`writer.abort()`).
4. **Every read goes through `BoundedRead`**, and every command's stdout
   goes through `Engine.capped`, so nothing unbounded reaches QML.
5. **Values reach the shell only as argv** (`sh -c script sh "$@"`). Never
   interpolate a value into a script string.
6. **`hyprland.lua` is touched only by Connect/Disconnect** (`hookScript`):
   one optional-require line (`Engine.HOOK_LINE`). It's checksum-guarded
   against concurrent edits, backed up first, and a dotfile symlink is
   preserved.
7. **The panel and the service serialize on `state.json`.** The service's
   `withState` refuses while `panelBusy`, and the panel waits while
   `opBusy`. Don't add a third writer.
8. **`Engine.normalize` returns a copy.** Snapshots (`lastGood`, profiles,
   history, undo) depend on it. `Engine.shape` doesn't copy and is for
   read-only callers.
9. **Never restart the shell right after changing plugin folders.** A
   folder change makes the running shell hot-reload, and it stops answering
   IPC for up to about 30 s. An `omarchy restart shell` in that window can
   leave **no shell at all**: upstream's `timeout 5` kill loop, nixarchy
   #953. This took p620's bar down for 17 minutes on 2026-09-29. After
   installing, updating or removing: run
   `omarchy-shell shell rescanPlugins`, then
   `until omarchy-shell shell ping >/dev/null 2>&1; do sleep 1; done`. If a
   restart is unavoidable, wait for idle, keep its output, and check `ping`
   afterwards. Move old plugin copies **out of**
   `~/.config/omarchy/plugins`: a renamed copy left inside is still
   discovered, and shadows the real install.

## How changes are made

Anything tracked as a task or touching more than one file follows
`intent/` → `spec/` → `plan/` (slug `YYYY-MM-DD-<issue>-<slug>`). Each stage
is committed as `status: draft` and approved by the user in its own commit
before the next is written. There's no code before the plan is approved. A
deviation updates `plan/` in the same commit as the code. PRs link all three
files.

## Don'ts

- Don't edit a generated `hyprforge.lua`, and don't hand-edit `state.json`.
  Both belong to the plugin.
- Don't make the flake or the Home Manager module write
  `~/.config/omarchy/shell.json`, `bindings.lua` or `hyprland.lua`. Omarchy
  and the user own those.
- Don't add runtime dependencies. The plugin needs only `lua` and `hyprctl`,
  which Hyprland already brings.
- Don't commit `result`, `.devenv*` or `devenv.local.nix`.
- Don't rely on `test/live.js` in CI. It needs a live session.
