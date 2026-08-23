---
name: morning-brief
description: Your daily planner brief — triggers on "good morning", "the brief", or the daily cycle. Dispatches a background brief-runner so you stay free, then relays the brief when it lands.
allowed-tools: Task
---

# Morning Brief

**You are the supervisor. Dispatch the cycle and stay free.**

1. **Launch `brief-runner` in the background.** It runs the whole cycle and returns the brief. Do not block on it.
2. **Say what you are doing, in one line, and name the objective.** The brief arrives as a `/goal` and the founder's client shows the command name without its argument, so that line is the only part of the contract they can read.
    - **"🌅 Running the daily brief — gathering it in the background, and I'll drop it here when it's ready. What else?"**
3. **Relay it in the runner's order, with no plumbing**: agenda · inbox · intel · focus, with a one-line **✅ Cleared today** if the sweep cleared anything · projects · what the fleet landed.
    - **What the fleet landed goes in the relay only, never into the planner.** The planner is a glance and must never accumulate a running log.
    - **Follow the headings the planner actually uses**, and surface the glance rather than every heading.

## Act on intel, never relay it

4. **Scan intel and inbox against the live projects** — a competitor's release, a paper on a project's own variable, a new model, dataset or benchmark.
5. **When something is material, do the work rather than wait to be asked.** Judge it scoop-versus-validation-versus-citable, dispatch it to the project that can use it with your read attached, and land a `reference/` note if it will still matter next month.
    - **A founder answering a brief with *"dispatch a survey"* means the brief did half its job.**
    - **Send it now, never "when the box is free".** A deferred dispatch is a dropped one: the outbox exists to hold it, delivers at the next turn boundary, and flushing is yours. A morphology piece held for a quieter moment was still undispatched a day later.
    - **The judgement is yours and the brief is not where it goes.** The intel line stays one sentence; your assessment belongs in the dispatch and in one line of the relay. Asking the runner for it inline is how the section becomes an essay, and that request has come from this side every time.
    - **Gate the survey before it reaches the founder.** The teams produce; Chief gates.

## The schedule

**Trigger the brief however your machine schedules jobs; no session holds a clock.**

- **It sends rather than runs.** The timer has no session, so it hands the trigger to the command centre through the outbox every dispatch uses.
- **One brief per day, by a dated stamp**, so a box asleep at the hour still briefs when it wakes and every extra pass is a no-op.
- **The brief is the one named job that types into this session, and it types nothing else.**

## Writing a planner two people share

`planner.md` has no regions and no ownership. Which sections Chief may write at all is CLAUDE.md's; these three make the writing safe.

6. **Surgical edits against unique anchors**, never a wholesale section rewrite — a full rewrite ripples the merge into adjacent lines.
7. **Write only when quiet.** An inbound planner change in the last few minutes means wait and stage.
8. **Settle then sweep.** Clear an `[x]` only once it is stably synced, so the sweep never races a live check.

### Why the sweep is the most collision-prone write in the vault

**It fires during the founder's morning check-off, and when it collides it looks like broken sync.** Checking a box is a *modification*; the sweep is a *deletion*; Obsidian's merge keeps the `[x]` on the device that made the check. Locally the item is gone, on their device it stays checked-but-uncleared, and the sweep loses silently on their side.

- **This is not a daemon fault.** Other files sync fine and their own edits arrive; the failure is the merge.
- **When they report it, the local planner is already clean** — so force a strictly-newer version rather than editing again. **Bump the frontmatter `updated` stamp**, one atomic frontmatter-only edit, and let it re-upload.
- **If it still lingers, re-add the items to match their view**, let both sides agree on that base, then delete cleanly. A delete from a shared base is conflict-free.
