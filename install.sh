#!/usr/bin/env bash
# Install the skills, agents and global rules onto this machine, then prove they landed.
#
#   ./install.sh                  install, then verify
#   ./install.sh --check          verify only, change nothing
#   ./install.sh --write-manifest re-bless the shipping set after editing it
#
# 1. Skills (.agents/skills) and agents (.claude/agents) are copied to ~/.claude so every repo
#    sees them, and to ~/.agents/skills and ~/.codex/agents for Codex (agents as TOML).
# 2. The shipping set is enumerated from git, never hand-listed, so a skill added later ships.
# 3. The reference is the committed manifest (.claude/institution-manifest.txt), not the working
#    tree: comparing the tree to its own copy has no floor.
# 4. ~/.claude/PRINCIPLES.md and the Codex global are generated from AGENTS.md.
# 5. The push guard (.githooks) is wired by setting core.hooksPath.
# 6. Each instruction file stays under its word ceiling in .claude/rule-budget.


set -uo pipefail

if ! command -v sha256sum >/dev/null 2>&1 && command -v shasum >/dev/null 2>&1; then
    sha256sum() { shasum -a 256 "$@"; }
fi
ROOT="$(cd "$(dirname "$0")" && pwd)"
DEST="${DEST:-$HOME/.claude}"
MODE="${1-}"
MANIFEST="$ROOT/.claude/institution-manifest.txt"
BACKUP="$DEST/.institution-backup"
MARKER="$DEST/.institution-installed"
CODEX_SKILLS="${CODEX_SKILLS:-$HOME/.agents/skills}"
CODEX_AGENTS="${CODEX_AGENTS:-$HOME/.codex/agents}"

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
    git -C "$ROOT" rev-parse --git-dir >/dev/null 2>&1 \
        || { echo "not a git checkout — the shipping set is enumerated from git and cannot be derived here"; return 1; }
    return 0
}

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
    ( cd "$ROOT" && shipping_set | sort | xargs sha256sum ) > "$MANIFEST" || return 1
    echo "manifest written: $(wc -l < "$MANIFEST") files. Commit it — it is what every check measures against."
}

check_repo() {
    [ -f "$MANIFEST" ] || { echo "NO MANIFEST at $MANIFEST — run '$0 --write-manifest' and commit it"; return 1; }
    local out extra fail=0
    out=$( cd "$ROOT" && sha256sum -c --quiet "$MANIFEST" 2>&1 )
    [ -n "$out" ] && { echo "REPO DOES NOT MATCH ITS MANIFEST:"; printf '%s\n' "$out" | sed 's/^/    /'
                       echo "    If the change is intended: $0 --write-manifest, then commit."; fail=1; }
    extra=$( comm -23 <(cd "$ROOT" && shipping_set 2>/dev/null | sort) <(awk '{print $2}' "$MANIFEST" | sort) )
    [ -n "$extra" ] && { echo "IN THE SHIPPING SET BUT NOT THE MANIFEST:"; printf '%s\n' "$extra" | sed 's/^/    /'
                         echo "    Run $0 --write-manifest, then commit."; fail=1; }
    return "$fail"
}

preserve() {
    [ -f "$MARKER" ] && return 0
    local path="$1" rel
    [ -e "$path" ] || return 0
    rel="${path#"$DEST/"}"
    mkdir -p "$BACKUP/$(dirname "$rel")" || return 1
    [ -e "$BACKUP/$rel" ] && return 0
    mv "$path" "$BACKUP/$rel" && echo "kept your existing $rel as .institution-backup/$rel"
}

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

