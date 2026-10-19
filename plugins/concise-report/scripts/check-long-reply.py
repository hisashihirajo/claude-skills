#!/usr/bin/env python3
"""Stop。返答が長すぎたら止めて、結果だけの短い報告に書き直させる。

長い作業のあとほど、調査の経緯や試したこと、ログの貼り付けで報告が膨らむ。
このターンの最後の返答が上限（行数か字数）を超えていたら止める。
上限は環境変数 CONCISE_REPORT_MAX_LINES / CONCISE_REPORT_MAX_CHARS で変えられる。
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
        f'返答が {len(lines)} 行・{len(reply)} 字あります（上限 {MAX_LINES} 行・{MAX_CHARS} 字）。\n'
        '報告は「何ができるようになったか」「どこで確認できるか」「何をしてほしいか」だけにして、短く書き直してください。\n'
        '調査の経緯・試した仮説・ログ・比較表は書かないでください。'
        '長い本文（文書や原稿）を見せる必要があるなら、チャットに貼らずファイルに書き出し、その場所を伝えてください。'
    )
    print(json.dumps({'decision': 'block', 'reason': reason}, ensure_ascii=False))


if __name__ == '__main__':
    main()
