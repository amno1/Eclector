# Open items (live note)

Update this file when something is done, dropped or learned. Last state:
branch 41 commits after 1088a79 (0.13 + docs), all 23 code/test commits pass
both suites in a clean export, `origin/master` is still 1088a79.

## Open: item 7 reopened, list machinery (about one hour, then decide)

Evidence: 2000 lists of one atom `(x) (x) ...` read in 916 us, one flat list
of 2000 atoms in 390 us: about 263 ns per list. This says where per-list
cost sits, it does not say 26% of `source` would go away. A handler-case plus
SIGNAL of the end-of-list condition costs 31.7 ns (the signal about 24 ns),
at most 2.5-3.3% of a `source` pass, so it is not the main part.

Plan:
1. `sb-sprof` CPU and alloc (bench/profile.lisp, add the two corpora) and
   attribute the 263 ns to: signal, handler-case, %READ-LIST-ELEMENT (PEEK-CHAR,
   READ-MAYBE-NOTHING, READ-TOKEN), WITH-STATE-VALUES, the cons, dispatch.
2. Gate, set before looking: if the redundant read in %READ-LIST-ELEMENT is
   more than 5% of `base source` time, do one restructure commit; check with
   3x3 on `nested` and `source`, both suites, output check, a negative control.
   Otherwise close it with a code comment and stop.
3. Constraint: simply dropping PEEK-CHAR measured 0.99x nested and 0.95x
   source (comment in read.lisp). A restructure has to avoid the re-read
   without moving it, and keep recognizing the close character before readtable
   dispatch.

## Ideas recorded, not tried

* Several reader state aspects with one call, for clients other than NIL
  (comment in generic-functions.lisp). Needs a staleness rule.
* `cst source` is 4.37x of SBCL: source tracking, MAKE-EXPRESSION-RESULT,
  MAKE-INSTANCE of the nodes. Dotted lists still go through RECONSTRUCT.

## Closed by measurement (where it is written down)

* STATE-VALUE helpers in INTERPRET-TOKEN, INTERPRET-SYMBOL: tokens.lisp.
* MULTIPLE-VALUE-CALL in READ-COMMON: read-common.lisp.
* Dropping PEEK-CHAR: read.lisp.
* Token as buffer and range, %INTERN, fused case conversion: utilities.lisp.
* Marker for clients that do not override STATE-VALUE: generic-functions.lisp.

## Facts worth keeping

* Stock SBCL 2.6.9 (the distribution package) is what all numbers here come
  from. Eclector (4635 + 355 checks), lisp-case (all dialect tests) and el-fmt
  (its suite) pass on it. el-fmt is about 1.55x slower on stock for `%e`,
  `%g` and floats with `%s`, 1.13x for `%f`, the same for integers.
* lisp-case adds 1.10-1.12x over Eclector on numbers and strings: its client
  is not NIL, so it does not get the STATE-VALUE helpers.
* Not checked: whether the upstream project has moved since 1088a79.
* el-fmt README.md has an uncommitted re-wrap that is not from this work.

## How to measure

* `bench/make-corpus.sh` once; then
  `sbcl --script bench/3x3.lisp BEFORE_DIR AFTER_DIR [FILE]`.
* Run both suites: Eclector and `eclector-concrete-syntax-tree/test`.
* After an edit, `touch` the sources: ASDF compares whole seconds.
* Profile first, set the gate before looking, check that a test fails when
  the thing it guards is broken, and write down every closed idea.