install_files() {
    mkdir -p "$DEST/skills" "$DEST/agents" "$CODEX_SKILLS" "$CODEX_AGENTS" || return 1
    local path tracked_list
    tracked_list=$(mktemp) || return 1
    trap 'rm -f "$tracked_list"' RETURN
    for path in $(skill_dirs); do
        preserve "$DEST/skills/$(basename "$path")"
        git -C "$ROOT" ls-files -- "$path" | sed "s|^$path/||" > "$tracked_list" || return 1
        # The destination gets a trailing slash and is created first: a skill with one file would
        # otherwise be copied to a plain file named after the skill.
        mkdir -p "$DEST/skills/$(basename "$path")" "$CODEX_SKILLS/$(basename "$path")" || return 1
        rsync -a --delete --files-from="$tracked_list" "$ROOT/$path" "$DEST/skills/$(basename "$path")/" || return 1
        rsync -a --delete --files-from="$tracked_list" "$ROOT/$path" "$CODEX_SKILLS/$(basename "$path")/" || return 1
    done
    for path in $(agent_files); do
        preserve "$DEST/agents/$(basename "$path")"
        rsync -a "$ROOT/$path" "$DEST/agents/" || return 1
        codex_agent "$ROOT/$path" > "$CODEX_AGENTS/$(basename "$path" .md).toml" || return 1
    done
    local dir
    retired_skills | while IFS= read -r dir; do rm -rf -- "$dir" && echo "removed retired skill $dir"; done
    { current_skills; retired_skills | while IFS= read -r dir; do basename "$dir"; done; } \
        | sort -u > "$MARKER.tmp" && mv "$MARKER.tmp" "$MARKER"
}

current_skills() { for path in $(skill_dirs); do basename "$path"; done | sort -u; }

