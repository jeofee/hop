;*=====================================================================*/
;*    serrano/prgm/project/hop/3.1.x/js2scheme/cps.scm                 */
;*    -------------------------------------------------------------    */
;*    Author      :  Manuel Serrano                                    */
;*    Creation    :  Wed Sep 11 14:30:38 2013                          */
;*    Last change :  Sat Dec 12 07:58:37 2015 (serrano)                */
;*    Copyright   :  2013-15 Manuel Serrano                            */
;*    -------------------------------------------------------------    */
;*    JavaScript CPS transformation                                    */
;*    -------------------------------------------------------------    */
;*    http://www.ecma-international.org/ecma-262/6.0/#sec-14.4         */
;*    -------------------------------------------------------------    */
;*    This module implements the JavaScript CPS transformation needed  */
;*    to implement generators. Only generator function are modified.   */
;*=====================================================================*/

;*---------------------------------------------------------------------*/
;*    The module                                                       */
;*---------------------------------------------------------------------*/
(module __js2scheme_cps

   (import __js2scheme_ast
	   __js2scheme_dump
	   __js2scheme_compile
	   __js2scheme_stage
	   __js2scheme_syntax
	   __js2scheme_utils)

   (static (final-class %J2STail::J2SReturn))
   
   (export j2s-cps-stage
	   (generic j2s-cps ::obj ::obj)))

;*---------------------------------------------------------------------*/
;*    j2s-cps-stage ...                                                */
;*---------------------------------------------------------------------*/
(define j2s-cps-stage
   (instantiate::J2SStageProc
      (name "cps")
      (comment "transform generator in CPS")
      (proc j2s-cps)))

;*---------------------------------------------------------------------*/
;*    j2s-cps ...                                                      */
;*---------------------------------------------------------------------*/
(define-generic (j2s-cps this args)
   this)

;*---------------------------------------------------------------------*/
;*    j2s-cps ::J2SProgram ...                                         */
;*---------------------------------------------------------------------*/
(define-method (j2s-cps this::J2SProgram args)
   (with-access::J2SProgram this (headers decls nodes)
      (for-each (lambda (o) (cps-fun o)) headers)
      (for-each (lambda (o) (cps-fun o)) decls)
      (for-each (lambda (o) (cps-fun o)) nodes))
   this)

;*---------------------------------------------------------------------*/
;*    kid ...                                                          */
;*---------------------------------------------------------------------*/
(define (kid n::J2SNode)
   n)

;*---------------------------------------------------------------------*/
;*    cps-fun ::J2SNode ...                                            */
;*---------------------------------------------------------------------*/
(define-walk-method (cps-fun this::J2SNode)
   (call-default-walker))

;*---------------------------------------------------------------------*/
;*    cps-fun ::J2SFun ...                                             */
;*---------------------------------------------------------------------*/
(define-walk-method (cps-fun this::J2SFun)
   (with-access::J2SFun this (generator body)
      (when generator
	 (set! body (cps body kid kid '() '())))
      this))

;*---------------------------------------------------------------------*/
;*    Small macro-based API for helping creating J2SNode               */
;*---------------------------------------------------------------------*/
(define-macro (J2SUndefined)
   `(instantiate::J2SUndefined
       (loc loc)))

(define-macro (J2SBool val)
   `(instantiate::J2SBool
       (loc loc)
       (val ,val)))

(define-macro (J2SNumber val)
   `(instantiate::J2SNumber
       (loc loc)
       (val ,val)))

(define-macro (J2SString val)
   `(instantiate::J2SString
       (loc loc)
       (val ,val)))

(define-macro (J2SNop)
   `(instantiate::J2SNop
       (loc loc)))

(define-macro (J2SPragma expr)
   `(instantiate::J2SPragma
       (loc loc)
       (expr ,expr)))

(define-macro (J2SParen expr)
   `(instantiate::J2SParen
       (loc loc)
       (expr ,expr)))

(define-macro (J2SBinary op lhs rhs)
   `(instantiate::J2SBinary
       (loc loc)
       (op ,op)
       (lhs ,lhs)
       (rhs ,rhs)))

(define-macro (J2SPostfix op lhs rhs)
   `(instantiate::J2SPostfix
       (loc loc)
       (op ,op)
       (lhs ,lhs)
       (rhs ,rhs)))

(define-macro (J2SCall fun . args)
   `(instantiate::J2SCall
       (loc loc)
       (fun ,fun)
       (args ,(if (pair? args) `(list ,(car args)) ''()))))

(define-macro (J2SAccess obj field)
   `(instantiate::J2SAccess
       (loc loc)
       (obj ,obj)
       (field ,field)))

(define-macro (J2SRef decl)
   `(instantiate::J2SRef
       (loc loc)
       (decl ,decl)))

(define-macro (J2SUnresolvedRef id)
   `(instantiate::J2SUnresolvedRef
       (loc loc)
       (id ,id)))

(define-macro (J2SHopRef id)
   `(instantiate::J2SHopRef
       (loc loc)
       (id ,id)))

(define-macro (J2SFun name params body)
   `(instantiate::J2SFun
       (loc loc)
       (mode 'hopscript)
       (name ,name)
       (params ,params)
       (body ,body)))

(define-macro (J2SBlock . nodes)
   `(instantiate::J2SBlock
       (loc loc)
       (endloc loc)
       (nodes ,(if (pair? nodes) `(list ,@nodes) ''()))))

(define-macro (J2SSeq . nodes)
   `(instantiate::J2SSeq
       (loc loc)
       (nodes ,(if (pair? nodes) `(list ,@nodes) ''()))))

