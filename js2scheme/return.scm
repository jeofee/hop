;*=====================================================================*/
;*    serrano/prgm/project/hop/2.6.x/js2scheme/return.scm              */
;*    -------------------------------------------------------------    */
;*    Author      :  Manuel Serrano                                    */
;*    Creation    :  Wed Sep 11 14:30:38 2013                          */
;*    Last change :  Sat Jan 11 08:29:37 2014 (serrano)                */
;*    Copyright   :  2013-14 Manuel Serrano                            */
;*    -------------------------------------------------------------    */
;*    JavaScript Return -> bind-exit                                   */
;*    -------------------------------------------------------------    */
;*    This module implements the JavaScript return removal. After      */
;*    this pass, return are not longer expected in the tree. They      */
;*    are replaced with either bind-exit calls or by tail returns.     */
;*=====================================================================*/

;*---------------------------------------------------------------------*/
;*    The module                                                       */
;*---------------------------------------------------------------------*/
(module __js2scheme_return

   (import __js2scheme_ast
	   __js2scheme_dump
	   __js2scheme_compile
	   __js2scheme_stage
	   __js2scheme_syntax)

   (export j2s-return-stage
	   (generic j2s-return ::obj)))

;*---------------------------------------------------------------------*/
;*    j2s-return-stage ...                                             */
;*---------------------------------------------------------------------*/
(define j2s-return-stage
   (instantiate::J2SStage
      (name "return")
      (comment "Mark functions that need a Bigloo bind-exit for return")
      (proc j2s-return)))

;*---------------------------------------------------------------------*/
;*    j2s-return ...                                                   */
;*---------------------------------------------------------------------*/
(define-generic (j2s-return this)
   this)

;*---------------------------------------------------------------------*/
;*    trim-nop ...                                                     */
;*---------------------------------------------------------------------*/
(define (trim-nop nodes)
   (filter (lambda (x) (not (isa? x J2SNop))) nodes))

