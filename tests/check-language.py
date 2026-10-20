#!/usr/bin/env python3
"""Checks that English and Japanese plugins are kept apart.

- English plugins (no -ja suffix, except japanese-reply) must not contain any Japanese character,
  except the link line to the Japanese version at the top of README.md
- Japanese plugins (-ja) must contain Japanese in every file
"""
import os
import re
import sys

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'plugins')
JA = re.compile(r'[぀-ヿ㐀-鿿＀-￯・]')
LINK = re.compile(r'^English \| \[日本語版 \([a-z-]+-ja\)\]\(\.\./[a-z-]+-ja/README\.md\)$')

fail = 0
for plugin in sorted(os.listdir(ROOT)):
    if plugin == 'japanese-reply':
        continue
    for d, _, files in os.walk(os.path.join(ROOT, plugin)):
        for f in files:
            path = os.path.join(d, f)
            rel = os.path.relpath(path, ROOT)
            lines = open(path, encoding='utf-8').read().splitlines()
            if plugin.endswith('-ja'):
                if not any(JA.search(l) for l in lines):
                    print(f'NG   {rel}: no Japanese in a Japanese plugin')
                    fail = 1
            else:
                for i, l in enumerate(lines, 1):
                    if JA.search(l) and not (f == 'README.md' and LINK.match(l)):
                        print(f'NG   {rel}:{i}: Japanese in an English plugin: {l.strip()[:60]}')
                        fail = 1
print('OK   English and Japanese plugins are separated' if not fail else 'NG   language check failed')
sys.exit(fail)
