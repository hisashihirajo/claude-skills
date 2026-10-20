#!/bin/sh
# Feed a short reply, a long reply and a second Stop, and check which are blocked
set -u
DIR=$(cd "$(dirname "$0")/.." && pwd)
TMP=$(mktemp -d)
FAIL=0

transcript() {  # $1=file $2=assistant text
  python3 -c '
import json, sys
rows = [
  {"type": "user", "message": {"content": "Change where the logs go"}},
  {"type": "assistant", "message": {"content": [{"type": "text", "text": sys.argv[2]}]}},
]
open(sys.argv[1], "w").write("\n".join(json.dumps(r) for r in rows) + "\n")
' "$1" "$2"
}

check() {  # $1=name $2=reply $3=expected (block|pass) $4=stop_hook_active
  transcript "$TMP/t.jsonl" "$2"
  OUT=$(printf '{"transcript_path":"%s","stop_hook_active":%s}' "$TMP/t.jsonl" "$4" | python3 "$DIR/scripts/check-long-reply.py")
  if [ -n "$OUT" ]; then GOT=block; else GOT=pass; fi
  if [ "$GOT" = "$3" ]; then echo "OK   $1"; else echo "NG   $1 (expected $3, got $GOT)"; FAIL=1; fi
}

SHORT='Logs now go to logs/app.log. It takes effect on the next start.'
LONG=$(python3 -c 'print("\n".join(f"Step {i} of the investigation." for i in range(40)))')
WIDE=$(python3 -c 'print("word " * 400)')

check 'Short reply passes'              "$SHORT" pass false
check 'Too many lines is blocked'       "$LONG"  block false
check 'Too many characters is blocked'  "$WIDE"  block false
check 'Second attempt is not blocked'   "$LONG"  pass true

rm -r "$TMP"
exit $FAIL
