;;;; Phase 2: load + run Rove.

(setf *debugger-hook*
      (lambda (c h)
        (declare (ignore h))
        (format *error-output* "~&UNHANDLED: ~A~%" c)
        (uiop:quit 1)))

(setf asdf:*compile-file-failure-behaviour* :warn)

(defun call-with-ci-muffles (fn)
  #+sbcl
  (handler-bind ((sb-ext:defconstant-uneql #'continue))
    (funcall fn))
  #-sbcl
  (funcall fn))

(defun freeze-already-loaded-systems ()
  "Client bootstrap QL-loads babel/cffi; cl-repo also installs OCI copies.
   Freeze the in-image systems so ASDF does not recompile OCI babel over them."
  (dolist (sys (asdf:already-loaded-systems))
    (ignore-errors (asdf:register-immutable-system sys))))

(call-with-ci-muffles (lambda () (asdf:load-system "cl-repository-client")))

(cl-repository-client/asdf-integration:configure-asdf-source-registry)
(cl-repository-client/asdf-integration:load-system-init-files)
(freeze-already-loaded-systems)

(call-with-ci-muffles
 (lambda ()
   (asdf:test-system "i18n-backend-icu")))

(format t "~&; ci: tests ok~%")
(uiop:quit 0)
