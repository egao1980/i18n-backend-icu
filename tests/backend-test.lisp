(in-package #:i18n-backend-icu/tests)

(deftest system-loads
  (ok (asdf:find-system "i18n-backend-icu")))

(deftest use-icu-backend-installs
  (let ((backend (use-icu-backend)))
    (ok (typep backend 'icu-backend))
    (ok (eq *i18n-backend* backend))
    (ok (null (backend-capabilities backend)))))
