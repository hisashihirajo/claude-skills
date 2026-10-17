#!/usr/bin/env python3
"""PreToolUse（全ツール）。ツールを呼ぶ直前に書いた一言が英語なら、そのツールを止める。

返答の最後の英語は Stop フック（check-reply-japanese.py）が止めるが、それは書き終えたあとで、
ツールの合間の一言は英語のまま画面に残る。ここでは、直前のアシスタントの文を会話記録から読み、
日本語の文字が1つも無く、英単語が3つ以上ある行があれば、ツールを止めて日本語で書き直させる。
"""
import json, re, sys

def main():
    try:
        inp = json.load(sys.stdin)
    except Exception:
        return
    tp = inp.get("transcript_path") or ""
    try:
        lines = open(tp, encoding="utf-8").read().splitlines()[-40:]
    except Exception:
        return
    texts = []
    for ln in reversed(lines):
        try:
            d = json.loads(ln)
        except Exception:
            continue
        if d.get("isSidechain"):
            continue
        t = d.get("type")
        if t == "user":
            c = d.get("message", {}).get("content")
            # ツールの結果は飛ばし、人の発言に当たったら止める
            if isinstance(c, list) and any(isinstance(b, dict) and b.get("type") == "tool_result" for b in c):
                break
            break
        if t == "assistant":
            for b in d.get("message", {}).get("content", []) or []:
                if isinstance(b, dict) and b.get("type") == "text":
                    texts.append(b.get("text", ""))
            if texts:
                break
    bad = []
    for tx in texts:
        for line in tx.splitlines():
            s = line.strip()
            if not s or s.startswith(("http", "/", "`", "$")):
                continue
            if re.search(r"[぀-ヿ一-鿿]", s):
                continue
            if len(re.findall(r"[A-Za-z]{2,}", s)) >= 3:
                bad.append(s[:80])
    if bad:
        print(json.dumps({"hookSpecificOutput": {"hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": "ツールを呼ぶ直前の一言が英語です。日本語で書き直してから、もう一度呼んでください。\n該当: " + " / ".join(bad[:2])}},
            ensure_ascii=False))

main()
