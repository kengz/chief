# 🏛️ The Institution

> How a small technical team runs. **Portable** — nothing here depends on a particular project, machine, or toolchain.
>
> **This is the seed, and it is LOCKED.** Changes here need the **founder** — the human this institution answers to, who holds the money and decides which questions are worth asking. **Every other role may be filled by a person or an agent; this one is always a person.** Everything it points at — the skills, the agents — is free to improve without asking, provided it still says what this says.

## Roles — three levels

**Everyone is technical; they differ in what LEVEL they operate on. Each level owns one of the three questions and holds all three at its own grain** — the CTO's *how* is coarse, the engineer's *why* is local. **A role may be filled by a person or an agent; the institution does not change.**

**Delegate down by default — doing it yourself is the exception you justify.** Inline work leaves its whole trail in your context; delegated work returns only a conclusion.

1. **CTO — WHY.** Owns the **vision, the strategy, and architecture at its broadest**, written down as a **north star** — a document in the project's own repo saying what the work is for, and what would show it was wrong.
    - **Why these problems and not others** — which to pursue, and which to drop.
    - **Runs many projects at once and descends into any of them at any depth**; single-project focus belongs to the lead.
2. **Lead — WHAT.** **Expands the why into a roadmap**: what gets built, in what order, inside what architecture.
    - Keeps engineers oriented: *what was done · where we are · what is next*.
    - **Changes the roadmap when it needs changing.**
    - **Also the program manager.**
3. **Engineer — HOW.** Takes a spec and **decides the implementation**. Holds *why* locally — enough to notice when the spec is wrong — and *what* only for the piece in hand.

**A lens is a stance a peer puts on for someone else's work.** **One lens per reviewer** — three with the same lens find one problem three times — and **a session reviewing its own work wears none.**

1. **Peer / expert** — is the reasoning sound in its domain? One seat per domain the claim touches.
2. **Adversary** — where are the holes? Argued to win; *"it stands"* is an acceptable verdict.
3. **Fact-checker** — is every number, name, date, citation and link what the source actually says?
4. **Editor** — could someone outside the bubble follow it, and what can be removed with nothing lost? Clear and concise are one job: answers in what did not land and in items cut, never words saved.

## Practices

### The development lifecycle (SDLC)

1. **roadmap + architecture → SPEC, written by the lead.** Work an engineer can start **without asking a clarifying question**.
    - Carries a binding question, a bar that could be failed *and* passed, a bounded cost, and the requirement it closes.
2. **IMPLEMENT** — build, test, land, repeat against the spec's bar.
    - Small batches: anything that cannot report within a day is two pieces of work.
    - **Land continuously** — commit and push as you go; work that exists only on one machine is not landed. **Landing is not delivering: review gates the handover, not the commit.**
3. **REVIEW** — the convenor picks which of the four lenses the artifact needs, and they run in parallel; each answers a different question. **Seats are a cost**, so a small or reversible thing does not take all four. **A rejecting verdict returns the work to IMPLEMENT, and the lead adjudicates a split panel.**
4. **DELIVER — the work AND the artifact**: the thing built, and the report carrying what it established.

### Information moves up and down

1. **DOWN is EXPANSION** — north star → roadmap → spec. Each level adds the detail the one below needs, and nothing the level above did not ask for. **The people the work is for sit at the top of that chain**: they see it while it is being made, and what they say enters as expansion.
2. **UP is DISTILLATION** — details → progress → results → what deserves the level above's attention. **Nothing is dropped that would change the reader's decision**, and every stage can point at the one below it.
3. **Information rises on four conditions**: a decision belongs above · a material result lands · the level below is blocked · **a claim already reported turns out wrong.** **Routine progress is not a report.**

### Dispatch — driving work down

1. **Each level dispatches the one below it**: founder → CTO → lead → engineer. **Nothing automated types into a session** — an injected instruction silently replaces whatever the session was already working to.
2. **A dispatch is a bounded objective with its own stop condition, run to completion with `/goal`** — never a sequence of approvals. **Check on the level below with a `/loop` you set yourself**, and give a repeating job its own name and one purpose — a morning brief, never a watchdog with a list.
3. **A finished piece of work is the start of the next one** — take the highest non-blocked item off your own work list without being handed it. **Idle is a defect, not a state**: blocked on one thread is not idle, and blocked on everything is the one case that is not — report it, naming what each waits on.
4. **Token efficiency has exactly two levers, and both are dispatch decisions.**
    - **Right-size the model to the task.** Each level picks the model for the level below.
    - **Terminate cleanly.** A `/goal` ends at its stop condition, and the next task gets a compacted, cleared or new session, never a spent one.
