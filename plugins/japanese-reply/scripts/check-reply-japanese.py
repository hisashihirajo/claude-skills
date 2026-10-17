#!/usr/bin/env python3
"""Stop。返答が英語になっていたら止めて、日本語で書き直させる。

このターンでユーザーに見せた文（ツールの合間の一言も含む）を1つずつ見て、
コード・URL・識別子を除いた残りが英語中心なら止める。
"""
import json
import os
import re
import sys

META = re.compile(r'check-reply-japanese')
JA = re.compile(r'[぀-ヿ㐀-鿿ｦ-ﾟ]')
LATIN_WORD = re.compile(r'[A-Za-z]{2,}')


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


def strip_code(text):
    text = re.sub(r'```.*?```', ' ', text, flags=re.S)
    text = re.sub(r'`[^`\n]*`', ' ', text)
    text = re.sub(r'https?://\S+', ' ', text)
    text = re.sub(r'\S+@\S+', ' ', text)
    text = re.sub(r'(?:[\w.-]+/)+[\w.-]+', ' ', text)  # パス
    text = re.sub(r'\b[\w-]*[_\d][\w-]*\b', ' ', text)  # user_id・v2 など識別子
    return text


def is_english(text):
    body = strip_code(text)
    ja = len(JA.findall(body))
    words = LATIN_WORD.findall(body)
    latin = sum(len(w) for w in words)
    if len(words) < 6:
        return False
    # 日本語の文字が英字の3割に届かなければ英語の文とみなす
    return ja < latin * 0.3


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
        rows = load_rows(path)
    except OSError:
        return
    start = 0
    for i, row in enumerate(rows):
        if is_real_user(row):
            start = i
    hits = []
    for row in rows[start:]:
        if row.get('type') != 'assistant':
            continue
        for p in (row.get('message') or {}).get('content') or []:
            if isinstance(p, dict) and p.get('type') == 'text':
                t = p.get('text', '').strip()
                if t and not META.search(t) and is_english(t):
                    hits.append(t.splitlines()[0][:80])
    if hits:
        print(json.dumps({'decision': 'block', 'reason': (
            '返答が英語になっています。\n'
            + '\n'.join(f'  {h}' for h in hits[:3]) + '\n'
            '回答・報告・途中経過の一言まで、すべて日本語で書き直してください。'
            '識別子・コマンド・ファイル名・製品名だけは英語のままでかまいません。'
        )}, ensure_ascii=False))


if __name__ == '__main__':
    main()
