#!/usr/bin/env python3
"""Stop hook. Blocks a reply that is too long and asks for a short, results-only report.
Stop フック。返答が長すぎたら止めて、結果だけの短い報告に書き直させる。

After long work, reports tend to grow with investigation history, tried hypotheses and pasted logs.
If the last reply of this turn exceeds the limit (lines or characters), it is blocked.
長い作業のあとほど、調査の経緯や試したこと、ログの貼り付けで報告が膨らむ。
このターンの最後の返答が上限（行数か字数）を超えていたら止める。

Limits / 上限: CONCISE_REPORT_MAX_LINES, CONCISE_REPORT_MAX_CHARS
Message language / 注意文の言語: CLAUDE_HOOK_LANG=ja|en (default: ja if LANG starts with ja, otherwise en)
"""
import json
import os
import sys

MAX_LINES = int(os.environ.get('CONCISE_REPORT_MAX_LINES', '25'))
MAX_CHARS = int(os.environ.get('CONCISE_REPORT_MAX_CHARS', '1500'))


def lang():
    v = os.environ.get('CLAUDE_HOOK_LANG') or os.environ.get('LC_ALL') or os.environ.get('LANG') or ''
    return 'ja' if v.lower().startswith('ja') else 'en'


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


def message(n_lines, n_chars):
    if lang() == 'ja':
        return (
            f'返答が {n_lines} 行・{n_chars} 字あります（上限 {MAX_LINES} 行・{MAX_CHARS} 字）。\n'
            '報告は「何ができるようになったか」「どこで確認できるか」「何をしてほしいか」だけにして、短く書き直してください。\n'
            '調査の経緯・試した仮説・ログ・比較表は書かないでください。'
            '長い本文（文書や原稿）を見せる必要があるなら、チャットに貼らずファイルに書き出し、その場所を伝えてください。'
        )
    return (
        f'The reply has {n_lines} lines and {n_chars} characters (limit: {MAX_LINES} lines, {MAX_CHARS} characters).\n'
        'Rewrite it as a short report that only says what now works, where to check it, and what you need from the user.\n'
        'Leave out the investigation history, tried hypotheses, logs and comparison tables. '
        'If a long text (a document or a draft) must be shown, write it to a file instead of the chat and give its path.'
    )


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
    print(json.dumps({'decision': 'block', 'reason': message(len(lines), len(reply))}, ensure_ascii=False))


if __name__ == '__main__':
    main()
