;;;; The report: median of the set minima and the table.

(defun print-report (before after same set-minima info names out-file)
  (flet ((medians (which name)
           (let ((values (mapcar (lambda (m) (gethash name m))
                                 (cdr (assoc which set-minima)))))
             (values (median values)
                     (* 100 (/ (- (reduce #'max values) (reduce #'min values))
                               (median values)))))))
    (let ((lines (list "Eclector, 3 sets x 3 runs: median of the per-set minimum (us per corpus pass)"
                       (format nil "before: ~A" before)
                       (format nil "after:  ~A" after)
                       (format nil "output: ~A" (if same "identical" "DIFFERENT"))
                       ""
                       (format nil "~26A ~10@A ~10@A ~7@A ~11@A ~10@A ~6@A ~6@A ~6@A ~6@A ~8@A"
                               "case" "before" "after" "ratio" "KB before" "KB after"
                               "gc% B" "gc% A" "GCs B" "GCs A" "spread%"))))
      (dolist (name names)
        (multiple-value-bind (b sb) (medians :before name)
          (multiple-value-bind (a sa) (medians :after name)
            (destructuring-bind (bb bg bforms bn) (summarize (gethash (cons :before name) info))
              (destructuring-bind (ab ag aforms an) (summarize (gethash (cons :after name) info))
                (setf lines
                      (append lines
                              (list (format nil "~26A ~10,1F ~10,1F ~6,2Fx ~11,1F ~10,1F ~6,1F ~6,1F ~6D ~6D ~8,1F~A"
                                            name (/ b 1000) (/ a 1000) (/ b a)
                                            (/ bb 1024) (/ ab 1024) bg ag bn an (max sb sa)
                                            (if (string= bforms aforms) ""
                                                "  FORMS DIFFER"))))))))))
      (setf lines (append lines (list ""
                                      "ratio = before / after (above 1: faster). spread% = largest difference"
                                      "between the 3 set minima, relative to the median. KB and gc% = median over all 9 runs.")))
      (format t "~{~A~%~}" lines)
      (when out-file
        (with-open-file (f out-file :direction :output :if-exists :supersede)
          (format f "~{~A~%~}" lines))))))
