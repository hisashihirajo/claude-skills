# claude-skills

Claude Code 用のプラグインとスキルをまとめたリポジトリです。

## 収録しているもの

| 名前 | 内容 |
|---|---|
| [japanese-reply](plugins/japanese-reply/) | Claude Code の返答を日本語に保つフック |
| [concise-report](plugins/concise-report/) | 返答が長すぎたら止めて、結果だけの短い報告に書き直させるフック |
| [verified-fix](plugins/verified-fix/) | 「直しました」と報告するなら、同じ条件で確かめた事実を書かせるフック |
| [block-destructive](plugins/block-destructive/) | DB の削除・git push --force・本番の直接編集などを実行前に止めるフック |

## インストール

最初に1回だけ、このリポジトリを Claude Code に登録します。

```
/plugin marketplace add hisashihirajo/claude-skills
```

そのあと、使いたいものを名前で入れます。

```
/plugin install japanese-reply@claude-skills
```

## ライセンス

MIT