;*---------------------------------------------------------------------*/
;*    j2s-return ::J2SProgram ...                                      */
;*---------------------------------------------------------------------*/
(define-method (j2s-return this::J2SProgram)
   (with-access::J2SProgram this (nodes)
      (for-each (lambda (o) (unreturn! o #f #t)) nodes)
      (set! nodes (trim-nop nodes)))
   this)

;*---------------------------------------------------------------------*/
;*    unreturn! ::J2SNode ...                                          */
;*---------------------------------------------------------------------*/
(define-walk-method (unreturn! this::J2SNode target tail?)
   (default-walk! this target tail?))

;*---------------------------------------------------------------------*/
;*    unreturn! ::J2SBlock ...                                         */
;*---------------------------------------------------------------------*/
(define-walk-method (unreturn! this::J2SBlock target tail?)
   (with-access::J2SBlock this (nodes loc)
      (let loop ((n nodes))
	 (when (pair? n)
	    (let ((t? (and tail? (null? (cdr n)))))
	       (set-car! n (walk! (car n) target t?))
	       (loop (cdr n)))))
      ;; remove all useful nop (for readability)
      (set! nodes (trim-nop nodes))
      ;; force a return when needed
      (when (and target tail? (not (return? this)))
	 ;; this is a function tail statement that misses a return
	 ;; statement, add one.
	 ;; we could do better here, instead of transformaing
	 ;;    (if test (return XXX))
	 ;; into
	 ;;    (seq (if test (return XXXX)) (return (js-undefined)))
	 ;; we could tranform it into
	 ;;    (if test (return XXX) (return (js-undefined)))
	 (let ((ret (instantiate::J2SReturn
		       (loc loc)
		       (tail #t)
		       (expr (instantiate::J2SUndefined
				(loc loc))))))
	    (if (null? nodes)
		(set! nodes (list ret))
		(begin
		   (for-each (lambda (n) (untail-return! n target)) nodes)
		   (set-cdr! (last-pair nodes) (list ret)))))))
   this)

;*---------------------------------------------------------------------*/
;*    unreturn! ::J2STry...                                            */
;*---------------------------------------------------------------------*/
(define-walk-method (unreturn! this::J2STry target tail?)
   (with-access::J2STry this (body catch finally)
      (set! body (walk! body target tail?))
      (set! catch (walk! catch target tail?))
      (set! finally (walk! finally target #f)))
   this)
   
;*---------------------------------------------------------------------*/
;*    unreturn! ::J2SFun ...                                           */
;*---------------------------------------------------------------------*/
(define-walk-method (unreturn! this::J2SFun target tail?)
   (with-access::J2SFun this (body)
      (set! body (walk! body this #t)))
   this)

;*---------------------------------------------------------------------*/
;*    unreturn! ::J2SCatch ...                                         */
;*---------------------------------------------------------------------*/
(define-walk-method (unreturn! this::J2SCatch target tail?)
   (with-access::J2SCatch this (body)
      (set! body (walk! body target tail?)))
   this)

;*---------------------------------------------------------------------*/
;*    unreturn! ::J2SWhile ...                                         */
;*---------------------------------------------------------------------*/
(define-walk-method (unreturn! this::J2SWhile target tail?)
   (with-access::J2SWhile this (test body)
      (set! test (walk! test target #f))
      (set! body (walk! body target #f)))
   this)

;*---------------------------------------------------------------------*/
;*    unreturn! ::J2SAssig ...                                         */
;*---------------------------------------------------------------------*/
(define-walk-method (unreturn! this::J2SAssig target tail?)
   (with-access::J2SAssig this (lhs rhs)
      (set! lhs (walk! lhs target #f))
      (set! rhs (walk! rhs target #f)))
   this)

;*---------------------------------------------------------------------*/
;*    unreturn! ::J2SReturn ...                                        */
;*---------------------------------------------------------------------*/
(define-walk-method (unreturn! this::J2SReturn target tail?)
   (with-access::J2SReturn this (tail loc expr)
      (unless target
	 (syntax-error this "Illegal return statement"))
      (unless tail?
	 ;; mark the return as non-tail
	 (set! tail #f)
	 ;; mark the function as needing a bind-exit
	 (with-access::J2SFun target (need-bind-exit-return)
	    (set! need-bind-exit-return #t)))
      (set! expr (walk! expr target #f)))
   this)

;*---------------------------------------------------------------------*/
;*    unreturn! ::J2SLabel ...                                         */
;*---------------------------------------------------------------------*/
(define-walk-method (unreturn! this::J2SLabel target tail?)
   (with-access::J2SLabel this (body)
      (set! body (walk! body target tail?)))
   this)

;*---------------------------------------------------------------------*/
;*    unreturn! ::J2SIf ...                                            */
;*---------------------------------------------------------------------*/
(define-walk-method (unreturn! this::J2SIf target tail?)
   (with-access::J2SIf this (test then else)
      (set! test (walk! test target #f))
      (set! then (walk! then target tail?))
      (set! else (walk! else target tail?)))
   this)

;*---------------------------------------------------------------------*/
;*    unreturn! ::J2SCond ...                                          */
;*---------------------------------------------------------------------*/
(define-walk-method (unreturn! this::J2SCond target tail?)
   (with-access::J2SCond this (test then else)
      (set! test (walk! test target #f))
      (set! then (walk! then target tail?))
      (set! else (walk! else target tail?)))
   this)

;*---------------------------------------------------------------------*/
;*    unreturn! ::J2SFor ...                                           */
;*---------------------------------------------------------------------*/
(define-walk-method (unreturn! this::J2SFor target tail?)
   (with-access::J2SFor this (init test incr body)
      (set! init (walk! init target #f))
      (set! test (walk! test target #f))
      (set! incr (walk! incr target #f))
      (set! body (walk! body target #f)))
   this)

;*---------------------------------------------------------------------*/
;*    unreturn! ::J2SForIn ...                                         */
;*---------------------------------------------------------------------*/
(define-walk-method (unreturn! this::J2SForIn target tail?)
   (with-access::J2SForIn this (lhs obj body)
      (set! lhs (walk! lhs target #f))
      (set! obj (walk! obj target #f))
      (set! body (walk! body target #f)))
   this)

;*---------------------------------------------------------------------*/
;*    untail-return! ::J2SNode ...                                     */
;*---------------------------------------------------------------------*/
(define-walk-method (untail-return! this::J2SNode target)
   (default-walk! this target))

;*---------------------------------------------------------------------*/
;*    untail-return! ::J2SReturn ...                                   */
;*---------------------------------------------------------------------*/
(define-method (untail-return! this::J2SReturn target)
   (with-access::J2SReturn this (tail)
      (with-access::J2SFun target (need-bind-exit-return)
	 (set! need-bind-exit-return #t))
      (set! tail #f)
      this))

;*---------------------------------------------------------------------*/
;*    untail-return! ::J2SFun ...                                      */
;*---------------------------------------------------------------------*/
(define-method (untail-return! this::J2SFun target)
   this)

;*---------------------------------------------------------------------*/
;*    return? ::J2SNode ...                                            */
;*---------------------------------------------------------------------*/
(define-walk-method (return? this::J2SNode)
   #f)

;*---------------------------------------------------------------------*/
;*    return? ::J2SFun ...                                             */
;*---------------------------------------------------------------------*/
(define-method (return? this::J2SFun)
   #f)

;*---------------------------------------------------------------------*/
;*    return? ::J2SBlock ...                                           */
;*---------------------------------------------------------------------*/
(define-walk-method (return? this::J2SBlock)
   (with-access::J2SBlock this (nodes)
      (when (pair? nodes)
	 (return? (car (last-pair nodes))))))

;*---------------------------------------------------------------------*/
;*    return? ::J2SIf ...                                              */
;*---------------------------------------------------------------------*/
(define-walk-method (return? this::J2SIf)
   (with-access::J2SIf this (then else)
      (and (return? then) (return? else))))

;*---------------------------------------------------------------------*/
;*    return? ::J2SStmtExpr ...                                        */
;*---------------------------------------------------------------------*/
(define-walk-method (return? this::J2SStmtExpr)
   (with-access::J2SStmtExpr this (expr)
      (return? expr)))

;*---------------------------------------------------------------------*/
;*    return? ::J2SSwitch ...                                          */
;*---------------------------------------------------------------------*/
(define-walk-method (return? this::J2SSwitch)
   (with-access::J2SSwitch this (cases)
      (every return? cases)))

;*---------------------------------------------------------------------*/
;*    return? ::J2SDo ...                                              */
;*    -------------------------------------------------------------    */
;*    Only the Do loop is considered as other loops are not            */
;*    guarantied to execute once.                                      */
;*---------------------------------------------------------------------*/
(define-walk-method (return? this::J2SDo)
   (with-access::J2SDo this (body)
      (return? body)))

;*---------------------------------------------------------------------*/
;*    unreturn? ::J2SReturn ...                                        */
;*---------------------------------------------------------------------*/
(define-walk-method (return? this::J2SReturn)
   #t)