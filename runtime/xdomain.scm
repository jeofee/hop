;*=====================================================================*/
;*    serrano/prgm/project/hop/2.2.x/runtime/xdomain.scm               */
;*    -------------------------------------------------------------    */
;*    Author      :  Manuel Serrano                                    */
;*    Creation    :  Fri May  6 11:54:10 2011                          */
;*    Last change :  Fri May  6 14:56:24 2011 (serrano)                */
;*    Copyright   :  2011 Manuel Serrano                               */
;*    -------------------------------------------------------------    */
;*    Hop xdomain requests                                             */
;*=====================================================================*/

;*---------------------------------------------------------------------*/
;*    The module                                                       */
;*---------------------------------------------------------------------*/
(module __hop_xdomain

   (include "service.sch")
   
   (import  __hop_param
	    __hop_configure
	    __hop_types
	    __hop_misc
	    __hop_xml-types
	    __hop_xml
	    __hop_html-base
	    __hop_html-head
	    __hop_cgi
	    __hop_service
	    __hop_js-lib
	    __hop_read
	    __hop_hop
	    __hop_user
	    __hop_http-error
	    __hop_security)
   
   (export (init-hop-xdomain-service!)))

;*---------------------------------------------------------------------*/
;*    *xdomain-svc* ...                                                */
;*---------------------------------------------------------------------*/
(define *xdomain-svc* #unspecified)

;*---------------------------------------------------------------------*/
;*    init-hop-xdomain-service! ...                                    */
;*---------------------------------------------------------------------*/
(define (init-hop-xdomain-service!)
   (set! *xdomain-svc*
      (service :name "admin/xdomain" (#!key origin)
	 (instantiate::http-response-hop
	    (request (current-request))
	    (charset (hop-locale))
	    (xml (<HTML>
		    (<HEAD>)
		    (<BODY>
		       (sexp->xml-tilde
			  `(add-event-listener! window "message"
			      (lambda (e)
				 ((@ hop_send_request_xdomain _) e ,origin)))))))))))