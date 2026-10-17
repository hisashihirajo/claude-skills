#!/bin/sh
# 3本のフックに、日本語と英語の会話記録を渡して、止める・止めないを確かめる
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

check() {  # $1=名前 $2=スクリプト $3=文 $4=期待（block|pass）
  transcript "$TMP/t.jsonl" "$3"
  OUT=$(printf '{"transcript_path":"%s"}' "$TMP/t.jsonl" | python3 "$DIR/scripts/$2")
  if [ -n "$OUT" ]; then GOT=block; else GOT=pass; fi
  if [ "$GOT" = "$4" ]; then echo "OK   $1"; else echo "NG   $1（期待 $4、結果 $GOT）"; FAIL=1; fi
}

EN='The build finished without errors, and all tests passed on the first run.'
JA='ビルドが終わりました。テストもすべて通っています。'
MIX='`config.json` の logLevel を debug に変えました。次回の起動から効きます。'

check 'Stop: 英語の返答を止める'          check-reply-japanese.py   "$EN"  block
check 'Stop: 日本語の返答は通す'          check-reply-japanese.py   "$JA"  pass
check 'Stop: 識別子まじりの日本語は通す'  check-reply-japanese.py   "$MIX" pass
check 'PreToolUse: 英語の一言を止める'    check-midturn-japanese.py "$EN"  block
check 'PreToolUse: 日本語の一言は通す'    check-midturn-japanese.py "$JA"  pass

R=$(echo '{}' | sh "$DIR/scripts/remind-japanese.sh")
case "$R" in *日本語*) echo 'OK   UserPromptSubmit: 念押しを出す' ;; *) echo 'NG   UserPromptSubmit'; FAIL=1 ;; esac

rm -r "$TMP"
exit $FAIL
