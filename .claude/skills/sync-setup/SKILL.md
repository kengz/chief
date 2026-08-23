---
name: sync-setup
description: Set up cross-machine / remote sync for the chief vault so Chief runs at full parity on any box (laptop, beast, phone). Two layers — Obsidian Sync (paid; real-time content/notes, incl. phone) + git (free; the `.claude/` toolkit; content is git-ignored). Triggers on "set up sync", "run chief on a beast/remote", "enable Obsidian sync", "remote parity", or onboarding a new machine.
allowed-tools: Read, Write, Edit, Bash
---

# Sync Setup — remote Chief parity

The vault syncs across machines by **two layers, split by what they carry: Obsidian Sync moves the _content_ (notes), git moves the _toolkit_ (`.claude/`).**

- Content is **git-ignored** and never enters git, so even a repo leak exposes nothing personal.
- So a machine gets its **notes from Obsidian** and its **toolkit from git** — or, on the Obsidian-only route, Chief copies `.claude/` over the Tailnet.
- **Full parity needs the content layer, so the standard is `both`.** A pure-`git` box gets the toolkit only.

| Route | Carries | Sync | Cost | Needs |
|---|---|---|---|---|
| **Obsidian Sync** | **content / notes** (toolkit copied by Chief) | **real-time**, every device incl. phone | paid | — |
| **git** | **toolkit only** (`.claude/`; content is git-ignored) | non-real-time, agent-driven (commit · pull · push) | free | a **private** remote |
| **both** (standard) | content via Obsidian **+** toolkit via git | real-time notes **+** git toolkit & history | both | a **private** remote |

A headless box (no GUI) can do **either** — git natively, or Obsidian via the official **headless client** (`obsidian-headless`, Feb 2026+).

**No symlink trick:** Obsidian ignores dotfolders, so `.claude/` never rides Obsidian — fine, since the toolkit isn't synced content (git carries it, or Chief copies it). It stays a plain dotfolder everywhere; no `claude/` rename, no per-node symlink.

**Record the choice (do this last, on every machine).** The per-machine source of truth is `chief.syncMethod` — `git config chief.syncMethod <git|obsidian|both>`.

- It governs the **toolkit's** transport only; content always rides Obsidian. Chief reads it before any toolkit commit or push (CLAUDE.md › Version Control).
- `obsidian` ⇒ git-free, and Chief copies `.claude/` over the Tailnet. `git` or `both` ⇒ toolkit commit, then push. Unset is treated as `git`.
- Set it once a route is verified, so behaviour follows the choice instead of whatever git remote happens to exist.

## Git route (free)

The vault *is* a git repo; sync = commit + push/pull to a remote. It carries **only the toolkit** (`.claude/` + `CLAUDE.md`/`README`/`LICENSE`) — content is git-ignored and rides Obsidian — so a git-only box has the toolkit but no notes. Keep the remote **private** regardless (it's the user's vault repo).

