---
name: refine-instructions
description: The procedure for Method's Iteration measure and Refinement in AGENTS.md, the rules as one theory under test. Runs on every lane watcher's periodic check, which fires on a clock even while lanes are busy; also when a slice lands, at day end, at an anomaly, and after the founder corrects how the work runs. Never wait to be asked.
---

# Refine the instructions

`AGENTS.md` Method states the laws; this is how to run Iteration's measure and Refinement.

## 1. Measure, from the repo

1. [`measure.sh`](measure.sh) `<repo> <since> [base]` prints what Git holds: landings per day,
   review-record lines per code line, tests on `main`, fix commits lacking an `Anomaly:` trailer, and
   the idiot index: the bar's wall time against the compute it truly needs. Add rounds per slice and hours from
   ready to landed from the project's institution log.
2. A measure enters only with the action it triggers. Write the figures into the work list's measure
   row before judging them.

## 2. Notice and classify

1. Anomalies are the evidence; each trailer says what was expected, what happened, and the assumption
   that failed. Find them with `git log --grep='^Anomaly:'` in every mapped repo since
   the last pass, plus any not yet committed.
2. Classify in one batch at the pass, not one by one. A seat other than the author assigns each
   anomaly a class (misapplied, rule wrong or missing, principle) and a failure type, then counts the
   types. The largest type is worked first; a misapplied rule gets a check and needs no second seat.

## 3. Absorb and unify

1. A candidate passes Refinement's Absorb step and does not move the failure elsewhere, or it becomes
   a check or a script. Contain a failure at once when it must be; the rule stays provisional.
2. The pass is weekly. Rules that share a cause become one rule, with the deletions in the same
   change, never a whole rewrite; a pass may change nothing. Changes go to the founder for ratification, one proposal per pass.
3. Delete process steps freely and count what comes back: about one deletion in ten should.
4. `install.sh --check` holds each file under `.claude/rule-budget`: an alarm; the principles decide.

## 4. Verify and converge

1. One structural change at a time, its commit trailed `Provisional:` with what it should change.
   Its verdict commit names it, `Verdict: <hash> kept|reverted|inconclusive`; a pass commit carries
   `Refinement-pass:`. `measure.sh` shows a due pass and every change still without a verdict.
2. At each milestone, a seat from the other provider derives the rules blind, from the principles,
   the premises and the anomalies alone. Compare by content, not wording: each divergence is either justified by
   evidence or cut. Record the result beside the measure.
