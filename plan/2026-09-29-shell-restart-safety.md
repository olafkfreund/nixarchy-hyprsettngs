---
status: approved
issue: none (issues are disabled on this repo)
spec: spec/2026-09-29-shell-restart-safety.md
---

# Plan: Installing or updating the plugin must not take the shell down

## Decisions carried from the approved spec

- **Root cause:** `omarchy-restart-shell:66`'s `timeout 5` kill loop lets
  a new shell start before the old one exits. Both end up gone. This is
  nixarchy #953, and the journal on p620 shows it at 11:57:39–44.
- **The rule:** after install, update or remove, no
  `omarchy restart shell`. Run `omarchy-shell shell rescanPlugins`, then
  `until omarchy-shell shell ping >/dev/null 2>&1; do sleep 1; done`. If a
  restart is unavoidable: wait for idle, keep the output, and check `ping`
  after.
- **Where it lands:** the README, `AGENTS.md` (invariant 9) and the skill,
  all **in the rename-plugin-id PR** (`plan/2026-09-29-rename-plugin-id.md`,
  steps 3–5). Those files are rewritten there. This branch carries only the
  records.
- **Nixarchy #953:** it's reopened with today's evidence. The patch is
  separate work in the nixarchy repo, under its own AGENTS.md and
  intent/spec/plan.

## Steps

1. **Hand-off check**: once the rename-plugin-id PR is implemented,
   confirm its README, `AGENTS.md` and skill contain the rule, and that
   `grep -n "restart shell"` in them shows only the #953 explanation.
   Record the commit hashes here.
   → verify: the grep output is pasted here.

2. **Reopen nixarchy #953**:
   - `gh issue reopen 953 -R olafkfreund/nixarchy`;
   - add a comment with the 11:57:39–44 journal lines (PIDs, "already
     running", "Exiting due to IPC request"), the 17-minute outage, the
     hot-reload measurements, and the proposed patch direction (keep waiting
     after the `timeout` loop until no instance for `$CONFIG_DIR` remains, or
     relaunch once if the new one exits "already running").

   It's the user's own repo, and reopening was approved at intent.
   → verify: `gh issue view 953` shows OPEN and the comment.

3. **Push this branch and open a PR** (base `feat/nixos-packaging`) that
   holds only the intent, spec and plan, and links the rename-plugin-id PR
   and nixarchy #953. Alternatively, close this branch without a PR if the
   user prefers the records to travel with the rename-plugin-id PR. Ask at
   step 3.

## Tests

- The step 1 grep is clean.
- #953 is reopened with the evidence.

## Rollback

- Re-close #953 with a comment.
- This branch only has docs, so drop it.

## Results (2026-09-29)

- **Step 1:** the rule landed in PR #5 (`feat/rename-plugin-id`) at
  48b6280 (AGENTS.md invariant 9 and the skill), 93fe26a (README) and
  6e24866 (wait for `listPlugins`, not `ping`, measured live). The grep
  found one leftover, `AGENTS.md`'s command block saying
  `omarchy restart shell  # after any QML change`. It was fixed in PR #5 at
  ddd7ea2. `grep -n "restart shell"` now shows only the #953 explanation
  (README), invariant 9 (AGENTS.md) and the "Don't restart" note (skill).
- **Rule refined by the live run:** wait until `listPlugins` shows the id,
  not until `ping` answers. `ping` can answer before the reload starts, and
  the next step then fails "not known".
- **Step 2:** nixarchy #953 was reopened, with the journal evidence, the
  hot-reload measurements and the patch direction:
  https://github.com/olafkfreund/nixarchy/issues/953#issuecomment-5889563876
- **Step 3:** waiting on the user (a PR for this records-only branch, or
  close it).
