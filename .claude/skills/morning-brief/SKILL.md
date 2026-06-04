---
name: morning-brief
description: Your daily planner brief — triggers on "good morning", "the brief", or the daily cycle. Dispatches a background brief-runner so you stay free, then relays the brief when it lands.
allowed-tools: Task
---

# Morning Brief

You are the supervisor — **don't run the cycle yourself. Dispatch it and stay free.**

1. Launch the **`brief-runner`** agent in the **background** (do not block on it). It runs the whole daily cycle — sync, archive, then its capability-gated checks inline (agenda, inbox, project status, intel), refresh the planner sections, persist per the machine's sync method — and returns the brief.
2. Immediately tell the user, in one line: **"🌅 Gathering your brief in the background — I'll drop it here when it's ready. What else?"** Then carry on with whatever they ask. You are NOT blocked waiting.
3. Relay it cleanly (no plumbing), in the brief-runner's returned order: lead with **Today** — **agenda** (the day's calendar), **inbox** (unread worth a human), then **intel** — then the user's **focus** (with a one-line **✅ Cleared today** if the sweep cleared anything), then **project status** — the forward-looking glance sections, in `planner.md` order. Surface the glance, not every heading (the planner also holds parked/ledger/scratch sections); follow whatever headings `planner.md` actually uses.
