# Chief

A setup that turns [Claude Code](https://claude.com/claude-code) into your chief of staff.

You are the founder. Chief is a long-running session that holds the purpose of each project, dispatches the work to project sessions, reviews what comes back, and keeps the few records a session must not lose.

## What is in it

1. **Rules:** `AGENTS.md` holds everything that binds a session.
    1. Principles: five axioms every rule must derive from.
    2. Premises: what the founder decides, given and not derived.
    3. Method: the laws for changing, moving, tracing, refining and writing work.
    4. Institution: the roles (founder, chief, lead, engineer), authority, dispatch, delivery and records.
    5. Codification: how the rules, skills and history are kept.
2. **`CLAUDE.md`:** exactly `@AGENTS.md`, so Claude Code and any other agent read the same file.
3. **Skills** in `.agents/skills/`, which Claude mirrors:
    1. `fleet`: driving persistent sessions across machines.
    2. `state`: the records and the daily brief.
    3. `lead-role`: what a project's lead session owns, plus a deck kit for progress decks.
    4. `refine-instructions`: measuring the work and improving the rules from evidence.
4. **Agents** in `.claude/agents/`: `engineer`, `verifier`, `challenger` and `brief-runner`.
5. **Records** in `records/`: the work list and the approvals. `planner.md` and `projects/` are small templates for the founder's day and project cards.
6. **Guards** in `.githooks/`:
    1. `commit-msg` requires a fix commit to name its anomaly.
    2. `pre-push` refuses conflict markers, GNU-only shell constructs, dated incident history in skills, unratified edits to `AGENTS.md`, and unlisted remotes.

## Install

You need `git`, `rsync`, `find`, `cmp`, `sha256sum` (or `shasum`) and `bash`.

1. Clone it: `git clone https://github.com/kengz/chief.git && cd chief`
2. Run `./install.sh`. It does five things:
    1. copies the skills and agents to `~/.claude` and to `~/.agents` and `~/.codex` for Codex;
    2. writes `~/.claude/PRINCIPLES.md` from `AGENTS.md`, and a global `~/.claude/CLAUDE.md` that imports it;
    3. sets `core.hooksPath` to `.githooks` so the guards run;
    4. checks every file against `.claude/institution-manifest.txt`;
    5. checks each instruction file against its word ceiling in `.claude/rule-budget`.
3. Prove it with `./install.sh --check`. It changes nothing and exits 0 only when everything matches.
4. Open Claude Code in this folder. The session is Chief.

An existing `~/.claude/CLAUDE.md` that you wrote by hand is left alone; the installer only replaces files it generated.

## How the parts fit

1. `AGENTS.md` is the one hand-edited source. The installer generates the global rules from its first sections, so every repo on the machine loads Principles, Premises, Method and Codification.
2. Each project repo has its own `AGENTS.md` with a lead-scoped Institution. The `lead-role` skill says what goes in it.
3. Chief writes the work list when work starts, not when it returns, so work that never returns still leaves a row.
4. Review is done by someone other than the builder: a verifier asks whether it is right and clear, a challenger asks how it could fail.
5. `rule-budget` keeps the rules short: adding a rule means cutting or merging another.
6. The anomaly trailers on fix commits are the evidence `refine-instructions` reads to improve the rules.

## Make it yours

1. Edit `AGENTS.md` to fit how you work. The installer blocks growth past the word ceilings, and the push guard requires a `FOUNDER-RATIFIED:` line in any commit that changes it.
2. After editing any skill or agent, run `./install.sh --write-manifest`, commit, then `./install.sh`.
3. The `fleet` skill assumes a tool that starts and drives persistent sessions on your machines (`map`, `goal`, `send`, `read`, `up`, `restart`). Use your own and rename the verbs.
4. For the daily brief, copy `.claude/intel-sources.example.md` to `.claude/intel-sources.md` (it is gitignored) and list your feeds. Add calendar or mail connectors to `brief-runner` if you want those sections.
5. The "vault" is this checkout, synced across your machines (git carries the toolkit; a sync service such as Obsidian can carry the notes). The brief archives each day's notes under `archive/daily/`.
6. `refine-instructions/measure.sh` finds this repo at `$HOME/projects/chief`; set `CHIEF_REPO` if you cloned it elsewhere.
7. Keep notes, calendars and anything personal out of git. `.gitignore` allows only the toolkit; allow a push only to remotes you trust with `git config --add chief.allowedRemote <url>`.

## Licence

See `LICENSE`.
