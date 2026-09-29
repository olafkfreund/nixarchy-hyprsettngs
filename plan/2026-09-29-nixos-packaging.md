---
status: approved
issue: none (issues are disabled on this repo)
spec: spec/2026-09-29-nixos-packaging.md
---

# Plan: Rename to nixarchy-hyprsetting and package for NixOS

Branch `feat/nixos-packaging`. One commit per step, and each commit message
names its step.

## Decisions carried from the approved spec

- **README only** is renamed to "nixarchy-hyprsetting". Plugin id
  `aziz.hyprforge`, IPC `omarchy-shell hyprforge`, state paths,
  `manifest.json`, launcher entry and `LICENSE` are unchanged.
- The README links https://github.com/AbdulazizAlwabel/omarchy-hyprforge and
  credits Aziz (AbdulazizAlwabel) as the original author. The upstream install
  line stays, labelled "non-NixOS".
- `flake.nix`: nixpkgs (nixos-unstable) only, for x86_64-linux and
  aarch64-linux. It provides:
  - `packages.default`, a copy of the plugin files;
  - `homeManagerModules.default`, which sets
    `programs.nixarchy-hyprsetting.{enable,package}` and links
    `xdg.configFile."omarchy/plugins/aziz.hyprforge".source` as one directory
    symlink. It never writes `shell.json` and adds no `lua` (Hyprland already
    brings it);
  - `checks.default`, which runs `node test/run.js`.
- devenv: plain `devenv.nix` + `devenv.yaml`. It provides `nodejs` and `lua`,
  and the scripts `test` and `test-live`. No `.envrc`.
- Every confirmed review finding is fixed: B1–B8 and E1–E7. These are **not**
  changed:
  - the getoption regex;
  - the drag-end undo;
  - the `refreshLive` batch;
  - `.bak.hyprforge-*` pruning.
- B4 policy: while the panel is committing, the service refuses IPC changes
  and notifies. While a service op runs, the panel defers its commit. If both
  happen, the service's change wins.
- Migration: the copied `~/.config/omarchy/plugins/aziz.hyprforge` is moved
  aside once before the first HM switch. User state in
  `~/.config/hypr/hyprforge/` is untouched.

### Refinement of spec E2 (needs your OK with this plan)

The spec said `normalize` should stop cloning and that callers which mutate
should clone. There are 25 call sites in `Panel.qml`/`Service.qml` that use
`normalize` as a **snapshot** (`lastGood`, profiles, history, undo). Changing
its meaning there risks aliasing bugs in the rollback path. Instead:
`normalize` keeps cloning. A new non-cloning `shape(cfg)` is used by the six
read-only Engine callers (`render`, `validate`, `isEmpty`, `curveByName`,
`curveNames`, `diffKeys`), which are the hot ones: `render` runs on every
preview frame. The goal (no JSON round-trip on hot paths) is the same; the
blast radius is smaller.

## Steps

