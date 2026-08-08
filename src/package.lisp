(defpackage #:i18n-backend-icu
  (:use #:cl #:cffi #:i18n-protocol)
  (:export #:icu-backend
           #:use-icu-backend
           #:*icu-backend*))

(in-package #:i18n-backend-icu)
