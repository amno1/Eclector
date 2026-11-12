#!/bin/sh
# Generate corpus/eclector-reader.txt: code/reader/*.lisp of a fixed revision,
# concatenated, so that every checkout under test reads the same text.
# The revision is the 0.13 release plus documentation commits.
set -e
REV=1088a79
cd "$(dirname "$0")/.."
mkdir -p bench/corpus
for f in $(git ls-tree --name-only "$REV" code/reader/ | grep '\.lisp$' | sort); do
    git show "$REV:$f"
done > bench/corpus/eclector-reader.txt
