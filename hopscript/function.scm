;*=====================================================================*/
;*    serrano/prgm/project/hop/3.1.x/hopscript/function.scm            */
;*    -------------------------------------------------------------    */
;*    Author      :  Manuel Serrano                                    */
;*    Creation    :  Sun Sep 22 06:56:33 2013                          */
;*    Last change :  Mon Jun 12 20:36:15 2017 (serrano)                */
;*    Copyright   :  2013-17 Manuel Serrano                            */
;*    -------------------------------------------------------------    */
;*    HopScript function implementation                                */
;*    -------------------------------------------------------------    */
;*    http://www.ecma-international.org/ecma-262/5.1/#sec-15.3         */
;*=====================================================================*/

;*---------------------------------------------------------------------*/
;*    The module                                                       */
;*---------------------------------------------------------------------*/
(module __hopscript_function
   
   (library hop js2scheme)
   
   (include "stringliteral.sch")
   
   (import __hopscript_types
	   __hopscript_property
	   __hopscript_object
	   __hopscript_error
	   __hopscript_private
	   __hopscript_public
	   __hopscript_worker)
   
   (export (js-init-function! ::JsGlobalObject)
	   
	   thrower-get
	   thrower-set
	   
	   (js-function-debug-name::bstring ::JsFunction)
	   (js-make-function::JsFunction ::JsGlobalObject
	      ::procedure ::int ::obj
	      #!key
	      __proto__ prototype constructor construct alloc
	      (strict 'normal) arity (minlen -1) src rest
	      (constrsize 3) (maxconstrsize 100) method)
	   (js-make-function-simple::JsFunction ::JsGlobalObject ::procedure
	      ::int ::obj ::int ::int ::symbol ::bool ::int)))

;*---------------------------------------------------------------------*/
;*    JsStringLiteral begin                                            */
;*---------------------------------------------------------------------*/
(%js-jsstringliteral-begin!)

;*---------------------------------------------------------------------*/
;*    object-serializer ::JsFunction ...                               */
;*---------------------------------------------------------------------*/
(register-class-serialization! JsFunction
   (lambda (o)
      (js-undefined))
   (lambda (o %this) o))

;*---------------------------------------------------------------------*/
;*    xml-primitive-value ::JsFunction ...                             */
;*---------------------------------------------------------------------*/
(define-method (xml-primitive-value obj::JsFunction)
   obj)

;*---------------------------------------------------------------------*/
;*    js-donate ::Jsfunction ...                                       */
;*---------------------------------------------------------------------*/
(define-method (js-donate obj::JsFunction worker::WorkerHopThread %_this)
   (with-access::WorkerHopThread worker (%this)
      (with-access::JsGlobalObject %this (js-function)
	 (with-access::JsFunction obj (procedure src)
	    (if (eq? src 'builtin)
		(duplicate::JsFunction obj
		   (__proto__ (js-get js-function 'prototype %this))
		   (properties '()))
		(js-undefined))))))
   
;*---------------------------------------------------------------------*/
;*    xml-unpack ::JsObject ...                                        */
;*    -------------------------------------------------------------    */
;*    Simply returns the function. This will give XML write            */
;*    a chance to raise an appropriate error messages.                 */
;*---------------------------------------------------------------------*/
(define-method (xml-unpack o::JsFunction)
   o)

;*---------------------------------------------------------------------*/
;*    throwers                                                         */
;*---------------------------------------------------------------------*/
(define thrower-get #f)
(define thrower-set #f)

;*---------------------------------------------------------------------*/
;*    current-loc ...                                                  */
;*---------------------------------------------------------------------*/
(define-expander current-loc
   (lambda (x e)
      (when (epair? x) `',(cer x))))
	 
;*---------------------------------------------------------------------*/
;*    j2s-js-literal ::JsFunction ...                                  */
;*---------------------------------------------------------------------*/
(define-method (j2s-js-literal o::JsFunction)
   (error "js" "Cannot compile function" o))

;*---------------------------------------------------------------------*/
;*    js-init-function! ...                                            */
;*    -------------------------------------------------------------    */
;*    http://www.ecma-international.org/ecma-262/5.1/#sec-15.3.3       */
;*---------------------------------------------------------------------*/
(define (js-init-function! %this::JsGlobalObject)
   ;; first, bind the builtin function prototype
   (with-access::JsGlobalObject %this ((js-object-prototype __proto__)
				       js-function-prototype
				       js-function)
      
      (set! js-function-prototype
	 (instantiate::JsFunction
	    (name "builtin")
	    (src "[Function.__proto__@function.scm]")
	    (len -1)
	    (procedure (lambda l (js-undefined)))
	    (method (lambda l (js-undefined)))
	    (alloc (lambda (_) #unspecified))
	    (construct (lambda (constructor args)
			  (js-raise-type-error %this "not a constructor ~s"
			     js-function-prototype)))
	    (arity -1)
	    (prototype (with-access::JsGlobalObject %this (__proto__)
			  __proto__))
	    (cmap (instantiate::JsConstructMap))
	    (__proto__ js-object-prototype)))
      
      ;; then, create the properties of the function contructor
      (set! js-function
	 (js-make-function %this
	    (%js-function %this) 1 "Function"
	    :src (cons (current-loc) "Function() { /* function.scm */}")
	    :__proto__ js-function-prototype
	    :prototype js-function-prototype
	    :construct (js-function-construct %this)))
      ;; throwers
      (let ((thrower (js-make-function %this
			(lambda (o)
			   (js-raise-type-error %this "[[ThrowTypeError]] ~a" o))
			1 'thrower)))
	 (set! thrower-get thrower)
	 (set! thrower-set thrower))
      ;; prototype properties
      (init-builtin-function-prototype! %this js-function js-function-prototype)
      ;; bind Function in the global object
      (js-bind! %this %this 'Function
	 :value js-function
	 :configurable #f :enumerable #f
	 :hidden-class #f)
      ;; return the js-function object
      js-function))

;*---------------------------------------------------------------------*/
;*    %js-function ...                                                 */
;*    -------------------------------------------------------------    */
;*    http://www.ecma-international.org/ecma-262/5.1/#sec-15.3.1.1     */
;*---------------------------------------------------------------------*/
(define (%js-function %this::JsGlobalObject)
   (lambda (this . value)
      (with-access::JsGlobalObject %this (js-function)
	 (apply js-new %this js-function value))))

;*---------------------------------------------------------------------*/
;*    js-function-construct ...                                        */
;*    -------------------------------------------------------------    */
;*    http://www.ecma-international.org/ecma-262/5.1/#sec-15.3.2.1     */
;*    -------------------------------------------------------------    */
;*    This definition is overriden by the definition of                */
;*    nodejs_require (nodejs/require.scm).                             */
;*---------------------------------------------------------------------*/
(define (js-function-construct %this::JsGlobalObject)
   (lambda (this . args)
      (if (null? args)
	  (js-make-function %this (lambda (this) (js-undefined))
	     0 "" :construct (lambda (_) (js-undefined)))
	  (let* ((len (length args))
		 (formals (take args (-fx len 1)))
		 (body (car (last-pair args)))
		 (fun (format "(function(~(,)) { ~a })"
			 (map (lambda (o) (js-tostring o %this)) formals)
			 (js-tostring body %this))))
	     (call-with-input-string fun
		(lambda (ip)
		   (%js-eval ip 'eval %this this %this)))))))

;*---------------------------------------------------------------------*/
;*    js-function-debug-name ...                                       */
;*---------------------------------------------------------------------*/
(define (js-function-debug-name::bstring obj::JsFunction)
   (with-access::JsFunction obj (name src)
      (cond
	 ((and (string? name) (not (string-null? name)))
	  name)
	 ((pair? src)
	  (format "~a:~a" (cadr (car src)) (caddr (car src))))
	 (else
	  "function"))))

;*---------------------------------------------------------------------*/
;*    INSTANTIATE-JSFUNCTION ...                                       */
;*---------------------------------------------------------------------*/
(define-macro (INSTANTIATE-JSFUNCTION arity . rest)
   `(case ,(cadr arity)
       ,@(map (lambda (n)
		 `((,n)
		   (,(string->symbol (format "instantiate::JsFunction~a" n))
		    ,arity ,@rest)))
	  (iota 5 1))
       (else
	(instantiate::JsFunction
	   ,arity ,@rest))))

;*---------------------------------------------------------------------*/
;*    js-make-function ...                                             */
;*    -------------------------------------------------------------    */
;*    http://www.ecma-international.org/ecma-262/5.1/#sec-15.3.3.1     */
;*---------------------------------------------------------------------*/
(define (js-make-function %this procedure length name
	   #!key __proto__ prototype
	   constructor alloc construct (strict 'normal)
	   arity (minlen -1) src rest
	   (constrsize 3) (maxconstrsize 100) method)
   
   (define (js-not-a-constructor constr)
      (with-access::JsFunction constr (name)
	 (js-raise-type-error %this (format "~s not a constructor ~~a" name)
	    name)))

   (define (get-source)
      
      (define (source this::JsFunction)
	 (with-access::JsFunction this (src)
	    (when (pair? src)
	       (js-string->jsstring
		  (format "~a:~a" (cadr (car src)) (caddr (car src)))))))
      
      (if js-get-source
	  js-get-source
	  (set! js-get-source
	     (instantiate::JsFunction
		(procedure source)
		(method source)
		(arity 0)
		(minlen 0)
		(len 0)
		(alloc js-not-a-constructor)
		(construct list)
		(name "source")
		(prototype (with-access::JsGlobalObject %this (__proto__)
			      __proto__))))))
   
   (with-access::JsGlobalObject %this (js-function js-object)
      (with-access::JsFunction js-function ((js-function-prototype __proto__))
	 (let* ((constr (or construct list))
		(fname (if (symbol? name) (symbol->string! name) name))
		(fun (INSTANTIATE-JSFUNCTION
			(arity (or arity (procedure-arity procedure)))
			(procedure procedure)
			(method (or method procedure))
			(rest rest)
			(len length)
			(__proto__ (or __proto__ js-function-prototype))
			(name fname)
			(src src)
			(alloc (cond
				  (alloc alloc)
				  (construct (lambda (_) #unspecified))
				  (else js-not-a-constructor)))
			(constrsize constrsize)
			(maxconstrsize maxconstrsize)
			(construct constr)
			(cmap (instantiate::JsConstructMap))
			(prototype (if (isa? prototype JsObject)
				       prototype
				       (with-access::JsGlobalObject %this (__proto__)
					  __proto__)))
			(constructor constructor))))
	    
	    (when (or constructor construct)
	       (with-access::JsFunction fun (constrmap)
		  (set! constrmap (instantiate::JsConstructMap (ctor fun)))))
	    
	    (cond
	       (prototype
		(when (isa? prototype JsObject)
		   (js-bind! %this prototype 'constructor
		      :value fun
		      :configurable #t :writable #t :enumerable #f
		      :hidden-class #t))
		(js-bind! %this fun 'prototype
		   :value prototype
		   :enumerable #f :configurable #f :writable #f
		   :hidden-class #t))
	       (construct
		(with-access::JsObject %this ((js-object-prototype __proto__))
		   (let ((prototype (instantiate::JsObject
				       (cmap (instantiate::JsConstructMap))
				       (__proto__ js-object-prototype))))
		      (js-bind! %this prototype 'constructor
			 :value fun
			 :configurable #t :writable #t :enumerable #f
			 :hidden-class #t)
		      (js-bind! %this fun 'prototype
			 :value prototype
			 :enumerable #f :configurable #f :writable #t
			 :hidden-class #t)))))
	    (js-bind! %this fun 'length
	       :value length
	       :enumerable #f :configurable #f :writable #f
	       :hidden-class #f)
	    (unless (eq? strict 'normal)
	       (js-bind! %this fun 'arguments
		  :get thrower-get :set thrower-set
		  :enumerable #f :configurable #f
		  :hidden-class #t)
	       (js-bind! %this fun 'caller
		  :get thrower-get :set thrower-set
		  :enumerable #f :configurable #f
		  :hidden-class #t))
	    (js-bind! %this fun 'name
	       :value (js-string->jsstring fname)
	       :writable #f
	       :enumerable #f :configurable #f
	       :hidden-class #f)
	    ;; source is an hop extension
	    (js-bind! %this fun 'source
	       :get (get-source)
	       :writable #f
	       :enumerable #f :configurable #f
	       :hidden-class #f)
	    fun))))

;*---------------------------------------------------------------------*/
;*    js-get-source ...                                                */
;*---------------------------------------------------------------------*/
(define js-get-source #f)

;*---------------------------------------------------------------------*/
;*    js-make-function-simple ...                                      */
;*---------------------------------------------------------------------*/
(define (js-make-function-simple %this::JsGlobalObject proc::procedure
	   len::int name arity::int minlen::int strict::symbol rest::bool
	   constrsize::int)
   (js-make-function %this proc len name
      :prototype #f :__proto__ #f
      :arity arity :strict strict :rest rest :minlen minlen
      :src #f
      :alloc (lambda (o) (js-object-alloc o %this))
      :construct proc :constrsize constrsize))

;*---------------------------------------------------------------------*/
;*    init-builtin-function-prototype! ...                             */
;*    -------------------------------------------------------------    */
;*    http://www.ecma-international.org/ecma-262/5.1/#sec-15.3.4       */
;*---------------------------------------------------------------------*/
(define (init-builtin-function-prototype! %this::JsGlobalObject js-function obj)
   ;; length
   (js-bind! %this obj 'length
      :value 0
      :enumerable #f :configurable #f :writable #f
      :hidden-class #t)
   
   ;; constructor
   (js-bind! %this obj 'constructor
      :value js-function
      :enumerable #f :configurable #t :writable #t
      :hidden-class #t)
   
   ;; toString
   ;; http://www.ecma-international.org/ecma-262/5.1/#sec-15.3.4.2
   (define (tostring this)
      (cond
	 ((isa? this JsFunction)
	  (with-access::JsFunction this (name src)
	     (cond
		((pair? src)
		 (if (string? (cdr src))
		     (js-string->jsstring (cdr src))
		     (js-string->jsstring
			(format "[Function ~a~a]"
			   (cadr (car src)) (caddr (car src))))))
		((>fx (string-length name) 0)
		 (js-string->jsstring (format "[Function ~a]" name)))
		(else
		 (js-string->jsstring "[Function]")))))
	 (else
	  (js-raise-type-error %this "toString: not a function ~s"
	     (js-typeof this)))))

   (define (vector->sublist vec len)
      (if (=fx (vector-length vec) len)
	  (vector->list vec)
	  (let loop ((i (-fx len 1))
		     (acc '()))
	     (if (=fx i -1)
		 acc
		 (loop (-fx i 1) (cons (vector-ref vec i) acc))))))

   
   (js-bind! %this obj 'toString
      :value (js-make-function %this tostring 0 "toString"
		:prototype (js-undefined))
      :enumerable #f :writable #t :configurable #t
      :hidden-class #t)
   
   ;; apply
   ;; http://www.ecma-international.org/ecma-262/5.1/#sec-15.3.4.3
   (define (prototype-apply this::obj thisarg argarray)
      (cond
	 ((not (isa? this JsFunction))
	  (js-raise-type-error %this
	     "apply: argument not a function ~s" this))
	 ((or (eq? argarray (js-null)) (eq? argarray (js-undefined)))
	  (js-call0 %this this thisarg))
	 ((not (isa? argarray JsObject))
	  (js-raise-type-error %this
	     "apply: argument not an object ~s" argarray))
	 ((isa? argarray JsArray)
	  (let ((len (js-get argarray 'length %this)))
	     (with-access::JsArray argarray (vec properties)
		(if (>fx (vector-length vec) 0)
		    ;; fast path
		    (js-apply %this this thisarg
		       (map (lambda (p)
			       (if (eq? p (js-absent)) (js-undefined) p))
			  (vector->sublist vec len)))
		    ;; slow path
		    ;; CARE (5 jul 2014): MS NOT SURE OF THE SECOND ARGARRAY BELOW
		    (js-apply %this this thisarg
		       (map! (lambda (d)
				(js-property-value argarray argarray %this))
			  (filter (lambda (d)
				     (with-access::JsPropertyDescriptor d (name)
					(js-isindex? (js-toindex name))))
			     properties)))))))
	 (else
	  ;; slow path
	  (let ((len (uint32->fixnum
			(js-touint32
			   (js-get argarray 'length %this)
			   %this))))
	     ;; assumes here a fixnum length as an iteration over the range
	     ;; 1..2^32-1 is not computable with 2014 computer's performance
	     (with-access::JsArray argarray (vec)
		(let loop ((i 0)
			   (acc '()))
		   (if (=fx i len)
		       ;; fast path
		       (js-apply %this this thisarg (reverse! acc))
		       ;; slow path
		       (loop (+fx i 1)
			  (cons (js-get argarray i %this) acc)))))))))
   
   (js-bind! %this obj 'apply
      :value (js-make-function %this prototype-apply 2 "apply"
		:prototype (js-undefined))
      :enumerable #f :writable #t :configurable #t
      :hidden-class #t)
   
   ;; call
   ;; http://www.ecma-international.org/ecma-262/5.1/#sec-15.3.4.4
   (define (call this::obj thisarg . args)
      (cond
	 ((null? args)
	  (js-call0 %this this thisarg))
	 ((null? (cdr args))
	  (js-call1 %this this thisarg (car args)))
	 ((null? (cddr args))
	  (js-call2 %this this thisarg (car args) (cadr args)))
	 ((null? (cdddr args))
	  (js-call3 %this this thisarg (car args) (cadr args) (caddr args)))
	 (else
	  (js-apply %this this thisarg args))))
   
   (with-access::JsGlobalObject %this (js-call)
      (set! js-call
	 (js-make-function %this call 1 "call" :prototype (js-undefined)))
      (js-bind! %this obj 'call
	 :value js-call
	 :enumerable #f :writable #t :configurable #t
	 :hidden-class #t))
   
   ;; bind
   ;; http://www.ecma-international.org/ecma-262/5.1/#sec-15.3.4.5
   (define (bind this::obj thisarg . args)
      (if (not (isa? this JsFunction))
	  (js-raise-type-error %this "bind: this not a function ~s" this)
	  (with-access::JsFunction this (name len construct alloc procedure)
	     (let ((fun (lambda (_ . actuals)
			   (js-apply %this this thisarg (append args actuals)))))
		(js-make-function
		   %this
		   fun
		   (maxfx 0 (-fx len (length args)))
		   name
		   :strict 'strict
		   :alloc alloc
		   :construct fun)))))

   (js-bind! %this obj 'bind
      :value (js-make-function %this bind 1 "bind" :prototype (js-undefined))
      :enumerable #f :writable #t :configurable #t
      :hidden-class #t)
   
   ;; hopscript does not support caller
   (js-bind! %this obj 'caller
      :get thrower-get
      :set thrower-set
      :enumerable #f :configurable #f
      :hidden-class #t))

;*---------------------------------------------------------------------*/
;*    JsStringLiteral end                                              */
;*---------------------------------------------------------------------*/
(%js-jsstringliteral-end!)
