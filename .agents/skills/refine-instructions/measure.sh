#!/usr/bin/env bash
# The loop's repo-held measures, read the same way every time. Read-only.
#   measure.sh <repo> <since> [base]   e.g. measure.sh ~/projects/example 2026-01-15
# <base> is the main commit the period starts from; by default the last commit on main's
# first-parent line committed before <since> (a date pick alone lands on old branch commits).
# Prints landings per day on origin/main (commits whose subject starts land( or merge(),
# review-record lines against code and test lines added on main since <since>, and test size on main.
set -euo pipefail
repo=${1:?usage: measure.sh <repo> <since>}
since=${2:?usage: measure.sh <repo> <since>}
git -C "$repo" fetch -q origin
# A bare date makes git log --since read nothing; anchor it to midnight UTC.
case $since in *T*) gsince=$since ;; *) gsince="${since}T00:00:00Z" ;; esac
echo "landings per day on origin/main since $since:"
git -C "$repo" log origin/main --first-parent --since="$gsince" --date=short --format='%ad %s' \
  | { grep -E '^[0-9-]+ (land|merge)\(' || true; } | awk '{print $1}' | sort | uniq -c | awk '{print "  " $2 ": " $1}'
cutoff=$(python3 -c "import sys,datetime;print(int(datetime.datetime.fromisoformat(sys.argv[1]).replace(tzinfo=datetime.timezone.utc).timestamp()))" "$since")
base=${3:-$(git -C "$repo" log origin/main --first-parent --format='%H %ct' | awk -v c="$cutoff" '!found && $2 < c {print $1; found = 1}')}
echo "base $(git -C "$repo" log -1 --format='%h %cs %s' "$base" | cut -c1-80)"
added() { git -C "$repo" diff --numstat "$base" origin/main -- "$@" | awk '{s += $1} END {print s + 0}'; }
reviews=$(added docs/reviews)
code=$(added src tests migrations web)
echo "lines added since $since: review records $reviews, code and tests $code"
[ "$code" -gt 0 ] && awk -v r="$reviews" -v c="$code" 'BEGIN {printf "review records per code line: %.2f\n", r / c}'
# Tests are refactored like code, so their size is a measure too: it should shrink as duplicates go.
fns=$({ git -C "$repo" grep -h -E '^\s*(async )?def test_' origin/main -- tests || true; } | wc -l)
tlines=$(git -C "$repo" ls-tree -r --name-only origin/main -- tests | sed 's|^|origin/main:|' | xargs git -C "$repo" show 2>/dev/null | wc -l)
echo "tests on main: $fns test functions, $tlines lines (collected cases: pytest --collect-only)"
# Refinement reads Anomaly: trailers; a fix commit without one is evidence lost.
fixes=$(git -C "$repo" log origin/main --since="$gsince" --format='%H %s' | { grep -E '^[0-9a-f]+ fix' || true; } | awk '{print $1}')
bare=0; for h in $fixes; do git -C "$repo" log -1 --format=%B "$h" | grep -q '^Anomaly:' || bare=$((bare + 1)); done
echo "fix commits since $since: $(echo "$fixes" | grep -c . || true), without an Anomaly: trailer: $bare"
# The Cycle's own clock, read from the chief repo's record so no one has to remember it:
# a pass commit carries 'Refinement-pass:'; a change kept on trial carries 'Provisional:' until
# a later commit names its hash in a 'Verdict:' trailer.
chief="${CHIEF_REPO:-$HOME/projects/chief}"
last=$(git -C "$chief" log -1 --format=%ct --grep='^Refinement-pass:' 2>/dev/null)
if [ -n "$last" ]; then days=$(( ($(date +%s) - last) / 86400 )); echo "last refinement pass: $days days ago$([ "$days" -ge 7 ] && echo ' — DUE')"
else echo "last refinement pass: none recorded — DUE"; fi
verdicts=$(git -C "$chief" log --format=%B --grep='^Verdict:' 2>/dev/null | sed -n 's/^Verdict: *\([0-9a-f]\{7,\}\) *\(kept\|reverted\).*/\1/p')
git -C "$chief" log --format='%h %cs %s' --grep='^Provisional:' 2>/dev/null | while read -r h d rest; do
  printf '%s\n' "$verdicts" | grep -q "^$h" || echo "provisional, no verdict yet: $h $d $(echo "$rest" | cut -c1-60)"
done
