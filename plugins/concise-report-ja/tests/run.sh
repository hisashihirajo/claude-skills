#!/bin/sh
# 短い返答・長い返答・2回目の Stop を渡して、止める・止めないを確かめる
set -u
DIR=$(cd "$(dirname "$0")/.." && pwd)
TMP=$(mktemp -d)
FAIL=0

transcript() {  # $1=ファイル $2=アシスタントの文
  python3 -c '
import json, sys
rows = [
  {"type": "user", "message": {"content": "ログの出力先を変えたい"}},
  {"type": "assistant", "message": {"content": [{"type": "text", "text": sys.argv[2]}]}},
]
open(sys.argv[1], "w").write("\n".join(json.dumps(r, ensure_ascii=False) for r in rows) + "\n")
' "$1" "$2"
}

check() {  # $1=名前 $2=文 $3=期待（block|pass） $4=stop_hook_active
  transcript "$TMP/t.jsonl" "$2"
  OUT=$(printf '{"transcript_path":"%s","stop_hook_active":%s}' "$TMP/t.jsonl" "$4" | python3 "$DIR/scripts/check-long-reply.py")
  if [ -n "$OUT" ]; then GOT=block; else GOT=pass; fi
  if [ "$GOT" = "$3" ]; then echo "OK   $1"; else echo "NG   $1（期待 $3、結果 $GOT）"; FAIL=1; fi
}

SHORT='ログの出力先を変えました。次回の起動から効きます。'
LONG=$(python3 -c 'print("\n".join(f"{i}行目の経緯です。" for i in range(40)))')
WIDE=$(python3 -c 'print("あ" * 1600)')

check '短い返答は通す'              "$SHORT" pass false
check '行数が多い返答を止める'      "$LONG"  block false
check '字数が多い返答を止める'      "$WIDE"  block false
check '書き直しの2回目は止めない'   "$LONG"  pass true

rm -r "$TMP"
exit $FAIL
