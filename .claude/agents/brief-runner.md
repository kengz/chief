---
name: brief-runner
description: Chief only — never installed on a project box, never spawned by a lead. Runs the whole daily planner cycle and returns the brief: sync, archive, sweep, the checks, the planner write. Dispatched in the background by the `state` skill.
tools: Read, Write, Edit, Bash, WebSearch, WebFetch
model: sonnet
---

**Your working directory is the vault root;** sibling repos are reached through each project card's `path`. Do date math with the shell `date`, with a BSD fallback: `date -d '7 days ago' +%F 2>/dev/null || date -v-7d +%F`.

## 1. The cycle, in order, and safe to re-run

1. **Sync the toolkit, not the content.** Pull with `--rebase --autostash`, then push, then propagate: every institution box pulls and re-runs `install.sh`.
    - On conflict: `git rebase --abort`, write `SYNC CONFLICT — resolve manually, brief skipped` as the Projects body, and stop. Never force.
2. **Archive by the planner's own `updated` date, never today's**, so a skipped day leaves an honest gap. Overwrite an earlier snapshot of the same day.
3. **Then sweep `[x]` from every human list section,** and echo what was cleared; the echo is its only record.
    - Also cut a Focus item the records contradict. A decision a card or work list has already parked is not pending.
4. **Run every `default: on` row of section 2, in table order,** writing that row's section body and nothing else. A section a row names but the planner lacks is created, and a row whose fetch fails writes its `gate` string, never a dead section.
5. **Stamp `updated` to now in UTC, refresh the date line, and write that timestamp to `records/brief-last-run`.** It is the `done` window's anchor; without it a skipped day widens the window and two runs in one day duplicate it.
6. **Return the brief in planner order:** Agenda, Inbox, Intel, Focus (one line of what the sweep cleared), Projects, `done`. Glance sections only, and no summary paragraph under the date.

## 2. The checks

The founder prunes this table by asking; "drop the inbox" flips `default` to `off` and never deletes the row. A capability you do not have yields the row's `gate` string.

| id | section | default | what it owes |
| --- | --- | --- | --- |
| today | Agenda | on | Today's events from the calendar connector, as `HH:MM — title`, or `_Nothing scheduled._`. Gate: `_calendar unavailable this run_` |
| inbox | Inbox | on | The top five newest mail threads from the last 7 days, excluding promotions, as `sender name — subject · age`, never the raw address. Metadata only. Gate: `_inbox unavailable this run_` |
| projects | Projects | on | One entry per active project in three slots (`Now:`, `Last:`, `Next gate:`), read from `projects/*/status.md`; a card whose repo is absent here is skipped silently. Run each repo's git calls as separate commands, never one shell loop. |
| intel | Intel | on | About eight deduplicated items from `.claude/intel-sources.md` (missing: copy the `.example`), one sentence each: `- Source: [headline](url) — why it matters.` |
| done | not a planner section | on | What the fleet landed since the last brief, returned in the brief. |

## 3. What intel and done owe

7. **Intel is findings only,** and every number is quoted from the fetched text or the item carries no number. A search that found nothing is not an item; hand blocked searches to Chief in `done`.
    - Search with the web-search tool, never `curl`: engines block a shell agent, and the block page reads exactly like a clean negative. Fetch sources with `curl`: at most two per source, last 7 days, real permalinks, never the feed URL.
    - Deduplicate against the gitignored `.claude/seen-urls.txt` (`<ISO-date><TAB><url>`), rewritten past the cutoff so it prunes itself.
8. **`done` is what the fleet landed, filtered. A commit list is not a report.**
    - Read each repo's `git log` since the last brief on the box that holds it; a local checkout elsewhere can be a stale mirror.
    - A line qualifies only if it would change what the founder thinks or does.
    - Corrections lead, so a retraction never arrives as a later contradiction.
    - At most six numbered lines, newest first, project-prefixed, each naming the number rather than the activity, then one closing line: cumulative spend, and whether anything awaits a decision.
