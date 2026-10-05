---
name: records
description: Chief's records — where each lives under records/, the work list, and the planner run that writes the planner. Load before reading or writing a record, on "good morning" or "the brief", when asked what is in flight, and before creating a new record.
---

# Records

[`AGENTS.md`](../../../AGENTS.md) is the neutral source: the records, what each answers, who writes it, and the rule before a new one is created. Here is where they sit.

| record | here |
|---|---|
| work list | [`records/WORK_LIST.md`](../../../records/WORK_LIST.md) |
| approvals | [`records/approvals/`](../../../records/approvals/): `boxes.md` and the live approvals |
| planner | `planner.md`, in the vault |

Per-record details:

1. `boxes.md` is in git, so it carries purpose, scope, owner, validation state and evidence; the transport's own configuration stays on the machine.
2. Edit a record only after syncing to `origin/main` (the vault delivers other Chiefs' edits). A dispatch is a work-list row written when it is sent, carrying the brief's path and the lane; a reversal edits that row in place.
3. The planner: Chief updates it at milestones; it is archived by its `updated` date, so a skipped day leaves an honest gap.
4. `records/planner-last-run` is the planner run's anchor, overwritten whole.

## The planner run

[`planner-runner`](../../../.claude/agents/planner-runner.md) writes the planner. It runs when a Chief session starts its day, never from a timer (Dispatch rule 9). The caller's rules:

1. **Never run it as a `/goal`:** a recurring chore must not take over the session's stop condition.
2. Launch it in the background, do not block, and relay it in the runner's order, glance sections only.
3. Act on intel, never relay it: dispatch what is material to the project it touches, in this turn.
4. Checked `[x]` items are removed from the planner and echoed in the report, never kept. If the sweep collides with the founder's own check-off, the check stands (the item is cleared, not restored). Bump the frontmatter `updated` stamp in one atomic edit and let it re-upload.
5. **A project card shows landings by slice:** each roadmap slice, ticked with its landing date only when the whole slice is on main, ticked in the same step as reading that landing, an open one with a few words of state. Follow-ons, fixes, cleanups, hashes and measures stay in the work list.

## Meters

1. Consumption is `claude -p "/usage"`.
