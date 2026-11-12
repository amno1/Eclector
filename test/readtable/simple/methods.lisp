(cl:in-package #:eclector.readtable.simple.test)

(in-suite :eclector.readtable.simple)

(test readtablep.smoke
  "Smoke test for the method on the READTABLEP protocol function."
  (is-false (eclector.readtable:readtablep 1))
  (is-true (eclector.readtable:readtablep
            (make-instance 'eclector.readtable.simple:readtable))))

(test syntax-type.changes
  "Changes of the syntax type must be visible to later lookups."
  (let ((readtable (make-instance 'eclector.readtable.simple:readtable)))
    (flet ((type-of-char (char)
             (eclector.readtable:syntax-type readtable char)))
      (dolist (char (list #\! (code-char 955)))
        (is (eq :constituent (type-of-char char)))
        (setf (eclector.readtable:syntax-type readtable char) :whitespace)
        (is (eq :whitespace (type-of-char char)))
        (eclector.readtable:set-macro-character
         readtable char (constantly nil) t)
        (is (eq :non-terminating-macro (type-of-char char)))
        (eclector.readtable:make-dispatch-macro-character readtable char)
        (is (eq :terminating-macro (type-of-char char)))
        (setf (eclector.readtable:syntax-type readtable char) :constituent)
        (is (eq :constituent (type-of-char char)))))))

(test syntax-type.copy-readtable-into
  "COPY-READTABLE-INTO must replace syntax types seen before the copy."
  (let ((from (make-instance 'eclector.readtable.simple:readtable))
        (to   (make-instance 'eclector.readtable.simple:readtable)))
    (setf (eclector.readtable:syntax-type from #\!) :whitespace)
    (is (eq :constituent (eclector.readtable:syntax-type to #\!)))
    (eclector.readtable:copy-readtable-into from to)
    (is (eq :whitespace (eclector.readtable:syntax-type to #\!)))))
