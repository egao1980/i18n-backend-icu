(in-package #:i18n-backend-icu)

(defclass icu-backend (i18n-backend) ()
  (:documentation "i18n-protocol backend over ICU4C (scaffold — CFFI bindings TODO)."))

(defvar *icu-backend* nil)

(defmethod backend-capabilities ((backend icu-backend))
  ;; Planned: :locale :message :plural :catalog
  '())

(defun use-icu-backend (&optional (backend (or *icu-backend*
                                              (setf *icu-backend*
                                                    (make-instance 'icu-backend)))))
  "Install ICU backend as *I18N-BACKEND*. Returns BACKEND."
  (use-i18n-backend backend)
  backend)
