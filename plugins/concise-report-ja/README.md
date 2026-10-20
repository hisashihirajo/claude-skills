# concise-report-ja

[English (concise-report)](../concise-report/README.md) | 日本語

Claude Code の返答が長すぎたら止めて、結果だけの短い報告に書き直させるプラグインです。
長い作業のあとに、調査の経緯やログの貼り付けで報告が膨らむのを止めます。

## 動き

・返答を書き終えたときに、最後の返答が25行か1500字を超えていたら止めます（Stop）
・止めたときは「何ができるようになったか」「どこで確認できるか」「何をしてほしいか」だけで書き直させます
・書き直しは1回だけ求めます。2回目は止めません（止まり続けることはありません）

上限は環境変数で変えられます。

```
export CONCISE_REPORT_MAX_LINES=15
export CONCISE_REPORT_MAX_CHARS=1000
```

## インストール

```
/plugin marketplace add hisashihirajo/claude-skills
/plugin install concise-report-ja@claude-skills
```

インストール後、Claude Code を起動し直すと有効になります。
英語版の concise-report と一緒に入れる必要はありません。

## 必要なもの

・Claude Code
・python3

## テスト

```
sh plugins/concise-report-ja/tests/run.sh
```
