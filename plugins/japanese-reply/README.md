# japanese-reply

English | [日本語](README.ja.md)

A Claude Code plugin that keeps Claude's replies in Japanese.
After long work or after reading English documents, replies tend to switch to English. This stops that.

## How it works

・On every prompt, Claude is reminded to answer in Japanese (UserPromptSubmit)
・If the short note Claude writes right before a tool call is in English, the tool call is blocked and Claude rewrites it (PreToolUse)
・If a finished reply is mostly English, Claude is asked to rewrite it (Stop)

Identifiers, commands, file names, URLs and code may stay in English and are not blocked.
The messages to Claude are always in Japanese, since the purpose is to keep replies in Japanese.

## Install

Run these two commands in Claude Code.

```
/plugin marketplace add hisashihirajo/claude-skills
/plugin install japanese-reply@claude-skills
```

Restart Claude Code after installing.

## Requirements

・Claude Code
・python3 (preinstalled on macOS and major Linux distributions)

## Disable or remove

```
/plugin disable japanese-reply@claude-skills
/plugin uninstall japanese-reply@claude-skills
```

## Tests

```
sh plugins/japanese-reply/tests/run.sh
```