(define-macro (J2SSeq* nodes)
   `(instantiate::J2SSeq
       (loc loc)
       (nodes ,nodes)))

(define-macro (J2SSequence . exprs)
   `(instantiate::J2SSequence
       (loc loc)
       (exprs ,(if (pair? exprs) `(list ,@exprs) ''()))))

(define-macro (J2SSequence* exprs)
   `(instantiate::J2SSequence
       (loc loc)
       (exprs ,exprs)))

(define-macro (J2SLetBlock decls . nodes)
   `(instantiate::J2SLetBlock
       (loc loc)
       (endloc loc)
       (decls ,decls)
       (nodes ,(if (pair? nodes) `(list ,@nodes) ''()))))

(define-macro (J2STry body catch . finally)
   `(instantiate::J2STry
       (loc loc)
       (body ,body)
       (catch ,catch)
       (finally ,(if (pair? finally) (car finally) '(J2SNop)))))

(define-macro (J2SCatch param body)
   `(instantiate::J2SCatch
       (loc loc)
       (param ,param)
       (body ,body)))

(define-macro (J2SKont param exn body)
   `(instantiate::J2SKont
       (loc loc)
       (param ,param)
       (exn ,exn)
       (body ,body)))

(define-macro (J2SYield expr kont)
   `(instantiate::J2SYield
       (loc loc)
       (expr ,expr)
       (kont ,kont)))

(define-macro (J2SStmtExpr expr)
   `(instantiate::J2SStmtExpr
       (loc loc)
       (expr ,expr)))

(define-macro (J2SExprStmt stmt)
   `(instantiate::J2SExprStmt
       (loc loc)
       (stmt ,stmt)))

(define-macro (J2SLetOpt usage id val)
   `(instantiate::J2SLetOpt
       (loc loc)
       (isconst #t)
       (usage ,usage)
       (val ,val)
       (id ,id)))

(define-macro (J2SDeclInit usage id val)
   `(instantiate::J2SDeclInit
       (loc loc)
       (usage ,usage)
       (val ,val)
       (id ,id)))

(define-macro (%J2STail expr)
   `(instantiate::%J2STail
       (loc loc)
       (expr ,expr)))

(define-macro (J2SIf test then else)
   `(instantiate::J2SIf
       (loc loc)
       (test ,test)
       (then ,then)
       (else ,else)))

(define-macro (J2SCond test then else)
   `(instantiate::J2SCond
       (loc loc)
       (test ,test)
       (then ,then)
       (else ,else)))

(define-macro (J2SParam id usage)
   `(instantiate::J2SParam
       (loc loc)
       (usage ,usage)
       (id ,id)))

(define-macro (J2SReturn tail expr)
   `(instantiate::J2SReturn
       (loc loc)
       (tail ,tail)
       (expr ,expr)))

(define-macro (J2SAssig lhs rhs)
   `(instantiate::J2SAssig
       (loc loc)
       (lhs ,lhs)
       (rhs ,rhs)))

(define-macro (J2SThrow expr)
   `(instantiate::J2SThrow
       (loc loc)
       (expr ,expr)))

(define-macro (J2SSwitch key cases)
   `(instantiate::J2SSwitch
       (loc loc)
       (key ,key)
       (cases ,cases)))

(define-macro (J2SDefault body)
   `(instantiate::J2SDefault
       (loc loc)
       (expr (J2SUndefined))
       (body ,body)))

(define-macro (J2SFor init test incr body)
   `(instantiate::J2SFor
       (loc loc)
       (init ,init)
       (test ,test)
       (incr ,incr)
       (body ,body)))

;*---------------------------------------------------------------------*/
;*    empty-stmt? ...                                                  */
;*---------------------------------------------------------------------*/
(define (empty-stmt? stmt)
   (when (isa? stmt J2SSeq)
      (with-access::J2SSeq stmt (nodes)
	 (null? nodes))))

