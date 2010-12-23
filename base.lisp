;; -*-LISP-*-
(IN-PACKAGE :MACLISP)

(defmacro keep (&body body)
  (declare (ignore body))
  (values))

(define-condition wrng-type-arg (error)
  ((argument :reader wrng-type-arg-argument :initarg :argument)
   (message :reader wrng-type-arg-message :initarg :message))
  (:report (lambda (condition stream)
             (format stream
                     (wrng-type-arg-message condition)
                     (wrng-type-arg-argument condition)))))

(define-condition wrng-no-args (error)
  ((argument :reader wrng-no-args-argument :initarg :argument)
   (message :reader wrng-no-args-message :initarg :message))
  (:report (lambda (condition stream)
             (format stream
                     (wrng-no-args-message condition)
                     (wrng-no-args-argument condition)))))

(defun exploden (expr)
  (map 'list
    (lambda (x) (char-code x))
    (princ-to-string
     (read-from-string
      (write-to-string expr)))))

(defun explodec (expr)
  (map 'list
    (lambda (x) (intern (string x)))
    (princ-to-string
     (read-from-string
      (write-to-string expr)))))

(defun mapatoms (function)
  (let (ans)
    (do-all-symbols (s)
      (push (funcall function s) ans))
    ans))

(defun getcharn (string-designator pos)
  (char-code
   (char (string string-designator)
         (1- pos))))

(defun flatc (expr)
  (length
   (princ-to-string
    (read-from-string
     (write-to-string expr)))))

(defun plist (sym)
  (and (symbolp sym)
       (symbol-plist sym)))

(defun alphalessp (x y)
  (null (not (string< x y))))

(setf (symbol-function 'add1) #'1+)
(setf (symbol-function 'greaterp) #'>)
(setf (symbol-function 'lessp) #'<)
(setf (symbol-function 'DIFFERENCE) #'-)
(setf (symbol-function 'DIFFERENCE) #'-)
(setf (symbol-function 'REMAINDER) #'rem)

(defun bigp (obj)
  (typep obj 'bignum))

(defun lsh (integer count)
  (ash (- integer) count))

(defun minus (&optional number)
  (if number
      (- number)
      0))

(cardinal 8.8)

(fnorm 8)


;; implode
    (EQ 'ABC (IMPLODE '(A B C)))   =>   T

    (IMPLODE '(A #\SPACE #\B))      =>   |A B|

    (IMPLODE (EXPLODE 3))           =>   /3

    (NUMBERP (IMPLODE (EXPLODE 3))) =>   NIL

(defun implode (expr)
  (values (intern (format nil "~{~A~}" expr))))
