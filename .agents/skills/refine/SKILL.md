---
name: refine
description: "The procedure for Refinement and the Iteration measure: at every landing (introspect, fix, unify) and weekly (classify, absorb, verify, converge); never wait to be asked."
---

# Refine the instructions

Method §4's six steps; take each the work needs. Introspect, fix and unify at every landing, the rest weekly.

1. **Introspect and fix** (§2).
2. **Classify** (§2).
3. **Absorb** (§3).
4. **Unify** (§3).
5. **Verify** (§4).
6. **Converge** (§4).

## 1. Measure, from the repo

1. [`measure.sh`](measure.sh) `<repo> <since> [base]` prints what Git holds, velocity first; its header lists the rest.
2. A measure enters only with the action it triggers; write the figures into the work list's measure row first.

## 2. Introspect, fix and classify

1. Anomalies are the evidence: each trailer says what was expected, what happened, and the failed assumption
   (`git log --grep='^Anomaly:'`, every mapped repo, since the last pass, plus any uncommitted). One the founder had to point out is the
   costliest; its trailer begins `founder-raised:`. The pass works these first, building the check that would have caught each.
2. Classify in one batch. A seat other than the author assigns each anomaly a class (misapplied, rule wrong or missing, principle) and a failure type, and counts types. The largest type is
   worked first; a misapplied rule gets a check.

## 3. Absorb and unify

1. Unify at each landing and at the weekly pass:
    1. Search the anomalies since the last pass for the shortfall's cause.
    2. From the second with one cause, fix the kind with one rule or check folded into the nearest, cutting what it makes redundant in the same change, never a whole rewrite. A lesson for the instance is not a fix.
    3. Report the net size change; growth names the anomaly that demanded it.
    4. A pass may change nothing; its changes go to the founder as one proposal.
2. A candidate passes Absorb without moving the failure elsewhere or adding more drag than the failure costs, or becomes a check or a script. Contain a failure at once if it must be; the rule stays provisional.
3. Names: each concept keeps one name across AGENTS.md, the skills, the scripts and the hooks (Clear); a concept under two names is an anomaly.

## 4. Verify and converge

1. One structural change at a time, its commit trailed `Provisional:` with what it should change.
   Its verdict commit names it, `Verdict: <hash> kept|reverted|inconclusive`; a pass commit carries
   `Refinement-pass:`. `measure.sh` shows a due pass and every change still without a verdict.
2. At each milestone, run Method §4's Converge, comparing by content, not wording; record the result beside the measure.
