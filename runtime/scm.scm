;*=====================================================================*/
;*    serrano/prgm/project/hop/1.9.x/runtime/scm.scm                   */
;*    -------------------------------------------------------------    */
;*    Author      :  Manuel Serrano                                    */
;*    Creation    :  Wed Dec 26 08:30:35 2007                          */
;*    Last change :  Wed Dec 26 10:59:36 2007 (serrano)                */
;*    Copyright   :  2007 Manuel Serrano                               */
;*    -------------------------------------------------------------    */
;*    HOP client-side -> JavaScript compiler                           */
;*=====================================================================*/

;*---------------------------------------------------------------------*/
;*    The module                                                       */
;*---------------------------------------------------------------------*/
(module __hop_scm
   
   (library web)
   
   (include "xml.sch"
	    "service.sch")
   
   (import  __hop_read
	    __hop_param
	    __hop_cache)
   
   (use	    __hop_user
	    __hop_hop
	    __hop_cgi
	    __hop_misc
	    __hop_service
	    __hop_mime
	    __hop_types
	    __hop_http-error
	    __hop_xml)
   
   (export  (init-scm-compiler! ::procedure)
	    (scm-response::%http-response ::http-request ::bstring)
	    (scm2js-url ::bstring)
	    (scm2js-compile-file ::bstring)))

;*---------------------------------------------------------------------*/
;*    scm2js-compiler ...                                              */
;*---------------------------------------------------------------------*/
(define scm2js-compiler (lambda (f) (error 'scm2js "no compiler provided" #f)))

;*---------------------------------------------------------------------*/
;*    scm2js-cache ...                                                 */
;*---------------------------------------------------------------------*/
(define scm2js-cache #f)

;*---------------------------------------------------------------------*/
;*    scm2js-mutex ...                                                 */
;*---------------------------------------------------------------------*/
(define scm2js-mutex (make-mutex 'scm))

;*---------------------------------------------------------------------*/
;*    scm2js-url ...                                                   */
;*---------------------------------------------------------------------*/
(define (scm2js-url path)
   (string-append path (hop-scm-compile-suffix)))

;*---------------------------------------------------------------------*/
;*    scm-response ...                                                 */
;*---------------------------------------------------------------------*/
(define (scm-response req path)
   (let ((cache (cache-get scm2js-cache path))
	 (mime (mime-type path (hop-javascript-mime-type)))
	 (method (http-request-method req)))
      (if (string? cache)
	  ;; since we are serving a cached answer, we also have
	  ;; to check that the client is allowed to the requested
	  ;; file, i.e., the non-compiled file.
	  (instantiate::http-response-file
	     (request req)
	     (charset (hop-locale))
	     (content-type mime)
	     (bodyp (eq? method 'GET))
	     (file cache))
	  (let ((m (eval-module)))
	     (unwind-protect
		(let* ((jscript (scm2js-compiler path))
		       (cache (cache-put! scm2js-cache path jscript)))
		   (instantiate::http-response-file
		      (request req)
		      (charset (hop-locale))
		      (content-type mime)
		      (bodyp (eq? method 'GET))
		      (file cache)))
		(eval-module-set! m))))))

;*---------------------------------------------------------------------*/
;*    scm2js-compile-file ...                                          */
;*---------------------------------------------------------------------*/
(define (scm2js-compile-file path)
   (let* ((req (current-request))
	  (rep (scm-response req path)))
      (with-input-from-file (http-response-file-file rep) read-string)))
      
;*---------------------------------------------------------------------*/
;*    init-scm-compiler! ...                                           */
;*---------------------------------------------------------------------*/
(define (init-scm-compiler! compiler)
   
   (set! scm2js-cache
	 (instantiate::cache-disk
	    (path (make-file-path (hop-rc-directory)
				  "cache"
				  (string-append "scm2js-"
						 (integer->string (hop-port)))))
	    (out (lambda (o p) (with-output-to-port p (lambda () (print o)))))))
   
   (set! scm2js-compiler compiler))
	    
