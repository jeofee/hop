;*=====================================================================*/
;*    serrano/prgm/project/hop/2.1.x/runtime/http_request.scm          */
;*    -------------------------------------------------------------    */
;*    Author      :  Manuel Serrano                                    */
;*    Creation    :  Fri Nov 12 13:55:24 2004                          */
;*    Last change :  Sat Jun 19 06:41:16 2010 (serrano)                */
;*    Copyright   :  2004-10 Manuel Serrano                            */
;*    -------------------------------------------------------------    */
;*    The HTTP request management                                      */
;*    -------------------------------------------------------------    */
;*    HTTP/1.1 is defined in the RFC 2616.                             */
;*    Authentication is defined in the RFC 2617.                       */
;*    Cookie is defined in the RFC 2109.                               */
;*=====================================================================*/

;*---------------------------------------------------------------------*/
;*    The module                                                       */
;*---------------------------------------------------------------------*/
(module __hop_http-request

   (library web)
   
   (import  __hop_param
	    __hop_configure
	    __hop_types
	    __hop_http-lib
	    __hop_user
	    __hop_misc
	    __hop_charset)
   
   (export  (http-parse-request::http-request ::socket ::int ::int)))

;*---------------------------------------------------------------------*/
;*    parse-error ...                                                  */
;*---------------------------------------------------------------------*/
(define (parse-error proc msg obj port)
   (let ((o (if (eof-object? obj)
		obj
		(let ((l (read-line port)))
		   (if (eof-object? l)
		       obj
		       (format "{~a}~a" obj l))))))
      (raise (instantiate::&io-parse-error
		(obj o)
		(proc proc)
		(msg msg)))))

;*---------------------------------------------------------------------*/
;*    http-parse-request ...                                           */
;*---------------------------------------------------------------------*/
(define (http-parse-request sock id timeout)
   (let ((port (socket-input sock))
	 (out (socket-output sock)))
      (socket-timeout-set! sock timeout timeout)
      (let* ((req (read/rp request-line-grammar port id out))
	     (localc (string=? (socket-local-address sock)
			       (socket-host-address sock))))
	 (with-access::http-request req (socket localclientp)
	    (set! socket sock)
	    (set! localclientp localc)
	    req))))

