---
status: approved
issue: none (issues are disabled on this repo)
author: olafkfreund
---

# Intent: Installing or updating the plugin must not take the shell down

## Problem

On this host (p620), the Omarchy shell and its top bar were gone from
**11:57:44 to 12:15:04** (about 17 minutes) during PR #3's live test. The
cause, from the user journal:

1. The plugin folders under `~/.config/omarchy/plugins/` were swapped
   (`rm`/`mv`). The running shell hot-reloads a plugin when its folder
   changes, so it started reloading `aziz.hyprforge` and
   `aziz.hyprforge.bak`.
2. `omarchy restart shell` ran immediately afterwards. Upstream's script
   waits for the old shell with `timeout 5 quickshell kill …`
   (`omarchy-restart-shell:66`). The busy old shell took more than 5 s to
   exit, so the script launched the new one early.
3. The new instance logged "An instance of this configuration is already
   running." and exited. The old one then exited on the restart request,
   leaving **no shell** until the next manual restart.

This is Nixarchy issue **#953**, closed as "upstream's bug, not ours" and
deliberately not reported upstream. It was also my procedure error: the
restart's output went to `/dev/null`, so its "did not become ready" error
wasn't seen, and nothing checked that the shell came back.

This repo invites the same failure for users. PR #1's README says to run
`omarchy restart shell` right after a Home Manager switch, and that switch
swaps the plugin folder: steps 1 and 2 above, exactly.

## Proposed outcome

- Installing, updating or migrating the plugin with this repo's documented
  steps never leaves the user without a shell.
- The docs don't tell users to restart the shell when hot-reload already
  covers it (the log shows "Local plugin changed, reloading: <id>"). Where a
  restart is really needed, they say to wait for the reload to settle and
  to check the shell came back.
- Agents working here (AGENTS.md, the skill, and my own test procedures)
  follow the same rule: never swap plugin folders and restart in one
  breath; check `omarchy-shell shell ping` afterwards; never silence
  restart output.

## Affected users and systems

- This repo: `README.md`, `AGENTS.md` and the skill (PR #3), and possibly
  the HM module if an activation step helps.
- Every Nixarchy/Omarchy host with many plugins (slow teardown), which is
  where the upstream race bites.
- The upstream script itself (`omarchy-restart-shell`) belongs to Omarchy
  and, per nixarchy's policy on #953, isn't patched in the port.

## Constraints

- Don't patch Omarchy from this repo.
- The HM module must not start or stop the shell on its own during
  activation without a way to verify it came back.
- Every claim about hot-reload is verified on this host before it goes into
  the docs.

## Open questions

Resolved at approval (2026-09-29): the user approved with the suggested answers:

1. Reopen nixarchy #953 and carry a patch there. That is separate work in the nixarchy repo under its own AGENTS.md and workflow, and it is not done from this repo. This repo links to it.
2. Scope here: docs and procedure only. No HM activation step.
