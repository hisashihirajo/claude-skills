#!/bin/bash
# PreToolUse hook (Bash). Denies irreversible commands before they run.
#
# Rules written in CLAUDE.md are the first to be forgotten late in long work or in a hurry.
# This hook stops only three kinds of operations, matching the command string:
# deleting, overwriting, and editing production directly.
# It is string matching, not a permission boundary: commands run from script files
# or written another way can slip through.
#
# Blocked
#   1) Deleting or emptying a DB (DROP DATABASE / DROP SCHEMA ... CASCADE / TRUNCATE)
#   2) Removing Docker volumes or images in bulk
#   3) Irreversible git operations (push --force / clean -f)
#   4) Editing files on production over ssh (vi / nano / sed -i / tee / redirects)
#      List the hosts in BLOCK_DESTRUCTIVE_SSH_HOSTS, separated by spaces (not checked if unset)

set -u

cmd=$(python3 -c 'import json, sys
try:
    print((json.load(sys.stdin).get("tool_input") or {}).get("command") or "")
except ValueError:
    pass' 2>/dev/null)
[ -z "$cmd" ] && exit 0

deny() {
  python3 -c 'import json, sys
print(json.dumps({"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny",
      "permissionDecisionReason": "BLOCKED: " + sys.argv[1]}}))' "$1"
  exit 0
}

# git with options before the subcommand (git -C <dir>, git -c <key=value>)
GIT='git([[:space:]]+-[^[:space:]]+([[:space:]]+[^-[:space:]][^[:space:]]*)?)*[[:space:]]+'

# 1) Deleting or emptying a DB
# Text that only mentions it (inside echo, or in a draft) is not blocked.
# Only commands sent to a DB client or starting with DROP / TRUNCATE are checked.
to_db=0
printf '%s' "$cmd" | grep -qiE '(psql|mysql|sqlite3|drizzle|prisma|supabase|pg_)' && to_db=1
printf '%s' "$cmd" | grep -qiE '^[[:space:]]*(DROP|TRUNCATE)[[:space:]]' && to_db=1

if [ "$to_db" = "1" ] \
  && printf '%s' "$cmd" | grep -qiE 'DROP[[:space:]]+DATABASE|DROP[[:space:]]+SCHEMA[[:space:]]+[^;]*CASCADE|TRUNCATE[[:space:]]+(TABLE[[:space:]]+)?[a-z_]'; then
  deny 'This deletes or empties a database. Do not run it in development or production. Find a way to fix things without deleting, and ask the user if it is truly necessary.'
fi

if printf '%s' "$cmd" | grep -q 'supabase stop' && printf '%s' "$cmd" | grep -q -- '--no-backup'; then
  deny 'This stops Supabase without a backup. The data will be lost.'
fi

# 2) Removing Docker volumes or images
if printf '%s' "$cmd" | grep -qE 'docker[[:space:]]+(volume[[:space:]]+(rm|prune)|system[[:space:]]+prune)'; then
  deny 'This removes Docker volumes or images. Volumes keep the data even when no container exists, and removing them cannot be undone.'
fi

# 3) Irreversible git operations
if printf '%s' "$cmd" | grep -qE "${GIT}push[[:space:]]+[^|;&]*(--force|-f)([[:space:]]|$)"; then
  deny 'git push --force rewrites the remote history. Use it only when the user explicitly asks.'
fi

if printf '%s' "$cmd" | grep -qE "${GIT}clean[[:space:]]+[^|;&]*-[a-z]*f"; then
  deny 'git clean deletes untracked files, including files from other work in progress.'
fi

# 4) Editing files on production directly
for host in ${BLOCK_DESTRUCTIVE_SSH_HOSTS:-}; do
  if printf '%s' "$cmd" | grep -qE "ssh[[:space:]]+(-[^[:space:]]+[[:space:]]+)*([^[:space:]]+@)?${host}([[:space:]]|$)" \
     && printf '%s' "$cmd" | grep -qE '(vi|vim|nano|emacs)[[:space:]]+/|sed[[:space:]]+-i|tee[[:space:]]+/|>[[:space:]]*/'; then
    deny 'This edits a file directly on a production server. Edit it in the local repository and diff against production first. A change made only on production is lost at the next deploy.'
  fi
done

exit 0