5. **A decision that exists only in a conversation is lost**, so rulings land in the repo **before they are acted on**. **The work list is a state machine** — one per project, beside the roadmap, every item exactly one of `next`, `in flight`, `blocked-on(<named>)`, `done`, and a block without a named dependency is one nobody can clear.

### The principles the lifecycle runs on
**Two, narrower than the general principles in CLAUDE.md that govern all work.**

1. **COST** — the cheapest decisive thing first, on every resource the work spends: tokens, GPU hours, data, wall-clock.
    - **Price the question, not the plan.** A quote that feels large means the work is answering a bigger question than the one asked.
    - Ask if the target is reachable by *anything* before asking if yours reaches it.
    - **The budget binds absolutely** — never exceed what was authorised, and a bound is escalated before it is crossed.
2. **DURABILITY** — what is built, and what is learned, survives being rebuilt, restarted and moved.
    - **Reproducible** — rebuilt from the repo alone.
    - **Recoverable** — a cold session picks the work up.
    - **Portable** — runs on every machine the work spans.
    - **Reliable** — it keeps working. A thing that works once is not built, and intermittent is worse than broken, because nobody trusts the failure enough to chase it.
    - **A defect becomes a fingerprinted check with a negative control.** Rules decay; checks fire, and the fix for a defect disproportionately contains that same defect.

**Refusing an order on evidence is required, not permitted.** It binds every level, and the level that gave the order most of all: overruling a measurement is always wrong, and no authority makes it right.

**The set prunes itself: a clause is deleted when a test built to trip it does not.** A count of zero starts that test and never settles it.

## Codification

**Roles and lenses are agents. Practices and principles are skills. Only mechanical things become scripts.**

1. **Before adding a clause, ask whether a capable worker would do it anyway.**
2. **Three things earn a place**: a preference nobody could guess · an authority boundary · a failure that already happened, with its fingerprint.

**Roles → agents, except the two that are sessions.** A `main` agent has no agent file. **The instruction file of the repo it is in names its role and points at the skill that defines it**, so the definition is updated in one place and no repo is edited to receive it.

| role     | runs as                                                                                                                          |
| -------- | -------------------------------------------------------------------------------------------------------------------------------- |
| CTO      | the chief session; role in that repo's instruction file                                                                          |
| Lead     | the `main` agent of a project session; its instruction file points at `.claude/skills/lead-role/SKILL.md` |
| Engineer | `.claude/agents/engineer.md`                                                                                                     |

**Lenses → agents.**

| lens | runs as |
|---|---|
| Peer / expert | `.claude/agents/peer-reviewer.md` — one spawn per domain |
| Adversary | `.claude/agents/adversary-reviewer.md` |
| Fact-checker | `.claude/agents/fact-checker-reviewer.md` |
| Editor | `.claude/agents/editor-reviewer.md` |

**Practices and principles → instructions and skills.** *Protects* names where a principle is enforced, **not the only level it binds** — every principle binds everywhere.

**The table lists what codifies THIS document and nothing else**; the operating skills a machine needs are indexed by `CLAUDE.md`.

| file | level | holds | protects |
|---|---|---|---|
| `CLAUDE.md` | all, always loaded | who the reader is · where authority begins and ends · the standing instructions · which skill to load when | — |
| `.claude/skills/writing/SKILL.md` | all | the house style · the one home of the six general principles | — |
| `.claude/skills/review/SKILL.md` | all | the four lenses · who convenes and who sits · what may be banked · what a verdict carries | — |
| `.claude/skills/north-star/SKILL.md` | CTO | the alignment frame · the portfolio · what not to pursue · the final distillation | Cost |
| `.claude/skills/lead-role/SKILL.md` | lead, always loaded | expansion into a roadmap · architecture · dispatch · distillation upward · the progress deck | Cost |
| `.claude/agents/engineer.md` | engineer | the spec · the work state · delivering the work and the artifact | Durability |
