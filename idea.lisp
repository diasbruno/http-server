(defvar *server* nil)

(defmacro nop (name)
  `(defun ,name (r rs)
     (declare (ignore r))
     (print ',name)
     rs))

(nop f)
(nop g)
(nop h)
(nop i)
(defun i (r rs)
  (declare (ignore r))
  (setf (response-status rs) 500)
  rs)
(nop j)
(nop k)

(defun http-server (port
                    &key
                      (before-route nil)
                      (before-responder nil)
                      (routes nil))
  nil)

(defstruct request
  (method :get)
  uri
  body)

(defstruct response
  (status nil)
  (headers nil)
  body)

(defun process (request
                &key
                  (before-route nil)
                  (before-responder nil)
                  (routes nil))
  (labels ((exec (request response fs)
             (reduce #'(lambda (response f)
                       (if (null (response-status response))
                           (funcall f request response)
                           response))
                     fs :initial-value response)))
    (let ((response (exec request (make-response) before-route)))
      (if (not (null (response-status response)))
          response
          (let ((route (assoc (request-uri request) routes :test #'string-equal)))
            (let ((response (exec request response before-responder)))
              (funcall (cadr route) request response)))))))

(defun json-resp (response status data)
  (setf (response-status response) status
        (response-headers response) nil
        (response-body response) data)
  response)


(defvar *routes* nil)
(setf *routes* `(("/a" ,(lambda (req resp)
                          (json-resp resp 200 "{}")))

                 ("/c" ,(lambda (req resp) resp))))

(process
 (make-request :uri "/b")
 ;; => accept socket
 ;; unknown route
 :before-route (list #'f #'g #'h)
 ;; known route dispatched
 :before-responder (list #'i #'j #'k)
 ;; => response
 :routes *routes*)

(setf *server* (http-server
                8000
                ;; unknown route
                :before-route (list #'f #'g #'h)
                ;; known route dispatched
                :before-responder (list #'i #'j #'k)
                ;; => response
                :routes *routes*))
