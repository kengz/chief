---
name: calendar-sync
description: Reconcile planner.md's agenda with today's Google Calendar, and mirror any calendar change you make. Low-stakes convenience, kept roughly current as you talk through the day — activity-driven, never a loop; optional and droppable. Triggers on "sync calendar", "what's on today", or when the day's schedule comes up.
allowed-tools: Read, Edit, Bash, ToolSearch, mcp__claude_ai_Google_Calendar__list_events
---

# Calendar Sync

Reconcile `planner.md`'s `### 📅 Agenda` with Google Calendar. **Low-stakes** — the user's calendar app is the primary source; the planner's agenda is a convenience, kept roughly current. **Optional** — drop this skill if a user doesn't want calendar in their planner; never assume it's wanted.

Activity-driven, never a loop: sync opportunistically when the day's schedule comes up as you talk, and mirror any event you add/move/cancel the same turn. Command-center machine only (boxes are read-mostly).

**Steps:**

1. Read the day + tz from `planner.md`'s `updated` frontmatter; shell `date` for any math.
2. List events — `ToolSearch` → `select:mcp__claude_ai_Google_Calendar__list_events`, then call it for the **primary calendar, today**, planner tz (`startTime`/`endTime` offset-less ISO **+** `timeZone`). Unreachable → leave the agenda as-is and say so.
3. Rewrite `### 📅 Agenda` (heading → next `###`/`##`): `- HH:MM — title`, all-day as `- All day — title`, `_Nothing scheduled._` if none. Touch only that section.
4. Persist by **writing `planner.md`** — it's git-ignored content carried by Obsidian Sync, so no commit/push (the Write is the durable record).
