;*=====================================================================*/
;*    serrano/prgm/project/hop/2.6.x/js2scheme/parser.scm              */
;*    -------------------------------------------------------------    */
;*    Author      :  Manuel Serrano                                    */
;*    Creation    :  Sun Sep  8 07:38:28 2013                          */
;*    Last change :  Tue Feb 11 17:55:07 2014 (serrano)                */
;*    Copyright   :  2013-14 Manuel Serrano                            */
;*    -------------------------------------------------------------    */
;*    JavaScript parser                                                */
;*=====================================================================*/

;*---------------------------------------------------------------------*/
;*    The module                                                       */
;*---------------------------------------------------------------------*/
(module __js2scheme_parser

   (import __js2scheme_lexer
	   __js2scheme_ast
	   __js2scheme_dump)

   (export (j2s-parser ::input-port #!key start module)))

;*---------------------------------------------------------------------*/
;*    j2s-parser ...                                                   */
;*    -------------------------------------------------------------    */
;*    JavaScript parser                                                */
;*---------------------------------------------------------------------*/
(define (j2s-parser input-port #!key start module)

   (define (current-loc)
      `(at ,(input-port-name input-port) ,(input-port-position input-port)))

   (define (token-loc token)
      (cer token))
      
   (define (parse-token-error msg token::pair)
      (let ((l (read-line input-port)))
	 (match-case (token-loc token)
	    ((at ?fname ?loc)
	     (raise
		(instantiate::&io-parse-error
		   (proc "js-parser")
		   (msg msg)
		   (obj (cdr token))
		   (fname fname)
		   (location loc))))
	    (else
	     (raise
		(instantiate::&io-parse-error
		   (proc "js-parser")
		   (msg msg)
		   (obj (cdr token))))))))

   (define (parse-node-error msg node::J2SNode)
      (with-access::J2SNode node (loc)
	 (let ((l (read-line input-port)))
	    (match-case loc
	       ((at ?fname ?loc)
		(raise
		   (instantiate::&io-parse-error
		      (proc "js-parser")
		      (msg msg)
		      (obj (j2s->list node))
		      (fname fname)
		      (location loc))))
	       (else
		(raise
		   (instantiate::&io-parse-error
		      (proc "js-parser")
		      (msg msg)
		      (obj (j2s->list node)))))))))

   (define (parse-error msg obj)
      (let ((fname (input-port-name input-port))
	    (loc (input-port-position input-port)))
	 (raise
	    (instantiate::&io-parse-error
	       (proc "js-parser")
	       (msg msg)
	       (obj (read-line input-port))
	       (fname fname)
	       (location loc)))))
   
   (define *peeked-tokens* '())
   (define *previous-token-type* #unspecified)
   
   
   (define (read-regexp intro-token)
      (when (eq? intro-token '/=)
	 (unread-char! #\= input-port))
      (let ((token (read/rp (j2s-regex-lexer) input-port)))
	 (case (car token)
	    ((EOF)
	     (parse-token-error "Unfinished regular expression literal" token))
	    ((ERROR)
	     (parse-error "Bad regular-expression literal" token))
	    (else
	     token))))
   
   (define (peek-token)
      (if (null? *peeked-tokens*)
	  (begin
	     (set! *peeked-tokens* (list (read/rp (j2s-lexer) input-port)))
	     (if (eq? (caar *peeked-tokens*) 'NEWLINE)
		 (begin
		    (set! *previous-token-type* 'NEWLINE)
		    (set! *peeked-tokens* (cdr *peeked-tokens*))
		    (peek-token))
		 (car *peeked-tokens*)))
	  (car *peeked-tokens*)))
   
   (define (token-push-back! token)
      (if (at-new-line-token?)
	  (set! *peeked-tokens*
	     (cons* token (econs 'NEWLINE 'NEWLINE (token-loc token))
		*peeked-tokens*))
	  (set! *peeked-tokens*
	     (cons token *peeked-tokens*))))
   
   (define (peek-token-type)
      (car (peek-token)))
   
   (define (at-new-line-token?)
      (eq? *previous-token-type* 'NEWLINE))

   (define (consume-token! type)
      (let ((token (consume-any!)))
	 (if (eq? (car token) type)
	     token
	     (parse-token-error 
		(format "expected \"~a\" got \"~a\"" type
		   (car token))
		token))))
   
   (define (consume! type)
      (cdr (consume-token! type)))
   
   (define (consume-statement-semicolon! where)
      (cond
	 ((eq? (peek-token-type) 'SEMICOLON)
	  (consume-any!))
	 ((eq? (peek-token-type) 'NEWLINE)
	  (consume-any!))
	 ((or (eq? (peek-token-type) 'RBRACE)
	      (at-new-line-token?)
	      (eq? (peek-token-type) 'EOF))
	  (peek-token))
	 (else
	  (parse-token-error (format "~a, \"\;\" or newline expected" where)
	     (peek-token)))))
   
   (define (consume-any!)
      (let ((res (peek-token)))
	 (set! *previous-token-type* (car res))
	 (set! *peeked-tokens* (cdr *peeked-tokens*))
	 ;; (peek-token) ;; prepare new token.
	 res))
   
   (define (eof?)
      (eq? (peek-token-type) 'EOF))
   
   (define (program)
      (when (eq? (peek-token-type) 'MODULE)
	 (let ((token (consume-any!)))
	    (set! module (cdr token))))
      (with-access::J2SBlock (source-elements) (loc nodes)
	 (let ((mode (when (pair? nodes) (javascript-mode-nodes nodes))))
	    (instantiate::J2SProgram
	       (loc loc)
	       (path (input-port-name input-port))
	       (module module)
	       (mode (if (symbol? mode) mode 'normal))
	       (nodes nodes)))))
   
   (define (source-elements::J2SBlock)
      (let loop ((rev-ses '()))
	 (if (eof?)
	     (if (null? rev-ses)
		 (instantiate::J2SBlock
		    (loc `(at ,(input-port-name input-port) 0))
		    (nodes '()))
		 (let ((nodes (reverse! rev-ses)))
		    (with-access::J2SNode (car nodes) (loc)
		       (instantiate::J2SBlock
			  (loc loc)
			  (nodes nodes)))))
	     (loop (cons (source-element) rev-ses)))))
   
   (define (source-element)
      (case (peek-token-type)
	 ((function) (function-declaration))
	 ((service) (service-declaration))
	 ((EOF) (parse-token-error "eof" (consume-any!)))
	 ((ERROR) (parse-token-error "error" (consume-any!)))
	 (else (statement))))

   (define (repl)
      (let ((el (repl-element)))
	 (if (isa? el J2SNode)
	     (with-access::J2SNode el (loc)
		(instantiate::J2SProgram
		   (loc loc)
		   (path (input-port-name input-port))
		   (module #f)
		   (nodes (list el))))
	     el)))
   
   (define (repl-element)
      (case (peek-token-type)
	 ((function) (function-declaration))
	 ((service) (service-declaration))
	 ((EOF) (cdr (consume-any!)))
	 ((ERROR) (parse-token-error "error" (consume-any!)))
	 (else (statement))))
   
   (define (statement)
      (case (peek-token-type)
	 ((LBRACE) (block))
	 ((var) (var-decl-list #f))
	 ((SEMICOLON) (empty-statement))
	 ((if) (iff))
	 ((for while do) (iteration))
	 ((continue) (continue))
	 ((break) (break))
	 ((return) (return))
	 ((with) (with))
	 ((switch) (switch))
	 ((throw) (throw))
	 ((try) (trie))
	 ((ID) (labeled-or-expr))
	 ;; ECMA 262 recommends implementations not to support
	 ;; function declarations in statements. See
	 ;;   http://www.ecma-international.org/ecma-262/5.1/#sec-12
	 ;; However, it looks like main implementation do. For compatibility
	 ;; we mimic this behavior.
	 ((function) (function-declaration))
	 ((debugger) (debugger-statement))
	 (else (expression-statement))))
   
   (define (block)
      (let ((token (consume-token! 'LBRACE)))
	 (let loop ((rev-stats '()))
	    (case (peek-token-type)
	       ((RBRACE)
		(consume-any!)
		(instantiate::J2SBlock
		   (loc (token-loc token))
		   (nodes (reverse! rev-stats))))
	       (else
		(loop (cons (statement) rev-stats)))))))
   
   (define (var-decl-list in-for-init?)
      (let ((token (consume-token! 'var)))
	 (let loop ((rev-vars (list (var in-for-init?))))
	    (case (peek-token-type)
	       ((SEMICOLON)
		(unless in-for-init? (consume-any!))
		(instantiate::J2SVarDecls
		   (loc (token-loc token))
		   (decls (reverse! rev-vars))))
	       ((COMMA)
		(consume-any!)
		(loop (cons (var in-for-init?) rev-vars)))
	       ((in)
		(cond
		   ((not in-for-init?)
		    (parse-token-error "illegal variable declaration"
		       (peek-token)))
		   (else
		    (instantiate::J2SVarDecls
		       (loc (token-loc token))
		       (decls rev-vars)))))
	       (else
		(if (and (not in-for-init?)
			 (or (at-new-line-token?)
			     (eq? (peek-token-type) 'RBRACE)
			     (eq? (peek-token-type) 'EOF)))
		    (instantiate::J2SVarDecls
		       (loc (token-loc token))
		       (decls (reverse! rev-vars)))
		    (parse-token-error "illegal variable declaration"
		       (consume-any!))))))))
   
   (define (var in-for-init?)
      (let ((id (consume-any!)))
	 (case (car id)
	    ((ID)
	     (case (peek-token-type)
		((=)
		 (let* ((token (consume-any!))
			(expr (assig-expr in-for-init?)))
		    (instantiate::J2SDeclInit
		       (loc (token-loc token))
		       (id (cdr id))
		       (val expr))))
		(else
		 (instantiate::J2SDecl
		    (loc (token-loc id))
		    (id (cdr id))))))
	    ((undefined NaN Infinity)
	     (case (peek-token-type)
		((=)
		 (consume-any!)
		 (assig-expr in-for-init?))
		(else
		 (parse-token-error "Illegal variable declaration" id))))
	    (else
	     (parse-token-error "Illegal lhs" id)))))
   
   (define (empty-statement)
      (instantiate::J2SNop
	 (loc (token-loc (consume-token! 'SEMICOLON)))))
   
   (define (iff)
      (let ((tif (consume-any!)))
	 (consume! 'LPAREN)
	 (let ((test (expression #f)))
	    (consume! 'RPAREN)
	    (let ((then (statement)))
	       (case (peek-token-type)
		  ((else)
		   (let* ((tok (consume-any!))
			  (otherwise (statement)))
		      (instantiate::J2SIf
			 (loc (token-loc tif))
			 (test test)
			 (then then)
			 (else otherwise))))
		  (else
		   (instantiate::J2SIf
		      (loc (token-loc tif))
		      (test test)
		      (then then)
		      (else (instantiate::J2SNop
			       (loc (token-loc tif)))))))))))
   
   (define (iteration)
      (case (peek-token-type)
	 ((for) (for))
	 ((while) (while))
	 ((do) (do-while))))
   
   (define (for)
      
      (define (init-first-part)
	 (case (peek-token-type)
	    ((var) (var-decl-list #t))
	    ((SEMICOLON) #f)
	    (else (expression #t))))
      
      (let ((loc (token-loc (consume-token! 'for))))
	 (consume! 'LPAREN)
	 (let ((first-part (init-first-part)))
	    (case (peek-token-type)
	       ((SEMICOLON)
		(for-init/test/incr loc
		   (or first-part (instantiate::J2SNop (loc loc)))))
	       ((in)
		(for-in loc first-part ))))))
   
   ;; for (init; test; incr)
   (define (for-init/test/incr loc init::J2SNode)
      (consume! 'SEMICOLON)
      (let ((test (case (peek-token-type)
		     ((SEMICOLON) #f)
		     (else (expression #f)))))
	 (consume! 'SEMICOLON)
	 (let ((incr (case (peek-token-type)
			((RPAREN) #f)
			(else (expression #f)))))
	    (consume! 'RPAREN)
	    (let* ((body (statement)))
	       (instantiate::J2SFor
		  (loc loc)
		  (init (or init (instantiate::J2SNop (loc loc))))
		  (test (or test (instantiate::J2SBool (val #t) (loc loc))))
		  (incr (or incr (instantiate::J2SUndefined (loc loc))))
		  (body body))))))
   
   ;; for (lhs/var x in obj)
   (define (for-in loc lhs)
      ;; TODO: weed out bad lhs
      (consume! 'in)
      (let ((error-token (peek-token))
	    (obj (expression #f))
	    (ignore-RPAREN (consume! 'RPAREN))
	    (body (statement)))
	 (cond
	    ((isa? lhs J2SVarDecls)
	     (with-access::J2SVarDecls lhs (decls)
		(cond
		   ((null? lhs)
		    (parse-error "Illegal emtpy declaration"
		       error-token))
		   ((not (null? (cdr decls)))
		    (parse-error "Only one declaration allowed"
		       error-token)))))
	    ((not (isa? lhs J2SUnresolvedRef))
	     (parse-error "Variable reference or declaration required"
		error-token)))
	 (instantiate::J2SForIn
	    (loc loc)
	    (lhs lhs)
	    (obj obj)
	    (body body))))
   
   (define (while)
      (let ((token (consume-token! 'while)))
	 (consume! 'LPAREN)
	 (let ((test (expression #f)))
	    (consume! 'RPAREN)
	    (let ((body (statement)))
	       (instantiate::J2SWhile
		  (loc (token-loc token))
		  (test test)
		  (body body))))))
   
   (define (do-while)
      (let* ((loc (token-loc (consume-token! 'do)))
	     (body (statement)))
	 (consume! 'while)
	 (consume! 'LPAREN)
	 (let ((test (expression #f)))
	    (consume! 'RPAREN)
;* 	    (consume-statement-semicolon! "do/while")                  */
	    (instantiate::J2SDo
	       (loc loc)
	       (test test)
	       (body body)))))
   
   (define (continue)
      (let ((loc (token-loc (consume-token! 'continue))))
	 (if (and (eq? (peek-token-type) 'ID)
		  (not (at-new-line-token?)))
	     (let ((id (consume! 'ID)))
		(consume-statement-semicolon! "continue")
		(instantiate::J2SContinue
		   (loc loc)
		   (id id)))
	     (begin
		(consume-statement-semicolon! "continue")
		(instantiate::J2SContinue
		   (loc loc)
		   (id #f))))))
   
   (define (break)
      (let ((loc (token-loc (consume-token! 'break))))
	 (if (and (eq? (peek-token-type) 'ID)
		  (not (at-new-line-token?)))
	     (let ((id (consume! 'ID)))
		(consume-statement-semicolon! "break")
		(instantiate::J2SBreak
		   (loc loc)
		   (id id)))
	     (begin
		(consume-statement-semicolon! "break")
		(instantiate::J2SBreak
		   (loc loc))))))
   
   (define (return)
      (let ((loc (token-loc (consume-token! 'return))))
	 (if (or (case (peek-token-type) ((EOF ERROR SEMICOLON) #t) (else #f))
		 (at-new-line-token?))
	     (begin
		(consume-statement-semicolon! "return")
		(instantiate::J2SReturn
		   (loc loc)
		   (expr (instantiate::J2SUndefined
			    (loc loc)))))
	     (let ((expr (expression #f)))
		(consume-statement-semicolon! "return")
		(instantiate::J2SReturn
		   (loc loc)
		   (expr expr))))))
   
   (define (with)
      (let ((token (consume-token! 'with)))
	 (consume! 'LPAREN)
	 (let ((expr (expression #f)))
	    (consume! 'RPAREN)
	    (let ((body (statement)))
	       (instantiate::J2SWith
		  (loc (token-loc token))
		  (obj expr)
		  (block body))))))
   
   (define (switch)
      (let ((token (consume-token! 'switch)))
	 (consume! 'LPAREN)
	 (let ((key (expression #f)))
	    (consume! 'RPAREN)
	    (let ((cases (case-block)))
	       (instantiate::J2SSwitch
		  (loc (token-loc token))
		  (key key)
		  (cases cases))))))
   
   (define (case-block)
      (consume! 'LBRACE)
      (let loop ((rev-cases '())
		 (default-case-done? #f))
	 (case (peek-token-type)
	    ((RBRACE) (consume-any!)
	     (reverse! rev-cases))
	    ((case) (loop (cons (case-clause) rev-cases)
		       default-case-done?))
	    ((default) (if default-case-done?
			   (error "Only one default-clause allowed"
			      (peek-token)
			      (peek-token))
			   (loop (cons (default-clause) rev-cases)
			      #t))))))
   
   (define (case-clause)
      (let ((token (consume-token! 'case)))
	 (let ((expr (expression #f)))
	    (consume! ':)
	    (let ((body (switch-clause-statements)))
	       (instantiate::J2SCase
		  (loc (token-loc token))
		  (expr expr)
		  (body body))))))
   
   (define (default-clause)
      (let ((token (consume-token! 'default)))
	 (consume! ':)
	 (instantiate::J2SDefault
	    (loc (token-loc token))
	    (expr (class-nil J2SExpr))
	    (body (switch-clause-statements)))))
   
   (define (switch-clause-statements)
      (let loop ((rev-stats '()))
	 (case (peek-token-type)
	    ((RBRACE EOF ERROR default case)
	     (instantiate::J2SBlock
		(loc (token-loc (peek-token)))
		(nodes (reverse! rev-stats))))
	    (else
	     (loop (cons (statement) rev-stats))))))
   
   (define (throw)
      (let ((token (consume-token! 'throw)))
	 (when (or (at-new-line-token?) (eq? (peek-token-type) 'NEWLINE))
	    (parse-token-error "throw must have a value" (peek-token)))
	 (peek-token)
	 (when (or (at-new-line-token?) (eq? (peek-token-type) 'NEWLINE))
	    (parse-token-error "throw must have a value" (peek-token)))
	 (let ((expr (expression #f)))
	    (consume-statement-semicolon! "throw")
	    (instantiate::J2SThrow
	       (loc (token-loc token))
	       (expr expr)))))
   
   (define (trie)
      (let ((loc (token-loc (consume-token! 'try))))
	 (let ((body (block)))
	    (let ((catch-part #f)
		  (finally-part #f))
	       (when (eq? (peek-token-type) 'catch)
		  (set! catch-part (catch)))
	       (when (eq? (peek-token-type) 'finally)
		  (set! finally-part (finally)))
	       (instantiate::J2STry
		  (loc loc)
		  (body body)
		  (catch (or catch-part
			     (instantiate::J2SNop (loc loc))))
		  (finally (or finally-part
			       (instantiate::J2SNop (loc loc)))))))))
   
   (define (catch)
      (let ((loc (token-loc (consume-token! 'catch))))
	 (consume! 'LPAREN)
	 (let ((id (consume! 'ID)))
	    (consume! 'RPAREN)
	    (let ((body (block)))
	       ;; not sure, if 'Param' is a really good choice.
	       ;; we'll see...
	       (instantiate::J2SCatch
		  (loc loc)
		  (param (instantiate::J2SParam
			    (loc loc)
			    (id id)))
		  (body body))))))
   
   (define (finally)
      (consume! 'finally)
      (block))
   
   (define (labeled-or-expr)
      (let* ((id-token (consume-token! 'ID))
	     (next-token-type (peek-token-type)))
	 (if (eq? next-token-type  ':)
	     (begin
		(consume-any!)
		(instantiate::J2SLabel
		   (loc (token-loc id-token))
		   (id (cdr id-token))
		   (body (statement))))
	     (begin
		(token-push-back! id-token)
		(expression-statement)))))

   (define (debugger-statement)
      (let ((token (consume-token! 'debugger)))
	 (instantiate::J2SNop
	    (loc (token-loc token)))))
   
   (define (expression-statement)
      (let ((expr (expression #f)))
	 (consume-statement-semicolon! "expression")
	 (with-access::J2SExpr expr (loc)
	    (instantiate::J2SStmtExpr
	       (loc loc)
	       (expr expr)))))
   
   (define (function-declaration)
      (function #t))
   
   (define (function-expression)
      (function #f))
   
   (define (service-declaration)
      (service #t))
   
   (define (service-expression)
      (service #f))
   
   (define (function declaration?)
      (let* ((token (consume-token! 'function))
	     (id (when (or declaration? (eq? (peek-token-type) 'ID))
		    (consume-token! 'ID)))
	     (params (params))
	     (body (fun-body)))
	 (cond
	    (declaration?
	     (instantiate::J2SDeclFun
		(loc (token-loc token))
		(id (cdr id))
		(val (instantiate::J2SFun
			(id (cdr id))
			(loc (token-loc token))
			(params params)
			(mode (or (javascript-mode body) 'normal))
			(body body)))))
	    (id
	     (instantiate::J2SFun
		(loc (token-loc id))
		(id (cdr id))
		(params params)
		(mode (or (javascript-mode body) 'normal))
		(body body)))
	    (else
	     (instantiate::J2SFun
		(loc (token-loc token))
		(params params)
		(mode (or (javascript-mode body) 'normal))
		(body body))))))

   (define (init->params init)
      (if (isa? init J2SPropertyInit)
	  (with-access::J2SPropertyInit init (loc name)
	     (if (isa? name J2SString)
		 (with-access::J2SString name (val)
		    (instantiate::J2SParam
		       (loc loc)
		       (id (string->symbol val))))
		 (parse-node-error "Illegal parameter declaration" init)))
	  (parse-node-error "Illegal parameter declaration" init)))

   (define (service declaration?)
      (let* ((token (consume-token! 'service))
	     (id (when (or declaration? (eq? (peek-token-type) 'ID))
		    (consume-token! 'ID)))
	     (inits (service-params))
	     (params (if (isa? inits J2SObjInit)
			 (with-access::J2SObjInit inits (inits)
			    (map init->params inits))
			 inits))
	     (init (if (isa? inits J2SObjInit)
		       inits
		       (instantiate::J2SNop
			  (loc (token-loc token)))))
	     (body (fun-body)))
	 (cond
	    (declaration?
	     (instantiate::J2SDeclSvc
		(loc (token-loc token))
		(id (cdr id))
		(val (instantiate::J2SSvc
			(id (cdr id))
			(loc (token-loc token))
			(params params)
			(init init)
			(body body)))))
	    (id
	     (instantiate::J2SSvc
		(loc (token-loc id))
		(id (cdr id))
		(params params)
		(init init)
		(body body)))
	    (else
	     (instantiate::J2SSvc
		(loc (token-loc token))
		(params params)
		(init init)
		(body body))))))

   (define (consume-param!)
      (let ((token (consume-token! 'ID)))
	 (instantiate::J2SParam
	    (loc (token-loc token))
	    (id (cdr token)))))
      
   (define (params)
      (consume! 'LPAREN)
      (if (eq? (peek-token-type) 'RPAREN)
	  (begin
	     (consume-any!)
	     '())
	  (let loop ((rev-params (list (consume-param!))))
	     (if (eq? (peek-token-type) 'COMMA)
		 (begin
		    (consume-any!)
		    (loop (cons (consume-param!) rev-params)))
		 (begin
		    (consume! 'RPAREN)
		    (reverse! rev-params))))))

   (define (service-params)
      (consume! 'LPAREN)
      (case (peek-token-type)
	 ((RPAREN)
	  (consume-any!)
	  '())
	 ((LBRACE)
	  (let ((o (object-literal)))
	     (consume! 'RPAREN)
	     o))
	 (else
	  (let loop ((rev-params (list (consume-param!))))
	     (if (eq? (peek-token-type) 'COMMA)
		 (begin
		    (consume-any!)
		    (loop (cons (consume-param!) rev-params)))
		 (begin
		    (consume! 'RPAREN)
		    (reverse! rev-params)))))))
   
   (define (fun-body)
      (let ((token (consume-token! 'LBRACE)))
	 (let ((loc (current-loc)))
	    (let loop ((rev-ses '()))
	       (if (eq? (peek-token-type) 'RBRACE)
		   (begin
		      (consume-any!)
		      (instantiate::J2SBlock
			 (loc (token-loc token))
			 (nodes (reverse! rev-ses))))
		   (loop (cons (source-element) rev-ses)))))))
   
   (define (expression::J2SExpr in-for-init?)
      (let ((assig (assig-expr in-for-init?)))
	 (let loop ((rev-exprs (list assig)))
	    (if (eq? (peek-token-type) 'COMMA)
		(begin
		   (consume-any!)
		   (loop (cons (assig-expr in-for-init?) rev-exprs)))
		(if (null? (cdr rev-exprs))
		    (car rev-exprs)
		    (let ((exprs (reverse! rev-exprs)))
		       (with-access::J2SNode (car exprs) (loc)
			  (instantiate::J2SSequence
			     (loc loc)
			     (exprs exprs)))))))))
   
   (define (assig-operator? x)
      (case x
	 ((= *= /= %= += -= <<= >>= >>>= &= ^= BIT_OR=)
	  #t)
	 (else #f)))
   
   (define (assig-expr in-for-init?)
      
      (define (with-out-= op=)
	 (let* ((s= (symbol->string op=))
		(s=-length (string-length s=))
		(s (substring s= 0 (- s=-length 1)))
		(op (string->symbol s)))
	    op))
      
      (let ((expr (cond-expr in-for-init?)))
	 (if (assig-operator? (peek-token-type))
	     (let* ((op (consume-any!))
		    (rhs (assig-expr in-for-init?)))
		(cond
		   ((and (eq? op '=) (isa? expr J2SRef))
		    (instantiate::J2SAssig
		       (loc (token-loc op))
		       (lhs expr)
		       (rhs rhs)))
		   ((and (eq? op '=) (isa? expr J2SAccess))
		    `(instantiate::J2SAssig
		       (lhs ,expr)
		       (rhs ,rhs)))
		   ((eq? (car op) '=)
		    (instantiate::J2SAssig
		       (loc (token-loc op))
		       (lhs expr)
		       (rhs rhs)))
;* 		   ((isa? expr J2SAccess)                               */
;* 		    `(instantiate::J2SAccsig-op                         */
;* 		       (lhs ,expr)                                     */
;* 		       (op ,(with-out-= op))                           */
;* 		       (rhs ,rhs)))                                    */
		   (else
		    (instantiate::J2SAssigOp
		       (loc (token-loc op))
		       (lhs expr)
		       (op (with-out-= (car op)))
		       (rhs rhs)))))
	     expr)))
   
   (define (cond-expr in-for-init?)
      (let ((expr (binary-expr in-for-init?))
	    (token (peek-token)))
	 (if (eq? (car token) '?)
	     (let* ((ignore-? (consume-any!))
		    (then (assig-expr #f))
		    (ignore-colon (consume! ':))
		    (else (assig-expr in-for-init?)))
		(instantiate::J2SCond
		   (loc (token-loc token))
		   (test expr)
		   (then then)
		   (else else)))
	     expr)))
   
   (define (op-level op)
      (case op
	 ((OR) 1)
	 ((&&) 2)
	 ((BIT_OR) 3)
	 ((^) 4)
	 ((&) 5)
	 ((== != === !==) 6)
	 ((< > <= >= instanceof in) 7)
	 ((<< >> >>>) 8)
	 ((+ -) 9)
	 ((* / %) 10)
	 (else #f)))
   
   ;; left-associative binary expressions
   (define (binary-expr in-for-init?)
      (define (binary-aux level)
	 (if (> level 10)
	     (unary)
	     (let loop ((expr (binary-aux (+fx level 1))))
		(let* ((type (peek-token-type))
		       (new-level (op-level type)))
		   (cond
		      ((and in-for-init? (eq? type 'in))
		       expr)
		      ((not new-level)
		       expr)
		      ((=fx new-level level)
		       (let ((token (consume-any!)))
			  (loop (instantiate::J2SBinary
				   (loc (token-loc token))
				   (lhs expr)
				   (op (car token))
				   (rhs (binary-aux (+fx level 1)))))))
		      (else
		       expr))))))
      (binary-aux 1))
   
   (define (unary)
      (case (peek-token-type)
	 ((++ --)
	  (let* ((token (consume-any!))
		 (expr (unary)))
	     (if (or (isa? expr J2SUnresolvedRef) (isa? expr J2SAccess))
		 (instantiate::J2SPrefix
		       (loc (token-loc token))
		       (rhs (class-nil J2SExpr))
		       (lhs expr)
		       (op (car token)))
		 (parse-token-error
		    "Invalid left-hand side expression in prefix operation"
		    token))))
	 ((delete)
	  (let ((token (consume-any!))
		(expr (unary)))
	     (cond
		((or (isa? expr J2SAccess) (isa? expr J2SUnresolvedRef))
		 (instantiate::J2SUnary
		    (op (car token))
		    (loc (token-loc token))
		    (expr expr)))
		(else
		 (instantiate::J2SUnary
		    (op (car token))
		    (loc (token-loc token))
		    (expr expr))))))
	 ((void typeof ~ ! + -)
	  (let ((token (consume-any!)))
	     (instantiate::J2SUnary
		(loc (token-loc token))
		(op (car token))
		(expr (unary)))))
	 (else
	  (postfix (token-loc (peek-token))))))
   
   (define (postfix loc)
      (let ((expr (lhs loc)))
	 (if (not (at-new-line-token?))
	     (case (peek-token-type)
		((++ --)
		 (let ((token (consume-any!)))
		    (if (or (isa? expr J2SUnresolvedRef) (isa? expr J2SAccess))
			(instantiate::J2SPostfix
			   (loc (token-loc token))
			   (rhs (class-nil J2SExpr))
			   (lhs expr)
			   (op (car token)))
			(parse-token-error
			   "Invalid left-hand side expression in prefix operation"
			   token))))
		(else
		 expr))
	     expr)))
   
   ;; we start by getting all news (new-expr)
   ;; the remaining access and calls are then caught by the access-or-call
   ;; invocation allowing call-parenthesis.
   ;;
   ;; the access-or-call in new-expr does not all any parenthesis to be
   ;; consumed as they would be part of the new-expr.
   (define (lhs loc)
      (access-or-call (new-expr loc) loc #t))
   
   (define (new-expr loc)
      (if (eq? (peek-token-type) 'new)
	  (let* ((ignore (consume-any!))
		 (clazz (new-expr (token-loc ignore)))
		 (args (if (eq? (peek-token-type) 'LPAREN)
			   (arguments)
			   '())))
	     (instantiate::J2SNew
		(loc (token-loc ignore))
		(clazz clazz)
		(args args)))
	  (access-or-call (primary) loc #f)))
   
   (define (access-or-call expr loc call-allowed?)
      (let loop ((expr expr))
	 (case (peek-token-type)
	    ((LBRACKET)
	     (let* ((ignore (consume-any!))
		    (field (expression #f))
		    (ignore-too (consume! 'RBRACKET)))
		(loop (instantiate::J2SAccess
			 (loc loc)
			 (obj expr)
			 (field field)))))
	    ((NEWLINE)
	     (consume-any!)
	     (loop expr))
	    ((DOT)
	     (let* ((ignore (consume-any!))
		    (field (consume-any!))
		    (key (car field))
		    (field-str (format "~a" (cdr field))))
		(if (or (eq? key 'ID)
			(eq? key 'RESERVED)
			(j2s-reserved-id? key))
		    (loop (instantiate::J2SAccess
			     (loc loc)
			     (obj expr)
			     (field (instantiate::J2SString
				       (loc (token-loc field))
				       (val field-str)))))
		    (parse-token-error "Wrong property name" field))))
	    ((LPAREN)
	     (if call-allowed?
		 (loop (instantiate::J2SCall
			  (loc loc)
			  (fun expr)
			  (args (arguments))))
		 expr))
	    (else
	     expr))))
   
   (define (arguments)
      (consume! 'LPAREN)
      (if (eq? (peek-token-type) 'RPAREN)
	  (begin
	     (consume-any!)
	     '())
	  (let loop ((rev-args (list (assig-expr #f))))
	     (if (eq? (peek-token-type) 'RPAREN)
		 (begin
		    (consume-any!)
		    (reverse! rev-args))
		 (let* ((ignore (consume! 'COMMA))
			(arg (assig-expr #f)))
		    (loop (cons arg rev-args)))))))

   (define (tag-expression tag)

      (define (tag-body token attrs)
	 (let loop ((exprs '()))
	    (let ((expr (assig-expr #f)))
	       (let liip ((sep (consume-any!)))
		  (case (car sep)
		     ((COMMA)
		      (loop (cons expr exprs)))
		     ((NEWLINE)
		      (liip (consume-any!)))
		     ((RBRACE)
		      (let ((ctag (peek-token)))
			 (if (or (not (eq? (car ctag) 'CTAG))
				 (eq? (cdr ctag) (cdr tag)))
			     (begin
				(when (eq? (car ctag) 'CTAG) (consume-any!))
				(instantiate::J2SXml
				   (loc (token-loc tag))
				   (tag (cdr tag))
				   (attrs attrs)
				   (body (instantiate::J2SSequence
					    (loc (token-loc token))
					    (exprs (reverse! (cons expr exprs)))))))
			     (parse-token-error
				(format "Tag \"~a\" found, \"~a\" expected"
				   (cdr tag) (cdr ctag))
				ctag))))
		     (else
		      (parse-token-error
			 (format "Illegal tag \"~a\": \",\" or \"}\" expected"
			    (cdr tag))
			 sep)))))))

      (let ((token (consume-token! 'LBRACE)))
	 (if (eq? (peek-token-type) 'RBRACE)
	     (let* ((token (consume-any!))
		    (loc (token-loc token)))
		(instantiate::J2SXml
		   (loc loc)
		   (tag (cdr tag))
		   (body (instantiate::J2SBool (loc loc) (val #f)))))
	     (let loop ((inits '()))
		(case (peek-token-type)
		   ((ID STRING)
		    (let ((token (consume-any!)))
		       (if (eq? (peek-token-type) ':)
			   ;; an init
			   (begin
			      (consume-any!)
			      (let* ((name (instantiate::J2SString
					      (loc (token-loc token))
					      (val (if (eq? (car token) 'STRING)
						       (cdr token)
						       (symbol->string (cdr token))))))
				     (init (instantiate::J2SDataPropertyInit
					      (loc (token-loc token))
					      (name name)
					      (val (assig-expr #f))))
				     (sep (consume-any!)))
				 (case (car sep)
				    ((COMMA)
				     (loop (cons init inits)))
				    ((RBRACE)
				     (instantiate::J2SXml
					(loc (token-loc tag))
					(tag (cdr tag))
					(attrs (reverse! (cons init inits)))
					(body (instantiate::J2SBool
						 (loc (token-loc tag))
						 (val #f)))))
				    (else
				     (parse-token-error
					(format "Illegal tag \"~a\"" (car tag))
					sep)))))
			   ;; the body
			   (begin
			      (token-push-back! token)
			      (tag-body token (reverse! inits))))))
		   (else
		    (tag-body token (reverse! inits))))))))

   (define (tilde token)
      (let loop ((rev-stats '()))
	 (case (peek-token-type)
	    ((RBRACE)
	     (consume-any!)
	     (instantiate::J2SBlock
		(loc (token-loc token))
		(nodes (reverse! rev-stats))))
	    (else
	     (loop (cons (statement) rev-stats))))))
   
   (define (primary)
      (case (peek-token-type)
	 ((PRAGMA)
	  (jspragma))
	 ((function)
	  (function-expression))
	 ((service)
	  (service-expression))
	 ((this)
	  (instantiate::J2SThis
	     (loc (token-loc (consume-any!)))))
	 ((ID RESERVED)
	  (let ((token (consume-any!)))
	     (instantiate::J2SUnresolvedRef
		(loc (token-loc token))
		(id (cdr token)))))
	 ((HOP)
	  (let ((token (consume-token! 'HOP)))
	     (instantiate::J2SHopRef
		(loc (token-loc token))
		(id (cdr token)))))
	 ((LPAREN)
	  (let ((ignore (consume-any!))
		(expr (expression #f))
		(ignore-too (consume! 'RPAREN)))
	     expr))
	 ((LBRACKET)
	  (array-literal))
	 ((LBRACE)
	  (object-literal))
	 ((NaN)
	  (let ((token (consume-any!)))
	     (instantiate::J2SNumber
		(loc (token-loc token))
		(val +nan.0))))
	 ((Infinity)
	  (let ((token (consume-any!)))
	     (instantiate::J2SNumber
		(loc (token-loc token))
		(val +inf.0))))
	 ((null)
	  (let ((token (consume-any!)))
	     (instantiate::J2SNull
		(loc (token-loc token)))))
	 ((undefined)
	  (let ((token (consume-token! 'undefined)))
	     (instantiate::J2SUndefined
		(loc (token-loc token)))))
	 ((true false)
	  (let ((token (consume-any!)))
	     (instantiate::J2SBool
		(loc (token-loc token))
		(val (eq? (car token) 'true)))))
	 ((NUMBER)
	  (let ((token (consume-token! 'NUMBER)))
	     (instantiate::J2SNumber
		(loc (token-loc token))
		(val (cdr token)))))
	 ((OCTALNUMBER)
	  (let ((token (consume-token! 'OCTALNUMBER)))
	     (instantiate::J2SOctalNumber
		(loc (token-loc token))
		(val (cdr token)))))
	 ((STRING)
	  (let ((token (consume-token! 'STRING)))
	     (instantiate::J2SString
		(escape '())
		(loc (token-loc token))
		(val (cdr token)))))
	 ((ESTRING)
	  (let ((token (consume-token! 'ESTRING)))
	     (instantiate::J2SString
		(escape '(escape))
		(loc (token-loc token))
		(val (cdr token)))))
	 ((OSTRING)
	  (let ((token (consume-token! 'OSTRING)))
	     (instantiate::J2SString
		(escape '(escape octal))
		(loc (token-loc token))
		(val (cdr token)))))
	 ((EOF)
	  (parse-token-error "unexpected end of file" (peek-token)))
	 ((/ /=)
	  (let ((pattern (read-regexp (peek-token-type))))
	     ;; consume-any *must* be after having read the reg-exp,
	     ;; so that the read-regexp works. Only then can we remove
	     ;; the peeked token.
	     (let ((token (consume-any!)))
		(instantiate::J2SRegExp
		   (loc (token-loc token))
		   (val (car (cdr pattern)))
		   (flags (cdr (cdr pattern)))))))
	 ((OTAG)
	  (tag-expression (consume-any!)))
	 ((TILDE)
	  (let ((token (consume-any!)))
	     (instantiate::J2STilde
		(loc (token-loc token))
		(stmt (tilde token)))))
	 ((DOLLAR)
	  (let ((ignore (consume-any!))
		(expr (expression #f))
		(ignore-too (consume! 'RBRACE)))
	     (instantiate::J2SDollar
		(loc (token-loc ignore))
		(expr expr))))
	 ((NaN)
	  (let ((token (consume-token! 'NaN)))
	     (instantiate::J2SNumber
		(loc (token-loc token))
		(val +nan.0))))
	 (else
	  (parse-token-error "unexpected token" (peek-token)))))
   
   (define (jspragma)
      (error "jspragma" "Not implemented" #f))
   
   (define (array-literal)
      (let ((token (consume-token! 'LBRACKET)))
	 (let loop ((rev-els '())
		    (length 0))
	    (case (peek-token-type)
	       ((RBRACKET)
		(consume-any!)
		(instantiate::J2SArray
		   (loc (token-loc token))
		   (exprs (reverse! rev-els))
		   (len length)))
	       ((COMMA)
		(let ((token (consume-any!)))
		   (loop (cons (instantiate::J2SArrayAbsent
				  (loc (token-loc token)))
			    rev-els)
		      (+fx length 1))))
	       (else
		(let ((array-el (assig-expr #f)))
		   (if (eq? (peek-token-type) 'COMMA)
		       (begin
			  (consume-any!)
			  (loop (cons array-el rev-els)
			     (+fx length 1)))
		       (begin
			  (consume! 'RBRACKET)
			  (instantiate::J2SArray
			     (loc (token-loc token))
			     (exprs (reverse! (cons array-el rev-els)))
			     (len (+fx length 1)))))))))))
   
   (define (object-literal)
      
      (define (property-name)
	 (case (peek-token-type)
	    ;; IDs are automatically transformed to strings.
	    ((ID RESERVED)
	     (let ((token (consume-any!)))
		(case (cdr token)
		   ((get set)
		    token)
		   (else
		    (instantiate::J2SString
		       (loc (token-loc token))
		       (val (symbol->string (cdr token))))))))
	    ((STRING)
	     (let ((token (consume-token! 'STRING)))
		(instantiate::J2SString
		   (escape '())
		   (loc (token-loc token))
		   (val (cdr token)))))
	    ((ESTRING)
	     (let ((token (consume-token! 'ESTRING)))
		(instantiate::J2SString
		   (escape '(escape))
		   (loc (token-loc token))
		   (val (cdr token)))))
	    ((OSTRING)
	     (let ((token (consume-token! 'OSTRING)))
		(instantiate::J2SString
		   (escape '(escape octal))
		   (loc (token-loc token))
		   (val (cdr token)))))
	    ((NUMBER)
	     (let ((token (consume-token! 'NUMBER)))
		(instantiate::J2SNumber
		   (loc (token-loc token))
		   (val (cdr token)))))
	    ((OCTALNUMBER)
	     (let ((token (consume-token! 'OCTALNUMBER)))
		(instantiate::J2SOctalNumber
		   (loc (token-loc token))
		   (val (cdr token)))))
	    ((true false null)
	     (let ((token (consume-any!)))
		(instantiate::J2SString
		   (loc (token-loc token))
		   (val (symbol->string (cdr token))))))
	    (else
	     (if (j2s-reserved-id? (peek-token-type))
		 (let ((token (consume-any!)))
		    (case (cdr token)
		       ((get set)
			token)
		       (else
			(instantiate::J2SString
			   (loc (token-loc token))
			   (val (symbol->string (cdr token)))))))
		 (parse-token-error "Wrong property name" (peek-token))))))

      (define (property-accessor tokname name)
	 (let* ((id (consume-any!))
		(params (params))
		(body (fun-body))
		(fun (instantiate::J2SFun
			(mode (or (javascript-mode body) 'normal))
			(loc (token-loc tokname))
			(params params)
			(body body)))
		(prop (instantiate::J2SAccessorPropertyInit
			 (loc (token-loc tokname))
			 (name (instantiate::J2SString
				  (loc (token-loc id))
				  (val (symbol->string (cdr id))))))))
	    (with-access::J2SAccessorPropertyInit prop (get set)
	       (if (eq? name 'get)
		   (begin
		      (set! get fun)
		      (set! set (instantiate::J2SUndefined
				   (loc (token-loc id)))))
		   (begin
		      (set! set fun)
		      (set! get (instantiate::J2SUndefined
				   (loc (token-loc id))))))
	       prop)))
      
      (define (property-init)
	 (let* ((tokname (property-name))
		(name (when (pair? tokname) (cdr tokname))))
	    (case name
	       ((get set)
		(case (peek-token-type)
		   ((ID RESERVED)
		    (property-accessor tokname name))
		   ((:)
		    (let* ((ignore (consume-any!))
			   (val (assig-expr #f)))
		       (with-access::J2SLiteral ignore (loc)
			  (instantiate::J2SDataPropertyInit
			     (loc (token-loc tokname))
			     (name (instantiate::J2SString
				      (loc (token-loc tokname))
				      (val (symbol->string name))))
			     (val val)))))
		   (else
		    (if (j2s-reserved-id? (peek-token-type))
			(property-accessor tokname name)
			(parse-token-error "Wrong property name" (peek-token))))))
	       (else
		(let* ((ignore (consume! ':))
		       (val (assig-expr #f)))
		   (with-access::J2SLiteral tokname (loc)
		      (instantiate::J2SDataPropertyInit
			 (loc loc)
			 (name tokname)
			 (val val))))))))
      
      (consume! 'LBRACE)
      (if (eq? (peek-token-type) 'RBRACE)
	  (let ((token (consume-any!)))
	     (instantiate::J2SObjInit
		(loc (token-loc token))
		(inits '())))
	  (let loop ((rev-props (list (property-init))))
	     (if (eq? (peek-token-type) 'RBRACE)
		 (let ((token (consume-any!)))
		    (instantiate::J2SObjInit
		       (loc (token-loc token))
		       (inits (reverse! rev-props))))
		 (begin
		    (consume! 'COMMA)
		    ;; MS: I'm not sure this is demanded by the official
		    ;; JS syntax tome test case uses it
		    ;; (15.2.3.6-4-293-3.js)
		    (if (eq? (peek-token-type) 'RBRACE)
			(loop rev-props)
			(loop (cons (property-init) rev-props))))))))
   
   ;; procedure entry point.
   ;; ----------------------
   (case start
      ((program) (program))
      ((repl) (repl))
      (else (program))))

;*---------------------------------------------------------------------*/
;*    javascript-mode-nodes ...                                        */
;*---------------------------------------------------------------------*/
(define (javascript-mode-nodes nnodes::pair-nil)
   
   (define (octal-error s)
      (with-access::J2SString s (val loc)
	 (raise
	    (instantiate::&io-parse-error
	       (proc "js-symbol")
	       (msg "Octal literals are not allowed in strict mode")
	       (obj val)
	       (fname (cadr loc))
	       (location (caddr loc))))))

   (define (check-octal-string n)
      (cond
	 ((isa? n J2SStmtExpr)
	  (with-access::J2SStmtExpr n (expr)
	     (check-octal-string expr)))
	 ((isa? n J2SString)
	  (with-access::J2SString n (escape loc)
	     (when (memq 'octal escape)
		(octal-error n))))
	 (else
	  #f)))
   
   (let loop ((nodes nnodes))
      (when (pair? nodes)
	 (let ((mode (javascript-mode (car nodes))))
	    (cond
	       ((symbol? mode)
		(when (eq? mode 'strict)
		   (for-each check-octal-string nnodes))
		mode)
	       (mode
		(loop (cdr nodes))))))))

;*---------------------------------------------------------------------*/
;*    javascript-mode ...                                              */
;*---------------------------------------------------------------------*/
(define-generic (javascript-mode node::J2SNode)
   #f)

;*---------------------------------------------------------------------*/
;*    javascript-mode ::J2SBlock ...                                   */
;*---------------------------------------------------------------------*/
(define-method (javascript-mode node::J2SBlock)
   (with-access::J2SBlock node (nodes)
      (javascript-mode-nodes nodes)))

;*---------------------------------------------------------------------*/
;*    javascript-mode ::J2SStmtExpr ...                                */
;*---------------------------------------------------------------------*/
(define-method (javascript-mode node::J2SStmtExpr)
   (with-access::J2SStmtExpr node (expr)
      (when (isa? expr J2SString)
	 (with-access::J2SString expr (val escape)
	    (cond
	       ((pair? escape) (memq 'octal escape))
	       ((string=? val "use strict") 'strict)
	       ((string=? val "use hopscript") 'hopscript)
	       (else #t))))))
   