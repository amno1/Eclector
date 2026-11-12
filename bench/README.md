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
* A warm-up of 1.5 s reads `source` before the first case: without it the
  first cases of a process run while the CPU is still ramping up and show
  40-50% spread.
* ASDF compares file times in whole seconds. After editing a source file,
  `touch` it (or build with `--force`) before an A/B run, or a stale build
  may be measured; the same goes for the test suite.
* Environment: `LISP` (default `sbcl`), `SAMPLES` (15 per case), `TARGET_MS`
  (25, wall time of one sample), `ONLY=text` (case-name filter).

## Cases for the GC

On the corpora above GC is under 1% of the time, so less consing does not
show. The `gc` cases read `source` 400 times in a row as one timed run and
report the time per pass including GC:

* `sustained`: nothing is kept.
* `retained`: the results of the last 20 passes stay alive.
* `sustained 8MB`: as `sustained`, with `bytes-consed-between-gcs` set to
  8 MB, so that there are many more collections.

Select them with `ONLY="gc "`.

## Output identity

Before timing, `3x3.lisp` runs `cases.lisp` with `XCHECK=1` on both sides:
an MD5 of the printed results (`raw` of the CST for the CST reader) for every
case. The line `output: identical` must be there; otherwise a speed-up is
not a speed-up. The same check by hand:

```
ECLECTOR_DIR=$PWD XCHECK=1 sbcl --noinform --non-interactive --no-userinit --load bench/cases.lisp
```

The base and CST reader must print the same digest for the same corpus. The
`sbcl` rows differ from them for `quote` and `source` (SBCL reads backquote
into its own representation), so only the digests of the same row on the two
checkouts are compared.

## Controls

1. **Identical copy**: compare a checkout with a `git archive` copy of itself.
   Ratios must be 1.00 +- spread. If not, fix the measurement first.
2. **Dummy function**: add a never-called function near the changed code to a
   copy of the old checkout; a "regression" that shows up there too is image
   layout, not the change.

See `~/repos/cl/cl-emacs/el-fmt/bench/METHODOLOGY.md` for the reasons (two
machine speeds, layout noise of 4-10 %).
