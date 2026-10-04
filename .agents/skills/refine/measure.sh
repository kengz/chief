#!/usr/bin/env bash
# The loop's repo-held measures, read the same way every time. Read-only.
#   measure.sh <repo> <since> [base]   e.g. measure.sh ~/projects/example 2026-01-15
# <base> is the main commit the period starts from; by default the last commit on main's
# first-parent line committed before <since> (a date pick alone lands on old branch commits).
# Prints landings per day on the default branch (commits whose subject starts land( or merge(),
# review-record lines against code and test lines added on main since <since>, and test size on main.
if [ "${1-}" = "--selftest" ]; then # a blob that cannot be read must give no size, never a smaller one
  d=$(mktemp -d); chief=$d/r; n=0
  ( git init -q "$chief" && cd "$chief" && git config user.email t@t && git config user.name t \
    && mkdir -p .agents/skills/x && echo "one two" > .agents/skills/x/SKILL.md && echo b > install.sh \
    && git add . && git commit -qm c ) >/dev/null 2>&1
  eval "$(sed -n '/^size()/,/^}/p' "$0")"
  [ "$(size HEAD)" = "2 2 2" ] && echo "SELFTEST PASS: a readable tree is counted" || { echo "FAIL size: $(size HEAD)"; n=1; }
  ( cd "$chief" && printf 'a\nb\n\n\n' > install.sh && : > .agents/skills/x/empty && git add . && git commit -qm blanks ) >/dev/null 2>&1
  [ "$(size HEAD)" = "3 5 2" ] && echo "SELFTEST PASS: trailing blank lines and an empty file are counted" || { echo "FAIL size: blanks gave $(size HEAD), want 3 5 2"; n=1; }
  b=$(git -C "$chief" rev-parse HEAD:install.sh); rm -f "$chief/.git/objects/$(echo "$b" | cut -c1-2)/$(echo "$b" | cut -c3-)"
  size HEAD >/dev/null 2>&1 && { echo "FAIL size: an unreadable blob gave a size"; n=1; } || echo "SELFTEST PASS: an unreadable blob gives no size, so no delta"
  rm -rf "${d:?}"; exit "$n"
fi
set -euo pipefail
repo=${1:?usage: measure.sh <repo> <since>}
since=${2:?usage: measure.sh <repo> <since>}
git -C "$repo" fetch -q origin
# The remote's own default branch: a project may call it main or master.
git -C "$repo" remote set-head origin --auto >/dev/null
main=$(git -C "$repo" symbolic-ref --short refs/remotes/origin/HEAD)
# A bare date makes git log --since read nothing; anchor it to midnight UTC.
case $since in *T*) gsince=$since ;; *) gsince="${since}T00:00:00Z" ;; esac
echo "landings per day on $main since $since:"
git -C "$repo" log "$main" --first-parent --since="$gsince" --date=short --format='%ad %s' \
  | { grep -E '^[0-9-]+ (land|merge)\(' || true; } | awk '{print $1}' | sort | uniq -c | awk '{print "  " $2 ": " $1}'
