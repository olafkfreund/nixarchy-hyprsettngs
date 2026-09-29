# Nixarchy Hyprland Settings

*`nixarchy-hyprsetting`: a Hyprland settings studio for
[Nixarchy](https://github.com/olafkfreund/nixarchy) (Omarchy on NixOS),
installed declaratively with a flake and a Home Manager module.*

Every visual and behavioural knob Hyprland has, with a live scale model of your
desktop, theme-aware colors, an animation curve editor, per-app rules, profiles
and full history. Changes preview instantly on your real windows, and Hyprland
checks them before they're saved.

Based on **Hyprforge** by **Aziz
([AbdulazizAlwabel](https://github.com/AbdulazizAlwabel))**:
[github.com/AbdulazizAlwabel/omarchy-hyprforge](https://github.com/AbdulazizAlwabel/omarchy-hyprforge).

![Nixarchy Hyprland Settings](preview.png)

## Install on NixOS

Requirements: Nixarchy / Omarchy 4 with Hyprland ≥ 0.56 (Lua config), and
Home Manager. `lua` comes with Hyprland. The plugin needs no network access
and no sudo.

```nix
# flake.nix
inputs.nixarchy-hyprsetting.url = "github:olafkfreund/nixarchy-hyprsettngs";

# Home Manager configuration
imports = [ inputs.nixarchy-hyprsetting.homeManagerModules.default ];
programs.nixarchy-hyprsetting.enable = true;
```

| Option (`programs.nixarchy-hyprsetting.…`) | Default | Does |
|---|---|---|
| `enable` | `false` | Link the plugin into `~/.config/omarchy/plugins/nixarchy.hyprlandsettings` (read-only, from the Nix store) and write its keybindings to `~/.config/hypr/hyprforge-binds.lua` |
| `package` | this flake's package | The plugin build to link |
| `keybindings.open` | `"SUPER + ALT + H"` | Key that opens the panel; `null` for none |
| `keybindings.cycleProfile` | `"SUPER + ALT + SHIFT + P"` | Key that applies the next saved profile; `null` for none |
| `skill.enable` | `false` | Install the [agent skill](#for-ai-agents) to `~/.claude/skills/hyprforge` |

Home Manager only manages its own files. It never edits `shell.json`,
`bindings.lua` or `hyprland.lua`. After the first switch, do these once:

1. **Let the shell see the plugin.** Don't restart the shell (see
   [why](#why-not-omarchy-restart-shell)):

   ```bash
   omarchy-shell shell rescanPlugins
   until omarchy-shell shell ping >/dev/null 2>&1; do sleep 1; done
   ```

2. **Enable it.** This is recorded in `~/.config/omarchy/shell.json`:

   ```bash
   omarchy plugin enable nixarchy.hyprlandsettings
   ```

3. **Load the keybindings.** Add this line to `~/.config/hypr/bindings.lua`.
   `pcall` keeps Hyprland working if the file ever goes away:

   ```lua
   pcall(require, "hypr.hyprforge-binds")
   ```

4. **Connect.** Open the panel (**SUPER+ALT+H**, **SUPER+SPACE › Nixarchy
   Hyprland Settings**, or `omarchy-shell hyprforge toggle`) and click
   **Connect**. The plugin writes its settings to its own file,
   `~/.config/hypr/hyprforge.lua`, and Connect adds a single optional-require
   line for it to `~/.config/hypr/hyprland.lua`.
   - A full backup (`hyprland.lua.bak.hyprforge-XXXXXX`) is written first.
   - The edit is skipped if the backup fails, or if the file changed since
     the panel read it.
   - A symlinked dotfile stays a symlink.
   - Nothing else in your config is edited, and nothing changes until you
     click Connect.

## Updating

```bash
nix flake update nixarchy-hyprsetting
# switch your Home Manager / NixOS configuration as usual, then:
omarchy-shell shell rescanPlugins
until omarchy-shell shell ping >/dev/null 2>&1; do sleep 1; done
```

Your settings, profiles and history live in `~/.config/hypr/hyprforge/`.
Updates never touch them.

### Why not `omarchy restart shell`?

Changing a plugin folder makes the running shell hot-reload. On a machine
with many plugins it can stop answering for up to about 30 seconds while
the bar stays up. If `omarchy restart shell` runs in that window, the old
shell can outlive upstream's 5-second wait, and the new one exits with
"already running". You're then left with **no shell or bar at all**
([nixarchy #953](https://github.com/olafkfreund/nixarchy/issues/953)). So
rescan and wait instead. If you ever do need a restart, wait until the shell
answers `ping` first, and check it came back afterwards.

## Migrating

### From `omarchy plugin add`, or from the old id `aziz.hyprforge`

The plugin used to be installed as `aziz.hyprforge`. The order matters,
because Omarchy can only disable an id it can still see:

```bash
omarchy plugin disable aziz.hyprforge                              # 1. while the old copy is still installed
mv ~/.config/omarchy/plugins/aziz.hyprforge ~/aziz.hyprforge.old   # 2. OUT of the plugins directory
# 3. enable the Home Manager module (above) and switch
omarchy-shell shell rescanPlugins                                  # 4. then wait:
until omarchy-shell shell ping >/dev/null 2>&1; do sleep 1; done
omarchy plugin enable nixarchy.hyprlandsettings                    # 5.
```

- **Step 2:** move the old copy out of the plugins directory; don't just
  rename it in place. A copy left anywhere under `~/.config/omarchy/plugins/`
  is still found by its manifest, and would shadow the new install. If the
  old one came from an earlier version of this Home Manager module, skip
  step 2: the switch removes it.
- **Settings carry over.** State paths don't depend on the id. The
  `omarchy-shell hyprforge …` commands are unchanged, as is the line
  Connect added to `hyprland.lua`.
- **Hand-written keybindings or menu entries** that call
  `omarchy-shell shell toggle aziz.hyprforge` need the new id. The ones
  from `keybindings.*` are regenerated for you.

## Using it

Open it with **SUPER+ALT+H**, **SUPER+SPACE › Nixarchy Hyprland Settings**,
or `omarchy-shell hyprforge toggle`. Global search (`/`) covers everything.

| Section | Highlights |
|---|---|
| **Overview** | Live model of your screen, 9 one-click **Looks**, 7 **Motion** presets, and everything you've changed |
| **Windows & Gaps** | Inner/outer/workspace/floating gaps, border width, **smart gaps** and **smart borders**, resize-on-border, snapping |
| **Borders & Colors** | Gradient builder with **theme palette names**, alpha and angle; a **rotating gradient**; group borders |
| **Corners** | Rounding and squircle power |
| **Opacity** | Omarchy's per-window opacity rule; focused/unfocused/fullscreen multipliers |
| **Dimming** | Dim unfocused, strength, behind scratchpad, dim-around, dialogs |
| **Blur** | All of `decoration:blur`, **frosted glass behind the Omarchy bar/menus/notifications**, motion blur |
| **Shadow / Glow** | Size, falloff, sharpness, scale, offset, palette-tinted colors |
| **Animations** | Global speed, presets, per-animation curve/style, and a **curve studio** (bezier or spring) |
| **Layout** | Dwindle / Master / Scrolling / Monocle; lone-window aspect ratio for ultrawides |
| **Groups & Tabs** | Tab bar size, fonts, fill, rounding, indicator, colors, grouping |
| **Keyboard & Mouse** | Repeat, pointer speed, acceleration, natural scroll, focus-follows-mouse, touchpad |
| **Cursor & Zoom** | Magnifier, hide when idle/typing, warping |
| **Gestures** | Workspace swipe distance, threshold, flick speed, direction |
| **Behavior & Performance** | Focus stealing, VRR, swallowing, fullscreen, scratchpad, DPMS wake, direct scanout |
| **App Rules** | Pick a running app → opacity, blur, shadow, dim, rounding, border, float, size, workspace, monitor and more |
| **Profiles & History** | Save/apply/share profiles, import from clipboard, restore any change, copy the generated Lua |
| **Every option** | All ~350 Hyprland options from `hyprctl descriptions`, filterable |

**Colors follow your theme.** They're stored as palette names, not hex. The
generated Lua reads the active theme's `colors.toml` whenever Hyprland loads,
and `omarchy theme set` reloads Hyprland, so borders, shadows, glow and tabs
re-color with every theme. A fixed `#hex` is still available.

### Keys

| | |
|---|---|
| `Tab` / `Shift+Tab`, `1`–`9` | sections |
| `j` `k` / `↑` `↓` | rows |
| `h` `l` / `←` `→` | adjust (`Shift` = ×10) |
| `Space` / `Enter` | toggle / next choice |
| `Backspace` | reset the row to Omarchy |
| `/` or `Ctrl+F` | search |
| `Ctrl+Z`, `Ctrl+Shift+Z` | undo, redo |
| `P` | peek at the desktop (the panel goes see-through) |
| `A` | show/hide advanced options |
| `Esc` | clear search / close |

### Command line

```bash
omarchy-shell hyprforge toggle                  # also: open, close
omarchy-shell hyprforge section blur            # open at a section
omarchy-shell hyprforge look glass              # stock glass neon soft flat zen compact retro performance
omarchy-shell hyprforge motion bouncy           # omarchy snappy smooth bouncy slide fade minimal
omarchy-shell hyprforge set decoration:rounding 12
omarchy-shell hyprforge unset decoration:rounding
omarchy-shell hyprforge reset                   # back to stock (profiles are kept)
omarchy-shell hyprforge saveProfile "Work"
omarchy-shell hyprforge profile "Gaming"
omarchy-shell hyprforge cycleProfile
omarchy-shell hyprforge listProfiles
```

The Home Manager `keybindings.*` options cover the two common keys. To add
this app to **Menu › Style › Hyprland**, put the following in
`~/.config/omarchy/extensions/omarchy-menu.jsonc`. Reusing the id without an
`action` turns the entry into a submenu:

```jsonc
"style.hyprland": {"icon":"","label":"Hyprland","aliases":["hyprland","looknfeel"]},
"style.hyprland.hyprforge": {"icon":"󱌣","label":"Nixarchy Hyprland Settings","aliases":["hyprforge"],"action":"omarchy-shell shell toggle nixarchy.hyprlandsettings '{}'"},
"style.hyprland.edit": {"icon":"󰏫","label":"Edit looknfeel.lua","action":"omarchy-launch-config-editor \"$HOME/.config/hypr/looknfeel.lua\""}
```

## How it works and why it's safe

* **One file, one line.** Settings live in `~/.config/hypr/hyprforge/state.json`
  (with profiles; history is in `history.json`). They are rendered to
  `~/.config/hypr/hyprforge.lua`, which `hyprland.lua` loads with one
  optional require. That line sits after your own files and before
  Omarchy's toggles, so toggles like "no gaps" still work. Remove the plugin
  and nothing breaks.
* **Live preview** sends the same Lua to `hyprctl eval`, so what you see while
  dragging is exactly what gets saved.
* **Checked before saved.** Every commit is type-checked, then dry-run
  through `hyprctl eval`. The file is written and Hyprland reloaded only if
  Hyprland accepts it. If a reload still reports an error from
  `hyprforge.lua`, the last good state is restored. A reload-time config
  error can make Hyprland draw its error bar, which freezes the compositor
  on some systems; that's why validation comes first.
* **File safety.** Every file it writes (state, history, generated Lua, the
  launcher entry, the one-time `hyprland.lua` edit) goes to a fresh `mktemp`
  file that is renamed into place. A symlink is never written through, and
  backups complete before the edit they protect.
* **Colors never pinned.** Palette names keep `omarchy theme set` working,
  unlike `general:col.*` written into `looknfeel.lua`.
* **Omarchy's defaults stay visible.** Changed rows show the value underneath
  (`was 5px`).
* **Nix-friendly.** The plugin itself is read-only in the Nix store and never
  writes to its own directory. All state is in `~/.config/hypr` and
  `~/.cache/hyprforge`, so rollbacks and garbage collection can't lose it.

## What this fork adds

On top of upstream Hyprforge:

- **NixOS packaging:**
  - a flake with the plugin package;
  - a **Home Manager module** with keybinding and skill options;
  - a devenv shell.
- **Reviewed fixes:**
  - a failed state write can no longer leave `hyprforge.lua` ahead of
    `state.json`;
  - rapid `set` commands are queued;
  - the panel and scripts no longer race on `state.json`;
  - bad curve data can't empty the animation baseline;
  - the config is rendered once per save, and hot paths no longer copy it.

  Details are in
  [`plan/2026-09-29-nixos-packaging.md`](plan/2026-09-29-nixos-packaging.md).
- **CI:** `nix flake check` on every push and PR builds the package, runs
  the tests, and lints Nix, QML syntax, the embedded shell scripts and Lua.
- **Agent docs:** [`AGENTS.md`](AGENTS.md) for changing the code, and a
  skill for driving the plugin safely.
- **A new name and id:** Nixarchy Hyprland Settings,
  `nixarchy.hyprlandsettings`. Commands and state paths are unchanged.
- **A safe install/update procedure** that avoids the shell-restart race
  ([#953](https://github.com/olafkfreund/nixarchy/issues/953)).

## For AI agents

- **Changing this code:** read [`AGENTS.md`](AGENTS.md) for the commands,
  layout and safety rules.
- **Using the plugin on a desktop:** the skill in
  [`skills/hyprforge/SKILL.md`](skills/hyprforge/SKILL.md) teaches an agent
  to make changes through the commands above, with verification and undo,
  instead of editing config files. Enable it with `skill.enable = true`.

## Uninstall on NixOS

1. Optional: `omarchy-shell hyprforge reset` returns Hyprland to your own
   config.
2. In the panel, **Profiles & History › Disconnect from Hyprland**, or delete
   the line containing `hypr.hyprforge` from `~/.config/hypr/hyprland.lua`.
3. `omarchy plugin disable nixarchy.hyprlandsettings`. Do this while it's
   still installed. It also removes the launcher entry.
4. Set `programs.nixarchy-hyprsetting.enable = false`, switch, then run
   `omarchy-shell shell rescanPlugins` and wait for `ping` (as above).
5. Remove the `pcall(require, "hypr.hyprforge-binds")` line from
   `bindings.lua` if you like. It's harmless if left in.
6. Optional: delete `~/.config/hypr/hyprforge.lua`,
   `~/.config/hypr/hyprforge/` and `~/.cache/hyprforge/`.

## Development

```
manifest.json        plugin id nixarchy.hyprlandsettings: panel + service
Panel.qml            state, preview/commit pipeline, window, keyboard
Service.qml          launcher entry + `omarchy-shell hyprforge …` IPC
Schema.js            curated catalogue (208 options, 19 sections)
Engine.js            validation, Lua renderer, presets, curves, rules, hook
SafeWriter.qml       every file write (mktemp + rename, never through a symlink)
BoundedRead.qml      every file read (size-capped)
baseline.lua         reads Omarchy's stock animations with recording stubs
components/          OptionRow, PaletteEditor, PreviewCanvas, CurveEditor, views…
test/                run.js (offline), live.js (live Hyprland), embedded-sh.js, fixtures
flake.nix            package, Home Manager module, checks, formatter
intent/ spec/ plan/  design records, one set per change
```

```bash
devenv allow                # once per clone
devenv shell -- test        # node test/run.js: offline
devenv shell -- test-live   # node test/live.js: needs a running Omarchy, briefly changes the look
nix build .#default         # the plugin as the Home Manager module installs it
nix flake check             # package, tests and lint: exactly what CI runs
nix fmt                     # format the Nix files
```

The running shell hot-reloads a plugin when its files change. Wait for
`omarchy-shell shell ping` to answer, and avoid restarting the shell
mid-reload (see [above](#why-not-omarchy-restart-shell)).

Changes that touch more than one file go through `intent/` → `spec/` →
`plan/`, each approved before the next. See [`AGENTS.md`](AGENTS.md).

## Other distributions

Not on NixOS? Use upstream directly:

```bash
omarchy plugin add https://github.com/AbdulazizAlwabel/omarchy-hyprforge --enable --yes
```

## Credits

Hyprforge is the work of **Aziz
([AbdulazizAlwabel](https://github.com/AbdulazizAlwabel))**:
[github.com/AbdulazizAlwabel/omarchy-hyprforge](https://github.com/AbdulazizAlwabel/omarchy-hyprforge).
This repository adds NixOS packaging, fixes, CI and docs on top of it. Please
report problems with the plugin itself upstream.

## License

MIT — see [LICENSE](LICENSE).
