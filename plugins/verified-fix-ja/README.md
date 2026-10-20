# verified-fix-ja

[English (verified-fix)](../verified-fix/README.md) | 日本語

Claude Code が「直しました」と報告するとき、確かめた事実を書かせるプラグインです。
別の環境や別の条件で試しただけで「直りました」「動くはずです」と言い切り、ユーザーが試して外れる、を防ぎます。

## 動き

返答に「直しました」「原因を突き止めました」「動くはずです」などがあれば、次のどちらかの行を求めます（Stop）。

```
確認: ユーザーと同じ条件で、何を見て直ったと分かったか
未確認: 同じ条件で確かめられていないこと
```

・どちらの行も無ければ止めて、書き直させます
・「未確認」を書いたのに「直しました」「はずです」と言い切っていれば、それも止めます
・書き直しは1回だけ求めます。2回目は止めません

## インストール

```
/plugin marketplace add hisashihirajo/claude-skills
/plugin install verified-fix-ja@claude-skills
```

インストール後、Claude Code を起動し直すと有効になります。

## 必要なもの

・Claude Code
・python3

## テスト

```
sh plugins/verified-fix-ja/tests/run.sh
```
