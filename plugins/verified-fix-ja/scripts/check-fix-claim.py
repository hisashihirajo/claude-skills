#!/usr/bin/env python3
"""Stop フック。「直しました」「原因を突き止めました」と報告する返答を、確かめた事実が無ければ止める。

別の環境や別の条件で試しただけで「直りました」「動くはずです」と書き、ユーザーが試して外れる、を防ぐ。
返答に修正の報告があれば、返答の中に次のどちらかの行を求める。
  確認: <ユーザーの症状と同じ条件で、何を見て直ったと分かったか>
  未確認: <同じ条件で確かめられていないこと（と、その理由）>
「未確認」を書いた返答では「直しました」と言い切らせない（「対策を入れました（未確認）」の形にする）。
"""
import json
import os
import re
import sys

CLAIM = re.compile(
    r'(直しました|直りました|解決しました|修正しました|原因を突き止め|原因が分かりました|原因を特定|'
    r'(?:出る|動く|外れる|効く|入る|直る|できる)はずです)'
)
CONFIRMED = re.compile(r'^\s*[・]?\s*確認[:：]\s*\S', re.M)
UNCONFIRMED = re.compile(r'^\s*[・]?\s*未確認[:：]\s*\S', re.M)
# この決まり自体を論じている行は除く
META = re.compile(r'check-fix-claim|verified-fix')
ASSERT = re.compile(r'(直しました|直りました|解決しました|はずです)')


def last_reply(path):
    text = ''
    with open(path, encoding='utf-8') as f:
        for line in f:
            try:
                row = json.loads(line)
            except ValueError:
                continue
            if row.get('type') != 'assistant':
                continue
            parts = (row.get('message') or {}).get('content') or []
            body = ''.join(p.get('text', '') for p in parts
                           if isinstance(p, dict) and p.get('type') == 'text')
            if body.strip():
                text = body
    return text


def problems(text):
    claims = [l.strip() for l in text.splitlines() if CLAIM.search(l) and not META.search(l)]
    if not claims:
        return None
    if UNCONFIRMED.search(text):
        asserted = [l for l in claims if ASSERT.search(l)]
        if asserted:
            return ('「未確認」と書いたのに、言い切っています。「対策を入れました（未確認）」の形にし、'
                    '「はずです」を使わないでください。', asserted)
        return None
    if CONFIRMED.search(text):
        return None
    return ('「直した」「原因を突き止めた」と書くなら、ユーザーの症状と同じ条件で確かめた事実を'
            '「確認: ◯◯」の1行で書いてください。確かめていないなら「未確認: ◯◯」と書き、言い切らないでください。'
            '別の環境や別の条件で試しただけなら、それは未確認です。', claims)


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
        text = last_reply(path)
    except OSError:
        return
    found = problems(text)
    if not found:
        return
    reason, lines = found
    shown = '\n'.join(f'  {s}' for s in lines[:5])
    print(f'{reason}\n該当:\n{shown}', file=sys.stderr)
    sys.exit(2)


if __name__ == '__main__':
    main()