- **Pre-push guard (mandatory safety).** `.githooks/pre-push` (committed) blocks pushing to any remote not in `chief.allowedRemote`. Per clone: `git config core.hooksPath .githooks`, then allowlist the private remote: `git config --add chief.allowedRemote <url>`. The decision to trust a remote is the user's — confirm it's private and theirs before allowlisting (see CLAUDE.md › Version Control).
- **Verify the guard is live** before treating a box as set up or pushing anything: `git config --get core.hooksPath` must print `.githooks` **and** `chief.allowedRemote` must be set. A fresh clone has the hook **off by default** (the config lives in untracked `.git/config`) — Chief sets both and refuses to push until they check out.
- **New box:** clone the private repo → run the config lines → verify the guard → `claude`. The clone brings the **toolkit**; the box gets its **content from Obsidian** (set up the content layer too — that's why the standard is `both`). Chief commits + pushes **toolkit** changes; other machines pull. On the git route, propagating a toolkit change *is* just a commit + push.
- **Stay current (propagation, both halves).** Push-on-commit is automatic (Chief never leaves a commit unpushed); the receiving side is **pull, and it's activity-driven** — every Chief session pulls at start, so a box gets the latest *when it triggers*. No pull cron or daemon: an idle box stays behind until next use, by design (CLAUDE.md › *chat is the interface*).

## Obsidian route (paid, real-time) — headless on a box

Obsidian Sync is real-time and reaches the phone, and runs **headless** on a server. It carries the **notes**; `.claude/` is a dotfolder Obsidian ignores **by design** — Chief copies the toolkit to any box that *runs* Chief (laptop, beasts), over the Tailnet. A view-only device (phone) needs no toolkit at all, so there's nothing to patch there.

Run per box (drive a remote box over ssh / `claude-fleet`, referencing `$VARS` so creds never hit logs or tmux scrollback):

1. **Install** (Node 22+): `npm config set prefix ~/.npm-global` (a known prefix the service unit can hardcode; ensure `~/.npm-global/bin` is on PATH), then `npm install -g obsidian-headless` → the `ob` CLI (interactive calls resolve via a **login shell**: `bash -lc "ob …"`).
2. **Log in** — creds from `~/.obs-creds.env` (transferred per the Credentials note; never echoed):
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
4. **File-types: leave at default** — there is nothing to toggle. The notes are all `.md` and sync by default; `.claude/` is a dotfolder Obsidian ignores, which is exactly right, because the toolkit does not ride Obsidian.
    - **Bring the toolkit over by copy.** On any Obsidian-route box that *runs* Chief, Chief copies `.claude/` from the command centre over the Tailnet.
    - **`settings.json` especially** — it holds the `additionalDirectories` permissions Chief needs to reach sibling repos, and stores only portable `~/projects/...` paths.
    - **Re-copy whenever the toolkit changes.** `settings.local.json` is the machine-only override and stays put.
5. **First sync — seed read-only, then switch to bidirectional.** Direction is a per-vault **config** (`ob sync-config --mode`), *not* a flag on `ob sync`. Three modes:
    - **`bidirectional`** — up and down; what a Chief-running box needs.
    - **`pull-only`** — download only, ignoring local changes.
    - **`mirror-remote`** — download only, reverting and deleting local changes.

    Seed in pull-only first, so nothing local-missing is read as a deletion:
   ```sh
   ob sync-config --mode pull-only --path ~/projects/chief
   ob sync --path ~/projects/chief        # one-shot pull
   ls ~/projects/chief                     # verify the content landed
   ```
   **Then go bidirectional — mandatory for any box that *runs* Chief** (a backup-chief writes the planner; under `pull-only`/`mirror-remote` its writes are silently reverted/deleted, which quietly breaks the backup):
   ```sh
   ob sync-config --mode bidirectional --path ~/projects/chief
   ob sync-status --path ~/projects/chief | grep -i 'sync mode'   # confirm: bidirectional
   ```
   (A pure receive-only device can stay `pull-only`; a backup-chief must be `bidirectional`.)

   > ⚠️ **DANGER — never go *bidirectional* from an EMPTY or stale local dir against a populated remote.** Bidirectional reads the missing files as *deletions* and **wipes the remote vault, and every synced device with it.**
   >
   > The pull-only seed above exists to prevent exactly this. Switch to bidirectional only once the dir holds the full vault.
   >
   > _Recovery: restore the dir from git or any intact node — a healthy node re-uploads and the cloud heals. After a git purge, only an intact synced node plus Obsidian's ~1yr file history can recover it._

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

7. **Install the wedge watchdog** (REQUIRED — the sync client can disconnect and sit in "Connecting…" forever; the process never exits, so `Restart=always` never fires, and devices silently go stale while local writes pile up — observed 06-11, a 5-hour silent wedge):
   ```sh
   mkdir -p ~/.local/bin ~/.local/state
   cat > ~/.local/bin/obsidian-sync-watchdog.sh <<'WD'
   #!/usr/bin/env bash
   # Restart obsidian-sync if no "Fully synced" in the journal for 10 minutes (wedged-connection guard).
   if ! journalctl --user -u obsidian-sync.service --since "-10 minutes" --no-pager 2>/dev/null | grep -q "Fully synced"; then
     systemctl --user restart obsidian-sync.service
     echo "$(date -u +%FT%TZ) restarted (no 'Fully synced' in 10m)" >> ~/.local/state/obsidian-sync-watchdog.log
   fi
   WD
   chmod +x ~/.local/bin/obsidian-sync-watchdog.sh
   cat > ~/.config/systemd/user/obsidian-sync-watchdog.service <<'UNIT'
   [Unit]
   Description=Watchdog: restart wedged obsidian-sync
   [Service]
   Type=oneshot
   ExecStart=%h/.local/bin/obsidian-sync-watchdog.sh
   UNIT
   cat > ~/.config/systemd/user/obsidian-sync-watchdog.timer <<'UNIT'
   [Unit]
   Description=Run obsidian-sync watchdog every 5 minutes
   [Timer]
   OnBootSec=5min
   OnUnitActiveSec=5min
   [Install]
   WantedBy=timers.target
   UNIT
   systemctl --user daemon-reload && systemctl --user enable --now obsidian-sync-watchdog.timer
   ```
   Wedge symptom to recognize: *"my planner isn't updated"* + service shows `active (running)` + journal silent for hours. Watchdog log: `~/.local/state/obsidian-sync-watchdog.log`.

## Troubleshooting — silent stranded files (daemon says "Fully synced" but a folder never uploaded)

**Symptom:** the founder doesn't see specific new notes on their devices, yet `ob sync-status` shows `bidirectional` and the journal keeps logging `Fully synced`.

Distinct from the wedge above — the connection is healthy, and the daemon simply never uploaded those files. Observed 07-02: a whole project folder created days after the daemon started was absent from the remote while the daemon reported fully-synced.

**Root cause:** the client's local tracking DB (`~/.config/obsidian-headless/sync/<vault-id>/state.db`) can record files as *synced without ever uploading them* — so the daemon skips them on every scan (it only re-hashes files whose content changed) and never notices they're missing from the remote. A long-running daemon that indexed the vault before a new folder existed is the usual trigger.

**Diagnose:** `journalctl --user -u obsidian-sync.service --since '1 day ago' | grep '<filename>'` — no `Uploading`/`Upload complete` line for a file that exists locally confirms it.

**Fix — force re-detection by changing content (a restart alone does NOT work; the DB still marks them synced):**
```sh
# for each stranded file — a trailing newline is enough to change the hash
for f in projects/<name>/*.md projects/<name>/docs/**/*.md; do printf '\n' >> "$f"; done
sleep 35   # the daemon scans ~every 30s
journalctl --user -u obsidian-sync.service --since '45 sec ago' | grep -E 'New file|Upload complete'
```
Each stranded file logs `New file … → Upload complete` (proving it was absent from the remote). A marker round-trip (append a line, upload, strip it, upload) leaves bytes pristine if the trailing newline matters.

**Prevention:** after landing a **new top-level folder** or a batch of new notes into the vault, don't trust `Fully synced` — verify the upload (`journalctl … | grep 'Upload complete'`). The wedge watchdog can't catch this (it keys on "Fully synced" being present, which it *is*).

## Going full-Obsidian (purge git) — optional, max-safety

Once a box syncs the **notes** via Obsidian and parity is verified bidirectionally — the toolkit being agent-copied either way — git is redundant for sync. To purge:

- `rm -rf .git` on each box (Obsidian Sync keeps ~1yr of file history as the version backstop).
- **Post-purge there is no `git restore`** — the only recovery becomes Obsidian's file history + an intact synced node. Verify at least one healthy node holds the full vault **before** deleting the remote.
- **Delete the private remote** for "extra safety" — removes the historical copy of sensitive content. **Destructive (≈90-day restore only) — get an explicit go first.**
- The brief-runner **never** git-commits content (it's git-ignored on every route) — it just writes the planner and Obsidian propagates it.

## Credentials

Obsidian account password + the vault E2E encryption password live in gitignored `.claude/secrets.env` (`*.env`, never committed; `.claude/` is excluded from Obsidian). Transfer to a box over the Tailnet (`ssh box 'umask 077; cat > ~/.obs-creds.env' < .claude/secrets.env`), reference the `$VARS`, never echo the values, and wipe the box's copy once `ob` has stored its session.
