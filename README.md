# Chief

A setup for a chief of staff running in [Claude Code](https://claude.com/claude-code) or the Codex application, using native tools for its own provider.

You are the founder. Chief is a long-running session that holds the purpose of each project, dispatches the work to project sessions, reviews what comes back, and keeps the few records a session must not lose.

## What is in it

1. **Rules:** `AGENTS.md` holds everything that binds a session.
    1. Principles: five axioms every rule must derive from.
    2. Premises: what the founder decides, given and not derived.
    3. Method: the Algorithm, Iteration, Self-improvement and Communication.
    4. Institution: the roles (founder, chief, lead, engineer), authority, dispatch, delivery and records.
    5. Codification: how the rules, skills and history are kept.
2. **`CLAUDE.md`:** exactly `@AGENTS.md`, so Claude Code and any other agent read the same file.
3. **Skills** in `.agents/skills/`, which Claude mirrors:
    1. `fleet`: native Codex project dispatch, CLI/server setup and measured admission, with retained adapter transport.
    2. `records`: the records and the daily planner run.
    3. `lead-role`: what a project's lead session owns, plus a deck kit for progress decks.
    4. `self-improvement`: practical guidance for introspection, classification, correction, unification and verification; no automatic hook, special trailer or metric ledger.
4. **Agents** in `.agents/agents/`, which Claude mirrors: `engineer`, `verifier`, `challenger` and `planner-runner`.
5. **Records** in `records/`: the work list and the approvals. `planner.md` and `projects/` are small templates for the founder's day and project cards.
6. **Push protection** in `.githooks/`:
    1. `pre-push` refuses conflict markers, GNU-only shell constructs, dated incident history in skills, unratified edits to `AGENTS.md`, toolkit changes without a `Reviewed-by:` trailer, a changed toolkit script whose own `--selftest` fails, and unlisted remotes.

## Install

You need `git`, `rsync`, `find`, `cmp`, `sha256sum` (or `shasum`) and `bash`.

1. Clone it: `git clone https://github.com/kengz/chief.git && cd chief`
2. Run `./install.sh`. It does six things:
    1. copies the skills and agents to `~/.claude` and to `~/.agents` and `~/.codex` for Codex;
    2. writes `~/.claude/PRINCIPLES.md` from `AGENTS.md`, and a global `~/.claude/CLAUDE.md` that imports it;
    3. sets `core.hooksPath` to `.githooks` so the push guard runs;
    4. checks every file against `.agents/toolkit-manifest.txt`;
    5. checks each instruction file against its word ceiling in `.agents/rule-budget`;
    6. retires dead managed hook commands while preserving unrelated hooks.
3. Qualify it with `./install.sh --check` in the actual login environment: require exit 0 with no `NOTE` or `NOT CHECKED`, including byte-for-byte installed-file and generated-core checks.
4. Open this folder in Claude Code or the Codex application. The session is Chief. Discover the native project and thread tools available on your installation before dispatching.

An existing `~/.claude/CLAUDE.md` that you wrote by hand is left alone; the installer only replaces files it generated.

## How the parts fit

1. `AGENTS.md` is the one hand-edited source. The installer generates the global rules from its first sections, so every repo on the box loads Principles, Premises, Method and Codification.
2. Each project repo has its own `AGENTS.md` with a lead-scoped Institution. The `lead-role` skill says what goes in it.
3. Chief keeps material decisions, original starts and ownership in the existing work list.
4. Review is done by someone other than the builder: a verifier asks whether it is right and clear, a challenger asks how it could fail.
5. `rule-budget` keeps the rules short: adding a rule means cutting or merging another.
6. Self-improvement uses evidence from real work; no special commit trailer or measurement schema is required.

## Make it yours

1. Edit `AGENTS.md` to fit how you work. The installer blocks growth past the word ceilings, and the push guard requires a `FOUNDER-RATIFIED:` line in any commit that changes it.
2. After editing any skill or agent, run `./install.sh --write-manifest`, commit, then `./install.sh`.
3. Read the `fleet` skill before dispatch. Native Codex tools discover projects, create sessions and read acceptance; approved SSH is infrastructure transport. Retained adapters have their own verbs and provider scope. Qualify approval policy, sandbox, runtime and measured capacity separately; this template installs no host resource limits or admission checker.
4. For the daily planner run, copy `.agents/skills/records/intel-sources.example.md` to `.agents/local/intel-sources.md` (it is gitignored) and list your feeds. Add calendar or mail connectors to `planner-runner` if you want those sections.
5. The "vault" is this checkout, synced across your boxes (git carries the toolkit; a sync service such as Obsidian can carry the notes). The planner run archives each day's notes under `archive/daily/`.
6. Keep project-specific runtime policies and records in their project or authorized dispatch, not in reusable toolkit components.
7. Keep personal notes and configuration out of public templates. `.gitignore` is a boundary, not proof that tracked files are public-safe; inspect the entire proposed publication, including record and planner templates.

## Publishing templates and syncing private vaults

1. This repository is a public template. A customized vault with personal records belongs in a private destination; never publish it merely because its toolkit is useful.
2. The push guard remains opt-in for the exact remote URL and runs its other checks before the allowlist. It cannot determine whether content is safe to disclose. Only after explicit owner authorization and independent review of the exact public template candidate may the publisher run `git config --add chief.allowedRemote <approved-template-url>` and push that reviewed candidate through the unchanged guard.
3. For a private vault, approve only its intended private destination. Never copy private records, fleet identities, addresses, credentials, configuration or incident evidence into a public adaptation. Refusal holds publication: report it and obtain a decision; do not disable hooks, change destination or retry through another route.
4. The public adaptation documents project-scoped resource policy and actual containment. It does not deploy limits, prove a particular host reliable, or promise automatic dispatch interception.

## Licence

See `LICENSE`.
