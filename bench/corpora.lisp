;;;; Corpora: deterministic text, independent of the checkout under test.

(in-package #:eclector-bench)

(defun repeat (unit count &optional (separator " "))
  (with-output-to-string (out)
    (dotimes (i count)
      (when (plusp i) (write-string separator out))
      (write-string unit out))))

(defun join (strings &optional (separator " "))
  (with-output-to-string (out)
    (loop for (s . more) on strings
          do (write-string s out)
             (when more (write-string separator out)))))

(defun slurp (name)
  (let ((path (merge-pathnames (concatenate 'string "corpus/" name)
                               (directory-namestring *load-truename*))))
    (with-open-file (in path :external-format :utf-8)
      (let* ((string (make-string (file-length in)))
             (end (read-sequence string in)))
        (subseq string 0 end)))))

(defparameter *corpora*
  (list
   (cons "symbols"
         (repeat "(alpha beta gamma delta x y z foo-bar baz-quux *special* +constant+ f1 f2 f3 long-symbol-name-with-many-parts)" 150))
   (cons "qualified"
         (repeat "(cl:car :keyword cl:cdr eclector.reader:read common-lisp:list :a :bb :ccc eclector-bench-scratch::internal)" 150))
   (cons "numbers"
         (repeat "(0 1 -1 42 12345 -987654321 1.5 -2.25 3.0d0 6.02e23 1/3 -22/7 123456789012345678901234567890)" 150))
   (cons "strings"
         (repeat "(\"\" \"a\" \"hello world\" \"a string with \\\"escapes\\\" and \\\\ in it\" \"a considerably longer string literal that goes on for quite a while to exercise the per-character path of the string reader\")" 150))
   (cons "characters"
         (repeat "(#\\a #\\Z #\\Space #\\Newline #\\( #\\) #\\; #\\\" #\\Tab #\\Rubout #\\0)" 250))
   (cons "nested"
         (repeat "((a (b c) . d) (1 2 (3 4 (5 (6 (7 (8)))))) ((((x)))) (a . b) (a b . c))" 150))
   (cons "sharpsign"
         (repeat "(#(1 2 3) #*0101 #x1F #b101 #o17 #'car #:foo #+sbcl a #-sbcl b #c(1 2) #p\"x\" #+(and) kept #-(and) dropped)" 150))
   (cons "quote"
         (repeat "('a `(a ,b ,@c) '(quote x) #'(lambda (x) `(,x ,@x)) `(a `(b ,(c ,d))))" 150))
   (cons "comments"
         (repeat (format nil "; a line comment~%(a b) #| a block comment |# (c d) ;; another~%(e f)") 200 (string #\Newline)))
   (cons "source"
         (slurp "eclector-reader.txt"))))
