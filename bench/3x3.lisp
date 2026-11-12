;;;; 3x3 measurement of bench/cases.lisp on two Eclector checkouts.
;;;; 3 sets of 3 runs; per set, the lowest time of the 3 runs for each case;
;;;; the median of the 3 set minima is the reported number.  Every run
;;;; measures BEFORE and AFTER back to back (alternating which goes first), so
;;;; drift of a noisy machine hits both.  Before the timing, the output of both
;;;; checkouts is compared (XCHECK=1 in cases.lisp).
;;;;
;;;;   sbcl --script bench/3x3.lisp BEFORE_DIR AFTER_DIR [OUTPUT-FILE]
;;;;
;;;; LISP names the SBCL that runs the cases (default: sbcl); SAMPLES,
;;;; TARGET_MS and ONLY are passed on to cases.lisp.

(defparameter *sets* 3)
(defparameter *runs* 3)
(defparameter *lisp* (or (sb-ext:posix-getenv "LISP") "sbcl"))
(defparameter *cases*
  (namestring (merge-pathnames "cases.lisp" (directory-namestring *load-truename*))))

(dolist (file '("run" "collect" "report"))
  (load (merge-pathnames (concatenate 'string file ".lisp")
                         (directory-namestring *load-truename*))))

(defun main (before after out-file)
  (multiple-value-bind (same count) (check-output before after)
    (format *error-output* "output check: ~A (~D cases)~%"
            (if same "identical" "DIFFERENT") count)
    (multiple-value-bind (set-minima info names) (collect-timings before after)
      (print-report before after same set-minima info names out-file))))

(let ((args (cdr sb-ext:*posix-argv*)))
  (when (< (length args) 2)
    (format t "usage: sbcl --script bench/3x3.lisp BEFORE_DIR AFTER_DIR [OUTPUT-FILE]~%")
    (sb-ext:exit :code 1))
  (main (first args) (second args) (third args)))
