# claude-skills

[English](README.md) | 日本語

Claude Code 用のプラグインとスキルをまとめたリポジトリです。
プラグインは英語版と日本語版（名前の最後が `-ja`）に分けてあります。使う言語に合わせてどちらかを入れてください。

## 収録しているもの

| 日本語版 | 英語版 | 内容 |
|---|---|---|
| [concise-report-ja](plugins/concise-report-ja/README.md) | [concise-report](plugins/concise-report/README.md) | 返答が長すぎたら止めて、結果だけの短い報告に書き直させるフック |
| [verified-fix-ja](plugins/verified-fix-ja/README.md) | [verified-fix](plugins/verified-fix/README.md) | 「直しました」と報告するなら、同じ条件で確かめた事実を書かせるフック |
| [block-destructive-ja](plugins/block-destructive-ja/README.md) | [block-destructive](plugins/block-destructive/README.md) | DB の削除・git push --force・本番の直接編集などを実行前に止めるフック |
| [japanese-reply](plugins/japanese-reply/README.ja.md) | | Claude Code の返答を日本語に保つフック |

## インストール

最初に1回だけ、このリポジトリを Claude Code に登録します。

```
/plugin marketplace add hisashihirajo/claude-skills
```

そのあと、使いたいものを名前で入れます。

```
/plugin install concise-report-ja@claude-skills
```

## ライセンス

MIT
