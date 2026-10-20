#!/usr/bin/env python3
"""Stop hook. Blocks a fix claim ("I fixed it", "it should work now") that has no verified fact behind it.
Stop フック。「直しました」「原因を突き止めました」と報告する返答を、確かめた事実が無ければ止める。

It prevents "fixed" or "should work" after testing under different conditions, followed by the user trying and failing.
If the reply claims a fix, it must contain one of these lines:
別の条件で試しただけで「直りました」「動くはずです」と書き、ユーザーが試して外れる、を防ぐ。
返答に修正の報告があれば、返答の中に次のどちらかの行を求める。
  Verified: / 確認:     what was checked, under the same conditions as the user's problem
  Unverified: / 未確認: what could not be checked under those conditions, and why
With "Unverified:", the reply may not assert the fix ("Applied a change (unverified)" instead).
「未確認」を書いた返答では「直しました」と言い切らせない（「対策を入れました（未確認）」の形にする）。

Message language / 注意文の言語: CLAUDE_HOOK_LANG=ja|en (default: ja if LANG starts with ja, otherwise en)
"""
import json
import os
import re
import sys

CLAIM = re.compile(
    r'(直しました|直りました|解決しました|修正しました|原因を突き止め|原因が分かりました|原因を特定|'
    r'(?:出る|動く|外れる|効く|入る|直る|できる)はずです|'
    r"\b(?:I(?:'ve)? fixed|(?:is|it's|has been|have been) (?:now )?fixed|(?:is|it's) (?:now )?resolved|"
    r'found the (?:root )?cause|should (?:now )?work)\b)',
    re.I,
)
CONFIRMED = re.compile(r'^\s*[・\-*]?\s*(?:確認[:：]|Verified:)\s*\S', re.M | re.I)
UNCONFIRMED = re.compile(r'^\s*[・\-*]?\s*(?:未確認[:：]|Unverified:)\s*\S', re.M | re.I)
# Lines that discuss this rule itself are skipped / この決まり自体を論じている行は除く
META = re.compile(r'check-fix-claim|verified-fix')
ASSERT = re.compile(r"(直しました|直りました|解決しました|はずです|\bI(?:'ve)? fixed|should (?:now )?work)", re.I)

MESSAGES = {
    'ja': {
        'asserted': '「未確認」と書いたのに、言い切っています。「対策を入れました（未確認）」の形にし、「はずです」を使わないでください。',
        'missing': '「直した」「原因を突き止めた」と書くなら、ユーザーの症状と同じ条件で確かめた事実を'
                   '「確認: ◯◯」の1行で書いてください。確かめていないなら「未確認: ◯◯」と書き、言い切らないでください。'
                   '別の環境や別の条件で試しただけなら、それは未確認です。',
        'lines': '該当:',
    },
    'en': {
        'asserted': 'The reply says "Unverified:" but still asserts the fix. '
                    'Write it as "Applied a change (unverified)" and do not say it should work.',
        'missing': 'If you say it is fixed or you found the cause, add one line starting with "Verified:" '
                   'that states what you checked under the same conditions as the user\'s problem. '
                   'If you could not check it, add an "Unverified:" line instead and do not assert the fix. '
                   'Testing in a different environment or under different conditions counts as unverified.',
        'lines': 'Lines:',
    },
}


def lang():
    v = os.environ.get('CLAUDE_HOOK_LANG') or os.environ.get('LC_ALL') or os.environ.get('LANG') or ''
    return 'ja' if v.lower().startswith('ja') else 'en'


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
            return 'asserted', asserted
        return None
    if CONFIRMED.search(text):
        return None
    return 'missing', claims


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
    kind, lines = found
    m = MESSAGES[lang()]
    shown = '\n'.join(f'  {s}' for s in lines[:5])
    print(f'{m[kind]}\n{m["lines"]}\n{shown}', file=sys.stderr)
    sys.exit(2)


if __name__ == '__main__':
    main()
