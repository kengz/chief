# Public Chief synchronization bar

1. Built generic Chief extension coordination and relay fallback, with one active coordinator per scope and reciprocal checkpoints before delivery.
2. Native acceptance now requires the assigned checkout, applicable global/parent/project instructions and current work list to be read explicitly; changed guidance must be reloaded before further work.
3. Corrected the hook trust writer to canonicalize the requested user configuration path. On macOS, the original lexical temporary path was rejected by Codex 0.160.0 with `configLayerReadonly`; its canonical path succeeded. All writes were confined to isolated test configuration.
4. Removed the selftest requirement for Python 3.11 `tomllib`; the known fixture checks its preserved multiline strings and exact hook table using the standard library. An initial overly broad table check let the wrong-table negative pass; limiting inspection to that table corrected the test.
5. Validation:
    1. Repository manifest, shell syntax and whitespace checks passed.
    2. Existing push-guard negative controls and commit-message controls passed.
    3. Refinement selftest passed, including neutered wrong-table and canonical-path controls, preserved unrelated configuration and failed-write controls.
    4. Fresh isolated real installation and subsequent check both exited 0: 30 of 30 installed manifest files matched, globals matched and the actual Codex hook was trusted, enabled and synchronous. Neither output contained `NOTE` or `NOT CHECKED`.
    5. Instruction ceilings passed: AGENTS.md 1998 words of 2000; fleet skill 958 of 1050.
    6. Public exact-URL opt-in guards, record/planner templates and other installed source were unchanged. No private records, host identities, configurations or history were imported.
6. The original isolated installer and selftest failures are retained as findings above; they are not successful qualification. No production installation, restart or fleet qualification is claimed by this public candidate. Independent review and publication remain separate steps.
