(rest-server
 *myfirstserver*
 :port 8000
 ;; => accept socket
 ;; unknown route
 :before-route #'f #'g #'h
 ;; known route dispatched
 :before-responder #'i #'j #'k
 ;; => response
 :route (("/a" (req resp))
         ("/b" (req resp))
         ("/c" (req resp)))
 )
