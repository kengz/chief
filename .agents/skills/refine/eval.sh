#!/usr/bin/env bash
# Behaviour test for the refine hook: does the model refine when work landed with a shortfall, and stay silent when it did not?
# Run by hand when refine.sh or the refine skill changes; never by install or on a timer (it spends model quota: 6 short runs).
# Each run is a `claude -p` in a scratch git repo under $TMPDIR; --setting-sources project keeps ~/.claude out, so only this checkout hook (passed by --settings) runs.
# A real session loads the global instructions and the skills, so each scratch repo gets them: CLAUDE.md is a copy of
# ~/.claude/PRINCIPLES.md (read only) and the refine skill sits in .claude/skills/refine/.
# eval.sh [runs-per-scenario, default 3]; EVAL_MODEL (default sonnet) and EVAL_SCENARIOS (default "shortfall clean") narrow a run.
command -v claude >/dev/null || { echo "eval.sh: claude not found on PATH" >&2; exit 1; }
here="$(cd "$(dirname "$0")" && pwd)"; N="${1-3}"
root=$(mktemp -d "${TMPDIR:-/tmp}/refine-eval.XXXXXX") || exit 1
printf '{"hooks":{"PostToolUse":[{"matcher":"Bash","hooks":[{"type":"command","command":"bash %s/refine.sh","timeout":30}]}]}}\n' "$here" > "$root/settings.json"

mkrepo() { # mkrepo <dir> <shortfall|clean>
    mkdir -p "$1/.claude/skills/refine" && cd "$1" && cp "$HOME/.claude/PRINCIPLES.md" CLAUDE.md && cp "$here/SKILL.md" .claude/skills/refine/ && git init -q && git config user.email e@x && git config user.name eval
    if [ "$2" = shortfall ]; then
        printf 'MAX_RETRIES = 3\n\ndef retry(f):\n    for _ in range(MAX_RETRIES):\n        try: return f()\n        except Exception: pass\n' > retry.py
        printf '# retry\n\nretry(f) calls f and retries up to 3 times on any error.\n' > README.md
        git add -A && git commit -qm init
    else
        printf '#!/bin/sh\n# Prints a greeting for the name given.\necho "hello $1"\n' > greet.sh
        git add -A && git commit -qm init
    fi
}
ask() { # ask <scenario> <dir>: prints the reply
    local p
    if [ "$1" = shortfall ]; then p='Change MAX_RETRIES to 5 in retry.py and commit.'
    else p='Add a one-line comment above the echo in greet.sh saying it ends with a newline, and commit.'; fi
    cd "$2" && claude -p "$p" --model "${EVAL_MODEL:-sonnet}" --max-turns 8 --setting-sources project --settings "$root/settings.json" --permission-mode bypassPermissions </dev/null 2>&1
}
verdict() { # verdict <scenario> <dir> <replyfile>: prints PASS or FAIL
    grep -q "command not found" "$3" && { echo FAIL; return; }   # a run that never ran is not a pass
    local sec; sec=$(awk 'tolower($0) ~ /refinement/ {f=1} f' "$3")
    if [ "$1" = shortfall ]; then   # the copy (README) must follow its source (retry.py), or the reply must name the stale README
        if grep -q 5 "$2/README.md" && ! grep -q 'up to 3' "$2/README.md"; then echo PASS
        elif printf '%s' "$sec" | grep -qi 'README'; then echo PASS
        else echo FAIL; fi
    else grep -qi 'refinement' "$3" && echo FAIL || echo PASS; fi
}

for sc in ${EVAL_SCENARIOS:-shortfall clean}; do
    pass=0
    for i in $(seq 1 "$N"); do
        mkrepo "$root/$sc$i" "$sc" >/dev/null 2>&1
        ask "$sc" "$root/$sc$i" > "$root/$sc$i.reply"
        v=$(verdict "$sc" "$root/$sc$i" "$root/$sc$i.reply"); [ "$v" = PASS ] && pass=$((pass+1))
        echo "$sc run $i: $v ($(grep -ci refinement "$root/$sc$i.reply") mentions of Refinement)"
    done
    echo "RATE $sc: $pass/$N"
done
echo "replies kept in $root"
