# block-destructive

English | [日本語版 (block-destructive-ja)](../block-destructive-ja/README.md)

A Claude Code plugin that denies irreversible commands before Claude runs them.
Writing "never delete" in CLAUDE.md is the first rule to be forgotten late in long work or in a hurry.
This hook stops only three kinds of operations: deleting, overwriting, and touching production directly.

## What it blocks (PreToolUse, Bash)

- Deleting or emptying a database (`DROP DATABASE`, `DROP SCHEMA ... CASCADE`, `TRUNCATE`)
- `supabase stop --no-backup`
- Removing Docker volumes or images in bulk (`docker volume rm`, `docker volume prune`, `docker system prune`)
- `git push --force` and `git clean -f` (including forms with options in between, such as `git -C <dir>`)
- Editing files directly on a production server over ssh (`vi`, `nano`, `sed -i`, `tee`, redirects)

Text that merely mentions `DROP` (inside `echo`, or in a draft) is not blocked.
Only commands sent to a DB client (psql and others) or starting with `DROP` / `TRUNCATE` are checked.

Direct edits on production are checked only for the hosts you list.

```
export BLOCK_DESTRUCTIVE_SSH_HOSTS="prod web1"
```

## Limits

It matches the command string, so some forms slip through.
Deletions run from a script file, the contents of SQL files, and aliased commands are not caught.
Use it as a guardrail against mistakes, not as a permission boundary.

## Install

```
/plugin marketplace add hisashihirajo/claude-skills
/plugin install block-destructive@claude-skills
```

Restart Claude Code after installing.

## Requirements

- Claude Code
- bash and python3

## Tests

```
sh plugins/block-destructive/tests/run.sh
```