cutoff=$(python3 -c "import sys,datetime;print(int(datetime.datetime.fromisoformat(sys.argv[1]).replace(tzinfo=datetime.timezone.utc).timestamp()))" "$since")
base=${3:-$(git -C "$repo" log "$main" --first-parent --format='%H %ct' | awk -v c="$cutoff" '!found && $2 < c {print $1; found = 1}')}
echo "base $(git -C "$repo" log -1 --format='%h %cs %s' "$base" | cut -c1-80)"
added() { git -C "$repo" diff --numstat "$base" "$main" -- "$@" | awk '{s += $1} END {print s + 0}'; }
reviews=$(added docs/reviews)
code=$(added src tests migrations web)
echo "lines added since $since: review records $reviews, code and tests $code"
[ "$code" -gt 0 ] && awk -v r="$reviews" -v c="$code" 'BEGIN {printf "review records per code line: %.2f\n", r / c}'
# Tests are refactored like code, so their size is a measure too: it should shrink as duplicates go.
fns=$({ git -C "$repo" grep -h -E '^\s*(async )?def test_' "$main" -- tests || true; } | wc -l)
tlines=$(git -C "$repo" ls-tree -r --name-only "$main" -- tests | sed "s|^|$main:|" | xargs git -C "$repo" show 2>/dev/null | wc -l)
echo "tests on main: $fns test functions, $tlines lines (collected cases: pytest --collect-only)"
# Refinement reads Anomaly: trailers; a fix commit without one is evidence lost.
fixes=$(git -C "$repo" log "$main" --since="$gsince" --format='%H %s' | { grep -E '^[0-9a-f]+ fix' || true; } | awk '{print $1}')
bare=0; for h in $fixes; do git -C "$repo" log -1 --format=%B "$h" | git interpret-trailers --parse | grep -q '^Anomaly:' || bare=$((bare + 1)); done
echo "fix commits since $since: $(echo "$fixes" | grep -c . || true), without an Anomaly: trailer: $bare"
# The Cycle's own clock, read from the chief repo's record so no one has to remember it:
# a pass commit carries 'Refinement-pass:'; a change kept on trial carries 'Provisional:' until
# a later commit names its hash in a 'Verdict:' trailer.
chief="${CHIEF_REPO:-$HOME/projects/chief}"
last=$(git -C "$chief" log -1 --format=%ct --grep='^Refinement-pass:' 2>/dev/null)
if [ -n "$last" ]; then days=$(( ($(date +%s) - last) / 86400 )); echo "last refinement pass: $days days ago$([ "$days" -ge 7 ] && echo ' — DUE')"
else echo "last refinement pass: none recorded — DUE"; fi
# The work a pass owes, named so it is done unprompted: anomalies recorded since the last pass, here and in the project.
# The chief repo may also be the measured project, or a linked worktree of it: count each repository once,
# by its common git directory.
n=0; f=0; seen=""
for r in "$chief" "$repo"; do
  c=$(cd "$r" 2>/dev/null && cd -P "$(git rev-parse --git-common-dir 2>/dev/null)" 2>/dev/null && pwd) || continue
  [ -n "$c" ] && [ "$c" != "$seen" ] || continue
  seen=$c
  for h in $(git -C "$r" log --format=%h ${last:+--since=@$last} 2>/dev/null); do
    t=$(git -C "$r" log -1 --format=%B "$h" | git interpret-trailers --parse | grep '^Anomaly:') || continue
    n=$((n + 1)); printf '%s\n' "$t" | grep -q '^Anomaly: *founder-raised:' && f=$((f + 1)); done
done
echo "anomalies since the last pass: $n$([ "$n" -ge 5 ] && echo ' — classify them now (refine §2)')"
echo "founder-raised anomalies since the last pass: $f$([ "$f" -gt 0 ] && echo ' — the founder had to ask (Roles: asked only for what only they can give); the pass works these first')"
verdicts=$(git -C "$chief" log --format=%B --grep='^Verdict:' 2>/dev/null | sed -n 's/^Verdict: *\([0-9a-f]\{7,\}\) *\(kept\|reverted\).*/\1/p')
git -C "$chief" log --format='%h %cs %s' --grep='^Provisional:' 2>/dev/null | while read -r h d rest; do
  printf '%s\n' "$verdicts" | grep -q "^$h" || echo "provisional, no verdict yet: $h $d $(echo "$rest" | cut -c1-60)"
done
# The toolkit's size now and at the last pass (or the first commit): growth is deleted first.
size() { # size <rev> prints "files lines skillwords"; fails if the revision or any blob cannot be read
  local list f nf=0 nl=0 nw=0 tmp
  git -C "$chief" rev-parse -q --verify "$1^{commit}" >/dev/null || return 1
  list=$(git -C "$chief" ls-tree -r --name-only "$1" -- .agents .githooks install.sh .claude/agents) || return 1
  tmp=$(mktemp) || return 1
  for f in $list; do
    git -C "$chief" show "$1:$f" > "$tmp" || { rm -f "$tmp"; return 1; }   # a file, so trailing newlines count
    nl=$((nl + $(awk 'END {print NR}' "$tmp")))
    case $f in */SKILL.md) nw=$((nw + $(wc -w < "$tmp"))) ;; esac
    nf=$((nf + 1))
  done
  rm -f "$tmp"; echo "$nf $nl $nw"
}
prev=$(git -C "$chief" log -1 --format=%H --grep='^Refinement-pass:' 2>/dev/null); prev=${prev:-$(git -C "$chief" rev-list --max-parents=0 HEAD 2>/dev/null | tail -n 1)}
if now=$(size HEAD) && was=$(size "$prev"); then
  set -- $now $was
  echo "toolkit: $1 files, $2 lines, $3 skill words; since the last pass: $(printf '%+d, %+d, %+d' $(($1 - $4)) $(($2 - $5)) $(($3 - $6)))$([ "$1" -gt "$4" ] || [ "$2" -gt "$5" ] || [ "$3" -gt "$6" ] && echo ' — delete first (Method §1)')"
else echo "toolkit: baseline unavailable ($prev) or unreadable tree; no delta"; fi
