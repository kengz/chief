#!/usr/bin/env bash
# Install the skills, agents and global rules onto this box, then prove they landed.
#
#   ./install.sh                  install, then verify
#   ./install.sh --check          verify only, change nothing
#   ./install.sh --write-manifest re-bless the shipping set after editing it
#
# 1. Skills (.agents/skills) and agents (.claude/agents) are copied to ~/.claude so every repo
#    sees them, and to ~/.agents/skills and ~/.codex/agents for Codex (agents as TOML).
# 2. The shipping set is enumerated from git, never hand-listed, so a skill added later ships.
# 3. The reference is the committed manifest (.agents/toolkit-manifest.txt), not the working
#    tree: comparing the tree to its own copy has no floor.
# 4. ~/.claude/PRINCIPLES.md and the Codex global are generated from AGENTS.md.
# 5. The push guard (.githooks) is wired by setting core.hooksPath.
# 6. Each instruction file stays under its word ceiling in .agents/rule-budget.
# 7. The refine hook (refine/refine.sh) is wired as a quiet PostToolUse hook in Claude and Codex.

set -uo pipefail

if ! command -v sha256sum >/dev/null 2>&1 && command -v shasum >/dev/null 2>&1; then
    sha256sum() { shasum -a 256 "$@"; }
fi
ROOT="$(cd "$(dirname "$0")" && pwd)"
DEST="${DEST:-$HOME/.claude}"
MANIFEST="$ROOT/.agents/toolkit-manifest.txt"
BACKUP="$DEST/.toolkit-backup"
MARKER="$DEST/.toolkit-installed"
# Codex reads the same skills from ~/.agents/skills and its agents as TOML from ~/.codex/agents, derived on every install.
CODEX_SKILLS="${CODEX_SKILLS:-$HOME/.agents/skills}"
CODEX_AGENTS="${CODEX_AGENTS:-$HOME/.codex/agents}"

# What installs is enumerated from git, never hand-listed (a list misses a later skill with every check green).
# A skill is its whole directory; NF>=4 ignores a stray file directly under skills/.
# Every file the installer rewrites is produced beside the original and renamed over it only if its producer succeeded.
put() { local f=$1 tmp="$1.tmp.$$"; shift; "$@" > "$tmp" && mv "$tmp" "$f" || { rm -f "$tmp"; return 1; }; }
manifest_lines() { ( cd "$ROOT" && shipping_set | sort | xargs sha256sum ); }
skill_dirs()  { git -C "$ROOT" ls-files -- .agents/skills | awk -F/ 'NF>=4 {print $1"/"$2"/"$3}' | sort -u; }
agent_files() { git -C "$ROOT" ls-files -- .claude/agents; }

case "${1-}" in
    ""|--check|--write-manifest) ;;
    *) echo "usage: $0 [--check|--write-manifest]"; exit 2 ;;
esac

prerequisites() {
    local missing=""
    for c in rsync cmp find git sha256sum; do
        command -v "$c" >/dev/null || missing="$missing $c"
    done
    [ -n "$missing" ] && { echo "MISSING TOOLS:$missing — install them and run again"; return 1; }
    # No bash 4 gate: the checkers no longer need it, and it would block macOS.
    git -C "$ROOT" rev-parse --git-dir >/dev/null 2>&1 \
        || { echo "not a git checkout — the shipping set is enumerated from git and cannot be derived here"; return 1; }
    return 0
}

# Every tracked file of the shipping set, from git. A symlink is refused: its content is a path, not a file.
shipping_set() {
    local mode rest path
    git -C "$ROOT" ls-files -s -- $(skill_dirs) $(agent_files) \
    | while read -r mode rest; do
        path="${rest#*$'\t'}"
        [ "$mode" = 120000 ] && { echo "SYMLINK IN THE SHIPPING SET: $path — its content is a path, not a file" >&2; continue; }
        echo "$path"
      done
}

