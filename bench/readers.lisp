;;;; Readers under test (SBCL, base Eclector, CST client) and the output digest.

(in-package #:eclector-bench)

(defparameter *eof* '#:eof)

(defmacro define-reader (name (string-var) read-form)
  `(defun ,name (,string-var)
     (let ((*package* (find-package '#:eclector-bench-scratch))
           (start 0) (count 0))
       (declare (fixnum start count))
       (loop (multiple-value-bind (object index) ,read-form
               (when (eq object *eof*) (return count))
               (incf count)
               (setf start index))))))

(define-reader read-base (string)
  (eclector.reader:read-from-string string nil *eof* :start start))

(define-reader read-cst (string)
  (eclector.concrete-syntax-tree:read-from-string string nil *eof* :start start))

;;; SBCL's own reader: the reference the other rows are measured against.
(define-reader read-sbcl (string)
  (cl:read-from-string string nil *eof* :start start))

;;; (NAME PASS-FUNCTION READ-ONE-FORM RAW-OF-RESULT)
(defparameter *readers*
  (list (list "sbcl" #'read-sbcl
              (lambda (string start)
                (cl:read-from-string string nil *eof* :start start))
              #'identity)
        (list "base" #'read-base
              (lambda (string start)
                (eclector.reader:read-from-string string nil *eof* :start start))
              #'identity)
        (list "cst" #'read-cst
              (lambda (string start)
                (eclector.concrete-syntax-tree:read-from-string
                 string nil *eof* :start start))
              (lambda (cst) (cst:raw cst)))))

;;;; Output-identity check

(defun result-digest (read-one raw string)
  (let ((*package* (find-package '#:eclector-bench-scratch))
        (*print-circle* t) (*print-pretty* nil) (*print-readably* nil)
        (start 0))
    (sb-md5:md5sum-string
     (with-output-to-string (out)
       (loop (multiple-value-bind (object index) (funcall read-one string start)
               (when (eq object *eof*) (return))
               (prin1 (funcall raw object) out)
               (terpri out)
               (setf start index)))))))
