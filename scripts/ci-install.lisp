;;;; Phase 1: install SUT dependency closure via cl-repository-client.

(setf asdf:*compile-file-failure-behaviour* :warn)

(defun call-with-ci-muffles (fn)
  #+sbcl
  (handler-bind ((sb-ext:defconstant-uneql #'continue))
    (funcall fn))
  #-sbcl
  (funcall fn))

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

(call-with-ci-muffles
 (lambda ()
   (asdf:load-system "cl-repository-client")
   (cl-repo:add-registry "https://ghcr.io" :namespace "egao1980/cl-systems" :priority :prepend)
   (cl-repo:ensure-system-dependencies "i18n-backend-icu"
     :also-tests t
     :sources '(("rove" :ql)
                ("cffi" :ql)
                ("cffi-grovel" :ql)
                ("babel" :ql)
                ("trivial-features" :ql)
                ("trivial-garbage" :ql)))))

(format t "~&; ci: install phase done~%")
(uiop:quit 0)
