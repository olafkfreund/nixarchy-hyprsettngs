---
status: draft
issue: none (issues are disabled on this repo)
intent: intent/2026-09-29-shell-restart-safety.md
---

# Spec: Installing or updating the plugin must not take the shell down

## Design

### Facts this rests on (measured or read on p620, 2026-09-29)

- **Root cause:** `omarchy-restart-shell` line 66,
  `while timeout 5 quickshell kill -p "$CONFIG_DIR" --any-display …`. When
  the old shell takes more than 5 s to exit, the new one is launched early,
  logs "An instance of this configuration is already running." and exits,
  and the old one then exits too. The journal shows exactly this at
  11:57:39–44 (PIDs 1963857 → 1975327), followed by 17 minutes with no
  shell. That's nixarchy #953.
- **Plugin folder changes hot-reload the running shell** ("Local plugin
  changed, reloading: <id>"). With a real dir becoming a symlink, and a
  symlink retarget, the shell was busy for about 8–30 s: IPC didn't answer,
  CPU was high, and the bar stayed up. The plugin reappeared after 30+ s.
  No restart was needed.
- **Omarchy provides `omarchy-shell shell rescanPlugins`**, and its catalog
  follows symlinks (`find -L`).
- **`omarchy plugin disable`** needs the plugin to still be known.

### The rule (one sentence, used everywhere)

> After installing, updating or removing the plugin, don't run
> `omarchy restart shell`. Run `omarchy-shell shell rescanPlugins` and
> wait until `omarchy-shell shell ping` answers. If a restart is ever
> unavoidable, wait for the shell to go idle first, keep the command's
> output, and check `ping` afterwards (restart again if it's down).

The wait snippet:
`until omarchy-shell shell ping >/dev/null 2>&1; do sleep 1; done`

### Where it goes

| File | Change | Lands in |
|---|---|---|
| `README.md` | Install / Update / Migrate use the rule; no restart step | the rename-plugin-id PR (README rewrite; its spec §4) |
| `AGENTS.md` | a new invariant 9, "Never restart the shell right after changing plugin folders", with the rule, the #953 reference, and the "move old copies *out of* `~/.config/omarchy/plugins`" rule | the rename-plugin-id PR, which merges #3 where `AGENTS.md` lives |
| `skills/hyprforge/SKILL.md` | "If the panel/IPC stops answering right after an install or update, wait (`ping` loop); don't restart" | the same PR |

This branch (`fix/shell-restart-safety`) carries only the intent and this
spec, plus the plan, which says that. No code or docs change lands here,
because all three files are rewritten in the rename-plugin-id PR, and a
separate edit would conflict with it.

### nixarchy #953 (approved at intent: reopen and carry a patch)

Separate work in the nixarchy repo, under its own `AGENTS.md` and
intent → spec → plan. It isn't done from this repo. The plan here only
records the hand-off:
- reopen #953 with today's journal evidence;
- a proposed patch direction for that repo's own spec: after the `timeout`
  loop, keep waiting until no instance for `$CONFIG_DIR` remains, or, if
  the new instance exits with "already running", relaunch once the old one
  is gone.

## Alternatives rejected

- **A HM activation step that pings or restarts the shell:** declined at
  intent (Q2: docs and procedure only).
- **Patching `omarchy-restart-shell` from this repo:** not our file, and
  not how nixarchy carries fixes.
- **A separate README edit on this branch:** it conflicts with the README
  rewrite.

## Risks

- The 8–30 s busy window is from one host with 20+ plugins. Other hosts
  will vary. The wait loop doesn't depend on the number.
- A user who restarts anyway can still hit #953 until nixarchy carries the
  fix. The README says why not to.

## Verification

- The README, `AGENTS.md` and the skill in the rename-plugin-id PR contain
  the rule, and no "restart shell" instruction after install/update:
  `grep -n "restart shell"` shows only the explanation.
- That PR's live migration follows the rule, with **no restart**, and ends
  with the shell up (`ping`), the plugin listed, and the bar present.
- nixarchy #953 is reopened with the evidence, and the patch work is
  tracked there.
