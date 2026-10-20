#!/usr/bin/env python3
"""Stop hook. Blocks a fix claim ("I fixed it", "it should work now") that has no verified fact behind it.

It prevents "fixed" or "should work" after testing in a different environment or under different conditions,
followed by the user trying it and finding it still broken.
If the reply claims a fix, it must contain one of these lines:
  Verified: <what was checked, under the same conditions as the user's problem>
  Unverified: <what could not be checked under those conditions, and why>
With "Unverified:", the reply may not assert the fix ("Applied a change (unverified)" instead).
"""
import json
import os
import re
import sys

CLAIM = re.compile(
    r"\b(?:I(?:'ve| have)? fixed|(?:is|it's|has been|have been) (?:now )?fixed|"
    r"(?:is|it's) (?:now )?(?:resolved|working)|found the (?:root )?cause|should (?:now )?work|"
    r"should be (?:fixed|working|resolved))\b",
    re.I,
)
CONFIRMED = re.compile(r'^\s*[-*]?\s*Verified:\s*\S', re.M | re.I)
UNCONFIRMED = re.compile(r'^\s*[-*]?\s*Unverified:\s*\S', re.M | re.I)
# Lines that discuss this rule itself are skipped
META = re.compile(r'check-fix-claim|verified-fix')
ASSERT = re.compile(r"\b(?:I(?:'ve| have)? fixed|should (?:now )?work|should be (?:fixed|working|resolved)|(?:is|it's) (?:now )?working)\b", re.I)


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
            return ('The reply says "Unverified:" but still asserts the fix. '
                    'Write it as "Applied a change (unverified)" and do not say it should work.', asserted)
        return None
    if CONFIRMED.search(text):
        return None
    return ('If you say it is fixed or you found the cause, add one line starting with "Verified:" '
            "that states what you checked under the same conditions as the user's problem. "
            'If you could not check it, add an "Unverified:" line instead and do not assert the fix. '
            'Testing in a different environment or under different conditions counts as unverified.', claims)


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
    print(f'{reason}\nLines:\n{shown}', file=sys.stderr)
    sys.exit(2)


if __name__ == '__main__':
    main()