;*---------------------------------------------------------------------*/
;*    request-eof ...                                                  */
;*---------------------------------------------------------------------*/
(define request-eof-exception
   (instantiate::&io-parse-error
      (obj beof)
      (proc 'request-list-grammar)
      (msg "Illegal premature end-of-file")))

;*---------------------------------------------------------------------*/
;*    request-line-grammar ...                                         */
;*---------------------------------------------------------------------*/
(define request-line-grammar
   (regular-grammar ((SP #\Space)
		     (CRLF "\r\n")
		     id
		     out)
      ((: (+ (in ("AZ"))) SP)
       ;; HTTP requests
       (http-parse-method-request (the-subsymbol 0 -1) (the-port) out id))
      ((: "<" (+ (in "policyferqust" #\-)) (* SP) "/>" #a000)
       ;; Flash authentication requests
       (http-parse-policy-file-request id (the-string) (the-port)))
      ((: (out #\< SP) (+ (out SP)) SP)
       ;; Illegal (parsed) requests
       (raise (instantiate::&hop-method-error
		 (proc "request-line-grammar")
		 (msg "Method not implemented")
		 (obj (the-string)))))
      (else
       (let ((o (the-failure)))
	  (if (eof-object? o)
	      (raise request-eof-exception)
	      (parse-error "request-line-grammar"
			   "Illegal method"
			   o
			   (the-port)))))))

;*---------------------------------------------------------------------*/
;*    http-parse-method-request ...                                    */
;*---------------------------------------------------------------------*/
(define (http-parse-method-request method pi::input-port po::output-port id)
   (with-trace 3 'http-parse-method-request
      (let (scheme hostname port path http-version userinfo)
	 (multiple-value-bind (s u h p a)
	    (http-url-parse pi)
	    (trace-item "scheme=" s " user=" u
			" hostname=" h " port=" p " path=[" a "]")
	    (set! scheme (string->symbol s))
	    (set! hostname h)
	    (set! port p)
	    (set! path a)
	    (set! userinfo u)
	    (set! http-version (read/rp http-version-grammar pi))
	    (when (input-string-port? pi)
	       (close-input-port pi)))
	 (multiple-value-bind (header actual-host actual-port cl te auth pauth co)
	    (http-parse-header pi po)
	    (let* ((i (string-index path #\?))
		   (query #f)
                   (abspath (cond
                               ((not i)
				;; file name canonicalization is needed
				;; for authentication
				(file-name-canonicalize! (url-decode! path)))
                               ((>fx i 0)
                                (let ((l (string-length path)))
                                   (set! query (substring path (+fx i 1) l)))
                                (let ((p (url-decode! (substring path 0 i))))
                                   (file-name-canonicalize! p)))
                               (else
                                (let ((l (string-length path)))
                                   (set! query (substring path 1 l)))   
                                "/")))
		   (connection (if (hop-enable-keep-alive)
				   (or co
				       (if (eq? http-version 'HTTP/1.1)
					   'keep-alive
					   'close))
				   'close)))
	       (trace-item "abspath=" abspath
			   " query=" query
			   " connection=" connection)

	       (let* ((ip (input-port-name pi))
		      (user (or (and (string? auth)
				     (find-authenticated-user auth abspath method ip))
				(and (string? pauth)
				     (find-authenticated-user pauth abspath method ip))
				(and (string? userinfo)
				     (find-authenticated-user userinfo abspath method ip))
				(anonymous-user))))
		  (if (string? hostname)
		      (instantiate::http-proxy-request
			 (id id)
			 (method method)
			 (http http-version)
			 (scheme scheme)
			 (userinfo userinfo)
			 (path path)
			 (abspath abspath)
			 (query query)
			 (header header)
			 (port (or actual-port port (hop-port)))
			 (host (or actual-host hostname "localhost"))
			 (content-length cl)
			 (transfer-encoding te)
			 (authorization pauth)
			 (connection connection)
			 (user user))
		      (instantiate::http-server-request
			 (id id)
			 (method method)
			 (http http-version)
			 (scheme scheme)
			 (userinfo userinfo)
			 (path path)
			 (abspath abspath)
			 (query query)
			 (header header)
			 (port (or actual-port port (hop-port)))
			 (host (or actual-host hostname "localhost"))
			 (content-length cl)
			 (transfer-encoding te)
			 (authorization auth)
			 (connection connection)
			 (user user)))))))))

;*---------------------------------------------------------------------*/
;*    http-parse-policy-file-request ...                               */
;*---------------------------------------------------------------------*/
(define (http-parse-policy-file-request id string port)
   (if (substring-at? string "<policy-file-request" 0)
       ;; This request is emitted by Flash plugins >= 9.0.115.
       ;; This plugins are buggous because they should seek for
       ;; the policy file using the /hop/server-event/policy-file.
       ;; In the meantime, Hop also handles the <policy-file-request/>.
       (instantiate::http-server-request
	  (id id)
	  (method 'FLASH-POLICY-FILE)
	  (http 'HTTP/0.0)
	  (scheme 'policy-file-request)
	  (path "<policy-file-request/>")
	  (abspath "<policy-file-request/>")
	  (header '())
	  (port (hop-port))
	  (host "localhost")
	  (content-length 10)
	  (user (anonymous-user)))
       (raise (instantiate::&hop-method-error
		 (proc "request-line-grammar")
		 (msg "policy file request not understood")
		 (obj string)))))

;*---------------------------------------------------------------------*/
;*    http-version-grammar ...                                         */
;*---------------------------------------------------------------------*/
(define http-version-grammar
   (regular-grammar ((DIGIT (in ("09")))
		     (SP (+ #\Space)))
      (SP
       (ignore))
      ((: "HTTP/" (+ DIGIT) "." (+ DIGIT) "\n")
       (the-subsymbol 0 -1))
      ((: "HTTP/" (+ DIGIT) "." (+ DIGIT) "\r\n")
       (the-subsymbol 0 -2))
      (else
       (parse-error 'http-version-grammar "Illegal character"
		    (the-failure)
		    (the-port)))))

;*---------------------------------------------------------------------*/
;*    http-sp-grammar ...                                              */
;*---------------------------------------------------------------------*/
(define http-sp-grammar
   (regular-grammar ((SP #\Space))
      (SP
       'sp)
      (else
       (parse-error 'sp-grammar
		    "Illegal character"
		    (the-failure)
		    (the-port)))))
      