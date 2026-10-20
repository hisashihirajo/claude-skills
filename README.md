# claude-skills

English | [日本語](README.ja.md)

Plugins and skills for Claude Code.

## Plugins

| Name | What it does |
|---|---|
| [japanese-reply](plugins/japanese-reply/README.md) | Keeps Claude Code's replies in Japanese |
| [concise-report](plugins/concise-report/README.md) | Blocks a reply that is too long and asks for a short, results-only report |
| [verified-fix](plugins/verified-fix/README.md) | Requires a verified fact behind every "I fixed it" |
| [block-destructive](plugins/block-destructive/README.md) | Denies DB deletion, git push --force, direct edits on production and similar commands before they run |

## Install

Add this repository to Claude Code once.

```
/plugin marketplace add hisashihirajo/claude-skills
```

Then install a plugin by name.

```
/plugin install concise-report@claude-skills
```

## Message language

The messages a hook sends back to Claude exist in both English and Japanese.
If your locale (`LANG`) is Japanese they are in Japanese, otherwise in English.
To fix the language, set an environment variable.

```
export CLAUDE_HOOK_LANG=en
```

japanese-reply always uses Japanese, since its purpose is to keep replies in Japanese.

## License

MIT