write_manifest() {
    # An untracked file in a shipping folder is left out of the manifest, then ships unblessed once added.
    u=$(git -C "$ROOT" ls-files --others --exclude-standard -- .agents/skills .claude/agents)
    [ -z "$u" ] || { echo "untracked files in the shipping folders; git add them first:"; echo "$u" | sed 's/^/    /'; return 1; }
    put "$MANIFEST" manifest_lines || return 1
    echo "manifest written: $(wc -l < "$MANIFEST") files. Commit it — it is what every check measures against."
}

# The floor: does the repo still match what was blessed? Else every comparison is the working tree agreeing with itself.
check_repo() {
    [ -f "$MANIFEST" ] || { echo "NO MANIFEST at $MANIFEST — run '$0 --write-manifest' and commit it"; return 1; }
    local out extra fail=0
    out=$( cd "$ROOT" && sha256sum -c --quiet "$MANIFEST" 2>&1 )
    [ -n "$out" ] && { echo "REPO DOES NOT MATCH ITS MANIFEST:"; printf '%s\n' "$out" | sed 's/^/    /'
                       echo "    If the change is intended: $0 --write-manifest, then commit."; fail=1; }
    # A file added to the shipping set and never blessed would otherwise ship unchecked.
    extra=$( comm -23 <(cd "$ROOT" && shipping_set 2>/dev/null | sort) <(awk '{print $2}' "$MANIFEST" | sort) )
    [ -n "$extra" ] && { echo "IN THE SHIPPING SET BUT NOT THE MANIFEST:"; printf '%s\n' "$extra" | sed 's/^/    /'
                         echo "    Run $0 --write-manifest, then commit."; fail=1; }
    return "$fail"
}

# On the first install only, move anything already at our names into a backup outside skills/ (a renamed duplicate would load twice).
preserve() {
    [ -f "$MARKER" ] && return 0
    local path="$1" rel
    [ -e "$path" ] || return 0
    rel="${path#"$DEST/"}"
    mkdir -p "$BACKUP/$(dirname "$rel")" || return 1
    [ -e "$BACKUP/$rel" ] && return 0
    mv "$path" "$BACKUP/$rel" && echo "kept your existing $rel as .toolkit-backup/$rel"
}