1. **devenv**: add `devenv.nix` (`packages = [ pkgs.nodejs pkgs.lua ]`,
   `scripts.test.exec = "node test/run.js"`,
   `scripts.test-live.exec = "node test/live.js"`) and `devenv.yaml`. Run
   `devenv allow` (with the user's consent, given by this approval) and
   `devenv shell -- node --version`, which writes `devenv.lock`. Commit all
   three plus devenv's `.gitignore`.
   → verify: `devenv info` lists nodejs and lua.

2. **B1**: in `test/run.js` and `test/live.js`, resolve
   `looknfeel.lua` from `process.env.OMARCHY_PATH || "/usr/share/omarchy"`.
   In `run.js`, if the file is missing, print `skip: baseline (no Omarchy)`
   and use an empty baseline; the baseline check runs only when the file
   exists. `live.js` fails with a clear message if the file is missing, since
   it needs a live Omarchy anyway.
   → verify: `devenv shell -- node test/run.js` has 0 failures (was 1).

3. **E2 (refined) + E1 + E7, Engine.js**:
   - Add `shape(cfg)`: the current `normalize` body without `clone`. Then
     `normalize(cfg) = shape(clone(cfg))`. Point the six read-only callers at
     `shape`.
   - Add `wrapFile(body)`. `renderFile(cfg, ctx)` becomes
     `wrapFile(render(cfg, ctx))`.
   - Add `capped(cmd, bytes)`, moved verbatim from Panel/Service.
   - Add checks to `test/run.js`: `render` leaves its input deep-equal to a
     prior clone for every preset, and `wrapFile(render(x)) === renderFile(x)`.
   → verify: `node test/run.js` passes.

4. **E1 + E7 callers**:
   - `Service.finish` computes `body = render(...)` once and sets
     `p.lua = wrapFile(body)`.
   - `Panel.persistNow` stores the rendered body on
     `root.commitBody`, and the commit/eval path reuses it instead of
     re-rendering.
   - Replace both local `capped` functions with `Engine.capped`.
   → verify: `grep -c "renderFile\|render(" Panel.qml Service.qml` drops;
   tests pass.

5. **B5 + B6, baseline.lua**:
   - `num()` returns `null` for NaN and `±math.huge`.
   - Curve emission: skip a curve whose spec isn't a table, and a bezier
     whose `points` aren't two two-number tables. The skip is done by
     wrapping each entry's `string.format` in `pcall`.
   - Add to `test/run.js`: feed a temp Lua file with a bad `points` and an
     `inf` speed, then assert the output parses as JSON and still lists the
     good entries.
   → verify: tests pass.

6. **E3, SafeWriter.qml**:
   - `d=${1%/*}` and `n=${1##*/}` replace `dirname`/`basename`.
   - Add `property bool swept: false`. The stale-temp `find` runs only when
     arg `$3` is `1`, which `next()` passes on the first job and then sets
     `swept = true`.
   - The `-mmin +2` and exact-name guards stay.
   → verify: `sh -n` on the script text. Runtime check in step 10.

7. **B2 + B3 + B7, Service.qml**:
   - B2: add `abort(prefix)` to SafeWriter to drop queued jobs. In
     `writer.onWritten`, if a state or history write fails during an op, drop
     that op's remaining writes, call `stateWritten()` and `opDone()`, and
     notify "not applied".
   - B3: `set()` pushes a `withState` op that runs `checkProc` for that key.
     The `checkProc` handler applies the change inside the same op (or calls
     `opDone()` on rejection). Remove `pendingSet`.
   - B7: in `baselineProc`, if the output is empty or doesn't parse,
     `notify("Could not read Omarchy's animations; not applied", true)`,
     clear `pending` and call `opDone()`.
   → verify: tests pass. Runtime check in step 10.

8. **B4, Service ↔ Panel**:
   - Service: add `property bool panelBusy: false`. `run()` returns early
     with a notice while `panelBusy` is true.
   - Panel: add `Binding { target: root.service; property: "panelBusy";
     value: root.committing; when: root.service !== null }`. At the top of
     `persistNow`, if `root.service && root.service.opBusy`, call
     `schedulePersist()` and return. The existing `stateStale` re-read adopts
     the service's result.
   → verify: runtime check in step 10.

9. **E4 + E5 + E6 + B8, Panel.qml**:
   - E4: `buildAllItems` also builds `root.typeByKey`, and `typeOf` uses it.
   - E5: add `readonly property var lookCanon` and `motionCanon`, which hold
     the presets' canonical strings computed once. `activeLook` and
     `activeMotion` compare against them.
   - E6: `buildAllItems` stores `it._hay = (key+" "+label+" "+desc)
     .toLowerCase()` on a shallow copy. Schema items are shared, so this can't
     mutate them. `computeRows` uses `_hay`.
   - B8: add `trap 'rm -f -- "$new"' EXIT` after `new=$(mktemp …)` in
     `hookScript`, cleared with `trap - EXIT` after the `mv`.
   → verify: tests pass. `qmllint Panel.qml` shows no new warnings, if
   qmllint is available.

10. **flake + HM module + README**:
    - Write `flake.nix` as decided. Run `nix flake lock`.
    - README: new title, intro with credit and link, a "NixOS / Home Manager"
      install section with the one-time `mv` migration and
      `omarchy restart shell`, a "Credits" section, and a devenv note under
      Development.
    → verify:
      - `nix flake check` is green;
      - `nix build .#default && ls result` shows no test/intent/spec/plan/Nix
        files;
      - `devenv shell -- node test/live.js` is clean against the running
        Hyprland.

11. **Runtime on this host**: see Tests. If a live check fails, fix it in the
    step that caused it, and record any deviation in this plan in the same
    commit.

## Tests

- `devenv shell -- node test/run.js`: 0 failures.
- `devenv shell -- node test/live.js`: every preset dry-runs clean.
- `nix flake check`: passes.
- Runtime, after `mv ~/.config/omarchy/plugins/aziz.hyprforge{,.bak}` and
  wiring the HM module into the user's config (or, before that, a manual
  `ln -s $(nix build --print-out-paths) …` for a dry test), then
  `omarchy restart shell`:
  - open the panel and drag a slider: `state.json` and `hyprforge.lua`
    update, with one undo step;
  - `omarchy-shell hyprforge set decoration:rounding 12; omarchy-shell
    hyprforge set decoration:border_size 3`: both apply;
  - `omarchy-shell hyprforge profile <name>` while the panel is committing:
    a notice appears and nothing is lost;
  - `omarchy-shell hyprforge reset` returns to stock.

## Rollback

- Code: `git revert` the step commits, or drop the branch. `main` is
  untouched until merge.
- Host: remove the HM module line and switch, then
  `mv ~/.config/omarchy/plugins/aziz.hyprforge.bak
  ~/.config/omarchy/plugins/aziz.hyprforge` and `omarchy restart shell`.
  User state in `~/.config/hypr/hyprforge/` is never touched by this change.
