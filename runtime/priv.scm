;*=====================================================================*/
;*    serrano/prgm/project/hop/2.0.x/runtime/priv.scm                  */
;*    -------------------------------------------------------------    */
;*    Author      :  Manuel Serrano                                    */
;*    Creation    :  Fri Jun 19 14:41:13 2009                          */
;*    Last change :  Sat Jun 20 05:37:52 2009 (serrano)                */
;*    Copyright   :  2009 Manuel Serrano                               */
;*    -------------------------------------------------------------    */
;*    Private tools functions                                          */
;*=====================================================================*/

;*---------------------------------------------------------------------*/
;*    The module                                                       */
;*---------------------------------------------------------------------*/
(module __hop_priv

   (cond-expand
      (enable-ssl (library ssl)))
   
   (import  __hop_configure
	    __hop_param
	    __hop_types)
   
   (export  (inline plist-assq ::obj ::pair-nil)
	    (plist-remq ::obj ::pair-nil)
	    (plist-remq! ::obj ::pair-nil)))

;*---------------------------------------------------------------------*/
;*    plist-assq ...                                                   */
;*---------------------------------------------------------------------*/
(define-inline (plist-assq key lst)
   (memq key lst))

;*---------------------------------------------------------------------*/
;*    plist-remq ...                                                   */
;*---------------------------------------------------------------------*/
(define (plist-remq key lst)
   (cond
      ((null? lst) '())
      ((eq? key (car lst)) (plist-remq key (cddr lst)))
      (else (cons* (car lst) (cadr lst) (plist-remq key (cddr lst))))))

;*---------------------------------------------------------------------*/
;*    plist-remq! ...                                                  */
;*---------------------------------------------------------------------*/
(define (plist-remq! key lst)
   (cond
      ((null? lst) lst)
      ((eq? key (car lst)) (plist-remq! key (cddr lst)))
      (else (let loop ((prev lst))
               (cond ((null? (cddr prev))
                      lst)
                     ((eq? (cadr prev) key)
                      (set-cdr! (cdr prev) (cdddr prev))
                      (loop prev))
                     (else (loop (cddr prev))))))))

