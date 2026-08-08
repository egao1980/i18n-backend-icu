(in-package #:i18n-backend-icu)

;;; ICU ResourceBundle catalogs via ures_*.
;;; SOURCE NIL/"" → ICU data; string → package name/path; pathname → namestring.

(defun %catalog-ures (catalog)
  (getf (i18n-protocol::catalog-raw catalog) :ures))

(defun %open-ures (package locale)
  (with-foreign-object (err :int)
    (setf (mem-ref err :int) (%zero-error))
    (let* ((loc (%locale-tag locale))
           (bundle (if package
                       (cl-stack-icu:ures-open (string package) loc err)
                       (cl-stack-icu:ures-open (null-pointer) loc err))))
      (cl-stack-icu:check-icu (mem-ref err :int) "ures-open")
      bundle)))

(defun %ures→string (resource)
  (with-foreign-objects ((err :int) (len :int32))
    (setf (mem-ref err :int) (%zero-error)
          (mem-ref len :int32) 0)
    (let ((ptr (cl-stack-icu:ures-get-string resource len err)))
      (when (and (cl-stack-icu:u-success-p (mem-ref err :int))
                 (not (null-pointer-p ptr)))
        (cl-stack-icu:u-chars-to-lisp ptr (mem-ref len :int32))))))

(defun %with-key (root key fn)
  "Resolve KEY (\"a\" or \"a/b/c\") under ROOT; call FN with resource; close temps."
  (let* ((parts (remove "" (uiop:split-string (string key) :separator "/")
                        :test #'string=))
         (err-box (foreign-alloc :int))
         (cur root)
         (owned '()))
    (unwind-protect
         (progn
           (dolist (part parts)
             (setf (mem-ref err-box :int) (%zero-error))
             (let ((next (cl-stack-icu:ures-get-by-key cur part (null-pointer) err-box)))
               (unless (cl-stack-icu:u-success-p (mem-ref err-box :int))
                 (return-from %with-key nil))
               (push next owned)
               (setf cur next)))
           (funcall fn cur))
      (mapc (lambda (o) (ignore-errors (cl-stack-icu:ures-close o))) owned)
      (foreign-free err-box))))

(defmethod backend-load-catalog ((backend icu-backend) source &key locale)
  (declare (ignore backend))
  (let* ((package (cond
                    ((null source) nil)
                    ((pathnamep source) (uiop:native-namestring source))
                    ((stringp source) (if (string= source "") nil source))
                    (t (princ-to-string source))))
         (ures (%open-ures package locale))
         (cat (make-instance 'message-catalog
                             :locale locale
                             :raw (list :ures ures :package package))))
    (tg:finalize cat (lambda ()
                       (ignore-errors (cl-stack-icu:ures-close ures))))
    cat))

(defmethod backend-make-message-catalog ((backend icu-backend) &key locale)
  (backend-load-catalog backend nil :locale locale))

(defmethod backend-catalog-get ((backend icu-backend) catalog key &key default)
  (declare (ignore backend))
  (let ((ures (%catalog-ures catalog)))
    (unless ures
      (return-from backend-catalog-get default))
    (or (%with-key
         ures key
         (lambda (res)
           (let ((ty (cl-stack-icu:ures-get-type res))
                 (string-ty (cffi:foreign-enum-value 'cl-stack-icu:u-res-type :string))
                 (alias-ty (cffi:foreign-enum-value 'cl-stack-icu:u-res-type :alias)))
             (when (or (= ty string-ty) (= ty alias-ty))
               (%ures→string res)))))
        default)))

(defmethod backend-catalog-has-p ((backend icu-backend) catalog key)
  (declare (ignore backend))
  (let ((ures (%catalog-ures catalog)))
    (and ures
         (not (null (%with-key ures key (constantly t)))))))

(defmethod backend-catalog-locales ((backend icu-backend) catalog)
  (declare (ignore backend))
  (let ((ures (%catalog-ures catalog)))
    (when ures
      (with-foreign-object (err :int)
        (setf (mem-ref err :int) (%zero-error))
        (let ((loc (cl-stack-icu:ures-get-locale-by-type ures 0 err))) ; ULOC_ACTUAL_LOCALE
          (remove nil
                  (list (i18n-protocol::catalog-locale catalog)
                        (when (and (cl-stack-icu:u-success-p (mem-ref err :int)) loc)
                          loc))))))))
