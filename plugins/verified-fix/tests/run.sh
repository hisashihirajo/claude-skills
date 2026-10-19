#!/bin/sh
# 修正の報告を含む返答を渡して、止める・止めないを確かめる
set -u
DIR=$(cd "$(dirname "$0")/.." && pwd)
TMP=$(mktemp -d)
FAIL=0

transcript() {  # $1=ファイル $2=アシスタントの文
  python3 -c '
import json, sys
rows = [
  {"type": "user", "message": {"content": "ログインできない"}},
  {"type": "assistant", "message": {"content": [{"type": "text", "text": sys.argv[2]}]}},
]
open(sys.argv[1], "w").write("\n".join(json.dumps(r, ensure_ascii=False) for r in rows) + "\n")
' "$1" "$2"
}

check() {  # $1=名前 $2=文 $3=期待（block|pass）
  transcript "$TMP/t.jsonl" "$2"
  printf '{"transcript_path":"%s"}' "$TMP/t.jsonl" | python3 "$DIR/scripts/check-fix-claim.py" 2>/dev/null
  if [ $? -eq 2 ]; then GOT=block; else GOT=pass; fi
  if [ "$GOT" = "$3" ]; then echo "OK   $1"; else echo "NG   $1（期待 $3、結果 $GOT）"; FAIL=1; fi
}

check '確かめた事実の無い修正報告を止める' 'セッションの期限を直しました。' block
check '「はずです」も止める'               'これでログインできるはずです。' block
check '確認の行があれば通す'               "$(printf 'セッションの期限を直しました。\n確認: 同じアカウントで実際にログインし、画面が開いた')" pass
check '未確認で言い切っていたら止める'     "$(printf 'セッションの期限を直しました。\n未確認: 本番のアカウントでは試せていない')" block
check '未確認で言い切らなければ通す'       "$(printf '対策を入れました（未確認）。原因を特定するため、期限の設定を変えています。\n未確認: 本番のアカウントでは試せていない')" pass
check '修正の話でなければ通す'             'ログの出力先を変えました。' pass
check '英語の修正報告を止める'             'I fixed the session timeout.' block
check '英語で Verified があれば通す'       "$(printf 'I fixed the session timeout.\nVerified: logged in with the same account and the page loaded.')" pass

rm -r "$TMP"
exit $FAIL
