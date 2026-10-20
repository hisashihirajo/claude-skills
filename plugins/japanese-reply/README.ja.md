# japanese-reply

[English](README.md) | 日本語

Claude Code の返答を日本語に保つプラグインです。
長い作業のあとや英語の資料を読んだあとに、返答が英語に切り替わるのを止めます。

## 動き

・入力のたびに、日本語で答えるよう念を押します（UserPromptSubmit）
・ツールを使う直前の一言が英語なら、そのツールを止めて書き直させます（PreToolUse）
・返答を書き終えたときに英語が中心なら、書き直させます（Stop）

識別子・コマンド・ファイル名・URL・コードは英語のままで止まりません。

## インストール

Claude Code で次の2つを実行します。

```
/plugin marketplace add hisashihirajo/claude-skills
/plugin install japanese-reply@claude-skills
```

インストール後、Claude Code を起動し直すと有効になります。

## 必要なもの

・Claude Code
・python3（macOS と主要な Linux には最初から入っています）

## 無効にする・削除する

```
/plugin disable japanese-reply@claude-skills
/plugin uninstall japanese-reply@claude-skills
```

## テスト

```
sh plugins/japanese-reply/tests/run.sh
```

