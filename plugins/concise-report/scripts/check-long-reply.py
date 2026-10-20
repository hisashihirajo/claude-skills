#!/usr/bin/env python3
"""Stop hook. Blocks a reply that is too long and asks for a short, results-only report.

After long work, reports tend to grow with investigation history, tried hypotheses and pasted logs.
If the last reply of this turn exceeds the limit (lines or characters), it is blocked.
The limits can be changed with CONCISE_REPORT_MAX_LINES and CONCISE_REPORT_MAX_CHARS.
"""
import json
import os
import sys

MAX_LINES = int(os.environ.get('CONCISE_REPORT_MAX_LINES', '25'))
MAX_CHARS = int(os.environ.get('CONCISE_REPORT_MAX_CHARS', '1500'))


def load_rows(path):
    rows = []
    with open(path, encoding='utf-8') as f:
        for line in f:
            try:
                rows.append(json.loads(line))
            except ValueError:
                continue
    return rows


def is_real_user(row):
    if row.get('type') != 'user':
        return False
    content = (row.get('message') or {}).get('content')
    return isinstance(content, str) and not content.lstrip().startswith('<')


def last_reply(rows):
    start = 0
    for i, row in enumerate(rows):
        if is_real_user(row):
            start = i
    reply = ''
    for row in rows[start:]:
        if row.get('type') != 'assistant':
            continue
        for p in (row.get('message') or {}).get('content') or []:
            if isinstance(p, dict) and p.get('type') == 'text' and p.get('text', '').strip():
                reply = p['text']
    return reply


def main():
    try:
        data = json.load(sys.stdin)
    except ValueError:
        return
    if data.get('stop_hook_active'):
        return
    path = data.get('transcript_path')
    if not path or not os.path.exists(path):
        return
    try:
        reply = last_reply(load_rows(path))
    except OSError:
        return
    if not reply:
        return

    lines = [l for l in reply.splitlines() if l.strip()]
    if len(lines) <= MAX_LINES and len(reply) <= MAX_CHARS:
        return
    reason = (
        f'The reply has {len(lines)} lines and {len(reply)} characters (limit: {MAX_LINES} lines, {MAX_CHARS} characters).\n'
        'Rewrite it as a short report that only says what now works, where to check it, and what you need from the user.\n'
        'Leave out the investigation history, tried hypotheses, logs and comparison tables. '
        'If a long text (a document or a draft) must be shown, write it to a file instead of the chat and give its path.'
    )
    print(json.dumps({'decision': 'block', 'reason': reason}))


if __name__ == '__main__':
    main()
