;;;; Sustained reading, with the GC included (see bench/README.md).

(in-package #:eclector-bench)

(defun collect-pass (read-one string)
  (let ((start 0) (forms '()))
    (loop (multiple-value-bind (object index) (funcall read-one string start)
            (when (eq object *eof*) (return (nreverse forms)))
            (push object forms)
            (setf start index)))))

(defun measure-sustained (name read-one string
                          &key retain nursery-mb (passes 400))
  (let ((old (sb-ext:bytes-consed-between-gcs))
        (kept (make-array 20 :initial-element nil)) (forms 0) (gc0 0) (timer (make-instance 'tb:timer)))
    (when nursery-mb
      (setf (sb-ext:bytes-consed-between-gcs) (* nursery-mb 1024 1024)))
    (unwind-protect
         (progn
           (dotimes (i 5) (collect-pass read-one string))
           (sb-ext:gc :full t)
           (setf gc0 *gc-count*)
           (tb:with-sampling (timer wall-seconds gc-seconds tb:bytes-consed)
             (dotimes (p passes)
               (let ((results (collect-pass read-one string)))
                 (setf forms (length results))
                 (when retain (setf (svref kept (mod p 20)) results)))))
           (let ((wall (tb:compute :total (tb:samples timer 'wall-seconds))))
             (format t "~A~C~,1F~C~,1F~C~,0F~C~,2F~C~D~C~D~%"
                     name
                     #\Tab (/ (* 1d9 wall) passes)
                     #\Tab (/ (* 1d9 wall) passes)
                     #\Tab (/ (tb:compute :total (tb:samples timer 'tb:bytes-consed))
                             passes)
                     #\Tab (* 100 (/ (tb:compute :total (tb:samples timer 'gc-seconds))
                                    wall))
                     #\Tab forms
                     #\Tab (- *gc-count* gc0))))
      (setf (sb-ext:bytes-consed-between-gcs) old)
      (fill kept nil)
      (sb-ext:gc :full t))))

(defun gc-cases ()
  (loop for (reader-name nil read-one) in *readers*
        unless (string= reader-name "sbcl")
          do (let ((string (coerce (cdr (assoc "source" *corpora* :test (function string=)))
                                   (quote simple-string))))
               (flet ((run (variant &rest keys)
                        (let ((name (format nil "gc ~A source ~A" reader-name variant)))
                          (unless (and *only* (plusp (length *only*))
                                       (not (search *only* name)))
                            (apply (function measure-sustained) name read-one string keys)))))
                 (run "sustained")
                 (run "retained" :retain t)
                 (run "sustained 8MB" :nursery-mb 8)))))
