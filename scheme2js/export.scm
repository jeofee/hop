;*=====================================================================*/
;*    serrano/prgm/project/hop/2.5.x/scheme2js/export.scm              */
;*    -------------------------------------------------------------    */
;*    Author      :  Florian Loitsch                                   */
;*    Creation    :  2007-12                                           */
;*    Last change :  Thu Sep  5 16:26:57 2013 (serrano)                */
;*    Copyright   :  2013 Manuel Serrano                               */
;*    -------------------------------------------------------------    */
;*    export                                                           */
;*=====================================================================*/

;*---------------------------------------------------------------------*/
;*    The module                                                       */
;*---------------------------------------------------------------------*/
(module export-desc
   
   (import gen-js error)
   
   (export (find-desc-in-exports sym::symbol l/ht)
	   
	   (empty-exports?::bool l/ht)
	   
	   (final-class Export-Desc
	      (id::symbol read-only)
	      (js-id::bstring read-only)
	      (exported-as-const?::bool (default #f))
	      (runtime?::bool (default #f) read-only)
	      (peephole       (default #f) read-only)
	      (higher?::bool  (default #f) read-only)
	      (higher-params  (default #f) read-only) 
	      (return-type    (default #f) read-only)
	      (arity          (default #f) read-only))
	   
    (create-Export-Desc::Export-Desc info module-name runtime?::bool)))


;*---------------------------------------------------------------------*/
;*    empty-exports? ...                                               */
;*---------------------------------------------------------------------*/
(define (empty-exports? l/ht)
   (or (null? l/ht)
       (and (hashtable? l/ht)
	    (zerofx? (hashtable-size l/ht)))))

;*---------------------------------------------------------------------*/
;*    find-desc-in-exports ...                                         */
;*---------------------------------------------------------------------*/
(define (find-desc-in-exports sym l/ht)
   (cond
      ((pair? l/ht)
       (any (lambda (desc)
	       (and (eq? (with-access::Export-Desc desc (id) id) sym)
		    desc))
	  l/ht))
      ((hashtable? l/ht)
       (hashtable-get l/ht sym))
      ((null? l/ht)
       #f)
      (else
       (error "export.scm" "internal error" sym))))

;*---------------------------------------------------------------------*/
;*    entry-val ...                                                    */
;*---------------------------------------------------------------------*/
(define (entry-val sym l)
   (let ((try (assq sym (cdr l))))
      (and try (cadr try))))

;*---------------------------------------------------------------------*/
;*    entry-vals ...                                                   */
;*---------------------------------------------------------------------*/
(define (entry-vals sym l)
   (let ((try (assq sym (cdr l))))
      (and try (cdr try))))

;*---------------------------------------------------------------------*/
;*    normalize-export ...                                             */
;*---------------------------------------------------------------------*/
(define (normalize-export export module-name)
   (cond
      ((symbol? export)
       (list export
	  (list 'JS
	     (mangle-qualified-var export module-name))))
      ((pair? export)
       (cond
	  ((assq 'JS (cdr export))
	   export)
	  (else
	   (let ((scheme-sym (car export)))
	      (cons* scheme-sym
		 (list 'JS
		    (mangle-qualified-var scheme-sym module-name))
		 (cdr export))))))
      (else
       (scheme2js-error "normalize-export"
	  "bad import/export clause"
	  export
	  export))))

;*---------------------------------------------------------------------*/
;*    normalize-js-id ...                                              */
;*---------------------------------------------------------------------*/
(define (normalize-js-id normalized)
   (let* ((clause (assq 'JS (cdr normalized)))
	  (id (and clause
		   (pair? (cdr clause))
		   (cadr clause))))
      (cond
	 ((symbol? id) (symbol->string id))
	 ((string? id)
	  id)
	 (else 
	  (scheme2js-error "exported variable"
	     "JS-clause must be either symbol or string"
	     id
	     clause)))))

;*---------------------------------------------------------------------*/
;*    create-Export-Desc ...                                           */
;*---------------------------------------------------------------------*/
(define (create-Export-Desc::Export-Desc info module-name runtime?)
   (let* ((normalized (normalize-export info module-name))
	  (scheme-sym (car normalized))
	  (js-id (normalize-js-id normalized))
	  (peephole (entry-vals 'peephole normalized))
	  (higher? (entry-val 'call/cc? normalized))
	  (higher-params (entry-val 'call/cc-params normalized))
	  (return-type (entry-val 'type normalized))
	  (exported-as-const? (or (entry-val 'constant? normalized)))
	  (arity (entry-val 'arity normalized)))
      (instantiate::Export-Desc
	 (id scheme-sym)
	 (js-id js-id)
	 (exported-as-const? exported-as-const?)
	 (runtime? runtime?)
	 (peephole peephole)
	 (higher? higher?)
	 (higher-params higher-params)
	 (return-type return-type)
	 (arity arity))))
