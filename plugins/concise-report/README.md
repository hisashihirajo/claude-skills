# concise-report

English | [日本語](README.ja.md)

A Claude Code plugin that blocks a reply that is too long and asks Claude to rewrite it as a short, results-only report.
After long work, reports tend to grow with investigation history and pasted logs. This stops that.

## How it works

・When Claude finishes a reply, the last reply is blocked if it is longer than 25 lines or 1,500 characters (Stop hook)
・Claude is asked to rewrite it with only what now works, where to check it, and what it needs from you
・It asks for a rewrite once per turn. The second attempt is never blocked, so it cannot loop

The limits can be changed with environment variables.

```
export CONCISE_REPORT_MAX_LINES=15
export CONCISE_REPORT_MAX_CHARS=1000
```

The message is in English unless your locale is Japanese. Set `CLAUDE_HOOK_LANG=en` or `CLAUDE_HOOK_LANG=ja` to fix it.

## Install

```
/plugin marketplace add hisashihirajo/claude-skills
/plugin install concise-report@claude-skills
```

Restart Claude Code after installing.

## Requirements

・Claude Code
・python3

## Tests

```
sh plugins/concise-report/tests/run.sh
```
