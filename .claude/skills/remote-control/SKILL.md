---
name: remote-control
description: Make a fleet box remote-controllable from the Claude app / claude.ai/code — a "backup-chief" you drive from your phone. Covers the full-scope login it needs (the fleet setup-token is inference-only) and the per-session enable. Triggers on "remote control <box>", "drive <box> from my phone", "set up a backup chief", "turn on remote control".
allowed-tools: Read, Bash
---

# Remote Control — drive a box from your phone

Claude Code has a native **Remote Control** (`/remote-control <name>`): the session keeps running on its box while you drive it from the **Claude app › Code** tab or **claude.ai/code** on any device — terminal, phone, and browser share one live session. Use it to stand up a **backup-chief**: a standby chief on a fleet box you reach when your main machine is closed. The box stays drivable locally over `claude-fleet` too — same parity.

## The one gotcha — it needs a full-scope login

Remote Control **refuses the fleet's headless `setup-token`** (what `claude-fleet reauth` deploys) — that token is **inference-only** by design. The box needs a real **`claude auth login`** (subscription OAuth).

> A remote-control box is a **full-login box**. **Never `claude-fleet reauth` it** — that redeploys the inference-only token and silently re-breaks Remote Control. (See claude-fleet's README › *A note on auth*.)

## Enable it on a box (over `claude-fleet`/ssh — the parity)

1. **Swap to a full-scope login** — only if the box is on a setup-token (`claude auth status` shows `authMethod: oauth_token`):
   - Disable the inference override claude-fleet injected (it exports `CLAUDE_CODE_OAUTH_TOKEN`, which overrides any login): `mv ~/.config/claude-fleet/env ~/.config/claude-fleet/env.disabled`.
   - Log in via the headless **paste-code** flow — in a throwaway tmux window: `unset CLAUDE_CODE_OAUTH_TOKEN; claude auth login --claudeai`. It prints a URL → **the user opens it (signed into claude.ai), approves, and hands back the code** → feed the code into the prompt. `claude auth status` flips to `authMethod: claude.ai`.
2. **Restart the session** onto the new login: `systemctl --user restart claude-tmux` (on the box), then `claude-fleet up <host>` (from the command center) → `ready`.
3. **Enable it:** `claude-fleet send <host> "/remote-control <name>"`, then accept the **Enable Remote Control** menu (Enter). The pane shows `/remote-control is active` + a `claude.ai/code/session_…` URL.
4. **Connect & verify:** the user opens **Claude app › Code** — the session appears under `<name>`. Record the box's full-login status in the fleet ledger (`fleet.md`) so it never gets `reauth`'d.

## Durability caveats (state them honestly)

- **Per session, not per boot.** A reboot relaunches the session *without* Remote Control — re-enable with `claude-fleet send <host> "/remote-control <name>"`. To automate, the persistent unit *could* launch `claude --remote-control <name>` — **untested**; verify it auto-enables past the bypass gate before relying on it.
- **Renewal is unproven.** A full login unlocks Remote Control, but how long it lasts headless isn't pinned down (claude-fleet's note: headless can't refresh subscription OAuth). Watch `claude auth status`; if it lapses, re-run step 1. The trade is deliberate — full scope vs the setup-token's 1-year inference-only durability.
