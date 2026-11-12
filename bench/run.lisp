;;;; Running cases.lisp on one checkout, and comparing the output of two.

(defun split-tabs (line)
  (loop with start = 0
        for pos = (position #\Tab line :start start)
        collect (subseq line start pos)
        while pos do (setf start (1+ pos))))

(defun run-cases (dir &optional xcheck)
  "Run cases.lisp on the checkout in DIR: a list of tab-split lines."
  (let ((output (with-output-to-string (out)
                  (sb-ext:run-program
                   "/usr/bin/env"
                   (append (list *lisp* "--noinform" "--non-interactive" "--no-userinit"
                                 "--load" *cases*))
                   :search t :output out :error nil
                   :environment (list* (concatenate 'string "ECLECTOR_DIR=" dir)
                                       (if xcheck "XCHECK=1" "XCHECK=0")
                                       (if xcheck ; the identity check always covers every case
                                           (remove-if (lambda (s) (eql 0 (search "ONLY=" s))) (sb-ext:posix-environ))
                                           (sb-ext:posix-environ))))))
        (rows '()))
    (with-input-from-string (in output)
      (loop for line = (read-line in nil) while line
            do (let ((parts (split-tabs line)))
                 (when (>= (length parts) 2) (push parts rows)))))
    (nreverse rows)))

(defun median (numbers)
  (nth (floor (length numbers) 2) (sort (copy-list numbers) #'<)))

(defun num (string)
  (let ((*read-default-float-format* 'double-float))
    (read-from-string string)))
(defun check-output (before after)
  (let ((a (run-cases before t)) (b (run-cases after t)) (same t))
    (loop for ra in a for rb in b
          unless (equal ra rb)
            do (setf same nil)
               (format *error-output* "OUTPUT DIFFERS: ~A~%  before ~A~%  after  ~A~%"
                       (first ra) (second ra) (second rb)))
    (when (or (null a) (/= (length a) (length b)))
      (setf same nil)
      (format *error-output* "OUTPUT CHECK produced ~D vs ~D cases~%" (length a) (length b)))
    (values same (length a))))
