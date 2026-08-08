(in-package #:i18n-backend-icu)

(defclass icu-backend (i18n-backend) ()
  (:documentation "i18n-protocol backend over cl-stack-icu (ICU4C + MF2)."))

(defvar *icu-backend* nil)

(defmethod backend-capabilities ((backend icu-backend))
  '(:locale :message :plural))

(defun use-icu-backend (&optional (backend (or *icu-backend*
                                              (setf *icu-backend*
                                                    (make-instance 'icu-backend)))))
  (use-i18n-backend backend)
  backend)

(use-icu-backend)
