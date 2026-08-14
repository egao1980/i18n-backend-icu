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

;;; --- Accept-Language ---------------------------------------------------------

(defun %normalize-locale-tag (tag)
  "en-US / en_US → en-us (lower, hyphen)."
  (string-downcase
   (substitute #\- #\_ (string-trim '(#\Space #\Tab) (string tag)) :test #'char=)))

(defun %tag-language (tag)
  (let* ((n (%normalize-locale-tag tag))
         (dash (position #\- n)))
    (if dash (subseq n 0 dash) n)))

(defun %split-commas (string)
  (loop with s = (string string)
        with start = 0
        with n = (length s)
        for i = (position #\, s :start start)
        collect (subseq s start (or i n))
        while i
        do (setf start (1+ i))))

(defun %parse-accept-language (header)
  "→ list of (tag . q) sorted by q descending, then input order."
  (let ((raw (string-trim '(#\Space #\Tab) (or header "")))
        (items '())
        (order 0))
    (unless (plusp (length raw))
      (return-from %parse-accept-language '()))
    (dolist (part (%split-commas raw))
      (let* ((seg (string-trim '(#\Space #\Tab) part))
             (semi (position #\; seg))
             (tag (string-trim '(#\Space #\Tab) (if semi (subseq seg 0 semi) seg)))
             (q 1.0d0))
        (when (and semi (< (1+ semi) (length seg)))
          (let* ((params (subseq seg (1+ semi)))
                 (qpos (search "q=" params :test #'char-equal)))
            (when qpos
              (let* ((rest (subseq params (+ qpos 2)))
                     (end (or (position #\; rest) (length rest)))
                     (num (ignore-errors
                            (read-from-string (string-trim '(#\Space) (subseq rest 0 end))))))
                (when (realp num)
                  (setf q (float num 1d0)))))))
        (when (plusp (length tag))
          (push (list tag q (incf order)) items))))
    (mapcar (lambda (x) (cons (first x) (second x)))
            (sort items
                  (lambda (a b)
                    (cond ((> (second a) (second b)) t)
                          ((< (second a) (second b)) nil)
                          (t (< (third a) (third b)))))))))

(defun %tag-region (tag)
  (let* ((n (%normalize-locale-tag tag))
         (parts (%split-hyphens n)))
    (when (>= (length parts) 2)
      (let ((maybe (second parts)))
        (when (and (= (length maybe) 2)
                   (every #'alpha-char-p maybe))
          maybe)))))

(defun %split-hyphens (string)
  (loop with s = (string string)
        with start = 0
        with n = (length s)
        for i = (position #\- s :start start)
        collect (subseq s start (or i n))
        while i
        do (setf start (1+ i))))

(defun %locale-match-score (want have)
  "Higher is better. Exact=3, lang+region=2, lang-only=1, else 0."
  (let ((w (%normalize-locale-tag want))
        (h (%normalize-locale-tag have)))
    (cond ((string= w h) 3)
          ((and (string= (%tag-language w) (%tag-language h))
                (%tag-region w)
                (%tag-region h)
                (string= (%tag-region w) (%tag-region h)))
           2)
          ((string= (%tag-language w) (%tag-language h)) 1)
          (t 0))))

(defun %best-available (want available)
  (let ((best nil) (best-score 0))
    (dolist (have available)
      (let ((s (%locale-match-score want have)))
        (when (> s best-score)
          (setf best-score s best have))))
    (values best best-score)))

(defmethod backend-accept-language ((backend icu-backend) header &key available)
  (let* ((prefs (%parse-accept-language header))
         (avail (mapcar #'string
                        (or available (backend-available-locales backend)))))
    (or
     (dolist (pref prefs)
       (multiple-value-bind (hit score) (%best-available (car pref) avail)
         (when (and hit (plusp score))
           (return (backend-parse-locale backend (%normalize-locale-tag hit))))))
     (backend-parse-locale backend "en"))))
