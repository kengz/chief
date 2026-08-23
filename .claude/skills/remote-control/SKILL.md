---
name: remote-control
description: Make a fleet box remote-controllable from the Claude app / claude.ai/code — a "backup-chief" you drive from your phone. Covers the full-scope login it needs (the fleet setup-token is inference-only) and the per-session enable. Triggers on "remote control <box>", "drive <box> from my phone", "set up a backup chief", "turn on remote control".
allowed-tools: Read, Bash
---

# Remote Control — drive a box from your phone

Claude Code has a native **Remote Control** (`/remote-control <name>`): the session keeps running on its box while you drive it from the **Claude app › Code** tab or **claude.ai/code** on any device — terminal, phone and browser share one live session.

Use it to stand up a **backup-chief**: a standby chief on a fleet box you reach when your main machine is closed. The box stays drivable locally over `claude-fleet` too — same parity.

## The one gotcha — it needs a full-scope login

Remote Control **refuses the fleet's headless `setup-token`** (what `claude-fleet reauth` deploys) — that token is **inference-only** by design. The box needs a real **`claude auth login`** (subscription OAuth).

> A remote-control box is a **full-login box**. **Never `claude-fleet reauth` it** — that redeploys the inference-only token and silently re-breaks Remote Control. (See claude-fleet's README › *A note on auth*.)
>
> ⚠️ **Never `claude-fleet restart` it either.** `restart` relaunches a *plain* `claude`, dropping the `--remote-control <name>` flag — the device silently vanishes from the Claude app (the login stays fine, but RC is off). To restart an RC box, go through its unit: **`systemctl --user restart claude-tmux`** (carries the flag) → then **`claude-fleet up <host>`** to clear the bypass gate.

## Enable it on a box (over `claude-fleet`/ssh — the parity)

1. **Swap to a full-scope login** — only if the box is on a setup-token (`claude auth status` shows `authMethod: oauth_token`):
   - Disable the inference override claude-fleet injected (it exports `CLAUDE_CODE_OAUTH_TOKEN`, which overrides any login): `mv ~/.config/claude-fleet/env ~/.config/claude-fleet/env.disabled`.
   - Log in via the headless **paste-code** flow — in a throwaway tmux window: `unset CLAUDE_CODE_OAUTH_TOKEN; claude auth login --claudeai`. It prints a URL → **the user opens it (signed into claude.ai), approves, and hands back the code** → feed the code into the prompt. `claude auth status` flips to `authMethod: claude.ai`.
2. **Restart the session** onto the new login: `systemctl --user restart claude-tmux` (on the box), then `claude-fleet up <host>` (from the command center) → `ready`.
3. **Enable it:** `claude-fleet send <host> "/remote-control <name>"`, then accept the **Enable Remote Control** menu (Enter). The pane shows `/remote-control is active` + a `claude.ai/code/session_…` URL.
4. **Connect & verify:** the user opens **Claude app › Code** — the session appears under `<name>`. Record the box's full-login status in the fleet ledger (`fleet.md`) so it never gets `reauth`'d.

## Durability caveats (state them honestly)

- **Automate it via the launch flag.** Bake `--remote-control <name>` into the persistent unit's launch command (`ExecStart=… exec claude --remote-control <name>`), and it **re-arms on every boot and restart** with no manual `/remote-control` step.
    - After the unit (re)starts, run `claude-fleet up <host>` to clear the bypass gate → `ready`.
    - The one catch: a plain relaunch — including **`claude-fleet restart`**, see the warning above — bypasses the unit and drops the flag. Always restart through the unit.
- **Pair it with `--continue` so the chief keeps its memory across crashes.** Unit launch command: `claude --continue --remote-control <name> || exec claude --remote-control <name>`.
    - Every boot and restart **resumes the existing conversation** instead of starting blank; the `||` fallback covers a box with no prior conversation.
    - A large resumed session pauses at a "resume from summary / full as-is" menu. Accept **summary** — full re-ingests the whole transcript against plan limits — and it is one Enter, or one `claude-fleet up <host>`, away.
- **Reattach beats re-enable.** On relaunch the session reattaches to its existing remote session and un-archives it server-side — the app shows the same `<name>` entry, not a new one.
    - If the app shows it disconnected after an outage, restart through the unit and refresh the Code tab; check the archived list too.
    - **Never paste `/remote-control` into a running session via tmux** — it reaches the model as a prompt, not the TUI.

## A slash command sent through the remote channel arrives as plain text

**A `/goal` driven from the app does not become a contract.** It lands as an ordinary message whose
text happens to begin with a slash, so the session reads it and does not bind to it.

- **Dispatch a contract through tmux, never through the app.**
- **From a phone, send an instruction rather than a contract** — plain text works on either channel.
