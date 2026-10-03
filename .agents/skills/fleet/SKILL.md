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
    3. before the ready line, one fresh challenger seat and the project's quick checks;
    4. who instructs the lane, which prevents most questions;
    5. two closing lines, each ending the goal: `ready-for-gates <commit>` while a gate is owed, else `blocked <commit> — <reason>`.

## 2. Read the session, never a proxy

4. **Only the session's text says what happened.**
    - Busy is the session's own interrupt hint and nothing else; any other overlay means the reader could not tell.
    - A lane waiting on its supervisor still reads `ready`, so read the lane's events, not `wait` alone.
    - A transport exiting zero proves keystrokes were delivered, not accepted.
    - A stopped box with a live work list is correct, not broken; read the list itself, since annotated cells make a grep undercount.
5. **`goal` exit codes:**
    - **3** refused, nothing typed.
    - **4** typed, not submitted.
    - **5** landed as an ordinary message, with no contract or stop hook. Attach and re-enter, then flush until the outbox is empty before reporting.
        - First read the session: an active-goal marker means it registered, and re-entering stacks a second goal.

## 3. Act by identity, never by pattern or position

6. **Name the one object you mean (Method §3).**
    - A pane by its id or a fully quoted target: a bare name first matches a window.
    - A process by its launch PID (`$!`), never `pkill -f` or `pgrep -f`, which match other lanes.
    - A prompt by its text, never its position; confirm the cursor's answer with `capture-pane`, then Enter.
    - A project's owner by `map`, before picking a box.
    - A box's repo by its recorded working directory; a reassignment that skips it leaves the box `ready` against old instructions.
    - A gate by the exact candidate, by branch, reviewed in a read-only sandbox. A safety refusal moves it to a fresh seat of the other provider, recorded; never reword and retry.

## 4. Recover through the unit, never by hand

7. **`restart <box>` relaunches through the session's service unit, keeping its flags;** never a bare relaunch.
8. **A login error is usually a stale session: `restart <box>`, `up`, then re-select the dispatch model.**
    - Never copy credential files between boxes.
9. **Still logged out means the grant expired: relay a sign-in.** Only the approval click is the founder's; every other step is yours.
    - Read the sign-in URL from the pane with line joins, never by resizing the terminal.
    - Paste the full `code#state` value; the bare code fails.
    - Verify by running something, never by the prompt clearing.

## 5. The chief checkout

10. **If the checkout is synced to every box by a file-sync tool, a worktree edit lands on all.** Never `git stash` or `checkout` on a remote.
    - Dirty files are usually the sync beating `git pull`. If none is unpushed and each matches `origin/main`, `git reset origin/main` moves HEAD and the index, never a file. Then check `git status` on every checkout.
11. **A generated file never merges:** take either side of a conflict, then re-run the installer, which rewrites it from its sources.
12. **Propagate on every chief box, and finish it there yourself:**
    1. reach `origin/main`, archiving any file git does not hold before restoring it;
    2. run `./install.sh`;
    3. clear what it leaves: an old-layout folder or a `NOTE`d skill that is ours is archived, then deleted;
    4. done only when `./install.sh --check` exits 0 with no `NOTE`. Report only what needs the founder.

## 6. A new box

13. Stand it up to parity with the others:
    1. install the agent CLIs and sign in as the founder;
    2. clone this repo and run `./install.sh`, then `./install.sh --check`;
    3. add it to the fleet tool's configuration and to `records/approvals/machines.md` (purpose and scope, never an address);
    4. start a session with `up <box>` and read it before trusting it.
