# verified-fix

English | [日本語](README.ja.md)

A Claude Code plugin that makes Claude back up every "I fixed it" with a fact it actually checked.
It prevents "fixed" or "should work now" after testing in a different environment or under different conditions, followed by you trying it and finding it still broken.

## How it works

If a reply says things like "I fixed it", "found the root cause" or "it should work now", it must contain one of these lines (Stop hook).

```
Verified: what was checked, under the same conditions as your problem
Unverified: what could not be checked under those conditions
```

・If neither line is there, the reply is blocked and Claude rewrites it
・If the reply says "Unverified:" but still asserts the fix, that is blocked too
・Japanese replies use `確認:` / `未確認:` and are checked for phrases such as 「直しました」 and 「はずです」
・It asks for a rewrite once per turn. The second attempt is never blocked

The message is in English unless your locale is Japanese. Set `CLAUDE_HOOK_LANG=en` or `CLAUDE_HOOK_LANG=ja` to fix it.

## Install

```
/plugin marketplace add hisashihirajo/claude-skills
/plugin install verified-fix@claude-skills
```

Restart Claude Code after installing.

## Requirements

・Claude Code
・python3

## Tests

```
sh plugins/verified-fix/tests/run.sh
```
