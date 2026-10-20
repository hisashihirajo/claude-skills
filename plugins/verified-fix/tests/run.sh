#!/bin/sh
# Feed replies that claim a fix, and check which are blocked
set -u
DIR=$(cd "$(dirname "$0")/.." && pwd)
TMP=$(mktemp -d)
FAIL=0

transcript() {  # $1=file $2=assistant text
  python3 -c '
import json, sys
rows = [
  {"type": "user", "message": {"content": "I cannot log in"}},
  {"type": "assistant", "message": {"content": [{"type": "text", "text": sys.argv[2]}]}},
]
open(sys.argv[1], "w").write("\n".join(json.dumps(r) for r in rows) + "\n")
' "$1" "$2"
}

check() {  # $1=name $2=reply $3=expected (block|pass)
  transcript "$TMP/t.jsonl" "$2"
  printf '{"transcript_path":"%s"}' "$TMP/t.jsonl" | python3 "$DIR/scripts/check-fix-claim.py" 2>/dev/null
  if [ $? -eq 2 ]; then GOT=block; else GOT=pass; fi
  if [ "$GOT" = "$3" ]; then echo "OK   $1"; else echo "NG   $1 (expected $3, got $GOT)"; FAIL=1; fi
}

check 'Fix claim without a verified fact is blocked'  'I fixed the session timeout.' block
check '"should work" is blocked'                      'You should now be able to log in. It should work.' block
check 'Passes with a Verified line'                   "$(printf 'I fixed the session timeout.\nVerified: logged in with the same account and the page loaded.')" pass
check 'Asserting the fix with Unverified is blocked'  "$(printf 'I fixed the session timeout.\nUnverified: could not test with the production account.')" block
check 'Unverified without asserting passes'           "$(printf 'Applied a change to the session timeout (unverified).\nUnverified: could not test with the production account.')" pass
check 'Reply that is not about a fix passes'          'Logs now go to logs/app.log.' pass

rm -r "$TMP"
exit $FAIL
