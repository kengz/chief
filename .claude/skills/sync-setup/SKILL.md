---
name: sync-setup
description: Set up cross-machine / remote sync for the chief vault so Chief runs at full parity on any box (laptop, server, phone). Two routes — git (free; whole vault in a private repo) or Obsidian Sync (paid; real-time, headless on a box). Triggers on "set up sync", "run chief on a box/server/remote", "enable Obsidian sync", "remote parity", or onboarding a new machine.
allowed-tools: Read, Write, Edit, Bash
---

# Sync Setup — remote Chief parity

The vault syncs across machines by **one of two routes** (or `both`). **Sync moves the notes; the toolkit (`.claude/`) is agent-managed** — Chief sets it up on each machine and propagates its own changes (by copy, or carried free by git), never a sync layer. So every route reaches full parity, by different means.

| Route | Carries | Sync | Cost | Needs |
|---|---|---|---|---|
| **git** | whole vault (notes **+ toolkit**) | non-real-time, agent-driven (commit · pull · push) | free | a **private** remote |
| **Obsidian Sync** | notes (toolkit copied by Chief) | **real-time**, every device incl. phone | paid | — |
| **both** | git + Obsidian together | git history/backup **+** real-time notes | both | a **private** remote |

A headless box (no GUI) can do **either** — git natively, or Obsidian via the official **headless client** (`obsidian-headless`, Feb 2026+).

**No symlink trick:** Obsidian ignores dotfolders, so `.claude/` never rides Obsidian — fine, since the toolkit isn't synced content (git carries it, or Chief copies it). It stays a plain dotfolder everywhere; no `claude/` rename, no per-node symlink.

**Record the choice (do this last, on every machine).** The per-machine source of truth is `chief.syncMethod` — `git config chief.syncMethod <git|obsidian|both>`. Chief reads it before any commit/push (CLAUDE.md › Version Control): `obsidian` ⇒ git-free (Write only, Obsidian carries it); `git`/`both` ⇒ commit (+push). Unset ⇒ treated as `git`. Set it once a route is verified so behavior follows the choice instead of whatever git remote happens to exist.

## Git route (free)

The vault *is* a git repo; sync = commit + push/pull to a remote. It carries the whole vault including personal notes, so the remote **must be private**.

- **Pre-push guard (mandatory safety).** `.githooks/pre-push` (committed) blocks pushing to any remote not in `chief.allowedRemote`. Per clone: `git config core.hooksPath .githooks`, then allowlist the private remote: `git config --add chief.allowedRemote <url>`. The decision to trust a remote is the user's — confirm it's private and theirs before allowlisting (see CLAUDE.md › Version Control).
- **Verify the guard is live** before treating a box as set up or pushing anything: `git config --get core.hooksPath` must print `.githooks` **and** `chief.allowedRemote` must be set. A fresh clone has the hook **off by default** (the config lives in untracked `.git/config`) — Chief sets both and refuses to push until they check out.
- **New box:** clone the private repo → run the config lines → verify the guard → `claude`. Chief commits + pushes the whole vault (notes + `.claude/` toolkit); other machines pull. On the git route, propagating a toolkit change *is* just a commit + push.
- **Stay current (propagation, both halves).** Push-on-commit is automatic (Chief never leaves a commit unpushed); the receiving side is **pull, and it's activity-driven** — every Chief session pulls at start, so a box gets the latest *when it triggers*. No pull cron or daemon: an idle box stays behind until next use, by design (CLAUDE.md › *chat is the interface*).

## Obsidian route (paid, real-time) — headless on a box

Obsidian Sync is real-time and reaches the phone, and runs **headless** on a server. It carries the **notes**; `.claude/` is a dotfolder Obsidian ignores **by design** — Chief copies the toolkit to any box that *runs* Chief (laptop, servers), over your network (ssh / Tailscale). A view-only device (phone) needs no toolkit at all, so there's nothing to patch there.

Run per box (drive a remote box over ssh / `claude-fleet`, referencing `$VARS` so creds never hit logs or tmux scrollback):

1. **Install** (Node 22+): `npm config set prefix ~/.npm-global` (a known prefix the service unit can hardcode; ensure `~/.npm-global/bin` is on PATH), then `npm install -g obsidian-headless` → the `ob` CLI (interactive calls resolve via a **login shell**: `bash -lc "ob …"`).
2. **Log in** — creds from `~/.obs-creds.env` (transferred per the Credentials section below; never echoed):
   ```sh
   set -a; . ~/.obs-creds.env; set +a
   ob login --email "$OBSIDIAN_EMAIL" --password "$OBSIDIAN_PASSWORD"   # + --mfa "$OBSIDIAN_MFA" if 2FA
   ob sync-list-remote                                                   # find the vault id/name
   ```
