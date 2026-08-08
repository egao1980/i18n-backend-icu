(in-package #:i18n-backend-icu)

(defmethod backend-make-message-formatter ((backend icu-backend) pattern &key locale)
  (declare (ignore backend))
  (make-instance 'message-formatter
                 :pattern pattern
                 :locale (or locale *locale*)
                 :raw nil))

(defmethod backend-parse-message-pattern ((backend icu-backend) pattern)
  (declare (ignore backend))
  pattern)

(defun %args-alist (arguments)
  (cond ((null arguments) '())
        ((hash-table-p arguments)
         (loop for k being the hash-keys of arguments using (hash-value v)
               collect (cons (if (stringp k) k (string-downcase (string k))) v)))
        ((listp arguments) arguments)
        (t (error 'i18n-message-error :message "arguments must be alist or hash-table"))))

(defmethod backend-format-message ((backend icu-backend) formatter arguments)
  (declare (ignore backend))
  (cl-stack-icu:mf2-format-message
   (message-pattern formatter)
   (%args-alist arguments)
   :locale (%locale-tag (message-locale formatter))))
