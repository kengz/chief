---
name: review
description: How a review is convened and run — the four lenses and what each asks, one lens per reviewer, which seats an artifact needs, how a split panel is adjudicated, and what a verdict must carry. Load before reviewing anything, before commissioning a panel, and before a claim is banked or shipped. "Review" names a structure, never a careful read-through.
---

# Review

**"Review" is a trigger word.** Whoever says it — *review this, have it reviewed, let me review* — is asking for the structure below, not for someone to read the thing again carefully.

## Who convenes, and who sits

1. **The level above convenes. The author never sits.**
    - A lens is a stance a peer puts on for someone else's work.
    - **A session reviewing its own work wears none.**
2. **Give each reviewer one lens.** Three with the same lens find one problem three times.
3. **Route every seat to an independent reader.** An author re-reading cannot see the sentence they meant instead of the one they wrote.
4. **Which seats an artifact needs is the convenor's call, not a fixed quota. A full panel costs multiples of a solo pass — enough that the roster is a spending decision, not a thoroughness one. Convene it where being wrong is expensive.**
    - Cheap and reversible work may stop at one seat.
    - **Anything that authorises spend, ships outside the team, or gets built on takes the full panel.**
    - **The adversary is not optional wherever the decider benefits from the outcome.**
5. **The seats the convenor picked run in parallel, and no seat assumes another has run.** A seat that cannot proceed without a figure verified files that as a finding rather than presuming it was.
    - **Correctness still outranks communication when the findings come back.** An editor finding on a claim the fact-checker rejected is spent effort: discard it, rather than acting on it.
6. **The roster is written before the panel runs, and reconciled before it closes.** Every seat dispatched is accounted for as `returned` · `returned nothing` · `did not return`.
    - **`did not return` blocks banking exactly as a fail does.** A seat that never reported and a seat that read the artifact and found it clean are the same silence, and an omission reads as a pass to everyone downstream.
    - **Every verdict is persisted to a file before the panel closes** — written by the seat as its last action, or by the convenor on receipt where the seat is read-only by design. From outside, a finished seat and a dead one are indistinguishable.

## The four lenses

**Each lens presses on all six principles from a different side, and every file says which side is its own.** `Correct` is reached three ways — the fact against its source, the argument in its domain, the claim against someone trying to break it — and the editor carries the five that decide whether any of it lands. Name the lenses that ran, so a reader can see which side went unpressed.

7. **Peer / expert — is the reasoning sound in its domain?** Runs as the `peer-reviewer` agent.
    - **One seat per domain the claim touches.** A claim spanning two needs both, separately, never one reviewer holding both.
    - **Ask an expert about claims, not prose.** Sent to edit wording they will edit wording, and the error they were there to catch survives.
8. **Adversary — where are the holes?** Runs as the `adversary-reviewer` agent.
    - Argued to win, and *"it stands"* is an acceptable verdict.
    - **It fires on observable triggers, never on the decider noticing their own stake:** relaxing a gate that has never rejected anything · authorising spend · reversing one's own prior decision · adopting a conclusion one previously proposed.
9. **Fact-checker — is every number, name, date, citation and link what the source actually says?** Runs as the `fact-checker-reviewer` agent.
    - **Sound reasoning over a wrong figure is still wrong**, and a figure that was right once goes stale silently.
    - **Open every link.** Resolving is not supporting: a live page that does not say the thing is worse than a dead one, because nobody re-checks a link that loads.
    - **Cite what you read, at the version you read it.** A branch, an edited doc or a page behind a redirect needs a pinned reference, or the claim expires without notice.
10. **Editor — could someone outside the bubble follow it, and what can be removed with nothing lost?** Runs as the `editor-reviewer` agent.
    - **Clear and concise are one job.** A shorter draft that dropped the sentence carrying the point is not clearer, and one that explains itself three times is not either.
    - **Answer in what did not land and in items cut, never in words saved.**
    - **Merging ideas into one longer line is not cutting.**

## The question nobody asks for

11. **Every review also asks whether the thing still serves the level above it** — the work against its spec, the spec against the roadmap, the roadmap against the north star.
    - Nobody ever requests this, which is exactly why it is never optional.
    - **A perfectly executed artifact answering a question that no longer matters is the failure this catches**, and no other lens is looking for it.

## What may be banked