3. **Connect the vault** (E2E encryption password):
   ```sh
   ob sync-setup --vault "<name>" --path ~/projects/chief \
     --password "$OBSIDIAN_ENCRYPTION_PASSWORD" --device-name "<box>"
   ```
4. **File-types: leave at default** — nothing to toggle. The notes are all `.md` (cards, `planner.md`, `index.md`, areas) → synced by default. `.claude/` is a dotfolder Obsidian ignores, which is exactly what we want — the toolkit doesn't ride Obsidian. **Bring the toolkit over by copy:** on any Obsidian-route box that *runs* Chief, Chief copies `.claude/` from the command-center machine over your network (ssh / Tailscale) (`settings.json` especially — it holds the `additionalDirectories` permissions Chief needs to reach sibling repos; it stores only portable `~/projects/...` paths). Re-copy when the toolkit changes; `settings.local.json` is the machine-only override and stays put.
5. **First sync — seed read-only, then switch to bidirectional.** Sync direction is a per-vault **config** (`ob sync-config --mode`), *not* a flag on `ob sync` — three modes: **`bidirectional`** (up + down; what a Chief-running box needs), **`pull-only`** (download only, ignore local changes), **`mirror-remote`** (download only, *revert/delete* local changes). Seed in pull-only first so nothing local-missing is read as a deletion:
   ```sh
   ob sync-config --mode pull-only --path ~/projects/chief
   ob sync --path ~/projects/chief        # one-shot pull
   ls ~/projects/chief                     # verify the whole vault landed
   ```
   **Then go bidirectional — mandatory for any box that *runs* Chief** (a backup-chief writes the planner; under `pull-only`/`mirror-remote` its writes are silently reverted/deleted, which quietly breaks the backup):
   ```sh
   ob sync-config --mode bidirectional --path ~/projects/chief
   ob sync-status --path ~/projects/chief | grep -i 'sync mode'   # confirm: bidirectional
   ```
   (A pure receive-only device can stay `pull-only`; a backup-chief must be `bidirectional`.)

   > ⚠️ **DANGER — never go *bidirectional* from an EMPTY or stale local dir against a populated remote.** Bidirectional reads the missing files as *deletions* and **wipes the remote vault — and every synced device.** The pull-only seed above exists to prevent exactly this; switch to bidirectional only once the dir holds the full vault. _(Recovery: restore the dir from git or any intact node — a healthy node re-uploads and the cloud heals. After a git purge, only an intact synced node + Obsidian's ~1yr file history can recover it.)_

6. **Run it as a service** (persistent across reboots):
   ```sh
   mkdir -p ~/.config/systemd/user
   cat > ~/.config/systemd/user/obsidian-sync.service <<'UNIT'
   [Unit]
   Description=Obsidian headless sync (chief vault)
   After=network-online.target
   [Service]
   ExecStart=%h/.npm-global/bin/ob sync --continuous --path %h/projects/chief
   Restart=always
   RestartSec=10
   [Install]
   WantedBy=default.target
   UNIT
   loginctl enable-linger "$USER"
   systemctl --user daemon-reload && systemctl --user enable --now obsidian-sync
   ```
   Status: `systemctl --user status obsidian-sync` · logs: `journalctl --user -u obsidian-sync -f`.

## Going full-Obsidian (purge git) — optional, max-safety

Once a box syncs the **notes** via Obsidian and parity is verified bidirectionally — the toolkit being agent-copied either way — git is redundant for sync. To purge:

- `rm -rf .git` on each box (Obsidian Sync keeps ~1yr of file history as the version backstop).
- **Post-purge there is no `git restore`** — the only recovery becomes Obsidian's file history + an intact synced node. Verify at least one healthy node holds the full vault **before** deleting the remote.
- **Delete the private remote** for "extra safety" — removes the historical copy of sensitive content. **Destructive (≈90-day restore only) — get an explicit go first.**
- On an Obsidian-route box, the brief-runner does **not** git-commit content (no git); it just writes the planner and Obsidian propagates it.

## Credentials

Obsidian account password + the vault E2E encryption password live in gitignored `.claude/secrets.env` (`*.env`, never committed; `.claude/` is excluded from Obsidian). Transfer to a box over ssh (`ssh box 'umask 077; cat > ~/.obs-creds.env' < .claude/secrets.env`), reference the `$VARS`, never echo the values, and wipe the box's copy once `ob` has stored its session.
