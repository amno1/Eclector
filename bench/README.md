# Measuring Eclector changes

Reading speed and consing of two Eclector checkouts, on the same SBCL.

```
bench/make-corpus.sh                            # once: generates bench/corpus/
git worktree add /tmp/before <rev>              # the build to compare against
sbcl --script bench/3x3.lisp /tmp/before $PWD bench/3x3-NAME.txt
```

## Files

* `cases.lisp` loads one checkout (`ECLECTOR_DIR`) and prints one line per
  case. It loads `setup`, `corpora`, `readers`, `measure`, `sustained` and
  `main` from the same directory.
* `3x3.lisp` compares two checkouts with `cases.lisp`; `run`, `collect` and
  `report` hold the parts of it.
* `make-corpus.sh` writes `corpus/eclector-reader.txt` (not committed):
  `code/reader/*.lisp` of a fixed revision, so both sides read the same text.
* `profile.lisp` runs `sb-sprof` (see the file for the options).

## Method

* Cases are timed with
  [trivial-benchmark](https://codeberg.org/shinmera/trivial-benchmark): a
  `tb:timer` collects one sample per batch of passes, with nanosecond wall
  time (`sb-unix:clock-gettime`; the stock `real-time` sampler only ticks in
  1 ms steps), GC time and bytes consed as samplers.
* A case is a corpus read completely, form by form, by SBCL's own reader
  (`sbcl`, the reference), by the base reader (`base`) or by the CST client
  (`cst`). The corpora: symbols, qualified symbols, numbers, strings, `#\`
  characters, nested lists and dotted tails, `#` syntax, quote/backquote,
  comments, and `source` (the generated corpus file).
* `3x3.lisp` is the same method as el-fmt's: 3 sets of 3 runs, per set the
  lowest time per case, median of the three set minima reported. BEFORE and
  AFTER alternate within each run. `spread%` is the largest difference between
  the set minima relative to the median; a ratio inside its spread means
  nothing. `KB` (consed per corpus pass), `gc%` (share of wall time in GC)
  and `GCs` (number of collections) are medians over all 9 runs.
* Environment: `LISP` (default `sbcl`), `SAMPLES` (15 per case), `TARGET_MS`
  (25, wall time of one sample), `ONLY=text` (case-name filter).
