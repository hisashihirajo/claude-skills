# claude-skills

[English](README.md) | 日本語

Claude Code 用のプラグインとスキルをまとめたリポジトリです。

## 収録しているもの

| 名前 | 内容 |
|---|---|
| [japanese-reply](plugins/japanese-reply/README.ja.md) | Claude Code の返答を日本語に保つフック |
| [concise-report](plugins/concise-report/README.ja.md) | 返答が長すぎたら止めて、結果だけの短い報告に書き直させるフック |
| [verified-fix](plugins/verified-fix/README.ja.md) | 「直しました」と報告するなら、同じ条件で確かめた事実を書かせるフック |
| [block-destructive](plugins/block-destructive/README.ja.md) | DB の削除・git push --force・本番の直接編集などを実行前に止めるフック |

## インストール

最初に1回だけ、このリポジトリを Claude Code に登録します。

```
/plugin marketplace add hisashihirajo/claude-skills
```

そのあと、使いたいものを名前で入れます。

```
/plugin install concise-report@claude-skills
```

## 注意文の言語

フックが Claude に返す注意文は、日本語と英語の両方を持っています。
パソコンの言語設定（環境変数 `LANG`）が日本語なら日本語、それ以外なら英語で出ます。
決めて使いたいときは、環境変数で指定します。

```
export CLAUDE_HOOK_LANG=ja
```

japanese-reply は返答を日本語に保つためのものなので、注意文は常に日本語です。

## ライセンス

MIT
