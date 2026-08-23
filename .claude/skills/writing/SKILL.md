---
name: writing
description: The house writing style — the 6 Principles, structure over sprawl, list and nesting rules, vocabulary, the shape of a report, and the panel review that makes a draft good. Medium-agnostic — notes, docs, messages, commits, reports, decks, emails. Load before writing anything a person will read, whenever a draft feels long or dense, and when deciding how to structure a document.
---

# Writing

## 1. The 6 Principles

Framed for code, and they govern writing identically.

**This is their one home.** `CLAUDE.md` names them and points here.

Full writeup, pinned at the commit these six were read from: [good-code/PRINCIPLES.md](https://github.com/kengz/good-code/blob/043ddbf79508fd18da3b9373810bbf5e2156492d/skills/good-code/PRINCIPLES.md).

1. **Consistent** — the same concept named the same everywhere makes work searchable, replaceable, predictable.
2. **Correct** — constructed from known truths, not debugged into shape.
3. **Clear** — intent obvious from naming and logic alone. If a comment is needed to explain *what*, it's not clear enough.
4. **Concise** — nothing left to remove. Brevity is fewer concepts to hold, not fewer characters.
5. **Simple** — fewest moving parts, easy to explain, cheap to maintain.
6. **Salient** — essential enough to be used widely, fundamental enough to last.

## 2. Structure over sprawl

7. **Never write long paragraphs.** Nothing is salient inside a wall, tall or wide.
8. **A long line joined by `·` or `—` is sprawl with the line breaks removed.** Five ideas on one line removes zero concepts and adds parsing work.
9. **The fix is always structure, never compression.** Cut what is not needed, then nest what survives. Vertical space is free. Parsing effort is not.
10. **Every level doc uses one section order, so a reader who knows one knows them all**: what you own · dispatch · review · what reaches the level above · budget and cost.
    - **A section with nothing to say at that level is dropped, never padded.** Its absence is the claim that another level owns it.

11. **Before adding a clause, ask whether a capable worker would do it anyway.** If yes it is reassurance, not a rule, and it costs attention it does not repay.
    - **Three things earn a place**: a preference nobody could guess · a boundary on who decides · a failure that already happened, carrying its fingerprint.

## 3. Lists and nesting

12. **Numbered by default.** So a reader can reference item 9 rather than "the bit about walls." Bullets only where order and reference genuinely do not matter.
13. **One idea per line, short enough to read without scrolling.** Never fold a list inline as `(1)… (2)… (3)…`.
14. **Nest detail on the spot.** The parent line carries the claim, its children the evidence and exceptions.
    - **Indent exactly 4 spaces per level. Always.** Not 2, not a tab, not aligned to the bullet.
    - **A sub-list stays a sub-list.** It does not restart numbering or drift into prose.
    - **Depth stops at three levels.** A fourth means the parent is really a section: promote it to a heading.

## 4. Vocabulary

15. **Write the result, not the label.** *"A bounded null"* hides the finding. *"The test could not have shown anything either way"* carries it.
16. **Could a sharp person who has never seen this work read the line and know what happened?** If they would have to ask what a word means, it is not finished. Jargon reads as precision and functions as concealment. It lets a half-understood result pass as a finished one.
17. **A term the reader has not used first is not available**, unless it is defined in the same sentence and earns the space.
18. **Avoid inflated stock phrases** like "load-bearing" and kin. Use the plain word: core, essential, decisive.
19. **Audience sets the boundary.** Specialists writing to specialists may use the domain's vocabulary. Anything reaching a non-specialist may not.

## 5. Reports

20. **Cut framing, not content**: no preamble, no headers with paragraphs under them, no closing reflection. Reflection and self-assessment are not a report. Include them only when asked.
21. **Both directions are defects.** Prose that must be read to be understood, and telegram so compressed the reader cannot reconstruct what happened. A line earns its length by carrying information, never by carrying tone.
22. **A report to someone senior is capped at what they will actually read**, roughly 20 items and 700 words. Past that they skim, and skimming picks the wrong line.
23. **Rewrite it whole. Never append.** A living report grows by accretion, because adding a correction is cheaper than re-deciding what belongs. It always ends up twice the length nobody asked for. Every update re-derives the whole list from scratch. Items that mattered yesterday and not today are cut, not demoted.

## 6. Review and refinement

**A first draft is never the deliverable. Writing is made good in review, not in drafting.**

**Load the `review` skill.** It holds the four lenses, what each asks, who may sit, and how a verdict is reached — for a draft exactly as for a build. What follows is only what writing adds.

24. **Correctness runs before communication.** There is no point polishing a claim that is wrong.
25. **Writing needs more of the fact-checker than code does.** Prose can carry a wrong figure indefinitely without failing anything.
26. **Refine continuously, never only at the end.** Adding without realigning turns a document incoherent. A piece revisited three times while short beats one polished once when long.

