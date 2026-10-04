---
name: refine
description: The procedure for Method's Iteration measure and Refinement. Runs at each landing, at day end, at an anomaly, after a founder correction and after each hand-over. Never wait to be asked.
---

# Refine the instructions

## 1. Measure, from the repo

1. [`measure.sh`](measure.sh) `<repo> <since> [base]` prints what Git holds: landings per day,
   review-record lines per code line, tests on `main`, fix commits lacking an `Anomaly:` trailer,
   the toolkit's size change, and the idiot index: the bar's wall time against the compute it needs.
   Add rounds per slice and hours from ready to landed from the project's work list.
2. A measure enters only with the action it triggers; write the figures into the work list's measure row first.

## 2. Notice and classify

1. Anomalies are the evidence: each trailer says what was expected, what happened, and the failed assumption
   (`git log --grep='^Anomaly:'`, every mapped repo, since the last pass, plus any uncommitted). One the founder had to point out is the
   costliest; its trailer begins `founder-raised:`. The pass works these first, building the check that would have caught each.
2. Classify in one batch. A seat other than the author assigns each anomaly a class (misapplied, rule wrong or missing, principle) and a failure type, and counts types. The largest type is
   worked first; a misapplied rule gets a check.

## 3. Absorb and unify

1. A candidate passes Absorb without moving the failure elsewhere, or becomes a check or a script. Contain a failure at once if it must be; the rule stays provisional.
2. The pass is weekly. Rules that share a cause become one rule, with the deletions in the same change, never a whole rewrite; a pass may change nothing.
   It reports the toolkit's net size change, and growth names the anomaly that demanded it. Changes go to the founder for ratification, one proposal per pass.
3. Delete process steps freely and count what comes back: about one deletion in ten should.
4. `install.sh --check` holds each file under `.agents/rule-budget`: an alarm; the principles decide.
5. Names: each concept keeps one name across AGENTS.md, the skills, the scripts and the hooks (Clear); a concept under two names is an anomaly.

## 4. Verify and converge

1. One structural change at a time, its commit trailed `Provisional:` with what it should change.
   Its verdict commit names it, `Verdict: <hash> kept|reverted|inconclusive`; a pass commit carries
   `Refinement-pass:`. `measure.sh` shows a due pass and every change still without a verdict.
2. At each milestone, a seat from the other provider derives the rules blind from the principles,
   premises and anomalies alone. Compare by content, not wording: each divergence is justified by evidence or cut; record the result beside the measure.
