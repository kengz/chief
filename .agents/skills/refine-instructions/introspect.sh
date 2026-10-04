#!/usr/bin/env bash
# PostToolUse hook for Claude and Codex (Method section 4): after a hand-over action it adds one sentence of context for the
# model: introspect and unify, and report only what was found or changed. A hand-over is a shell command containing git commit, push, merge or
# rebase or a fleet tool send or goal, or a message to another session. It never blocks, shows the user nothing, keeps no
# state, and reads no Git, files or network. Any error of its own allows silently.
# introspect.sh --selftest   runs seeded controls, each shown failing against a neutered copy.
decide() {
    python3 -c 'import json,re,sys
d=json.load(sys.stdin); name=d.get("tool_name") or ""; cmd=str((d.get("tool_input") or {}).get("command") or "")
SH=re.compile(r"git\s+(commit|push|merge|rebase)\b|[a-z-]*fleet[a-z-]*\s+(send|goal)\b")  # arm:shell
SEND={"SendMessage","send_message","followup_task","spawn_agent"}  # arm:send
if not (name in SEND or (name=="Bash" and SH.search(cmd))): sys.exit(0)
print(json.dumps({"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"You just handed work over: introspect and unify it (Method \u00a74 items 1 and 4); report only what you found or changed, under a final heading **Introspection**; if nothing, say nothing about it."}}))  # arm:emit
'
}

selftest() {
    local d bad=0 arm tag want got S inst="$(cd "$(dirname "$0")" && pwd)/../../../install.sh"
    d=$(mktemp -d) || return 1
    # real-shaped PostToolUse inputs: Claude (tool_response an object) and Codex (tool_response a string), both with tool_name Bash
    run() { printf '%s' "$1" | bash "$S" 2>"$d/err"; }
    cl() { printf '{"session_id":"s","cwd":"/x","prompt_id":"p","permission_mode":"default","hook_event_name":"PostToolUse","tool_name":"%s","tool_input":%s,"tool_response":{"stdout":"","stderr":"","interrupted":false}}' "$1" "$2"; }
    cx() { printf '{"session_id":"s","turn_id":"t","cwd":"/x","hook_event_name":"PostToolUse","model":"m","permission_mode":"default","tool_name":"%s","tool_input":%s,"tool_response":"ok","tool_use_id":"u","transcript_path":null}' "$1" "$2"; }
    arms() {
        S=$1
        for p in cl cx; do
            for c in "git commit -m x" "git add -A && git push origin main" "fleet-tool send box hi" "fleet-tool goal box x"; do
                [ -n "$(run "$($p Bash "{\"command\":\"$c\"}")")" ] || echo "fires-$p-$c"
            done
            for c in "cat README.md" "git status" "git log -3"; do [ -z "$(run "$($p Bash "{\"command\":\"$c\"}")")" ] || echo "silent-$p-$c"; done
            [ -z "$(run "$($p Read '{"file_path":"/a"}')")" ] || echo "silent-$p-read"
            [ -z "$(run "$($p Edit '{"file_path":"/a"}')")" ] || echo "silent-$p-edit"
        done
        [ -n "$(run "$(cl SendMessage '{"to":"a","message":"hi"}')")" ] || echo fires-cl-send
        [ -n "$(run "$(cx send_message '{"target":"/root","message":"hi"}')")" ] || echo fires-cx-send
        printf 'garbage' | bash "$S" >"$d/out" 2>"$d/err"; r=$?
        { [ "$r" = 0 ] && [ ! -s "$d/out" ]; } || echo fails-open
        run "$(cl Bash '{"command":"git commit -m x"}')" | python3 -c 'import json,sys
d=json.load(sys.stdin); h=d["hookSpecificOutput"]
assert h["hookEventName"]=="PostToolUse" and "**Introspection**" in h["additionalContext"]      # Claude and Codex: context for the model
assert "decision" not in d and set(d)<={"continue","hookSpecificOutput","systemMessage","suppressOutput"} and set(h)<={"hookEventName","additionalContext"}   # never blocks, nothing for the user' 2>/dev/null || echo output-parses
    }
    for arm in $(arms "$0"); do echo "FAIL control: $arm"; bad=1; done
    [ "$bad" = 0 ] && echo "SELFTEST PASS: the real script passes every arm"
    # arm tag ~ replacement line ~ the arm that must then fail
    while IFS='~' read -r tag line want; do
        TAG="# arm:$tag" LINE="$line" awk '{ if (index($0, ENVIRON["TAG"]) && $0 ~ (ENVIRON["TAG"] "$")) print ENVIRON["LINE"]; else print }' "$0" > "$d/neutered.sh"
        got=$(arms "$d/neutered.sh")
        case "$got" in *"$want"*) echo "SELFTEST PASS: neutering '$tag' makes '$want' fail" ;; *) echo "FAIL: neutering '$tag' left '$want' passing (got: ${got:-none})"; bad=1 ;; esac
    done <<'NEUTER'
shell~SH=re.compile("^$")~fires-cl-git commit -m x
shell~SH=re.compile(".")~silent-cl-cat README.md
shell~SH=re.compile("git")~silent-cl-git status
send~SEND=set()~fires-cl-send
send~SEND=set()~fires-cx-send
emit~print(json.dumps({"decision":"block","reason":"x"}))~output-parses
open~    decide || exit 1~fails-open
NEUTER
    # the installer's trust write, extracted from install.sh (skipped beside an installed copy; the Codex arm also needs codex)
    if [ -f "$inst" ]; then
        inst_arms() { # inst_arms <function text>: names of the install arms that fail
            local k=/x/hooks.json:post_tool_use:0:0 c=$d/h/config.toml j=$d/s.json cmd="bash x" big; eval "$1"; CODEX_HOOKS=$d/h/hooks.json; mkdir -p "$d/h"
            big=$(python3 -c 'print("a"*3000)')
            seed() { # seed <timeout> <matcher> <1 if a Stop entry runs our command>
                local st='{"type":"command","command":"keep"}'; [ "${3:-0}" = 1 ] && st='{"type":"command","command":"bash x"},'$st
                printf '{"env":{"big":"%s"},"hooks":{"PreToolUse":[{"x":1}],"PostToolUse":[{"matcher":"%s","hooks":[{"type":"command","command":"bash x","timeout":%s}]}],"Stop":[{"hooks":[%s]}]}}' "$big" "${2:-$HOOK_MATCHER}" "$1" "$st" > "$j"; cp "$j" "$j.0"; }
            seed 0; hook_entry "$j" "$cmd" check 2>/dev/null && echo zero-timeout-refused
            seed 30 "$HOOK_MATCHER" 1; hook_entry "$j" "$cmd" check 2>/dev/null && echo old-stop-entry-refused
            seed 30 Read; hook_entry "$j" "$cmd" check 2>/dev/null && echo wrong-matcher-refused
            seed 0 "$HOOK_MATCHER" 1; hook_entry "$j" "$cmd" install 2>/dev/null; hook_entry "$j" "$cmd" check 2>/dev/null || echo zero-timeout-repaired
            python3 -c 'import json,sys
a=json.load(open(sys.argv[1])); b=json.load(open(sys.argv[1]+".0"))
assert a["env"]==b["env"] and a["hooks"]["PreToolUse"]==b["hooks"]["PreToolUse"] and len(a["hooks"]["PostToolUse"])==1   # the rest survives
assert a["hooks"]["Stop"]==[{"hooks":[{"type":"command","command":"keep"}]}]   # only our old Stop entry is gone' "$j" 2>/dev/null || echo install-keeps-the-rest-and-retires-the-old-stop
            seed 30; ( ulimit -f 2; hook_entry "$j" "bash y" install ) 2>/dev/null; cmp -s "$j" "$j.0" || echo failed-write-leaves-original
            printf 'original' > "$j"; put "$j" sh -c 'echo half; exit 1' 2>/dev/null; [ "$(cat "$j")" = original ] && [ ! -e "$j.tmp.$$" ] || echo failed-producer-leaves-original
            command -v codex >/dev/null || return 0
            # basic and literal multiline strings hold lines that look like the keys being written; they must come through untouched
            cat > "$c" <<TOML
# c
s = """
trusted_hash = "keep"
"""
l = '''
enabled = false
'''
[hooks.state."$k"] # t
enabled = false
TOML
            cp "$c" "$c.0"; codex_trust_write "$c" "$k" new >/dev/null 2>&1
            python3 -c 'import sys,tomllib
b=tomllib.load(open(sys.argv[1]+".0","rb")); a=tomllib.load(open(sys.argv[1],"rb")); k=sys.argv[2]
assert a["hooks"]["state"][k]=={"trusted_hash":"new","enabled":True}; a.pop("hooks"); b.pop("hooks")
assert a==b' "$c" "$k" 2>/dev/null || echo config-write-changes-only-the-trust-table
        }
        local fns; fns=$({ sed -n '/^put()/p' "$inst"; sed -n '/^HOOK_MATCHER=/,/^wire_hooks_introspect()/p' "$inst" | sed '$d'; })
        for arm in $(inst_arms "$fns"); do echo "FAIL control: $arm"; bad=1; done
        while IFS='~' read -r from to want; do
            got=$(inst_arms "$(printf '%s
' "$fns" | sed "s~$from~$to~")")
            case "$got" in *"$want"*) echo "SELFTEST PASS: neutering the installer makes '$want' fail" ;; *) echo "FAIL: neutering the installer left '$want' passing"; bad=1 ;; esac
        done <<'NEUTER'
"keyPath":"hooks.state"~"keyPath":"hooks.state.x"~config-write-changes-only-the-trust-table
; h\["timeout"\]=30~~zero-timeout-repaired
 and h.get("timeout")==30~~zero-timeout-refused
 and g.get("matcher")==matcher~~wrong-matcher-refused
^leftover=.*~leftover=False~old-stop-entry-refused
for g in hk.get("Stop",\[\]): g\["hooks"\]=~for g in []: g["hooks"]=~install-keeps-the-rest-and-retires-the-old-stop
t=f+".tmp"~t=f~failed-write-leaves-original
"\$@" > "\$tmp"~{ "$@"; true; } > "$tmp"~failed-producer-leaves-original
NEUTER
    else echo "SELFTEST SKIP: no install.sh beside this copy, so the installer was not exercised"; fi
    rm -rf "${d:?}" 2>/dev/null; return "$bad"
}

[ "${1-}" = "--selftest" ] && { selftest; exit $?; }
decide || echo "introspect.sh: failed, allowing silently" >&2  # arm:open
exit 0
