---
status: approved
issue: none (issues are disabled on this repo)
spec: spec/2026-09-29-agents-md-skill.md
---

# Plan: AGENTS.md and a Hyprforge skill for AI agents

Branch `docs/agents-md-skill`, based on `feat/nixos-packaging` (PR #1). Its
PR is based on that branch and retargeted to `main` after #1 merges. One
commit per step.

## Decisions carried from the approved spec

- `AGENTS.md` is for agents changing the code. It has these sections: what
  this is (with upstream credit and link), commands, a file-layout table, 8
  invariants (below), the intent → spec → plan workflow, and the don'ts.
  `CLAUDE.md` is just `@AGENTS.md`.
- The invariants:
  1. the id, IPC target and state paths are a contract;
  2. validate → `hyprctl eval` → write → reload → roll back;
  3. every write goes through SafeWriter;
  4. every read goes through BoundedRead, and command output through
     `Engine.capped`;
  5. values reach the shell only via argv;
  6. `hyprland.lua` is touched only by Connect/Disconnect;
  7. panel and service serialize on `state.json`;
  8. `normalize` copies and `shape` doesn't.
- The skill, `skills/hyprforge/SKILL.md` (`name: hyprforge`), is for agents
  operating a desktop. It covers:
  - when to use it (the plugin is installed and the change is to appearance
    or behaviour), with `nixarchy` handling hand edits, and never editing
    `hyprforge.lua` or `state.json`;
  - the full command reference with the real look, motion and section ids;
  - semantics:
    - `ok` means queued;
    - unknown ids are no-ops;
    - changes are refused while the panel saves;
    - `listProfiles` can be stale, so use the `jq` workaround;
    - Omarchy toggles can win;
  - verification: `state.json`, `hyprctl getoption`, `configerrors`;
  - undo: `unset`/`reset`, or a `saveProfile "before-<task>"` restore point.
- HM option `programs.nixarchy-hyprsetting.skill.enable`, default `false`. It
  sets `home.file.".claude/skills/hyprforge".source = ./skills/hyprforge`.
  The package's fileset is unchanged.
- README: a "For AI agents" section, plus `open`, `close` and `listProfiles`
  added to the scripting list.
- `listProfiles` staleness is documented only. No code change in this task.

## Steps

1. **`AGENTS.md` + `CLAUDE.md`**: write both as decided. `nix fmt` is
   mentioned as "after the CI PR".
   → verify: every file, function and property named exists (`grep -c` for
   each of `SafeWriter`, `BoundedRead`, `Engine.capped`, `panelBusy`,
   `opBusy`, `shape`, `normalize`, `hookScript`, `HOOK_LINE`, …); no line
   numbers are cited.

2. **Skill**: write `skills/hyprforge/SKILL.md`. The ids are pasted from a
   `node` dump of `Engine.LOOKS`, `Engine.MOTIONS` and `Schema.SECTIONS`, not
   typed by hand. The `hf:*` keys, with their labels, come from `Schema.js`.
   → verify: the dump output diffs clean against the ids in the skill.

3. **Exercise every command live** (this host, reversible):
   - back up `~/.config/hypr/hyprforge/` and `hyprforge.lua` to the
     scratchpad;
   - `open`, `close`, `toggle` ×2, `section blur`, `close`;
   - `look glass` then `look stock`;
   - `motion snappy` then `motion omarchy`;
   - `set decoration:rounding 12` then `unset`;
   - `saveProfile hf-skill-test`, `listProfiles` (called twice, to observe
     the staleness), `profile hf-skill-test`, `cycleProfile`;
   - restore `state.json`/`history.json`/`hyprforge.lua` from the backup
     with `cp` to a temp file and `mv` into place, which removes the temp
     profile (there's no delete IPC), then `hyprctl reload`.

   → verify: after each command, `state.json` and `hyprctl getoption` behave
   as the skill says. At the end, the files are byte-identical to the backup
   and `configerrors` is empty. Any mismatch fixes the skill text and is
   recorded here.

   **Results and deviations (implemented, 2026-09-29):**
   - The installed plugin was the original copy, without this repo's fixes,
     so the branch build was linked in for the run (as in PR #1 step 11),
     then the original copy was put back.
   - Every command ran. `open`/`close`/`toggle`/`section` print nothing, and
     the rest print `ok`. `look nope` and `set bogus:key` returned `ok` and
     changed nothing, which is what the skill says.
   - **Skill corrected:** `look stock` dropped a pre-existing user override
     (1 → 0 options). A look replaces every look-section setting, and the
     skill now says so and tells agents to take a restore point first.
   - **Skill corrected:** `listProfiles` is **not** stale after a restart
     (it returned the profile on the first call; the service reads state on
     start). The spec's claim was too broad. The real gap, from the code, is
     a panel-saved profile before the service's next op. The skill now says
     "call twice or read the file".
   - Restored: the `~/.config/hypr/hyprforge/` dir and `hyprforge.lua` are
     byte-identical to the backup (`diff -r`, `cmp`), the original plugin
     copy is back, and `configerrors` is empty.

4. **HM option**: add `skill.enable` to `flake.nix`.
   → verify: `nix flake check`. `nix eval` of the module with the option
   true shows `home.file.".claude/skills/hyprforge"`, and with it false the
   entry is absent.

5. **README**: add the "For AI agents" section and the 3 missing commands.
   → verify: no other README changes.

6. **Push and PR**: push the branch and open a PR with base
   `feat/nixos-packaging`, linking the intent, spec and plan.

## Tests

- `devenv shell -- test` and `nix flake check` pass.
- Every command in the skill ran live, and the host was restored
  byte-identical (step 3).
- The module eval shows the skill entry only when enabled.

## Rollback

`git revert` the branch commits. On the host, the step 3 backup restores
everything, and the HM option defaults to off.

## Note on the parallel CI PR

Both branches touch `flake.nix` and `README.md`. Whichever merges second
rebases. The CI PR also reformats `flake.nix` with `nixfmt`, so this branch
runs `nix fmt` after rebasing.
