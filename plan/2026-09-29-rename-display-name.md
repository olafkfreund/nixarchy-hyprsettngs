---
status: approved
issue: none (issues are disabled on this repo)
spec: spec/2026-09-29-rename-display-name.md
---

# Plan: Show the plugin as "Nixarchy Hyprland Settings"

Branch `feat/rename-display-name`, based on `feat/nixos-packaging` (PR #1).
Its PR is based on that branch and retargeted to `main` after #1 merges. One
commit per step.

## Decisions carried from the approved spec

- User-visible text only becomes "Nixarchy Hyprland Settings", in full
  everywhere. Code comments are unchanged, and there's no IPC alias.
- The edits:
  - `manifest.json`: `name`, and `description` (starts with "Nixarchy
    Hyprland Settings (based on Hyprforge by Aziz / AbdulazizAlwabel): …",
    and "SUPER+SPACE › Nixarchy Hyprland Settings");
  - `Panel.qml`:
    - the title text, plus `elide: Text.ElideRight` and
      `Layout.fillWidth: true`;
    - the two clipboard errors;
    - the Connect banner;
  - `Service.qml`:
    - `Name=`;
    - `Keywords=`, adding `nixarchy;hyprforge;settings;`;
    - the `notify-send -a` value and its title;
    - the "is saving" notice;
  - `components/ProfilesView.qml`: two subtitles (paths unchanged);
  - `Engine.js`: `HEADER` lines 1 and 4, and the `HOOK_LINE` comment;
  - `README.md`: the running-plugin wording. Credit and the upstream link
    stay.
- Unchanged: the id `aziz.hyprforge`, the IPC `hyprforge`, all paths,
  `hypr.hyprforge`, `X-Hyprforge-Managed`, `hyprforgeProfile`, `hf:*`, and
  code comments.
- `hasHook`/`removeHook` match `"hypr.hyprforge"`, so old hook lines keep
  working. A new test proves it.

## Steps

1. **Test first**: in `test/run.js`, assert that `Engine.hasHook` and
   `Engine.removeHook` handle a line with the **old** comment
   (`… -- Hyprforge (Omarchy plugin)`): `hasHook` is true, and after
   `removeHook` the result has no `hypr.hyprforge`.
   → verify: passes before the rename (it's a regression guard) and after.

2. **Engine.js**: `HEADER` and the `HOOK_LINE` comment.
   → verify: `devenv shell -- test` passes, including the hook placement
   test and `luac -p` on the rendered presets.

3. **manifest.json + Service.qml**: the name, description, `Name=`,
   `Keywords=`, notify app/title, and the saving notice.
   → verify: `jq . manifest.json` parses, and the embedded `installScript`
   is unchanged (`git diff` doesn't touch it).

4. **Panel.qml + ProfilesView.qml**: the title (with elide), errors, banner
   and subtitles.
   → verify: `qmllint` shows no `[syntax]` on the edited files and exits 0.

5. **Grep audit**: `git grep -n '"[^"]*Hyprforge'` on
   `*.qml *.js *.json`. The only hits left are the manifest credit, the
   `HEADER` "based on Hyprforge" and contract identifiers
   (`X-Hyprforge-Managed`). Each remaining hit is listed in this plan in the
   same commit as any fix.

6. **README**: the running-plugin wording (such as "Open it with
   SUPER+SPACE › …" and "Hyprforge writes…"). Keep the credit, the upstream
   link, and the "Hyprforge" mentions that describe the upstream project.
   → verify: a read-through; `git diff README.md` touches no credit lines.

   **Step 5 audit result:** the only remaining non-comment "Hyprforge"
   strings are the `HEADER` credit "(based on Hyprforge)", the manifest
   description credit, and the `X-Hyprforge-Managed` marker (contract).

   **Deviation (implemented, step 6):** the keybinding descriptions written
   by the Home Manager module in `flake.nix` ("Hyprforge", "Next Hyprforge
   profile") appear in Omarchy's keybinding list, so they're user-visible.
   The spec's table missed them, and they are renamed too.

7. **Live check** (this host; reversible; same procedure as before):
   - back up `~/.config/hypr/hyprforge/`, `hyprforge.lua` and
     `~/.local/share/applications/hyprforge.desktop`;
   - link the branch build and run `omarchy restart shell`;
   - title: `omarchy-shell hyprforge open`, then take a `grim` screenshot of
     the panel. Then flip the dock side for a second screenshot:
     temporarily set `ui.dockLeft` in a copy of `state.json`, put it in
     place, restart the shell, open the panel and take the screenshot. Look
     at both images: the title is full or cleanly elided, with no overlap;
   - launcher: `hyprforge.desktop` now has
     `Name=Nixarchy Hyprland Settings` and a `Keywords` line containing
     `hyprforge`, and it's still `X-Hyprforge-Managed`. The launcher's
     keyword *search* itself isn't driven by the agent; the
     desktop-file fields are the proof;
   - notification: run `set decoration:rounding 12`, then read the
     notification app name from `makoctl history` or `swaync-client`,
     whichever is running (checked first). Then `unset`;
   - header: after that commit, `head -1 ~/.config/hypr/hyprforge.lua`
     shows the new name;
   - `hyprctl configerrors` is empty;
   - restore: put back the three backed-up files and the original plugin,
     restart the shell, and check with `diff -r`/`cmp` that they're
     byte-identical.

   Record the results here.

8. **Push and PR**: base `feat/nixos-packaging`, linking the intent, spec
   and plan.

## Tests

- `devenv shell -- test` passes, including the old-comment hook test.
- `nix flake check` passes.
- The grep audit is clean (step 5).
- The live checks in step 7 are recorded.

## Rollback

`git revert` the step commits. On the host, the step 7 backup restores
everything. Users who updated see the old name again after a revert; their
state is unaffected, because no path or id changed.
