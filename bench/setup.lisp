;;;; Setup for cases.lisp: load Eclector from ECLECTOR_DIR, samplers, options.

(require :asdf)
(require :sb-md5)
(load (merge-pathnames "quicklisp/setup.lisp" (user-homedir-pathname)))

(let ((dir (sb-ext:posix-getenv "ECLECTOR_DIR")))
  (unless dir (error "ECLECTOR_DIR is not set"))
  (push (pathname (concatenate 'string (string-right-trim "/" dir) "/"))
        asdf:*central-registry*))
(push #p"/home/arthur/repos/cl/Concrete-Syntax-Tree/" asdf:*central-registry*)

(handler-bind ((warning #'muffle-warning))
  (let ((*standard-output* (make-broadcast-stream))
        (*error-output* (make-broadcast-stream)))
    (ql:quickload :trivial-benchmark :silent t)
    (asdf:load-system :eclector)
    (asdf:load-system :eclector-concrete-syntax-tree)))

(defpackage #:eclector-bench
  (:use #:cl)
  (:local-nicknames (#:tb #:org.shirakumo.trivial-benchmark)))
(defpackage #:eclector-bench-scratch (:use #:cl)) ; where the corpus interns
(in-package #:eclector-bench)

;;; Samplers: nanosecond-resolution wall time and GC time, instead of the
;;; stock REAL-TIME sampler, which only advances in 1 ms steps.
(defun now-ns ()
  (multiple-value-bind (s ns) (sb-unix:clock-gettime sb-unix:clock-monotonic)
    (+ (* s 1000000000) ns)))
(defun now-seconds () (/ (now-ns) 1d9))

(tb:define-delta-sampler (wall-seconds 1000000000) (now-ns))
(tb:define-delta-sampler (gc-seconds internal-time-units-per-second)
  sb-ext:*gc-run-time*)

(defparameter *samples*
  (or (ignore-errors (parse-integer (sb-ext:posix-getenv "SAMPLES"))) 15))
(defparameter *target-seconds*
  (/ (or (ignore-errors (parse-integer (sb-ext:posix-getenv "TARGET_MS"))) 25)
     1000d0))
(defparameter *only* (sb-ext:posix-getenv "ONLY"))
(defparameter *xcheck* (equal (sb-ext:posix-getenv "XCHECK") "1"))