;*---------------------------------------------------------------------*/
;*    make-stmt-kont ...                                               */
;*---------------------------------------------------------------------*/
(define (make-stmt-kont loc stmt::J2SStmt)
   (let* ((name (gensym '%kstmt))
	  (arg (J2SParam (gensym '%karg) '(ref)))
	  (kfun (J2SFun #f (list arg) (J2SBlock stmt))))
      (J2SLetOpt '(call) name kfun)))
   
;*---------------------------------------------------------------------*/
;*    cps* ...                                                         */
;*---------------------------------------------------------------------*/
(define (cps* nodes::pair-nil k pack kbreaks kcontinues)
   (let loop ((nodes nodes)
	      (knodes '()))
      (if (null? nodes)
	  (k (reverse! knodes))
	  (cps (car nodes)
	     (lambda (kexpr::J2SExpr)
		(loop (cdr nodes)
		   (cons kexpr knodes)))
	     pack kbreaks kcontinues))))

;*---------------------------------------------------------------------*/
;*    cps ::J2SNode ...                                                */
;*---------------------------------------------------------------------*/
(define-generic (cps this::J2SNode k pack kbreaks kcontinues)
   (warning "cps: should not be here " (typeof this))
   (k this))

;*---------------------------------------------------------------------*/
;*    cps ::J2SLiteral ...                                             */
;*---------------------------------------------------------------------*/
(define-method (cps this::J2SLiteral k pack kbreaks kcontinues)
   (k this))

;*---------------------------------------------------------------------*/
;*    cps ::J2SNop ...                                                 */
;*---------------------------------------------------------------------*/
(define-method (cps this::J2SNop k pack kbreaks kcontinues)
   (k this))

;*---------------------------------------------------------------------*/
;*    cps ::J2SParen ...                                               */
;*---------------------------------------------------------------------*/
(define-method (cps this::J2SParen k pack kbreaks kcontinues)
   (with-access::J2SParen this (loc expr)
      (if (yield-expr? expr kbreaks kcontinues)
	  (cps expr
	     (lambda (kexpr::J2SExpr)
		(k (J2SParen kexpr)))
	     pack kbreaks kcontinues)
	  (k this))))

;*---------------------------------------------------------------------*/
;*    cps ::J2SRef ...                                                 */
;*---------------------------------------------------------------------*/
(define-method (cps this::J2SRef k pack kbreaks kcontinues)
   (k this))

;*---------------------------------------------------------------------*/
;*    cps ::J2SUnary ...                                               */
;*---------------------------------------------------------------------*/
(define-method (cps this::J2SUnary k pack kbreaks kcontinues)
   (with-access::J2SUnary this (expr)
      (if (yield-expr? expr kbreaks kcontinues)
	  (cps expr
	     (lambda (kexpr::J2SNode)
		(k (duplicate::J2SUnary this
		      (expr kexpr))))
	     pack kbreaks kcontinues)
	  (k this))))

;*---------------------------------------------------------------------*/
;*    cps ::J2SBinary ...                                              */
;*---------------------------------------------------------------------*/
(define-method (cps this::J2SBinary k pack kbreaks kcontinues)
   (with-access::J2SBinary this (lhs rhs loc)
      (cond
	 ((yield-expr? lhs kbreaks kcontinues)
	  (cps lhs
	     (lambda (klhs::J2SNode)
		(cps (duplicate::J2SBinary this
			 (lhs klhs))
		   k pack kbreaks kcontinues))
	     pack kbreaks kcontinues))
	 ((yield-expr? rhs kbreaks kcontinues)
	  (cps rhs
	     (lambda (krhs::J2SNode)
		(cps (duplicate::J2SBinary this
			 (rhs krhs))
		   k pack kbreaks kcontinues))
	     pack kbreaks kcontinues))
	 (else
	  (k this)))))

;*---------------------------------------------------------------------*/
;*    cps ::J2SYield ...                                               */
;*---------------------------------------------------------------------*/
(define-method (cps this::J2SYield k pack kbreaks kcontinues)
   
   (define (make-yield-kont k loc)
      (let* ((id (gensym '%arg))
	     (exn (gensym '%exn))
	     (cont (J2SIf (J2SBinary '=== (J2SHopRef exn) (J2SBool #t))
		      (J2SThrow (J2SHopRef id))
		      (k (J2SHopRef id)))))
	 (J2SKont id exn (pack cont))))
   
   (with-access::J2SYield this (loc expr generator)
      (if generator
	  (tprint "TODO")
	  (let ((kont (make-yield-kont k loc)))
	     (if (yield-expr? expr kbreaks kcontinues)
		 (cps expr
		    (lambda (kexpr::J2SExpr)
		       (J2SYield kexpr kont))
		    pack kbreaks kcontinues)
		 (J2SYield expr kont))))))

;*---------------------------------------------------------------------*/
;*    cps ::J2SReturn ...                                              */
;*---------------------------------------------------------------------*/
(define-method (cps this::J2SReturn k pack kbreaks kcontinues)
   (with-access::J2SReturn this (loc expr)
      (if (yield-expr? expr kbreaks kcontinues)
	  (cps expr
	     (lambda (kexpr::J2SExpr)
		(J2SStmtExpr (J2SYield kexpr #t)))
	     pack kbreaks kcontinues)
	  (J2SStmtExpr (J2SYield expr #t)))))

;*---------------------------------------------------------------------*/
;*    cps ::%J2STail ...                                               */
;*    -------------------------------------------------------------    */
;*    J2STail are introduced by the CPS conversion of loops.           */
;*---------------------------------------------------------------------*/
(define-method (cps this::%J2STail k pack kbreaks kcontinues)
   (with-access::%J2STail this (loc expr)
      this))

;*---------------------------------------------------------------------*/
;*    cps ::J2SStmtExpr ...                                            */
;*---------------------------------------------------------------------*/
(define-method (cps this::J2SStmtExpr k pack kbreaks kcontinues)
   (with-access::J2SStmtExpr this (loc expr)
      (if (yield-expr? expr kbreaks kcontinues)
	  (J2SStmtExpr
	     (cps expr
		(lambda (ke::J2SExpr)
		   (k (J2SStmtExpr ke)))
		pack kbreaks kcontinues))
	  (k this))))

;*---------------------------------------------------------------------*/
;*    cps ::J2SSeq ...                                                 */
;*---------------------------------------------------------------------*/
(define-method (cps this::J2SSeq k pack kbreaks kcontinues)
   
   (define (pack-seq::J2SSeq this::J2SSeq prev res)
      (if (pair? prev)
	  (set-cdr! prev (list res))
	  (with-access::J2SSeq this (nodes)
	     (set! nodes (list res))))
      this)

   (with-access::J2SSeq this (loc nodes)
      (let loop ((walk nodes)
		 (pnodes '()))
	 (cond
	    ((null? walk)
	     (k this))
	    ((not (yield-expr? (car walk) kbreaks kcontinues))
	     (loop (cdr walk) walk))
	    ((null? (cdr walk))
	     (pack-seq this pnodes
		(cps (car walk)
		   k pack kbreaks kcontinues)))
	    (else
	     (pack-seq this pnodes
		(cps (car walk)
		   (lambda (khead::J2SStmt)
		      (cps (J2SSeq* (cons khead (cdr walk)))
			 k pack kbreaks kcontinues))
		   pack kbreaks kcontinues)))))))

;*---------------------------------------------------------------------*/
;*    cps ::J2SSequence ...                                            */
;*---------------------------------------------------------------------*/
(define-method (cps this::J2SSequence k pack kbreaks kcontinues)
   (with-access::J2SSequence this (loc exprs)
      (let loop ((walk exprs)
		 (pexprs '()))
	 (cond
	    ((null? walk)
	     (k this))
	    ((not (yield-expr? (car walk) kbreaks kcontinues))
	     (loop (cdr walk) walk))
	    (else
	     (let ((head (cps (car walk)
			    (lambda (khead::J2SExpr)
			       (cps (J2SSequence* (cons khead (cdr walk)))
				  k
				  pack kbreaks kcontinues))
			    pack kbreaks kcontinues)))
		(if (pair? pexprs)
		    (begin
		       (set-cdr! pexprs (list head))
		       this)
		    head)))))))

;*---------------------------------------------------------------------*/
;*    cps ::J2SDecl ...                                                */
;*---------------------------------------------------------------------*/
(define-method (cps this::J2SDecl k pack kbreaks kcontinues)
   (k this))

;*---------------------------------------------------------------------*/
;*    cps ::J2SDeclInit ...                                            */
;*---------------------------------------------------------------------*/
(define-method (cps this::J2SDeclInit k pack kbreaks kcontinues)
   (with-access::J2SDeclInit this (val)
      (if (yield-expr? val kbreaks kcontinues)
	 (cps val
	    (lambda (v::J2SExpr)
	       (set! val v)
	       (k this))
	    pack kbreaks kcontinues)
	 (k this))))

;*---------------------------------------------------------------------*/
;*    cps ::J2SLetOpt ...                                              */
;*---------------------------------------------------------------------*/
(define-method (cps this::J2SLetOpt k pack kbreaks kcontinues)
   (with-access::J2SLetOpt this (val)
      (if (yield-expr? val kbreaks kcontinues)
	  (cps val
	     (lambda (v::J2SExpr)
		(set! val v)
		(k this))
	     pack kbreaks kcontinues)
	  (k this))))

;*---------------------------------------------------------------------*/
;*    cps ::J2SVarDecls ...                                            */
;*---------------------------------------------------------------------*/
(define-method (cps this::J2SVarDecls k pack kbreaks kcontinues)
   (with-access::J2SVarDecls this (decls)
      (map! (lambda (decl)
	       (cps decl k pack kbreaks kcontinues))
	 decls)
      (k this)))

;*---------------------------------------------------------------------*/
;*    cps ::j2SLetBlock ...                                            */
;*---------------------------------------------------------------------*/
(define-method (cps this::J2SLetBlock k pack kbreaks kcontinues)
   (with-access::J2SLetBlock this (loc decls nodes)
      (let loop ((wdecls decls)
		 (pdecls '())
		 (sdecls '()))
	 (cond
	    ((null? wdecls)
	     (call-next-method))
	    ((not (yield-expr? (car wdecls) kbreaks kcontinues))
	     (loop (cdr wdecls) wdecls (if (pair? sdecls) sdecls wdecls)))
	    (else
	     (let* ((y (cps (car wdecls)
			  (lambda (ndecl)
			     (cond
				((null? (cdr decls))
				 (set-car! decls ndecl)
				 (call-next-method))
				((null? (cdr wdecls))
				 (let ((block (instantiate::J2SBlock
						 (loc loc)
						 (endloc loc)
						 (nodes nodes))))
				    (J2SLetBlock
				       (list ndecl)
				       (cps block k pack kbreaks kcontinues))))
				(else
				 (set! decls (cdr wdecls))
				 (J2SLetBlock
				    (list ndecl)
				    (cps this k pack kbreaks kcontinues)))))
			  pack kbreaks kcontinues))
		    (b (if (isa? y J2SExpr) (J2SStmtExpr y) y)))
		(if (null? pdecls)
		    (J2SBlock b)
		    (begin
		       (set-cdr! pdecls '())
		       (J2SLetBlock sdecls b)))))))))

;*---------------------------------------------------------------------*/
;*    cps ::J2SIf ...                                                  */
;*---------------------------------------------------------------------*/
(define-method (cps this::J2SIf k pack kbreaks kcontinues)
   
   (define (make-kont-decl loc k)
      (let* ((name (gensym '%kif))
	     (kfun (J2SFun name '()
		      (J2SBlock (k (J2SStmtExpr (J2SUndefined)))))))
	 (J2SLetOpt '(call) name kfun)))
   
   (define (make-kont-fun-call loc decl)
      (J2SCall (J2SRef decl)))
   
   (with-access::J2SIf this (loc test then else)
      (cond
	 ((yield-expr? test kbreaks kcontinues)
	  (cps test
	     (lambda (ktest::J2SNode)
		(cps (duplicate::J2SIf this
			(test ktest))
		   k pack kbreaks kcontinues))
	     pack kbreaks kcontinues))
	 ((or (yield-expr? then kbreaks kcontinues)
	      (yield-expr? else kbreaks kcontinues))
	  (if (eq? k kid)
	      ;; no continuation to the if
	      (duplicate::J2SIf this
		 (then (cps then k pack kbreaks kcontinues))
		 (else (cps else k pack kbreaks kcontinues)))
	      ;; full if
	      (let* ((decl (make-kont-decl loc k))
		     (callt (make-kont-fun-call loc decl))
		     (calle (make-kont-fun-call loc decl))
		     (kthen (J2SBlock then callt))
		     (kelse (if (isa? else J2SNop)
				(with-access::J2SNop else (loc)
				   (J2SStmtExpr calle))
				(J2SBlock else calle)))
		     (kif (duplicate::J2SIf this
			     (then (cps kthen kid pack kbreaks kcontinues))
			     (else (cps kelse kid pack kbreaks kcontinues)))))
		 (J2SLetBlock (list decl) kif))))
	 (else
	  (k this)))))

;*---------------------------------------------------------------------*/
;*    cps ::J2SExprStmt ...                                            */
;*---------------------------------------------------------------------*/
(define-method (cps this::J2SExprStmt k pack kbreaks kcontinues)
   (with-access::J2SExprStmt this (stmt)
      (if (yield-expr? stmt kbreaks kcontinues)
	  (cps stmt
	     (lambda (kstmt::J2SNode)
		(set! stmt kstmt)
		(k this))
	     pack kbreaks kcontinues)
	  (k this))))

;*---------------------------------------------------------------------*/
;*    cps ::J2SFor ...                                                 */
;*---------------------------------------------------------------------*/
(define-method (cps this::J2SFor k pack kbreaks kcontinues)
   (with-access::J2SFor this (loc init test incr body id)
      (cond
	 ((yield-expr? init kbreaks kcontinues)
	  (let ((i init))
	     (set! init (J2SNop))
	     (cps (J2SSeq (J2SStmtExpr i) this) k pack kbreaks kcontinues)))
	 ((let* ((cell (cons this #t))
		 (kbreaks+ (cons cell kbreaks))
		 (kcontinues+ (cons cell kcontinues)))
	     (or (yield-expr? test kbreaks kcontinues)
		 (yield-expr? incr kbreaks kcontinues)
		 (yield-expr? body kbreaks+ kcontinues+)))
	  ;; K( for( ; test; incr ) body )
	  ;;   -->
	  ;;  (letrec ((for (lambda () (K (if test (begin body incr (for)))))))
	  ;;      (for))
	  ;; If break is used
	  ;;   (let ((kfun (function () (K (js-undefined)))))
	  ;;     (letrec ((for (lambda ()
	  ;;                      (kfun (if test (begin body incr (for)))))))
	  ;;        (for)))
	  ;; If continue is used
	  ;;   (let ((kfun (function () (K (js-undefined)))))
	  ;;     (letrec ((for (lambda ()
	  ;;                      (kfun (if test (begin body incr (for)))))))
	  ;;        (for)))
	  ;;
	  (let* ((name (gensym '%kfor))
		 (bname (gensym '%kbreak))
		 (cname (gensym '%kcontinue))
		 (block (J2SBlock))
		 (for (J2SFun name '() block))
		 (decl (J2SLetOpt '(call) name for))
		 (break (J2SFun name '()
			   (J2SBlock (k (J2SStmtExpr (J2SUndefined))))))
		 (conti (J2SFun name '()
			   (cps (J2SBlock
				   (J2SSeq
				      (J2SStmtExpr incr)
				      (%J2STail (J2SCall (J2SRef decl)))))
			      kid
			      pack kbreaks
			      kcontinues)))
		 (bdecl (J2SLetOpt '(call) bname break))
		 (cdecl (J2SLetOpt '(call) cname conti))
		 (then (J2SBlock body (%J2STail (J2SCall (J2SRef cdecl)))))
		 (stop (J2SBlock (%J2STail (J2SCall (J2SRef bdecl)))))
		 (node (J2SIf test then stop)))
	     (with-access::J2SBlock block (nodes)
		(set! nodes
		   (list (cps node kid kid
			    (cons (cons this bdecl) kbreaks)
			    (cons (cons this cdecl) kcontinues)))))
	     (J2SLetBlock (list decl bdecl cdecl)
		init
		(%J2STail (J2SCall (J2SRef decl))))))
	 (else
	  (k this)))))

;*---------------------------------------------------------------------*/
;*    cps ::J2SForIn ...                                               */
;*---------------------------------------------------------------------*/
(define-method (cps this::J2SForIn k pack kbreaks kcontinues)
   (with-access::J2SForIn this (loc lhs obj body)
      (cond
	 ((yield-expr? obj kbreaks kcontinues)
	  (cps obj
	     (lambda (kobj)
		(cps (duplicate::J2SForIn this (obj kobj))
		   k pack kbreaks kcontinues))
	     pack kbreaks kcontinues))
	 ((let* ((cell (cons this #t))
		 (kbreaks+ (cons cell kbreaks))
		 (kcontinues+ (cons cell kcontinues)))
	     (yield-expr? body kbreaks+ kcontinues+))
	  (let* ((v (gensym '%kkeys))
		 (l (gensym '%klen))
		 (i (gensym '%ki))
		 (keys (J2SLetOpt '(ref) v
			  (J2SCall
			     (J2SAccess
				(J2SUnresolvedRef 'Object)
				(J2SString "keys"))
			     obj)))
		 (len (J2SLetOpt '(ref) l
			 (J2SAccess (J2SRef keys) (J2SString "length"))))
		 (idx (J2SDeclInit '(ref write) i (J2SNumber 0)))
		 (for (J2SFor idx
			 (J2SBinary '< (J2SRef idx) (J2SRef len))
			 (J2SPostfix '++ (J2SRef idx) (J2SUndefined))
			 (J2SBlock
			    (J2SStmtExpr
			       (J2SAssig lhs
				  (J2SAccess (J2SRef keys) (J2SRef idx))))
			    body))))
	     (J2SLetBlock (list keys len)
		(cps for k pack kbreaks kcontinues))))
	 (else
	  (k this)))))

;*---------------------------------------------------------------------*/
;*    cps ::J2SWhile ...                                               */
;*---------------------------------------------------------------------*/
(define-method (cps this::J2SWhile k pack kbreaks kcontinues)
   (with-access::J2SWhile this (test body loc)
      (let* ((cell (cons this #t))
	     (kbreaks+ (cons cell kbreaks))
	     (kcontinues+ (cons cell kcontinues)))
	 (if (or (yield-expr? test kbreaks kcontinues)
		 (yield-expr? body kbreaks+ kcontinues+))
	     (let* ((name (gensym '%kwhile))
		    (bname (gensym '%kbreak))
		    (cname (gensym '%kcontinue))
		    (block (J2SBlock))
		    (while (J2SFun name '() block))
		    (decl (J2SLetOpt '(call) name while))
		    (break (J2SFun name '()
			      (J2SBlock (k (J2SStmtExpr (J2SUndefined))))))
		    (conti (J2SFun name '()
			      (cps (J2SBlock
				      (J2SStmtExpr (J2SCall (J2SRef decl))))
				 kid
				 pack kbreaks
				 kcontinues)))
		    (bdecl (J2SLetOpt '(call) bname break))
		    (cdecl (J2SLetOpt '(call) cname conti))
		    (then (J2SBlock body (%J2STail (J2SCall (J2SRef cdecl)))))
		    (else (J2SBlock (%J2STail (J2SCall (J2SRef bdecl)))))
		    (node (J2SIf test then else)))
		(with-access::J2SBlock block (nodes)
		   (set! nodes
		      (list (cps node kid kid
			       (cons (cons this bdecl) kbreaks)
			       (cons (cons this cdecl) kcontinues)))))
		(J2SLetBlock (list decl bdecl cdecl)
		   (J2SStmtExpr (J2SCall (J2SRef decl)))))
	     (k this)))))
      
;*---------------------------------------------------------------------*/
;*    cps ::J2SDo ...                                                  */
;*---------------------------------------------------------------------*/
(define-method (cps this::J2SDo k pack kbreaks kcontinues)
   (with-access::J2SDo this (test body loc)
      (let* ((cell (cons this #t))
	     (kbreaks+ (cons cell kbreaks))
	     (kcontinues+ (cons cell kcontinues)))
	 (if (or (yield-expr? test kbreaks kcontinues)
		 (yield-expr? body kbreaks+ kcontinues+))
	     (let* ((name (gensym '%kdo))
		    (bname (gensym '%kbreak))
		    (cname (gensym '%kcontinue))
		    (tname (gensym '%ktmp))
		    (block (J2SBlock))
		    (while (J2SFun name '() block))
		    (decl (J2SLetOpt '(call) name while))
		    (declv (J2SLetOpt '(ref) tname (J2SBool #t)))
		    (conti (J2SFun name '()
			      (cps (J2SBlock
				      (J2SIf (J2SCond test
						(J2SRef declv)
						(J2SBool #f))
					 (%J2STail (J2SCall (J2SRef decl)))
					 (J2SNop)))
				 k
				 pack kbreaks kcontinues)))
		    (cdecl (J2SLetOpt '(call) cname conti))
		    (break (J2SFun name '()
			      (J2SBlock
				 (J2SStmtExpr
				    (J2SAssig (J2SRef declv) (J2SBool #f)))
				 (%J2STail (J2SCall (J2SRef cdecl))))))
		    (bdecl (J2SLetOpt '(call) bname break))
		    (else (J2SBlock (%J2STail (J2SCall (J2SRef bdecl)))))
		    (body (cps (J2SSeq body (%J2STail (J2SCall (J2SRef cdecl))))
			     kid kid
			     (cons (cons this bdecl) kbreaks)
			     (cons (cons this cdecl) kcontinues))))
		(with-access::J2SBlock block (nodes)
		   (set! nodes (list body)))
		(J2SLetBlock (list decl bdecl cdecl declv)
		   (J2SStmtExpr (J2SCall (J2SRef decl)))))
	     (k this)))))
      
;*---------------------------------------------------------------------*/
;*    cps ::J2SBreak ...                                               */
;*---------------------------------------------------------------------*/
(define-method (cps this::J2SBreak k pack kbreaks kcontinues)
   (with-access::J2SBreak this (loc target)
      (cond
	 ((assq target kbreaks)
	  =>
	  (lambda (c)
	     (let ((kont (cdr c)))
		(J2SCall (J2SRef kont)))))
	 (else
	  (k this)))))

;*---------------------------------------------------------------------*/
;*    cps ::J2SContinue ...                                            */
;*---------------------------------------------------------------------*/
(define-method (cps this::J2SContinue k pack kbreaks kcontinues)
   (with-access::J2SContinue this (loc target)
      (cond
	 ((assq target kcontinues)
	  =>
	  (lambda (c)
	     (let ((kont (cdr c)))
		(J2SCall (J2SRef kont)))))
	 (else
	  (k this)))))

;*---------------------------------------------------------------------*/
;*    cps ::J2SAssig ...                                               */
;*---------------------------------------------------------------------*/
(define-method (cps this::J2SAssig k pack kbreaks kcontinues)
   (with-access::J2SAssig this (lhs rhs)
      (cond
	 ((yield-expr? lhs kbreaks kcontinues)
	  (cps lhs
	     (lambda (klhs::J2SExpr)
		(set! lhs klhs)
		(cps this k pack kbreaks kcontinues))
	     pack kbreaks kcontinues))
	 ((yield-expr? rhs kbreaks kcontinues)
	  (cps rhs
	     (lambda (krhs::J2SExpr)
		(set! rhs krhs)
		(k this))
	     pack kbreaks kcontinues))
	 (else
	  (k this)))))

;*---------------------------------------------------------------------*/
;*    cps ::J2SCall ...                                                */
;*---------------------------------------------------------------------*/
(define-method (cps this::J2SCall k pack kbreaks kcontinues)
   (with-access::J2SCall this (fun args)
      (cond
	 ((yield-expr? fun kbreaks kcontinues)
	  (cps fun
	     (lambda (kfun::J2SNode)
		(set! fun kfun)
		(cps this k pack kbreaks kcontinues))
	     pack kbreaks kcontinues))
	 ((any (lambda (e) (yield-expr? e kbreaks kcontinues)) args)
	  (cps* args
	     (lambda (kargs::pair-nil)
		(set! args kargs)
		(cps this k pack kbreaks kcontinues))
	     pack kbreaks kcontinues))
	 (else
	  (k this)))))

;*---------------------------------------------------------------------*/
;*    cps ::J2SCond ...                                                */
;*---------------------------------------------------------------------*/
(define-method (cps this::J2SCond k pack kbreaks kcontinues)
   
   (define (make-kont-fun k param loc)
      (J2SFun (gensym '%kont) (list param)
	 (J2SBlock (k (J2SRef param)))))
   
   (define (make-kont-fun-call kfun arg loc)
      (J2SCall (J2SRef kfun) arg))
   
   (with-access::J2SCond this (test then else loc)
      (cond
	 ((yield-expr? test kbreaks kcontinues)
	  (cps test
	     (lambda (ktest::J2SExpr)
		(set! test ktest)
		(cps this k pack kbreaks kcontinues))
	     pack kbreaks kcontinues))
	 ((or (yield-expr? then kbreaks kcontinues)
	      (yield-expr? else kbreaks kcontinues))
	  ;; (K (test ? then : else ))
	  ;;    -->
	  ;; (let ((kfun (function (karg) (k karg))))
	  ;;    (test ? kfun(then) : kfun(else)))
	  ;;    ===
	  ;; ((function (kfun) test ? kfun(then) : kfun(else))
	  ;;  (function (karg) (K karg)))
	  (let* ((kfun (J2SParam (gensym '%kfun) '(call)))
		 (karg (J2SParam (gensym '%karg) '(ref)))
		 (kont (make-kont-fun k karg loc))
		 (kthen (cps then
			   (lambda (n) (make-kont-fun-call kfun n loc))
			   pack kbreaks kcontinues))
		 (kelse (cps else
			   (lambda (n) (make-kont-fun-call kfun n loc))
			   pack kbreaks kcontinues))
		 (kcond (duplicate::J2SCond this
			   (then kthen)
			   (else kelse)))
		 (binder (J2SFun (gensym '%fun) (list kfun)
			    (J2SBlock (J2SReturn #t kcond)))))
	     (J2SCall binder kont)))
	 (else
	  (k this)))))

;*---------------------------------------------------------------------*/
;*    cps ::J2STry ...                                                 */
;*---------------------------------------------------------------------*/
(define-method (cps this::J2STry k pack kbreaks kcontinues)
   
   (define (Catch loc param declc)
      (J2SCatch param
	 (J2SBlock
	    (%J2STail
	       (J2SCall (J2SRef declc) (J2SRef param))))))
   
   (define (cps-try-body this k pack kbreaks kcontinues param declc)
      (with-access::J2SSeq this (loc)
	 (J2SBlock
	    (cps this k (lambda (n)
			   (J2STry (J2SBlock (pack n))
			      (Catch loc param declc)))
	       kbreaks kcontinues))))
   
   (with-access::J2STry this (loc body catch finally)
      (cond
	 ((not (or (yield-expr? body kbreaks kcontinues)
		   (yield-expr? catch kbreaks kcontinues)
		   (yield-expr? finally kbreaks kcontinues)))
	  (k this))
	 ((isa? finally J2SNop)
	  (if (isa? catch J2SNop)
	      (cps body k pack kbreaks kcontinues)
	      (let* ((cname (gensym '%kcatch))
		     (catch (with-access::J2SCatch catch (param body)
			       (J2SFun cname (list param)
				  (J2SBlock
				     (cps body
					k pack kbreaks kcontinues)))))
		     (declc (J2SLetOpt '(call) cname catch))
		     (eparam (J2SParam (gensym '%exc) '(ref))))
		 (J2SLetBlock (list declc)
		    (J2STry
		       (cps-try-body body k pack kbreaks kcontinues eparam declc)
		       (Catch loc eparam declc))))))
	 ((isa? catch J2SNop)
	  (let* ((fname (gensym '%kfinally))
		 (paramf (J2SParam (gensym '%excf) '(ref)))
		 (okname (gensym '%kok))
		 (declok (J2SLetOpt '(call ref) okname (J2SPragma ''(0 . 0))))
		 (final (J2SFun fname (list paramf)
			   (J2SBlock
			      (cps (J2SSeq
				      finally
				      (J2SIf (J2SBinary '===
						(J2SRef paramf)
						(J2SRef declok))
					 (J2SNop)
					 (J2SThrow (J2SRef paramf))))
				 k pack kbreaks kcontinues))))
		 (declf (J2SLetOpt '(call ref) fname final))
		 (eparam (J2SParam (gensym '%exc) '(ref))))
	     (J2SLetBlock (list declf declok)
		(J2STry
		   (cps-try-body
		      (J2SSeq
			 body
			 (%J2STail (J2SCall (J2SRef declf) (J2SRef declok))))
		      k pack kbreaks kcontinues eparam declf)
		   (Catch loc eparam declf)))))
	 (else
	  (with-access::J2SCatch catch ((cbody body) param)
	     (let* ((fname (gensym '%kfinally))
		    (paramf (J2SParam (gensym '%excf) '(ref)))
		    (okname (gensym '%kok))
		    (declok (J2SLetOpt '(call ref) okname (J2SPragma ''(1 . 1))))
		    (final (J2SFun fname (list paramf)
			      (J2SBlock 
				 (cps (J2SSeq
					 finally
					 (J2SIf (J2SBinary '===
						   (J2SRef paramf)
						   (J2SRef declok))
					    (J2SNop)
					    (J2SThrow (J2SRef paramf))))
				    k pack kbreaks kcontinues))))
		    (declf (J2SLetOpt '(call ref) fname final))
		    (cname (gensym '%kcatch))
		    (eparam (J2SParam (gensym '%exc) '(ref)))
		    (catch (J2SFun cname (list param)
			      (cps (J2SBlock
				      (J2STry cbody (J2SNop)
					 (%J2STail
					    (J2SCall (J2SRef declf) (J2SRef declok)))))
				 k pack kbreaks kcontinues)))
		    (declc (J2SLetOpt '(call) cname catch)))
		(with-access::J2SParam param (usage)
		   (set! usage (cons 'ref usage)))
		(J2SLetBlock (list declf declc declok)
		   (J2STry
		      (cps-try-body
			 (J2SSeq
			    body
			    (%J2STail (J2SCall (J2SRef declf) (J2SRef declok))))
			 k pack kbreaks kcontinues param declc)
		      (Catch loc eparam declc)))))))))

;*---------------------------------------------------------------------*/
;*    cps ::J2SThrow ...                                               */
;*---------------------------------------------------------------------*/
(define-method (cps this::J2SThrow k pack kbreaks kcontinues)
   (with-access::J2SThrow this (loc expr)
      (if (yield-expr? expr kbreaks kcontinues)
	  (cps expr
	     (lambda (kexpr::J2SExpr)
		(k (J2SThrow kexpr)))
	     pack kbreaks kcontinues)
	  (k this))))

;*---------------------------------------------------------------------*/
;*    cps ::J2SSwitch ...                                              */
;*---------------------------------------------------------------------*/
(define-method (cps this::J2SSwitch k pack kbreaks kcontinues)
   
   (define (switch->if key tmp clause)
      (with-access::J2SCase clause (loc expr body)
	 (if (isa? clause J2SDefault)
	     body
	     (J2SIf (J2SBinary 'OR
		       (J2SRef tmp) (J2SBinary '=== (J2SRef key) expr))
		(J2SSeq
		   (J2SAssig (J2SRef tmp) (J2SBool #t))
		   body)
		(J2SNop)))))
   
   (with-access::J2SSwitch this (loc key cases need-bind-exit-break)
      (cond
	 ((yield-expr? key kbreaks kcontinues)
	  (cps key
	     (lambda (kkey::J2SNode)
		(cps (duplicate::J2SSwitch this (key kkey))
		   k pack kbreaks kcontinues))
	     pack kbreaks kcontinues))
	 ((not (any (lambda (c) (yield-expr? c kbreaks kcontinues)) cases))
	  (k this))
	 (else
	  (let* ((v (gensym '%kkey))
		 (t (gensym '%ktmp))
		 (key (J2SLetOpt '(ref) v key))
		 (tmp (J2SLetOpt '(write ref) t (J2SBool #f)))
		 (seq (J2SSeq*
			 (map (lambda (clause)
				 (switch->if key tmp clause))
			    cases))))
	     (if need-bind-exit-break
		 (let* ((bname (gensym '%kbreak))
			(break (J2SFun bname '()
				  (J2SBlock
				     (J2SBlock
					(k (J2SStmtExpr (J2SUndefined)))))))
			(bdecl (J2SLetOpt '(call) bname break)))
		    (J2SLetBlock (list key tmp bdecl)
		       (cps seq k pack
			  (cons (cons this bdecl) kbreaks)
			  kcontinues)))
		 (J2SLetBlock (list key tmp)
		    (cps seq k pack kbreaks kcontinues))))))))
	 
;*---------------------------------------------------------------------*/
;*    yield-expr? ...                                                  */
;*---------------------------------------------------------------------*/
(define (yield-expr? this kbreaks kcontinues)
   (let ((v (yield-expr* this kbreaks kcontinues)))
      (find (lambda (v) v) v)))

;*---------------------------------------------------------------------*/
;*    yield-expr* ::J2SNode ...                                        */
;*    -------------------------------------------------------------    */
;*    Returns #t iff a statement contains a YIELD. Otherwise           */
;*    returns #f.                                                      */
;*---------------------------------------------------------------------*/
(define-walk-method (yield-expr* this::J2SNode kbreaks kcontinues)
   (call-default-walker))

;*---------------------------------------------------------------------*/
;*    yield-expr* ::J2SYield ...                                       */
;*---------------------------------------------------------------------*/
(define-walk-method (yield-expr* this::J2SYield kbreaks kcontinues)
   (list this))

;*---------------------------------------------------------------------*/
;*    yield-expr* ::J2SReturn ...                                      */
;*---------------------------------------------------------------------*/
(define-walk-method (yield-expr* this::J2SReturn kbreaks kcontinues)
   (list this))

;*---------------------------------------------------------------------*/
;*    yield-expr* ::J2SBreak ...                                       */
;*---------------------------------------------------------------------*/
(define-walk-method (yield-expr* this::J2SBreak kbreaks kcontinues)
   (with-access::J2SBreak this (target)
      (if (assq target kbreaks)
	  (list this)
	  '())))

;*---------------------------------------------------------------------*/
;*    yield-expr* ::J2SContinue ...                                    */
;*---------------------------------------------------------------------*/
(define-walk-method (yield-expr* this::J2SContinue kbreaks kcontinues)
   (with-access::J2SContinue this (target)
      (if (assq target kcontinues)
	  (list this)
	  '())))

;*---------------------------------------------------------------------*/
;*    yield-expr* ::J2SFun ...                                         */
;*---------------------------------------------------------------------*/
(define-walk-method (yield-expr* this::J2SFun kbreaks kcontinues)
   '())

;*---------------------------------------------------------------------*/
;*    yield-expr* ::J2SCase ...                                        */
;*---------------------------------------------------------------------*/
(define-walk-method (yield-expr* this::J2SCase kbreaks kcontinues)
   (with-access::J2SCase this (expr body)
      (append (yield-expr* expr kbreaks kcontinues)
	 (yield-expr* body kbreaks kcontinues))))