# A Claude agent file as a Codex agent: its name and description, and its body as the
# instructions. TOML escapes backslashes, and a `"""` in the body would end the string.
codex_agent() {
    awk 'NR==1 && /^---$/ {fm=1; next}
         fm && /^---$/     {fm=0; print "developer_instructions = \"\"\""; next}
         fm && /^(name|description):/ {
             k=$1; sub(/:$/, "", k); sub(/^[a-z]+: */, "")
             gsub(/\\/, "\\\\"); gsub(/"/, "\\\""); printf "%s = \"%s\"\n", k, $0; next }
         fm {next}
         {gsub(/\\/, "\\\\"); gsub(/"""/, "\"\"\\\""); print}
         END {print "\"\"\""}' "$1"
}

# Box-local files moved from .claude/ to .agents/local/ (neutral to both providers): moved only where the new name is absent, never overwritten.
migrate_local() {
    local f
    for f in intel-sources.md seen-urls.txt secrets.env; do
        [ -e "$ROOT/.claude/$f" ] || continue
        [ ! -e "$ROOT/.agents/local/$f" ] || { echo "NOTE: .claude/$f and .agents/local/$f both exist; keeping both, merge by hand"; continue; }
        mkdir -p "$ROOT/.agents/local" && mv "$ROOT/.claude/$f" "$ROOT/.agents/local/$f" && echo "moved .claude/$f to .agents/local/$f"
    done
}

# The marker and backup were named for "the institution"; each moves once, only where the new name is absent. This runs before
# preserve, which reads the marker: a missed move would read as a first install and set our skills aside.
migrate_names() {
    [ ! -e "$DEST/.institution-installed" ] || [ -e "$MARKER" ] || mv "$DEST/.institution-installed" "$MARKER"
    [ ! -e "$DEST/.institution-backup" ] || [ -e "$BACKUP" ] || mv "$DEST/.institution-backup" "$BACKUP"
}

# rsync --files-from never deletes, so a file renamed or removed in the repo would stay installed (and load): remove every
# installed file of a skill that the repo no longer tracks. Only files under a skill we ship, only ones git does not list.
prune() {  # <installed skill dir> <tracked list>
    local f
    ( cd "$1" && find . -type f | sed 's|^\./||' | sort ) | comm -23 - <(sort "$2") | while IFS= read -r f; do
        rm -f -- "$1/$f" && echo "removed stale $1/$f"
    done
    find "$1" -type d -empty -delete 2>/dev/null
    return 0
}

install_files() {
    migrate_local
    mkdir -p "$DEST" && migrate_names
    mkdir -p "$DEST/skills" "$DEST/agents" "$CODEX_SKILLS" "$CODEX_AGENTS" || return 1
    local path tracked_list
    tracked_list=$(mktemp) || return 1
    trap 'rm -f "$tracked_list"' RETURN
    for path in $(skill_dirs); do
        preserve "$DEST/skills/$(basename "$path")"
        # No trailing slash on the source; a trailing slash on the destination keeps a one-file skill a directory. Only what git tracks ships.
        git -C "$ROOT" ls-files -- "$path" | sed "s|^$path/||" > "$tracked_list" || return 1
        rsync -a --files-from="$tracked_list" "$ROOT/$path" "$DEST/skills/$(basename "$path")/" || return 1
        rsync -a --files-from="$tracked_list" "$ROOT/$path" "$CODEX_SKILLS/$(basename "$path")/" || return 1
        prune "$DEST/skills/$(basename "$path")" "$tracked_list" && prune "$CODEX_SKILLS/$(basename "$path")" "$tracked_list" || return 1
    done
    for path in $(agent_files); do
        preserve "$DEST/agents/$(basename "$path")"
        rsync -a "$ROOT/$path" "$DEST/agents/" || return 1
        put "$CODEX_AGENTS/$(basename "$path" .md).toml" codex_agent "$ROOT/$path" || return 1
    done
    retired_agents | while IFS= read -r dir; do rm -f -- "$DEST/agents/$dir.md" "$CODEX_AGENTS/$dir.toml" && echo "removed retired agent $dir"; done
    # A retired skill's copy keeps loading until removed; one that cannot be removed stays in the record so --check keeps failing.
    local dir
    retired_skills | while IFS= read -r dir; do rm -rf -- "$dir" && echo "removed retired skill $dir"; done
    { current_skills; retired_skills | while IFS= read -r dir; do basename "$dir"; done; } \
        | sort -u > "$MARKER.tmp" && mv "$MARKER.tmp" "$MARKER"
}

# Installed agents this repo once shipped under a name it no longer has (an installed copy still loads): the name when the
# installed file is byte-identical to a version git tracked, so an agent from another installer is never touched.
retired_agents() {
    local f name blobs
    git -C "$ROOT" log --no-renames --diff-filter=D --name-only --format= -- .claude/agents 2>/dev/null | sort -u | while read -r f; do
        name=$(basename "$f" .md)
        agent_files | grep -qxF -- "$f" && continue
        [ -f "$DEST/agents/$name.md" ] || continue
        blobs=$(git -C "$ROOT" log --no-renames --format= --raw --no-abbrev -- "$f" | awk '{print $3; print $4}')
        printf '%s\n' "$blobs" | grep -qxF -- "$(git hash-object "$DEST/agents/$name.md")" && echo "$name"
    done
}

current_skills() { for path in $(skill_dirs); do basename "$path"; done | sort -u; }

# The installed copies of skills that are ours and retired: not shipped now, and either named in
# our record or holding a SKILL.md git once tracked here. A skill from another installer
# matches neither and is never touched. `|| :` because a first install has no record.
retired_skills() {
    local name base blobs current
    current=$(current_skills)
    { cat "$MARKER" 2>/dev/null || :
      git -C "$ROOT" log --no-renames --diff-filter=D --name-only --format= -- .claude/skills .agents/skills 2>/dev/null \
          | awk -F/ 'NF>3{print $3}'; } | sort -u | while read -r name; do
        case "$name" in ''|.*|*/*) continue ;; esac
        printf '%s\n' "$current" | grep -qxF -- "$name" && continue
        for base in "$DEST/skills" "$CODEX_SKILLS"; do
            [ -e "$base/$name" ] || continue
            if ! grep -qxF -- "$name" "$MARKER" 2>/dev/null; then
                [ -f "$base/$name/SKILL.md" ] || continue
                blobs=$(git -C "$ROOT" log --format= --raw --no-abbrev -- ".claude/skills/$name/SKILL.md" ".agents/skills/$name/SKILL.md" 2>/dev/null | awk '{print $3; print $4}')
                printf '%s\n' "$blobs" | grep -qxF -- "$(git hash-object "$base/$name/SKILL.md")" || continue
            fi
            echo "$base/$name"
        done
    done
}

# A checkout that cannot push is named, not read as clean: the push must have a trusted remote.
push_ready() {
    [ -n "$(git -C "$ROOT" config --get-all chief.allowedRemote)" ] \
        || { echo "PUSH BLOCKED: no chief.allowedRemote — git config --add chief.allowedRemote <url>"; return 1; }
}

# Both providers' copies against the manifest: every shipped file present and identical, nothing extra, agents regenerated.
verify_install() {
    local fail=0 want=0 got=0 path d sum f rel base
    while read -r sum path; do
        case "$path" in
            .agents/skills/*) rel="${path#.agents/skills/}"; set -- "$DEST/skills/$rel" "$CODEX_SKILLS/$rel" ;;
            .claude/agents/*) set -- "$DEST/agents/${path#.claude/agents/}" ;;
            *) continue ;;
        esac
        for d in "$@"; do
            want=$((want + 1))
            if [ ! -f "$d" ]; then
                echo "MISSING: $d — re-run without --check"; fail=1
            elif [ "$(sha256sum < "$d" | cut -d' ' -f1)" = "$sum" ]; then
                got=$((got + 1))
            else
                echo "DIFFERS: $d — edited or stale; re-run without --check to overwrite it"; fail=1
            fi
        done
    done < "$MANIFEST"
    for path in $(agent_files); do
        want=$((want + 1)); d="$CODEX_AGENTS/$(basename "$path" .md).toml"
        if codex_agent "$ROOT/$path" | cmp -s - "$d"; then got=$((got + 1)); else echo "DIFFERS: $d — re-run without --check"; fail=1; fi
    done

    # An installed agent the repo does not ship (Chief-only, or deleted upstream and never pruned) still loads.
    for d in "$DEST"/agents/*.md; do
        [ -f "$d" ] || continue
        agent_files | grep -qx ".claude/agents/$(basename "$d")" \
            || { echo "STRAY AGENT: $d is not shipped by this repo — delete it"; fail=1; }
    done

    # Anything in one of our skill directories that the manifest does not list is a leftover that still loads.
    for base in "$DEST/skills" "$CODEX_SKILLS"; do
        while IFS= read -r f; do
            grep -q " .agents/skills/${f#"$base/"}\$" "$MANIFEST" \
                || { echo "STALE: $f is not in the manifest — left by a rename or an old install; delete it"; fail=1; }
        done < <(for d in $( { current_skills; cat "$MARKER" 2>/dev/null; } | sort -u); do find "$base/$d" -type f 2>/dev/null; done)
    done

    d=$(retired_skills); [ -n "$d" ] && { printf 'RETIRED SKILL STILL INSTALLED: %s — re-run without --check\n' "$d"; fail=1; }
    # A copy under a retired name that git never tracked may be someone else's: named, never deleted or failed on.
    for d in $(git -C "$ROOT" log --no-renames --diff-filter=D --name-only --format= -- .claude/skills .agents/skills 2>/dev/null \
            | awk -F/ 'NF>3{print $3}' | sort -u); do
        current_skills | grep -qxF -- "$d" && continue
        for f in "$DEST/skills/$d" "$CODEX_SKILLS/$d"; do
            [ -e "$f" ] && ! retired_skills | grep -qxF -- "$f" \
                && echo "NOTE: $f has a retired skill's name but no version git tracked; delete it by hand if it is ours"
        done
    done

    [ "$fail" -eq 0 ] && echo "installed: $got of $want manifest files identical, no stale files"
    return "$fail"
}

# core.hooksPath wires the push guard; git ignores .githooks until it points there. --check reports a wired and an unwired repo differently.
wire_hooks() {
    local want=.githooks have
    [ -x "$ROOT/$want/pre-push" ] || { echo "NOT CHECKED: no $want/pre-push here, so no push guard to wire"; return 0; }
    have="$(git -C "$ROOT" config core.hooksPath || true)"
    if [ "$have" = "$want" ]; then
        echo "the push guard is wired: core.hooksPath is $want"
    elif [ "${1-}" = "--check" ]; then
        echo "PUSH GUARD OFF: core.hooksPath is ${have:-unset}, so $want/pre-push never runs — install to wire it"
        return 1
    elif [ -n "$have" ]; then
        echo "PUSH GUARD OFF: core.hooksPath is $have, set by someone on purpose — left alone. Point it at $want or run its hook from yours"
        return 1
    else
        git -C "$ROOT" config core.hooksPath "$want" || return 1
        echo "wired the push guard: core.hooksPath now $want, so the push guard runs on every push"
    fi
}

# THE REFINE HOOK (Method section 4, Refinement) is a PostToolUse hook in both providers, matched to the handover tools. Claude lists it in
# settings.json; Codex lists it in hooks.json and runs only hooks it has trusted, by a hash only Codex computes, so the install
# records the hash Codex reports in its config.toml. --check: present, synchronous, matched, timed, not disabled, trusted, and no
# no entry left under the hook's old name introspect.sh, under any event. Limit: project settings can still switch hooks off; --check certifies only what the install controls.
CODEX_HOOKS="${CODEX_HOOKS:-$HOME/.codex/hooks.json}"
HOOK_MATCHER="Bash|SendMessage|send_message|followup_task|spawn_agent"
hook_entry() { # hook_entry <file> <command> <install|check>: a synchronous, matched PostToolUse hook runs the command, no entry under the old name introspect.sh remains, hooks are not disabled; install makes it so
    python3 - "$@" "$HOOK_MATCHER" <<'PY'
import json,os,sys
f,cmd,mode,matcher=sys.argv[1:5]
try: d=json.load(open(f))
except FileNotFoundError: d={}
if d.get("disableAllHooks"): print("disableAllHooks is true in "+f); sys.exit(1)
hk=d.setdefault("hooks",{}); ev=hk.setdefault("PostToolUse",[])
runs=lambda h: h.get("command")==cmd
isold=lambda h: "refine-instructions/introspect.sh" in str(h.get("command"))  # the hook's old name and place, under any event
leftover=any(isold(h) for v in hk.values() if isinstance(v,list) for g in v for h in g.get("hooks",[]))
mine=[(g,h) for g in ev for h in g.get("hooks",[]) if runs(h)]
if mode=="install":
    for k in list(hk):
        if not isinstance(hk[k],list): continue
        keep=[g for g in hk[k] if not (g.get("hooks") and all(isold(h) for h in g["hooks"]))]   # groups holding only old entries go
        for g in keep:
            if isinstance(g.get("hooks"),list): g["hooks"]=[h for h in g["hooks"] if not isold(h)]
        if not keep and hk[k] and k!="PostToolUse": del hk[k]
        else: hk[k][:]=keep   # in place: ev is this very list
    for g,h in mine: h.pop("async",None); h["timeout"]=30; g["matcher"]=matcher
    if not mine: ev.append({"matcher":matcher,"hooks":[{"type":"command","command":cmd,"timeout":30}]})
    t=f+".tmp"
    try:
        with open(t,"w") as o: json.dump(d,o,indent=2); o.flush(); os.fsync(o.fileno())
        os.replace(t,f); sys.exit(0)
    except OSError as e:
        try: os.remove(t)
        except OSError: pass
        sys.exit("could not write %s (%s); the original is untouched"%(f,e))
sys.exit(0 if not leftover and any(h.get("type")=="command" and not h.get("async") and h.get("timeout")==30 and g.get("matcher")==matcher for g,h in mine) else 1)
PY
}
codex_call() { # codex_call <request json>: Codex's own reply to one app-server request
    { printf '%s\n' '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"clientInfo":{"name":"install","version":"1"}}}' \
        '{"jsonrpc":"2.0","method":"initialized"}' "$1"; sleep 2; } \
    | CODEX_HOME="$(dirname "$CODEX_HOOKS")" codex app-server --listen stdio:// 2>/dev/null | grep '"id":2'
}
codex_hook_trust() { # prints "key hash trustStatus enabled async" of our PostToolUse hook as Codex itself reports it
    codex_call "{\"jsonrpc\":\"2.0\",\"id\":2,\"method\":\"hooks/list\",\"params\":{\"cwds\":[\"$ROOT\"]}}" \
    | python3 -c 'import json,sys
for l in sys.stdin:
    for e in (json.loads(l).get("result") or {}).get("data") or []:
        for h in e["hooks"]:
            if h.get("command")==sys.argv[1] and h["eventName"]=="postToolUse": print(h["key"],h["currentHash"],h["trustStatus"],h["enabled"],h.get("async",False))' "$1"
}
codex_trust_write() { # codex_trust_write <config.toml> <key> <hash>: Codex's own config writer sets the hook's trust, so no TOML is edited here
    codex_call "$(python3 -c 'import json,sys
print(json.dumps({"jsonrpc":"2.0","id":2,"method":"config/value/write","params":{"keyPath":"hooks.state","mergeStrategy":"upsert","filePath":sys.argv[1],"value":{sys.argv[2]:{"trusted_hash":sys.argv[3],"enabled":True}}}}))' "$@")" | grep -q '"status":"ok"'
}
wire_hooks_refine() {
    local mode=install key hash trust enabled async
    [ "${1-}" = "--check" ] && mode=check
    local claude_cmd="bash \"$DEST/skills/refine/refine.sh\"" codex_cmd="bash \"$CODEX_SKILLS/refine/refine.sh\""
    [ "$mode" = install ] && { mkdir -p "$DEST" "$(dirname "$CODEX_HOOKS")" || return 1; }
    hook_entry "$DEST/settings.json" "$claude_cmd" "$mode" && hook_entry "$CODEX_HOOKS" "$codex_cmd" "$mode" \
        || { echo "REFINE HOOK OFF: $DEST/settings.json or $CODEX_HOOKS lacks a synchronous, matched PostToolUse hook running refine.sh, still has one under the old name introspect.sh, or has hooks disabled — install to wire it"; return 1; }
    if command -v codex >/dev/null; then
        read -r key hash trust enabled async <<< "$(codex_hook_trust "$codex_cmd")"
        if [ "$mode" = install ] && { [ "$trust" != trusted ] || [ "$enabled" != True ]; } && [ -n "$key" ]; then
            codex_trust_write "$(dirname "$CODEX_HOOKS")/config.toml" "$key" "$hash" || return 1
            read -r key hash trust enabled async <<< "$(codex_hook_trust "$codex_cmd")"   # believe Codex, not the write
        fi
        [ "$trust" = trusted ] && [ "$enabled" = True ] && [ "$async" = False ] \
            || { echo "REFINE HOOK NOT RUNNING IN CODEX: trust ${trust:-unknown}, enabled ${enabled:-unknown}, async ${async:-unknown} — install to trust it, or review it in Codex if it says modified"; return 1; }
    else echo "NOT CHECKED: no codex here, so its hook trust is unverified"; fi
    echo "the refine hook runs after handover tools in Claude ($DEST/settings.json) and Codex ($CODEX_HOOKS)"
}

# The global core is generated from AGENTS.md, the one hand-edited source: it becomes ~/.claude/PRINCIPLES.md and the Codex global.
section() { awk -v h="# $1" '$0==h {on=1} on && /^---$/ {exit} on' "$ROOT/AGENTS.md"; }
GENERATED_NOTE="<!-- GENERATED by install.sh from AGENTS.md. Do not edit. -->"
CODEX_GLOBAL="${CODEX_GLOBAL:-$HOME/.codex/AGENTS.md}"
global_targets() { printf '%s\n' "$DEST/PRINCIPLES.md" "$CODEX_GLOBAL"; }
global_content() {
    local out="$GENERATED_NOTE" h
    [ "$1" = "$CODEX_GLOBAL" ] && out="$out

These bind every session on this machine, in every repo; this is the Codex twin of ~/.claude/CLAUDE.md."
    for h in Principles Premises Method Codification; do out="$out

$(section "$h")"; done
    printf '%s\n' "$out"
}
# ~/.claude/CLAUDE.md imports the generated core; written when absent or opening with the chief marker, otherwise left alone.
CLAUDE_GLOBAL="$DEST/CLAUDE.md"
CLAUDE_MARK="<!-- chief:communication -->"
claude_owned() { [ ! -e "$CLAUDE_GLOBAL" ] || [ "$(head -n 1 "$CLAUDE_GLOBAL")" = "$CLAUDE_MARK" ]; }
claude_global() { printf '%s\n\n%s\n\n%s\n' "$CLAUDE_MARK" "These bind every session on this machine, in every repo." "@$DEST/PRINCIPLES.md"; }
install_globals() {
    local t
    if claude_owned && ! cmp -s "$CLAUDE_GLOBAL" <(claude_global); then
        [ -f "$CLAUDE_GLOBAL" ] && { mkdir -p "$BACKUP"; cp "$CLAUDE_GLOBAL" "$BACKUP/$(echo "$CLAUDE_GLOBAL" | tr / _)"; }
        put "$CLAUDE_GLOBAL" claude_global || return 1
    fi
    for t in $(global_targets); do
        # A hand-written file in a generated path is kept once in the backup before it is replaced.
        [ -f "$t" ] && ! grep -qF "$GENERATED_NOTE" "$t" && { mkdir -p "$BACKUP"; cp "$t" "$BACKUP/$(echo "$t" | tr / _)"; }
        mkdir -p "$(dirname "$t")" && put "$t" global_content "$t" || return 1
    done
}
verify_globals() {
    local t fail=0
    claude_owned && ! cmp -s "$CLAUDE_GLOBAL" <(claude_global) \
        && { echo "GLOBAL DIFFERS: $CLAUDE_GLOBAL — re-run without --check"; fail=1; }
    for t in $(global_targets); do
        cmp -s "$t" <(global_content "$t") || { echo "GLOBAL DIFFERS: $t — re-run without --check"; fail=1; }
    done
    [ "$fail" -eq 0 ] && echo "globals: the core and the Codex global match AGENTS.md"
    return "$fail"
}

# The rule budget: each instruction file's word ceiling (.agents/rule-budget). Growth past it fails here, so adding a rule means cutting or merging one.
check_rule_budget() {
    local budget="$ROOT/.agents/rule-budget" fail=0 path max n
    [ -f "$budget" ] || { echo "RULE BUDGET MISSING: $budget"; return 1; }
    while read -r path max _; do
        case "$path" in ''|'#'*) continue ;; esac
        n=$(wc -w < "$ROOT/$path")
        [ "$n" -le "$max" ] || { echo "OVER RULE BUDGET: $path has $n words, ceiling $max — cut or merge a rule"; fail=1; }
        # Shared instructions bind every provider, so they name roles, not one provider's tools.
        grep -qiw 'subagents\?' "$ROOT/$path" && { echo "NOT PROVIDER-NEUTRAL: $path names subagents — say 'a fresh seat'"; fail=1; }
    done < "$budget"
    [ "$fail" -eq 0 ] && echo "rule budget: every instruction file within its ceiling"
    return "$fail"
}

prerequisites || exit 1
[ "${1-}" = "--write-manifest" ] && { write_manifest; exit $?; }
check_repo || exit 1
check_rule_budget || exit 1
[ "${1-}" = "--check" ] || { install_files && install_globals; } || { echo "install failed — nothing verified"; exit 1; }
# Wiring the guard comes before verifying: an unrelated drift must not leave it unwired or hide that it is off.
wire_hooks "${1-}"; wired=$?
push_ready; ready=$?
wire_hooks_refine "${1-}"; hooked=$?
[ "$wired" = 0 ] && [ "$ready" = 0 ] || exit 1
verify_install || exit 1
verify_globals || exit 1
[ "$hooked" = 0 ] || exit 1   # last, so its failure never hides the other reports
# Explicit exit: a trailing false `[ ]` test would otherwise become the script's status.
exit 0
