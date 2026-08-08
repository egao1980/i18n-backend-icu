;;;; Phase 2: load + run Rove.

(setf asdf:*compile-file-failure-behaviour* :warn)

#+sbcl
(setf *debugger-hook*
      (lambda (c h)
        (declare (ignore h))
        (when (typep c 'sb-ext:defconstant-uneql)
          (invoke-restart 'continue))
        (format *error-output* "~&UNHANDLED: ~A~%" c)
        (uiop:quit 1)))
#-sbcl
(setf *debugger-hook*
      (lambda (c h)
        (declare (ignore h))
        (format *error-output* "~&UNHANDLED: ~A~%" c)
        (uiop:quit 1)))

(defun call-with-ci-muffles (fn)
  #+sbcl
  (handler-bind ((sb-ext:defconstant-uneql #'continue))
    (funcall fn))
  #-sbcl
  (funcall fn))

(call-with-ci-muffles (lambda () (asdf:load-system "cl-repository-client")))

(cl-repository-client/asdf-integration:configure-asdf-source-registry)
(cl-repository-client/asdf-integration:load-system-init-files)

(call-with-ci-muffles
 (lambda ()
   (asdf:test-system "i18n-backend-icu")))

(format t "~&; ci: tests ok~%")
(uiop:quit 0)
