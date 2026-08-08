(in-package #:i18n-backend-icu/tests)

(deftest backend-installed
  (ok (typep *i18n-backend* 'icu-backend))
  (ok (member :message (backend-capabilities *i18n-backend*)))
  (ok (member :plural (backend-capabilities *i18n-backend*))))

(deftest parse-locale-en-us
  (let ((loc (parse-locale "en-US")))
    (ok (string-equal (locale-language loc) "en"))
    (ok (string-equal (locale-region loc) "US"))))

(deftest plural-en
  (ok (eq (plural-category 1 :locale "en") :one))
  (ok (eq (plural-category 2 :locale "en") :other)))

(deftest mf2-hello
  (let ((out (format-message "Hello {$name}!" '(("name" . "Ada")) :locale "en")))
    (ok (search "Ada" out))
    (ok (search "Hello" out))))

(deftest available-locales-nonempty
  (ok (plusp (length (available-locales)))))
