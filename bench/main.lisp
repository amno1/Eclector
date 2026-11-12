;;;; Entry point: run every case (or print the output digests with XCHECK=1).

(in-package #:eclector-bench)

(defun warm-up (seconds)
  "Keep the CPU busy reading before the first measurement: the first cases of
a fresh process otherwise run while the clock is still ramping up."
  (let ((string (coerce (cdr (assoc "source" *corpora* :test (function string=)))
                        (quote simple-string)))
        (end (+ (now-seconds) seconds)))
    (loop while (< (now-seconds) end) do (read-base string))))

(defun main ()
  (unless *xcheck* (warm-up 0.7d0))
  (loop for (reader-name reader read-one raw) in *readers*
        do (loop for (corpus-name . string) in *corpora*
                 for name = (case-name reader-name corpus-name)
                 unless (and *only* (plusp (length *only*))
                             (not (search *only* name)))
                   do (let ((string (coerce string 'simple-string)))
                        (if *xcheck*
                            (format t "~A~C~A~%" name #\Tab
                                    (hex (result-digest read-one raw string)))
                            (measure name reader string)))))
  (unless *xcheck* (gc-cases)))

(main)
