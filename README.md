# Chief

A setup that turns [Claude Code](https://claude.com/claude-code) into your **chief of staff**. Two jobs:

1. **Second brain** — Chief's memory: an Obsidian vault of Markdown notes (planner, project cards, a daily brief) you mind-sync to.
2. **Right hand** — Chief's control plane: the `.claude/` toolkit (skills, agents, tools) and the claude-fleet adapter, driving Claude across your projects and machines — `attach` to take over any session.

The second brain grows as you mind-sync to it; Chief grows its own capabilities as the work calls for it.

## Usage

Setup — just tell Claude Code to set up your chief vault (it'll fork or clone [this repo](https://github.com/kengz/chief) — a plain zip-download works too, but only for a single machine with no sync), then run `claude` from inside it. That's Chief.

From there, it's mostly just chat — a few threads worth naming:

- **Brief** — say *"morning"* for your daily brief: Chief archives yesterday, clears done items, and refreshes Today (agenda + inbox), intel, and project status into `planner.md`.
- **Chat** — talk to Chief about anything (*"what's next?"*, *"add this doc"*); it lands in your vault — your **planner** (`planner.md`: Today, Focus, Projects), to read and edit.
- **Dispatch** — just ask: *"fix the failing tests in project X"*, *"run something on a box"*. Chief works in your real repos and machines, never the vault.
- **Take over** — ask Chief for a session's handle and `attach` to take the wheel.

**Handy commands:**
- **`/remote-control`** — drive a session running on a box from the Claude app (or claude.ai/code), on any device — your phone as a remote. Chief sets it up for you.
- **`/goal`** — hand Chief a bounded objective; it self-drives to completion, checking in only as needed (this is how it runs the fleet).
- **`/loop`** — run a prompt or check on a recurring interval (polling, babysitting a job).

**Prerequisites:** [Claude Code](https://claude.com/claude-code). Optional: [Obsidian](https://obsidian.md) for real-time sync to all your devices, a **private** GitHub repo to sync across machines, and [claude-fleet](https://github.com/kengz/claude-fleet) for a remote fleet.

### Sync

The vault is just a folder, so **sync is optional** — one machine needs none. To run across machines, **Chief sets up sync for you** (the `sync-setup` skill). Two routes, for reference:

- **git** — free, not real-time. Carries the **whole vault (notes + `.claude/` toolkit)** to your **private** repo.
- **[Obsidian Sync](https://obsidian.md/sync)** — paid, real-time, reaches your phone. Carries **content only (the notes)**; the `.claude/` toolkit rides git or is copied by Chief.

### Fleet (optional)

To drive Claude across other machines, just ask Chief to **set up the fleet** — it clones [claude-fleet](https://github.com/kengz/claude-fleet) (a separate repo, not copied into this vault), puts its CLI on PATH, and writes your `~/.config/claude-fleet/fleet.conf` (asking only for host details it can't assume). From then on the **Fleet Dispatch** protocol in `CLAUDE.md` just works; local sessions need no remote at all.

The one bit you do by hand (optional): to also load claude-fleet as a Claude Code **plugin** — interactive slash commands an agent can't run for you — type:

```
/plugin marketplace add kengz/claude-fleet
/plugin install claude-fleet
```

That loads the claude-fleet skill alongside the CLI. It's optional — Chief operates the fleet from the CLI alone.

## How it works

**Chief's premise:** native Claude Code features + good general principles + a few salient tools and the vault structure — not a pile of bespoke per-task tooling.

At its simplest, Chief is just the **second brain** — a Markdown vault you read, write, and get briefed from; a complete way to use it on its own, no agents or machines. One repo:

```
chief/
├── CLAUDE.md       its instructions (ends with @index.md)
├── index.md        the always-loaded map (MOC)
├── planner.md      your planner — Focus + today's brief
├── fleet.md        dispatch ledger — what's in flight across machines
├── inbox/          raw capture
├── projects/       one thin card per sibling repo
├── areas/          ongoing life threads
├── archive/daily/  dated planner.md history
└── .claude/        skills · agents · settings (the toolkit)
```

The vault (`planner.md`, `projects/`, `inbox/`, `areas/`) is the memory; `CLAUDE.md` + `.claude/` (derived from [good-code](https://github.com/kengz/good-code)) are the right hand's instructions and tools. Code never lives here — Chief reaches your repos through thin *cards*.

The **right hand** is Chief running work for you — directly in the conversation, or by driving Claude sessions where your code and machines live. You already run Claude Code a session per project (*terminal → `claude`*); Chief drives those, **local by default**, stretching across machines for a fleet:

```
  base:                            claude   you run it (local)
  remote:             ssh → tmux → claude   on another machine
  chief:  adapter → [ssh →] tmux → claude   Chief drives it
```

Wrap a Claude session in `tmux` (plus `ssh` for a remote box) and it becomes a durable surface. Chief drives that **same** session through its adapter ([claude-fleet](https://github.com/kengz/claude-fleet), a stateless CLI + plugin) — exactly as you would by hand — so either of you can `attach` and take over, anytime.

```mermaid
flowchart TD
    you([You]) -->|talk| chief["chief (claude)"]
    chief -->|remembers| vault[("second brain<br>Obsidian · git vault")]
    chief -->|drives| adapter["right hand<br>claude-fleet adapter"]
    adapter -.->|attach| sessions["Claude sessions<br>[ssh →] tmux → claude"]
    you -.->|attach| sessions
```

Going remote is optional — it just adds the `ssh` hop; the full protocol lives in `CLAUDE.md`'s **Fleet Dispatch**. Standing up a box — Tailscale access, a hardened `sshd`, your dotfiles, and Claude Code in `tmux` — is standard setup Chief handles for you, no special repo required.

## Make it yours

That's it — it's **yours**. Once you understand it, it's just Claude as your chief of staff: a second brain for your notes, a right hand on your repos and machines — one that grows the more you use it. Grow the vault, add the skills, agents, and tools your work needs, make it your own.

## License

[MIT](LICENSE) © kengz
