;;;; Cases for the 3x3 comparison of two Eclector checkouts (bench/3x3.lisp).
;;;;
;;;; Loads Eclector (and the CST client) from ECLECTOR_DIR and measures each
;;;; case with trivial-benchmark.  Prints one line per case:
;;;;
;;;;   NAME <TAB> MIN-NS <TAB> MEDIAN-NS <TAB> BYTES <TAB> GC-PERCENT <TAB> FORMS
;;;;
;;;; MIN-NS / MEDIAN-NS: nanoseconds for one pass over the corpus (every
;;;; top-level form read once); BYTES: bytes consed per pass; GC-PERCENT:
;;;; share of the wall time spent in GC; FORMS: top-level forms per pass
;;;; (a sanity number that must be identical for BEFORE and AFTER).
;;;;
;;;; Environment:
;;;;   ECLECTOR_DIR  checkout to measure (required)
;;;;   SAMPLES       samples per case (default 15)
;;;;   TARGET_MS     wall time one sample should take (default 25)
;;;;   ONLY          only cases whose name contains this text
;;;;   XCHECK=1      do not time; print NAME <TAB> md5 of the printed results
;;;;                 (the output-identity check, see bench/README.md)

(defparameter cl-user::*bench-dir* (directory-namestring *load-truename*))

(dolist (file '("setup" "corpora" "readers" "measure" "sustained" "main"))
  (load (merge-pathnames (concatenate 'string file ".lisp") cl-user::*bench-dir*)))
