#!/bin/bash
# PreToolUse hook (Bash). Denies irreversible commands before they run.
# PreToolUse（Bash）。取り返しがつかない操作だけを、実行する前に止める。
#
# Rules written in CLAUDE.md are the first to be forgotten late in long work or in a hurry.
# This hook stops only three kinds of operations by matching the command string: deleting, overwriting,
# and editing production directly. It is string matching, not a permission boundary: commands run from
# script files or written another way can slip through.
# 文章で書いた決まりは、長い作業の終盤や急いでいるときほど守られない。
# 消す・上書きする・本番を直接触る、の3種類だけを、コマンドの文字列で見分けて止める。
# 文字列の照合なので、スクリプトの中で実行するものや、別の書き方をしたものは止まらない（権限の境界ではない）。
#
# Blocked / 止めるもの
#   1) Deleting or emptying a DB / DB を消す・空にする（DROP DATABASE / DROP SCHEMA ... CASCADE / TRUNCATE）
#   2) Removing Docker volumes or images in bulk / Docker のボリュームやイメージをまとめて消す
#   3) Irreversible git operations / git の取り返しがつかない操作（push --force / clean -f）
#   4) Editing files on production over ssh / 本番サーバ上でのファイル直接編集（vi / nano / sed -i / tee / リダイレクト）
#      Hosts are listed in BLOCK_DESTRUCTIVE_SSH_HOSTS, separated by spaces (not checked if unset)
#      対象のホストは環境変数 BLOCK_DESTRUCTIVE_SSH_HOSTS に空白区切りで書く（未設定なら見ない）
#
# Message language / 注意文の言語: CLAUDE_HOOK_LANG=ja|en (default: ja if LANG starts with ja, otherwise en)

set -u

cmd=$(python3 -c 'import json, sys
try:
    print((json.load(sys.stdin).get("tool_input") or {}).get("command") or "")
except ValueError:
    pass' 2>/dev/null)
[ -z "$cmd" ] && exit 0

hook_lang=en
case "${CLAUDE_HOOK_LANG:-${LC_ALL:-${LANG:-}}}" in ja*|JA*) hook_lang=ja ;; esac

deny() {  # $1=English $2=日本語
  if [ "$hook_lang" = ja ]; then msg=$2; else msg=$1; fi
  python3 -c 'import json, sys
print(json.dumps({"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny",
      "permissionDecisionReason": "BLOCKED: " + sys.argv[1]}}, ensure_ascii=False))' "$msg"
  exit 0
}

# git with options before the subcommand (git -C <dir>, git -c <key=value>)
# サブコマンドの前に付くオプション（git -C <場所>、git -c <設定>）も見る
GIT='git([[:space:]]+-[^[:space:]]+([[:space:]]+[^-[:space:]][^[:space:]]*)?)*[[:space:]]+'

# 1) Deleting or emptying a DB / DB を消す・空にする
# Text that only mentions it (inside echo, drafts) is not blocked. Only commands sent to a DB client
# or starting with DROP/TRUNCATE are checked.
# 文章として書いただけのもの（echo の中身、記事の下書き）は止めない。
# 実際に DB へ送る形か、コマンドの先頭にある場合だけ見る。
to_db=0
printf '%s' "$cmd" | grep -qiE '(psql|mysql|sqlite3|drizzle|prisma|supabase|pg_)' && to_db=1
printf '%s' "$cmd" | grep -qiE '^[[:space:]]*(DROP|TRUNCATE)[[:space:]]' && to_db=1

if [ "$to_db" = "1" ] \
  && printf '%s' "$cmd" | grep -qiE 'DROP[[:space:]]+DATABASE|DROP[[:space:]]+SCHEMA[[:space:]]+[^;]*CASCADE|TRUNCATE[[:space:]]+(TABLE[[:space:]]+)?[a-z_]'; then
  deny 'This deletes or empties a database. Do not run it in development or production. Find a way to fix things without deleting, and ask the user if it is truly necessary.' \
       'DB を消す・空にする操作です。開発でも本番でも実行しません。消さずに直す手を探し、どうしても必要ならユーザーに確認してください。'
fi

if printf '%s' "$cmd" | grep -q 'supabase stop' && printf '%s' "$cmd" | grep -q -- '--no-backup'; then
  deny 'This stops Supabase without a backup. The data will be lost.' \
       'バックアップを取らずに Supabase を止めようとしています。データが消えます。'
fi

# 2) Removing Docker volumes or images / Docker のボリューム・イメージをまとめて消す
if printf '%s' "$cmd" | grep -qE 'docker[[:space:]]+(volume[[:space:]]+(rm|prune)|system[[:space:]]+prune)'; then
  deny 'This removes Docker volumes or images. Volumes keep the data even when no container exists, and removing them cannot be undone.' \
       'Docker のボリュームやイメージを消そうとしています。コンテナが無くてもボリューム（データ）は残っています。消すと戻せません。'
fi

# 3) Irreversible git operations / git の取り返しがつかない操作
if printf '%s' "$cmd" | grep -qE "${GIT}push[[:space:]]+[^|;&]*(--force|-f)([[:space:]]|$)"; then
  deny 'git push --force rewrites the remote history. Use it only when the user explicitly asks.' \
       'git push --force はリモートの履歴を壊します。ユーザーが明示的に指示したときだけ使えます。'
fi

if printf '%s' "$cmd" | grep -qE "${GIT}clean[[:space:]]+[^|;&]*-[a-z]*f"; then
  deny 'git clean deletes untracked files, including files from other work in progress.' \
       'git clean は未追跡のファイルを消します。他の作業中のファイルまで巻き込みます。'
fi

# 4) Editing files on production directly / 本番サーバ上でのファイル直接編集
for host in ${BLOCK_DESTRUCTIVE_SSH_HOSTS:-}; do
  if printf '%s' "$cmd" | grep -qE "ssh[[:space:]]+(-[^[:space:]]+[[:space:]]+)*([^[:space:]]+@)?${host}([[:space:]]|$)" \
     && printf '%s' "$cmd" | grep -qE '(vi|vim|nano|emacs)[[:space:]]+/|sed[[:space:]]+-i|tee[[:space:]]+/|>[[:space:]]*/'; then
    deny 'This edits a file directly on a production server. Edit it in the local repository and diff against production first. A change made only on production is lost at the next deploy.' \
         '本番サーバのファイルを直接編集しようとしています。編集は手元のリポジトリで行い、先に本番と diff を取ってください。本番だけが新しい状態になると、次のデプロイで消えます。'
  fi
done

exit 0
