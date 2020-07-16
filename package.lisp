;;;; package.lisp

(defpackage #:rest-server
  (:use #:cl))

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

(defvar *tp* nil)
(defvar *s* nil)

(defstruct server
  socket
  thread
  threadpool)

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

(defun http-server (&key
                      (port 8000)
                      (before-route nil)
                      (before-responder nil)
                      (routes nil))
  (declare (ignore before-route
                   before-responder
                   routes))
  (let ((server-socket (usocket:socket-listen "127.0.0.1" port
                                              :reuse-address t)))
    (let* ((client-socket (usocket:socket-accept server-socket))
           (stream (usocket:socket-stream client-socket )))
      (unwind-protect
           (do ((line (read-line stream nil nil)
                      (read-line stream nil nil)))
               ((null line))
             (format t "~A~%" line))
        (progn
          (usocket:socket-close client-socket)
          (usocket:socket-close server-socket))))))

(defun json-resp (response status data)
  (setf (response-status response) status
        (response-headers response) nil
        (response-body response) data)
  response)

(defvar *routes* nil)
(setf *routes* `(("/" ,(lambda (req resp)
                          (json-resp resp 200 "{}")))
                 ("/b" ,(lambda (req resp) resp))
                 ("/c" ,(lambda (req resp) resp))))

(setf *server* (http-server
                :port 8000
                ;; unknown route
                :before-route (list #'f #'g #'h)
                ;; known route dispatched
                :before-responder (list #'i #'j #'k)
                ;; => response
                :routes *routes*))
