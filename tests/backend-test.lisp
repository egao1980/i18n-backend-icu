;;;; i18n ICU backend tests — locale / plural / MF2 / catalog themes
;;;; inspired by ICU LocaleTest, PluralRulesTest, MessageFormat, and PyICU.

(in-package #:i18n-backend-icu/tests)

(deftest backend-installed
  (ok (typep *i18n-backend* 'icu-backend))
  (dolist (cap '(:locale :message :plural :catalog))
    (ok (member cap (backend-capabilities *i18n-backend*))
        (format nil "capability ~s" cap))))

;;; --- locales ----------------------------------------------------------------

(deftest parse-locale-en-us
  (let ((loc (parse-locale "en-US")))
    (ok (string-equal (locale-language loc) "en"))
    (ok (string-equal (locale-region loc) "US"))))

(deftest parse-locale-script
  (let ((loc (parse-locale "zh-Hans-CN")))
    (ok (string-equal (locale-language loc) "zh"))
    (ok (string-equal (locale-script loc) "Hans"))
    (ok (string-equal (locale-region loc) "CN"))))

(deftest available-locales-nonempty
  (let ((locs (available-locales)))
    (ok (plusp (length locs)))
    (ok (some (lambda (s) (search "en" s :test #'char-equal)) locs))))

(deftest accept-language-first-tag
  (let ((loc (accept-language "fr-FR,en;q=0.8")))
    (ok (string-equal (locale-language loc) "fr"))))

(deftest accept-language-q-weights
  (let ((loc (accept-language "en-US,en;q=0.8" :available '("fr" "en_GB" "de"))))
    (ok (string-equal (locale-language loc) "en"))))

(deftest accept-language-fallback-when-unavailable
  (let ((loc (accept-language "xx-YY,en;q=0.1" :available '("en_US" "fr"))))
    (ok (string-equal (locale-language loc) "en"))))

;;; --- plurals (CLDR) ---------------------------------------------------------

(deftest plural-en-cardinal
  (ok (eq (plural-category 0 :locale "en") :other))
  (ok (eq (plural-category 1 :locale "en") :one))
  (ok (eq (plural-category 2 :locale "en") :other)))

(deftest plural-ru-few-many
  ;; Russian: 2–4 → few, 5–20 → many (simplified check)
  (ok (eq (plural-category 1 :locale "ru") :one))
  (ok (eq (plural-category 2 :locale "ru") :few))
  (ok (eq (plural-category 5 :locale "ru") :many)))

(deftest plural-rules-object
  (let ((r (make-plural-rules "pl")))
    (ok (eq (plural-category 1 :rules r) :one))
    (ok (eq (plural-category 2 :rules r) :few))
    (ok (eq (plural-category 5 :rules r) :many))))

;;; --- MF2 --------------------------------------------------------------------

(deftest mf2-hello
  (let ((out (format-message "Hello {$name}!" '(("name" . "Ada")) :locale "en")))
    (ok (search "Ada" out))
    (ok (search "Hello" out))))

(deftest mf2-number-arg
  (let ((out (format-message "n={$n}" '(("n" . 42)) :locale "en")))
    (ok (search "42" out))))

(deftest mf2-formatter-object
  (let* ((fmt (make-message-formatter "Hi {$who}" :locale "en"))
         (out (format-message-to-string fmt '(("who" . "Bob")))))
    (ok (search "Bob" out))
    (ok (search "Hi" out))))

;;; --- catalogs (ICU resource bundles) ----------------------------------------

(deftest catalog-icu-version
  (let ((cat (load-catalog nil :locale "en")))
    (ok (catalog-has-p cat "Version"))
    (ok (stringp (catalog-get cat "Version")))
    (ok (plusp (length (catalog-locales cat))))
    (ok (null (catalog-get cat "DefinitelyMissingKeyXYZ" :default nil)))
    (ok (string= (catalog-get cat "DefinitelyMissingKeyXYZ" :default "x") "x"))))

(deftest catalog-nested-calendar
  ;; Locale data exposes a top-level "calendar" table (ICU resource bundle).
  (let ((cat (load-catalog nil :locale "en")))
    (ok (catalog-has-p cat "calendar"))
    (ok (catalog-has-p cat "Version"))))
