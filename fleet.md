---
type: fleet
---

# 🛰️ Fleet

> Chief's durable memory of **dispatched work** — *intent + disposition*, written from the command center. The adapter is stateless, so this board is the only record of what Chief set in motion and why. See [claude-fleet](https://github.com/kengz/claude-fleet).

**How to read this:** a row is keyed by `host` (one project per host). `task` is a one-line intent summary — never the raw prompt (`send` is remote code execution; prompts live in tmux scrollback). **Disposition** is Chief's intent layer:

- `in-flight` — dispatched, not yet checked back
- `needs-review` — session is `ready` again; transcript awaits a `read`
- `blocked` — stuck on input Chief must supply, or an external dependency
- `landed` — done + verified (moved to **Landed** below)

**Live state is never written here.** A session's real status — `ready` · `busy` · `down` · `gate` · `crashed` · `unauth` · `unknown` · `unreachable` — is always re-probed with `claude-fleet status`. Roster / assignment lives in `claude-fleet map`.

## 🚀 In flight

| host | project | task | disposition | since | next |
|------|---------|------|-------------|-------|------|
| _box1_ | _example_ | _One-line intent summary of what you dispatched_ | in-flight | _MM-DD_ | _what you're waiting on_ |

_Standby: notes on idle boxes, backup-chief, the local watcher (`ops`). Live state & roster: `claude-fleet status` / `map`._

## ✅ Landed

| host | project | outcome | landed |
|------|---------|---------|--------|
| _box1_ | _example_ | _What shipped + how it was verified (PR # / commit)_ | _MM-DD_ |
