# claude-skills

English | [日本語](README.ja.md)

Plugins and skills for Claude Code.
Each plugin comes in an English version and a Japanese version (`-ja`). Install the one for the language you work in.

## Plugins

| English | Japanese | What it does |
|---|---|---|
| [concise-report](plugins/concise-report/README.md) | [concise-report-ja](plugins/concise-report-ja/README.md) | Blocks a reply that is too long and asks for a short, results-only report |
| [verified-fix](plugins/verified-fix/README.md) | [verified-fix-ja](plugins/verified-fix-ja/README.md) | Requires a verified fact behind every "I fixed it" |
| [block-destructive](plugins/block-destructive/README.md) | [block-destructive-ja](plugins/block-destructive-ja/README.md) | Denies DB deletion, git push --force, direct edits on production and similar commands before they run |
| | [japanese-reply](plugins/japanese-reply/README.md) | Keeps Claude Code's replies in Japanese |

## Install

Add this repository to Claude Code once.

```
/plugin marketplace add hisashihirajo/claude-skills
```

Then install a plugin by name.

```
/plugin install concise-report@claude-skills
```

## License

MIT
