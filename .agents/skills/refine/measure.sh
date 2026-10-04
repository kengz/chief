#!/usr/bin/env bash
# The loop's repo-held measures, read the same way every time. Read-only.
#   measure.sh <repo> <since> [base]   e.g. measure.sh ~/projects/example 2026-01-15
# <base> is the main commit the period starts from; by default the last commit on main's
# first-parent line committed before <since> (a date pick alone lands on old branch commits).
# Prints velocity first (items landed per day), then lead time, review rounds and drops, then landings per day on the default branch (commits whose subject starts land( or merge(),
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
  # Fixture history at a fixed "now": a train of 3 slices 2h ago, a single landing 3 days ago, an old landing 10 days ago.
  eval "$(sed -n '/^drag()/,/^}/p' "$0")"
  now=1791115200; g=$d/g; br=$d/br; mkdir -p "$g" "$br"; ts() { python3 -c "import sys,time;print(time.strftime('%Y%m%d%H%M',time.gmtime(int(sys.argv[1]))))" "$1"; }
  for f in alpha-xb-20260101 alpha-xb2-20260101 alpha-xb3-20260101 beta-20260101 beta-recheck-20260101 gamma-r2-20260101; do : > "$g/$f.md"; TZ=UTC touch -t "$(ts $((now - 3600)))" "$g/$f.md"; done
  : > "$g/old-20200101.md"; TZ=UTC touch -t 202001010000 "$g/old-20200101.md"
  : > "$br/alpha-20260101.md"; TZ=UTC touch -t "$(ts $((now - 3 * 86400 - 4 * 3600)))" "$br/alpha-20260101.md"
  : > "$br/delta-20260102.md"; TZ=UTC touch -t "$(ts $((now - 12 * 3600)))" "$br/delta-20260102.md"
  ( git init -q "$d/dr" && cd "$d/dr" && git config user.email t@t && git config user.name t && echo 1 > l && git add l \
    && GIT_COMMITTER_DATE="@$((now - 10 * 86400)) +0000" git commit -qm "merge(old): early item" \
    && echo 2 >> l && git commit -qam x --date="@$((now - 3 * 86400)) +0000" -q && GIT_COMMITTER_DATE="@$((now - 3 * 86400)) +0000" git commit -q --amend --no-edit -m "land(alpha): the alpha item, dropped: 1" \
    && echo 3 >> l && GIT_COMMITTER_DATE="@$((now - 7200)) +0000" git commit -qam "land(batch): slices=delta,epsilon,zeta dropped: 2" ) >/dev/null 2>&1
  b=$(git -C "$d/dr" rev-parse --abbrev-ref HEAD); out=$(GATES="$g" BRIEFS="$br" drag "$d/dr" "$b" $((now - 8 * 86400)) "$now")
  for want in "velocity: 3 items landed in the last day, 4 in the last 7 days (0.6/day)" "lead time, dispatch to landed: median 7.0h, worst 10.0h over 2 items" \
    "review rounds per item: mean 2.0 over 3 items; worst alpha 3, beta 2, gamma 1" "items dropped per train: 1.5 (3 over 2 landings)"; do
    printf '%s\n' "$out" | grep -qxF "$want" && echo "SELFTEST PASS: drag prints '${want%%:*}'" || { echo "FAIL drag: wanted '$want', got: $out"; n=1; }
  done
  [ "$(printf '%s\n' "$out" | head -1 | cut -c1-9)" = "velocity:" ] && echo "SELFTEST PASS: velocity is the first line" || { echo "FAIL drag: velocity is not first: $out"; n=1; }
  out=$(GATES="$d/none" BRIEFS="$d/none" drag "$d/dr" "$b" $((now - 8 * 86400)) "$now")
  ! printf '%s\n' "$out" | grep -q 'review rounds\|lead time' && echo "SELFTEST PASS: with no gate reports or briefs those figures are skipped" || { echo "FAIL drag: figures printed with nothing to read: $out"; n=1; }
  rm -rf "${d:?}"; exit "$n"
