# block-destructive

[English](README.md) | 日本語

取り返しがつかない操作を、Claude Code が実行する前に止めるプラグインです。
CLAUDE.md に「消すな」と書いても、長い作業の終盤や急いでいるときほど守られません。
消す・上書きする・本番を直接触る、の3種類だけを機械で止めます。

## 止めるもの（PreToolUse・Bash）

・DB を消す・空にする（`DROP DATABASE`、`DROP SCHEMA ... CASCADE`、`TRUNCATE`）
・バックアップ無しの `supabase stop --no-backup`
・Docker のボリュームやイメージをまとめて消す（`docker volume rm`、`docker volume prune`、`docker system prune`）
・`git push --force` と `git clean -f`（`git -C <場所>` のようにオプションを挟んだものも含む）
・本番サーバ上でのファイル直接編集（ssh 越しの `vi`、`nano`、`sed -i`、`tee`、リダイレクト）

`echo` の中身や記事の下書きに `DROP` と書いただけでは止まりません。
DB のクライアント（psql など）に渡す形か、コマンドの先頭にある場合だけ見ます。

本番サーバの直接編集は、対象のホスト名を環境変数に書いたときだけ見ます。

```
export BLOCK_DESTRUCTIVE_SSH_HOSTS="prod web1"
```

注意文は、パソコンの言語設定が日本語なら日本語で出ます。決めて使いたいときは `CLAUDE_HOOK_LANG=ja` か `CLAUDE_HOOK_LANG=en` を指定します。

## 限界

コマンドの文字列で見分けているので、すり抜ける書き方はあります。
スクリプトのファイルの中で実行する削除、SQL ファイルの中身、別名を付けたコマンドなどは止まりません。
権限を制限する仕組みではなく、うっかりを止める安全柵として使ってください。

## インストール

```
/plugin marketplace add hisashihirajo/claude-skills
/plugin install block-destructive@claude-skills
```

インストール後、Claude Code を起動し直すと有効になります。

## 必要なもの

・Claude Code
・bash と python3

## テスト

```
sh plugins/block-destructive/tests/run.sh
```
