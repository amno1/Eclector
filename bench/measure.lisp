;;;; Timing one case: one pass over a corpus, sampled with trivial-benchmark.

(in-package #:eclector-bench)

(defun hex (digest)
  (format nil "~(~{~2,'0X~}~)" (coerce digest 'list)))

(defun case-name (reader-name corpus-name)
  (format nil "~A ~A" reader-name corpus-name))

(defun pass-seconds (reader string)
  "Seconds for one pass, after warming up."
  (dotimes (i 3) (funcall reader string))
  (let ((best most-positive-double-float))
    (dotimes (i 3 best)
      (let ((t0 (now-seconds)))
        (funcall reader string)
        (setf best (min best (- (now-seconds) t0)))))))

(defvar *gc-count* 0)
(push (lambda () (incf *gc-count*)) sb-ext:*after-gc-hooks*)

(defun measure (name reader string)
  (declare (function reader) (simple-string string))
  (let* ((forms (funcall reader string))
         (reps (max 1 (ceiling *target-seconds* (pass-seconds reader string))))
         (timer (make-instance 'tb:timer))
         (gc0 0))
    (sb-ext:gc :full t)
    (setf gc0 *gc-count*)
    (dotimes (i *samples*)
      (tb:with-sampling (timer wall-seconds gc-seconds tb:bytes-consed)
        (dotimes (r reps) (funcall reader string))))
    (flet ((per-pass (metric computation)
             (/ (tb:compute computation (tb:samples timer metric)) reps)))
      (let ((wall (tb:samples timer 'wall-seconds)))
        (format t "~A~C~,1F~C~,1F~C~,0F~C~,2F~C~D~C~D~%"
                name
                #\Tab (* 1d9 (per-pass 'wall-seconds :minimum))
                #\Tab (* 1d9 (per-pass 'wall-seconds :median))
                #\Tab (per-pass 'tb:bytes-consed :average)
                #\Tab (* 100 (/ (tb:compute :total (tb:samples timer 'gc-seconds))
                                (tb:compute :total wall)))
                #\Tab forms
                #\Tab (- *gc-count* gc0))))))

;;; Sustained reading: the same corpus over and over, timed as one long run
;;; with the GC included, so that less consing shows up as less GC work.
;;; RETAIN keeps the results of the last 20 passes alive (a reader whose
;;; output is used, so some of what it conses survives a few GCs);
