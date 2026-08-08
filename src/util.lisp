(in-package #:i18n-backend-icu)

(defun %zero-error ()
  (foreign-enum-value 'cl-stack-icu:u-error-code :zero-error))

(defun %locale-tag (locale)
  (cond ((null locale) "en")
        ((stringp locale) locale)
        ((typep locale 'locale) (or (locale-string locale) "en"))
        (t (princ-to-string locale))))

(defun %fill-buf (fn capacity-hint)
  "Call FN with (buf capacity err) expecting int32 return length; grow once on overflow."
  (with-foreign-object (err :int)
    (setf (mem-ref err :int) (%zero-error))
    (let ((cap (max 16 capacity-hint)))
      (with-foreign-pointer (buf cap)
        (let ((n (funcall fn buf cap err)))
          (if (and (plusp n) (>= n cap))
              (let ((need (1+ n)))
                (setf (mem-ref err :int) (%zero-error))
                (with-foreign-pointer (buf2 need)
                  (setf n (funcall fn buf2 need err))
                  (cl-stack-icu:check-icu (mem-ref err :int) "uloc-buf")
                  (foreign-string-to-lisp buf2 :count n)))
              (progn
                (cl-stack-icu:check-icu (mem-ref err :int) "uloc-buf")
                (foreign-string-to-lisp buf :count (max 0 n)))))))))
