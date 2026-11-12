(cl:in-package #:eclector.readtable.simple)

(defclass readtable ()
  ((%syntax-types
    :initform (make-hash-table)
    :reader syntax-types)
   ;; Cache of the syntax types of the characters below 128, filled
   ;; lazily. An entry is NIL when it has not been computed yet.
   (%ascii-syntax-types
    :initform (make-array 128 :initial-element nil)
    :reader ascii-syntax-types)
   (%macro-characters
    :initform (make-hash-table)
    :reader macro-characters)
   (%dispatch-macro-characters
    :initform (make-hash-table)
    :reader dispatch-macro-characters)
   (%readtable-case :initform :upcase
                    :accessor eclector.readtable:readtable-case)))