fi
# The measures that explain progress, read from what exists with no new records. First velocity (Method section 2): items
# landed per day on main, an item per name in a landing's slices= list or one per other landing. Then lead time from dispatch
# (a brief's mtime in $BRIEFS) to the first main commit naming the item, then the costs behind it: review rounds per item (gate
# reports in $GATES grouped by item name) and items dropped per train (a "dropped N" in the landing commits). A figure with
# nothing to read is skipped silently.
drag() { # drag <repo> <main> <since epoch> [now epoch]
  python3 - "$@" <<'PY'
import glob, os, re, statistics as st, subprocess, sys, time
repo, main, since = sys.argv[1], sys.argv[2], int(sys.argv[3] or 0)
now = int(sys.argv[4]) if len(sys.argv) > 4 else int(time.time())
def item(n):
    n = re.sub(r"-\d{8}$", "", n)
    while re.search(r"-(xb|recheck|r)\d*$", n): n = re.sub(r"-(xb|recheck|r)\d*$", "", n)
    return n
def files(d):  # the directory the environment names (GATES, BRIEFS); unset means nothing to read
    for f in glob.glob(os.path.join(os.environ[d], "*.md")) if os.environ.get(d) else []:
        if os.path.getmtime(f) > since: yield item(os.path.basename(f)[:-3]), os.path.getmtime(f)
out = subprocess.run(["git", "-C", repo, "log", main, "--since=@%d" % min(since, now - 7 * 86400), "--format=%ct%x09%s%n%b%x00"], capture_output=True, text=True).stdout
commits = [(int(c.split("\t", 1)[0]), c.split("\t", 1)[1]) for c in out.split("\0") if "\t" in c]
land = [(t, m) for t, m in commits if re.match(r"(land|merge)\(", m)]
def n_items(m):
    k = re.search(r"slices[=:]\s*([\w.-]+(?:\s*,\s*[\w.-]+)*)", m)
    return len(re.split(r"\s*,\s*", k.group(1))) if k else 1
day = sum(n_items(m) for t, m in land if t > now - 86400); week = sum(n_items(m) for t, m in land if t > now - 7 * 86400)
if land: print("velocity: %d items landed in the last day, %d in the last 7 days (%.1f/day)" % (day, week, week / 7))
lead = []
for i, t in files("BRIEFS"):
    done = [c for c, m in commits if c > t and re.search(r"(?<![\w-])%s(?![\w-])" % re.escape(i), m, re.I)]
    if done: lead.append((min(done) - t) / 3600)
if lead: print("lead time, dispatch to landed: median %.1fh, worst %.1fh over %d items" % (st.median(lead), max(lead), len(lead)))
rounds = {}
for i, t in files("GATES"): rounds[i] = rounds.get(i, 0) + 1
if rounds:
    top = sorted(rounds.items(), key=lambda kv: (-kv[1], kv[0]))[:3]
    print("review rounds per item: mean %.1f over %d items; worst %s" % (sum(rounds.values()) / len(rounds), len(rounds), ", ".join("%s %d" % kv for kv in top)))
trains = [m for t, m in land if t > since]
dropped = sum(int(n) for m in trains for n in re.findall(r"dropped[: ]+(\d+)", m))
if trains and dropped: print("items dropped per train: %.1f (%d over %d landings)" % (dropped / len(trains), dropped, len(trains)))
PY
}
set -euo pipefail
repo=${1:?usage: measure.sh <repo> <since>}
since=${2:?usage: measure.sh <repo> <since>}
git -C "$repo" fetch -q origin
# The remote's own default branch: a project may call it main or master.
git -C "$repo" remote set-head origin --auto >/dev/null
main=$(git -C "$repo" symbolic-ref --short refs/remotes/origin/HEAD)
# A bare date makes git log --since read nothing; anchor it to midnight UTC.
case $since in *T*) gsince=$since ;; *) gsince="${since}T00:00:00Z" ;; esac
chief="${CHIEF_REPO:-$HOME/projects/chief}"
last=$(git -C "$chief" log -1 --format=%ct --grep='^Refinement-pass:' 2>/dev/null)
drag "$repo" "$main" "${last:-0}"
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
