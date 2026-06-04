---
status: active
path: ~/projects/example
remote: https://github.com/you/example.git
tags: [example]
---

# example

> A thin card pointing at a sibling repo — Chief reads this, then dispatches work into the real repo. The card is *about* the repo; it never holds the repo's code or docs.

## Now

- Replace this with your real projects: one folder `projects/<name>/` per sibling repo, each with a `status.md` card like this.

## Notes

- `path` is where the repo lives on disk (portable `~/projects/...`); `remote` is its git URL. Chief expands `~` and dispatches a team into that absolute path.
- Also add the repo's path to `.claude/settings.json` → `permissions.additionalDirectories` so Chief is allowed to reach it.
