(in-package #:i18n-backend-icu)

(defmethod backend-make-locale ((backend icu-backend) &key language script region variants
                              extensions tag)
  (declare (ignore backend extensions))
  (make-instance 'locale
                 :language language
                 :script script
                 :region region
                 :variants variants
                 :tag (or tag
                          (with-output-to-string (out)
                            (when language (write-string language out))
                            (when script (format out "-~A" script))
                            (when region (format out "-~A" region))))))

(defmethod backend-parse-locale ((backend icu-backend) string)
  (declare (ignore backend))
  (with-foreign-object (err :int)
    (setf (mem-ref err :int) (%zero-error))
    (let* ((icu-id (%fill-buf
                    (lambda (buf cap e)
                      (cl-stack-icu:uloc-for-language-tag string buf cap (null-pointer) e))
                    64))
           (lang (%fill-buf
                  (lambda (buf cap e)
                    (cl-stack-icu:uloc-get-language icu-id buf cap e))
                  16))
           (script (%fill-buf
                    (lambda (buf cap e)
                      (cl-stack-icu:uloc-get-script icu-id buf cap e))
                    16))
           (region (%fill-buf
                    (lambda (buf cap e)
                      (cl-stack-icu:uloc-get-country icu-id buf cap e))
                    16))
           (tag (%fill-buf
                 (lambda (buf cap e)
                   (cl-stack-icu:uloc-to-language-tag icu-id buf cap 1 e))
                 64)))
      (make-instance 'locale
                     :language (if (plusp (length lang)) lang nil)
                     :script (if (plusp (length script)) script nil)
                     :region (if (plusp (length region)) region nil)
                     :tag tag))))

(defmethod backend-available-locales ((backend icu-backend))
  (declare (ignore backend))
  (loop for i below (cl-stack-icu:uloc-count-available)
        collect (cl-stack-icu:uloc-get-available i)))

(defmethod backend-accept-language ((backend icu-backend) header &key available)
  (declare (ignore available))
  ;; Minimal: take first tag before comma/q.
  (let* ((raw (string-trim '(#\Space #\Tab) (or header "")))
         (semi (or (position #\; raw) (position #\, raw) (length raw)))
         (tag (string-trim '(#\Space) (subseq raw 0 semi))))
    (if (plusp (length tag))
        (backend-parse-locale backend tag)
        (backend-parse-locale backend "en"))))
