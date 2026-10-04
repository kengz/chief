---
name: fleet
description: Running a fleet of persistent coding-agent sessions across machines through one adapter tool — dispatch and its exit codes, a quiet or stuck box, a send that vanished, a login failure, standing a new box up to parity.
---

# Fleet

How any provider drives sessions under `AGENTS.md` Institution: Dispatch. Every session is persistent: it survives a dropped connection and a person can take it over unchanged. One adapter tool, `<fleet-tool>`, serves every provider and box, run outside any sandbox; never a hand-built `tmux` or `claude` launcher. The tool reads its box list from its own configuration file, which holds addresses and is never committed here.

The tool is yours to choose. This skill assumes it offers the verbs below; rename them to match yours.

## 1. Dispatch

1. **`map` resolves a project's box and `status <box>` re-probes its state; dispatch is `goal <box> <file>`, then `wait <box>`.** A follow-up is `send <box> "<text>"`, its reply `read <box>`; `up <box>` starts a missing session.
    - Never inline the brief: long goals are truncated, and the shell expands `$(...)` and backticks.
2. **One objective per session, on current instructions.** Instructions load at start; a session keeps one stop condition, the last written silently winning.
    - Send only when the session reads `ready`; never force a goal into a working box.
    - New objective: bring the idle checkout to `origin/main` (detached, only if clean), then `clear <box>`. Mid-run, ask it to re-read the changed files.
3. **A brief is a contract:**
    1. objective and frozen bar;
    2. a size check in the first 30 minutes;
    3. before the ready line, one fresh challenger seat and the project's quick checks; a wording finding gives its replacement text;
    4. who instructs the lane;
    5. two closing lines, each ending the goal, and the brief says printing either one meets it: `ready-for-gates <commit>` while a gate is owed (its head commit carries a non-empty `Refined:` trailer, or the gate refuses), else `blocked <commit> — <reason>`.

## 2. Two providers

4. **A Chief reaches the other provider's sessions one way, and its own with native tools.**
    - To the other provider: a gate runner for a review, or for a build or design seat; lanes through the fleet tool (`goal`, `send`, `read`).
    - Its own provider: native sub-agents and threads, and the fleet tool; never `ssh` or a hand-built non-interactive launcher.

## 3. Read the session, never a proxy

5. **Only the session's text says what happened.**
    - Busy is the session's own interrupt hint and nothing else; any other overlay means the reader could not tell.
    - Watch with a loop printing a line per lane event and finished gate report, and flagging a ready lane unchanged for an hour; never `wait` alone.
    - A transport exiting zero proves keystrokes were delivered, not accepted.
    - A stopped box with a live work list is correct, not broken; read the list itself, since annotated cells make a grep undercount.
6. **`goal` exit codes:**
    - **3** refused, nothing typed.
    - **4** typed, not submitted.
    - **5** landed as an ordinary message, with no contract or stop hook. Attach and re-enter, then flush until the outbox is empty before reporting.
        - First read the session: an active-goal marker means it registered, and re-entering stacks a second goal.

## 4. Act by identity, never by pattern or position

7. **Name the one object you mean (Method §3).**
    - A pane by its id or a fully quoted target: a bare name first matches a window.
    - A process by its launch PID (`$!`), never `pkill -f` or `pgrep -f`, which match other lanes.
    - A worktree or clone, removed only by a script that first checks nothing would be lost.
    - A prompt by its text, never its position; confirm the cursor's answer with `capture-pane`, then Enter.
    - A project's owner by `map`, before picking a box.
    - A box's repo by its recorded working directory; a reassignment that skips it leaves the box `ready` against old instructions.
    - A gate by the exact candidate, by branch, reviewed in a sandbox; every seat's report, either provider, is published. A safety refusal moves it to a fresh seat of the other provider, recorded; never reword and retry.

## 5. Recover through the unit, never by hand

8. **`restart <box>` relaunches through the session's service unit, keeping its flags;** never a bare relaunch.
9. **A login error is usually a stale session: `restart <box>`, `up`, then re-select the dispatch model.**
    - Never copy credential files between boxes.
10. **Still logged out means the grant expired: relay a sign-in.** Only the approval click is the founder's; every other step is yours.
    - Read the sign-in URL from the pane with line joins, never by resizing the terminal.
    - Paste the full `code#state` value; the bare code fails.
    - Verify by running something, never by the prompt clearing.

## 6. The chief checkout

11. **If the checkout is synced to every box by a file-sync tool, a worktree edit lands on all.** Never `git stash` or `checkout` on a remote.
    - Dirty files are usually the sync beating `git pull`. If none is unpushed and each matches `origin/main`, `git reset origin/main` moves HEAD and the index, never a file. Then check `git status` on every checkout.
12. **A generated file never merges:** take either side of a conflict, then re-run the installer, which rewrites it from its sources.
13. **Propagate on every chief box, and finish it there yourself:**
    1. reach `origin/main`, refusing staged changes and archiving each dirty file before restoring it;
    2. run `./install.sh`;
    3. clear what it leaves: an old-layout folder or a `NOTE`d skill that is ours is archived, then deleted;
    4. done only when `./install.sh --check` exits 0 with no `NOTE` (project settings can still switch hooks off; none does). Report only what needs the founder.

## 7. A new box

14. Stand it up to parity with the others:
    1. install the agent CLIs and sign in as the founder;
    2. clone this repo and run `./install.sh`, then `./install.sh --check`;
    3. add it to the fleet tool's configuration and to `records/approvals/machines.md` (purpose and scope, never an address);
    4. start a session with `up <box>` and read it before trusting it.
