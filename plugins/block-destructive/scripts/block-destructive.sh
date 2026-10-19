#!/bin/bash
# PreToolUse（Bash）。取り返しがつかない操作だけを、実行する前に止める。
#
# 文章で書いた決まりは、長い作業の終盤や急いでいるときほど守られない。
# 消す・上書きする・本番を直接触る、の3種類だけを、コマンドの文字列で見分けて止める。
# 文字列の照合なので、スクリプトの中で実行するものや、別の書き方をしたものは止まらない（権限の境界ではない）。
#
# 止めるもの
#   1) DB を消す・空にする（DROP DATABASE / DROP SCHEMA ... CASCADE / TRUNCATE）
#   2) Docker のボリュームやイメージをまとめて消す
#   3) git の取り返しがつかない操作（push --force / clean -f）
#   4) 本番サーバ上でのファイル直接編集（ssh 越しの vi / nano / sed -i / tee / リダイレクト）
#      対象のホストは環境変数 BLOCK_DESTRUCTIVE_SSH_HOSTS に空白区切りで書く（未設定なら見ない）

set -u

cmd=$(python3 -c 'import json, sys
try:
    print((json.load(sys.stdin).get("tool_input") or {}).get("command") or "")
except ValueError:
    pass' 2>/dev/null)
[ -z "$cmd" ] && exit 0

deny() {
  python3 -c 'import json, sys
print(json.dumps({"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny",
      "permissionDecisionReason": "BLOCKED: " + sys.argv[1]}}, ensure_ascii=False))' "$1"
  exit 0
}

# 1) DB を消す・空にする
# 文章として書いただけのもの（echo の中身、記事の下書き）は止めない。
# 実際に DB へ送る形か、コマンドの先頭にある場合だけ見る。
to_db=0
printf '%s' "$cmd" | grep -qiE '(psql|mysql|sqlite3|drizzle|prisma|supabase|pg_)' && to_db=1
printf '%s' "$cmd" | grep -qiE '^[[:space:]]*(DROP|TRUNCATE)[[:space:]]' && to_db=1

if [ "$to_db" = "1" ] \
  && printf '%s' "$cmd" | grep -qiE 'DROP[[:space:]]+DATABASE|DROP[[:space:]]+SCHEMA[[:space:]]+[^;]*CASCADE|TRUNCATE[[:space:]]+(TABLE[[:space:]]+)?[a-z_]'; then
  deny 'DB を消す・空にする操作です。開発でも本番でも実行しません。消さずに直す手を探し、どうしても必要ならユーザーに確認してください。'
fi

if printf '%s' "$cmd" | grep -q 'supabase stop' && printf '%s' "$cmd" | grep -q -- '--no-backup'; then
  deny 'バックアップを取らずに Supabase を止めようとしています。データが消えます。'
fi

# 2) Docker のボリューム・イメージをまとめて消す
if printf '%s' "$cmd" | grep -qE 'docker[[:space:]]+(volume[[:space:]]+(rm|prune)|system[[:space:]]+prune)'; then
  deny 'Docker のボリュームやイメージを消そうとしています。コンテナが無くてもボリューム（データ）は残っています。消すと戻せません。'
fi

# 3) git の取り返しがつかない操作
if printf '%s' "$cmd" | grep -qE 'git([[:space:]]+-[^[:space:]]+([[:space:]]+[^-[:space:]][^[:space:]]*)?)*[[:space:]]+push[[:space:]]+[^|;&]*(--force|-f)([[:space:]]|$)'; then
  deny 'git push --force はリモートの履歴を壊します。ユーザーが明示的に指示したときだけ使えます。'
fi

if printf '%s' "$cmd" | grep -qE 'git([[:space:]]+-[^[:space:]]+([[:space:]]+[^-[:space:]][^[:space:]]*)?)*[[:space:]]+clean[[:space:]]+[^|;&]*-[a-z]*f'; then
  deny 'git clean は未追跡のファイルを消します。他の作業中のファイルまで巻き込みます。'
fi

# 4) 本番サーバ上でのファイル直接編集
for host in ${BLOCK_DESTRUCTIVE_SSH_HOSTS:-}; do
  if printf '%s' "$cmd" | grep -qE "ssh[[:space:]]+(-[^[:space:]]+[[:space:]]+)*([^[:space:]]+@)?${host}([[:space:]]|$)" \
     && printf '%s' "$cmd" | grep -qE '(vi|vim|nano|emacs)[[:space:]]+/|sed[[:space:]]+-i|tee[[:space:]]+/|>[[:space:]]*/'; then
    deny '本番サーバのファイルを直接編集しようとしています。編集は手元のリポジトリで行い、先に本番と diff を取ってください。本番だけが新しい状態になると、次のデプロイで消えます。'
  fi
done

exit 0