12. **A claim is measured, not narrated**, and it climbs these rungs before anything is built on it. Skipping one is provisional, and the debt falls on whoever builds on it.

| # | check | catches |
|---|---|---|
| −1 | instrument runs end-to-end on the execution target, before anything is costed | a plan costed for software nobody wrote · import-compatible mistaken for execution-compatible |
| 0 | calibrated on a named known-good input and a named null input, both stated in the artifact | *"nothing passed"* that means *"this measures nothing"*, and its twin that passes everything — fail ⇒ every verdict void |
| 1 | bar fixed before the result exists — something could fail it *and* pass it | gates that cannot reject; gates that cannot accept |
| 2 | artifact pinned at a commit, tracked and pushed | ruling on a file still being written |
| 3 | reproduced by a second party | agreement mistaken for replication |

13. **Rungs 0 and 1 are the adversary's**, and its file already asks both — whether the instrument could have said otherwise is the one question the fact-checker's *"the source says 19×"* and the peer's *"take 19× as given"* both step over. **No seat approves above rung 0 unless someone reached rung 0.** Approval means someone ran the thing against its own stated criterion; if nobody did, the verdict is `not measured`, never `approve`.
14. **Rungs −1, 2 and 3 are entry criteria, not verdicts.** The convenor checks them before spawning any seat, because a panel reviewing an unpinned artifact is reviewing a moving target.
    - **−1 and 2 are cheap and blocking**: the instrument runs on the target, and the artifact is pinned at a commit. Put the commit in the dispatch.
    - **Rung 3 is a scheduling call** — independent reproduction is commissioned, not asked of a lens.
15. **Name the failure class before you judge an instrument.** A gate that cannot fail, a
    fixture structurally incapable of exhibiting the defect it tests for, a metric that
    correlates with its own units — these recur, and naming which one you are looking at is
    faster than deriving it again.
16. **Four statuses, not three: pass, fail, not measured, INCONCLUSIVE.** Inconclusive means measured and below resolution; folding it into fail is how an under-powered null becomes a finding.
17. **A pinned number carries an identity fingerprint against drift and its resolution against noise, inside the artifact.** A citation without both is a rumour.
18. **Conclusion and mechanism are separate claims.** The *why* is where errors concentrate; mark it hypothesis unless the mechanism itself was tested.
19. **Withdrawing a claim is free. Asserting the negative is not**, and a wrong refutation is worse than an open question: it closes the line and nobody looks again.

## Verdicts

20. **A lens approves when the artifact clears its stated bar and is better than what it replaces.** Not when it is perfect.
21. **A rejection names the bar or the clause that fails.**
22. **A rejecting verdict returns the work to build.** A split panel is the convenor's to adjudicate, never the author's to break in their own favour.
23. **A finding carries the bound of what the seat could see, and the convenor may not widen it.** A seat that searched one machine found something about one machine.
    - **The seat states its bound. Relaying it without the bound is the convenor's error, not the seat's** — both halves fail separately, so name both.
    - **A finding that would change a decision is re-checked at the scope the decision covers**, before anything is dispatched on it.
24. **Name the lenses and the domains that ran.** An unlabelled "reviewed" is worth nothing, and a missing domain is only visible when the present ones are listed.
25. **A lens reporting zero findings still reports.** A yield of zero is what tells you the lens was calibrated, or that it was the wrong lens for this artifact. Silence tells you neither, and a seat that found nothing and a seat that never ran read identically.

## After the round

26. **Every round leaves defensive residue, so sweep it before the next one.** A reviewer misreads a line, the author adds a clause to prevent that misreading, the misreading is forgotten and the clause stays. Repeat five times and the artifact is arguing with its own history instead of saying what it means.
    - **The tell is a sentence whose second half explains the first** — *"X, because Y"*, *"X, so that Z cannot happen"*, *"X, not W"*.
    - **The test: delete the justification and read the rule alone.** If it still binds, it always did.
27. **Ship what survives.** A line no reviewer defends is a line to cut.
28. **A finding worth keeping becomes a fingerprinted check with a negative control, never a paragraph.** Rules decay; checks fire.
    - **The fix for a defect disproportionately contains that same defect**, so run its own fingerprint against the fix.
    - **And the set prunes itself: a check is deleted when a test built to trip it does not.** Without this half, every finding adds and nothing ever leaves.
29. **Read the result as the finished state, not as the edit history.** Say what is, never what it used to be.