retired_skills() {
    local name base blobs current
    current=$(current_skills)
    { cat "$MARKER" 2>/dev/null || :
      git -C "$ROOT" log --diff-filter=D --name-only --format= -- .claude/skills .agents/skills 2>/dev/null \
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

dest_of() {
    case "$1" in
        .agents/skills/*) echo "$DEST/skills/${1#.agents/skills/}" ;;
        .claude/agents/*) echo "$DEST/agents/${1#.claude/agents/}" ;;
        *) echo "" ;;
    esac
}

verify_install() {
    local fail=0 want=0 got=0 path d sum f rel
    while read -r sum path; do
        d="$(dest_of "$path")"; [ -n "$d" ] || continue
        want=$((want + 1))
        if [ ! -f "$d" ]; then
            echo "MISSING: $d — re-run without --check"; fail=1
        elif [ "$(sha256sum < "$d" | cut -d' ' -f1)" = "$sum" ]; then
            got=$((got + 1))
        else
            echo "DIFFERS: $d — edited or stale; re-run without --check to overwrite it"; fail=1
        fi
    done < "$MANIFEST"

    while IFS= read -r f; do
        rel=".agents/skills/${f#"$DEST/skills/"}"
        grep -q " $rel\$" "$MANIFEST" \
            || { echo "STALE: $f is not in the manifest — left by a rename or an old install; delete it"; fail=1; }
    done < <(for d in $( { for p in $(skill_dirs); do basename "$p"; done; cat "$MARKER" 2>/dev/null; } | sort -u); do find "$DEST/skills/$d" -type f 2>/dev/null; done)

    d=$(retired_skills); [ -n "$d" ] && { printf 'RETIRED SKILL STILL INSTALLED: %s — re-run without --check\n' "$d"; fail=1; }
    for d in $(git -C "$ROOT" log --diff-filter=D --name-only --format= -- .claude/skills .agents/skills 2>/dev/null \
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

verify_codex() {
    local fail=0 sum path d
    while read -r sum path; do
        case "$path" in .agents/skills/*) d="$CODEX_SKILLS/${path#.agents/skills/}" ;; *) continue ;; esac
        [ "$(sha256sum < "$d" 2>/dev/null | cut -d' ' -f1)" = "$sum" ] \
            || { echo "CODEX DIFFERS OR MISSING: $d — re-run without --check"; fail=1; }
    done < "$MANIFEST"
    for path in $(agent_files); do
        d="$CODEX_AGENTS/$(basename "$path" .md).toml"
        codex_agent "$ROOT/$path" | cmp -s - "$d" \
            || { echo "CODEX DIFFERS OR MISSING: $d — re-run without --check"; fail=1; }
    done
    while IFS= read -r d; do
        grep -q " .agents/skills/${d#"$CODEX_SKILLS/"}\$" "$MANIFEST" \
            || { echo "CODEX STALE: $d is not in the manifest — delete it"; fail=1; }
    done < <(for path in $(skill_dirs); do find "$CODEX_SKILLS/$(basename "$path")" -type f 2>/dev/null; done)
    [ "$fail" -eq 0 ] && echo "codex: skills in $CODEX_SKILLS and agents in $CODEX_AGENTS match their sources"
    return "$fail"
}

section() { awk -v h="# $1" '$0==h {on=1} on && /^---$/ {exit} on' "$ROOT/AGENTS.md"; }
GENERATED_NOTE="<!-- GENERATED by install.sh from AGENTS.md. Do not edit. -->"
CODEX_GLOBAL="${CODEX_GLOBAL:-$HOME/.codex/AGENTS.md}"
global_targets() { printf '%s\n' "$DEST/PRINCIPLES.md" "$CODEX_GLOBAL"; }
global_content() {
    case "$1" in
        */PRINCIPLES.md) printf '%s\n\n%s\n\n%s\n\n%s\n\n%s\n' "$GENERATED_NOTE" "$(section Principles)" "$(section Premises)" "$(section Method)" "$(section Codification)" ;;
        "$CODEX_GLOBAL") printf '%s\n\n%s\n\n%s\n\n%s\n\n%s\n\n%s\n' "$GENERATED_NOTE" \
            "These bind every session on this machine, in every repo; this is the Codex twin of ~/.claude/CLAUDE.md." \
            "$(section Principles)" "$(section Premises)" "$(section Method)" "$(section Codification)" ;;
    esac
}
CLAUDE_GLOBAL="$DEST/CLAUDE.md"
CLAUDE_MARK="<!-- chief:communication -->"
claude_owned() { [ ! -e "$CLAUDE_GLOBAL" ] || [ "$(head -n 1 "$CLAUDE_GLOBAL")" = "$CLAUDE_MARK" ]; }
claude_global() { printf '%s\n\n%s\n\n%s\n' "$CLAUDE_MARK" "These bind every session on this machine, in every repo." "@$DEST/PRINCIPLES.md"; }
RETIRED_GLOBALS="$DEST/skills/communication $CODEX_SKILLS/communication"
install_globals() {
    local t d
    for d in $RETIRED_GLOBALS; do
        [ -f "$d/SKILL.md" ] && grep -qF "<!-- GENERATED by install.sh" "$d/SKILL.md" && rm -rf -- "$d" && echo "removed retired generated $d"
    done
    if claude_owned && ! cmp -s "$CLAUDE_GLOBAL" <(claude_global); then
        [ -f "$CLAUDE_GLOBAL" ] && { mkdir -p "$BACKUP"; cp "$CLAUDE_GLOBAL" "$BACKUP/$(echo "$CLAUDE_GLOBAL" | tr / _)"; }
        claude_global > "$CLAUDE_GLOBAL" || return 1
    fi
    for t in $(global_targets); do
        [ -f "$t" ] && ! grep -qF "$GENERATED_NOTE" "$t" && { mkdir -p "$BACKUP"; cp "$t" "$BACKUP/$(echo "$t" | tr / _)"; }
        mkdir -p "$(dirname "$t")" && global_content "$t" > "$t" || return 1
    done
}
verify_globals() {
    local t d fail=0
    for d in $RETIRED_GLOBALS; do
        [ -f "$d/SKILL.md" ] && grep -qF "<!-- GENERATED by install.sh" "$d/SKILL.md" && { echo "RETIRED GLOBAL STILL INSTALLED: $d — re-run without --check"; fail=1; }
    done
    claude_owned && ! cmp -s "$CLAUDE_GLOBAL" <(claude_global) \
        && { echo "GLOBAL DIFFERS: $CLAUDE_GLOBAL — re-run without --check"; fail=1; }
    for t in $(global_targets); do
        cmp -s "$t" <(global_content "$t") || { echo "GLOBAL DIFFERS: $t — re-run without --check"; fail=1; }
    done
    [ "$fail" -eq 0 ] && echo "globals: the core and the Codex global match AGENTS.md"
    return "$fail"
}

check_rule_budget() {
    local budget="$ROOT/.claude/rule-budget" fail=0 path max n
    [ -f "$budget" ] || { echo "RULE BUDGET MISSING: $budget"; return 1; }
    while read -r path max _; do
        case "$path" in ''|'#'*) continue ;; esac
        n=$(wc -w < "$ROOT/$path")
        [ "$n" -le "$max" ] || { echo "OVER RULE BUDGET: $path has $n words, ceiling $max — cut or merge a rule"; fail=1; }
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
wire_hooks "${1-}" || exit 1
verify_install || exit 1
verify_codex || exit 1
verify_globals || exit 1
exit 0
