"""Publish CI logs as step summaries and bounded, secret-free annotations.

The sandbox can read GitHub's annotations API even when signed log-storage URLs
are unreachable. This keeps verification failures diagnosable without weakening
the workspace network policy or exposing credentials.
"""
import argparse
import os
from pathlib import Path
from urllib.parse import quote

parser = argparse.ArgumentParser()
parser.add_argument('files', nargs='+')
parser.add_argument('--annotate', action='store_true')
args = parser.parse_args()
summary_path = os.environ.get('GITHUB_STEP_SUMMARY')
for name in args.files:
    path = Path(name)
    if not path.exists():
        continue
    text = path.read_text(encoding='utf-8', errors='replace')
    print(text)
    if summary_path:
        with open(summary_path, 'a', encoding='utf-8') as summary:
            summary.write(f'\n## {path.name}\n\n```text\n{text[-45000:]}\n```\n')
    if args.annotate:
        # GitHub truncates long annotation messages. Keep complete failure blocks
        # in small chunks, preserving line boundaries where possible.
        chunks = []
        current = ''
        for line in text[-45000:].splitlines(keepends=True):
            if len(current) + len(line) > 750 and current:
                chunks.append(current)
                current = ''
            current += line[:750]
        if current:
            chunks.append(current)
        for index, chunk in enumerate(chunks, 1):
            message = quote(chunk, safe='')
            print(f'::error title={path.name} output {index}/{len(chunks)}::{message}')
