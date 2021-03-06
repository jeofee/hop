;*=====================================================================*/
;*    serrano/prgm/project/hop/2.3.x/widget/lframe.scm                 */
;*    -------------------------------------------------------------    */
;*    Author      :  Manuel Serrano                                    */
;*    Creation    :  Fri Jun 26 07:21:23 2009                          */
;*    Last change :  Tue May 15 17:27:07 2012 (serrano)                */
;*    Copyright   :  2009-12 Manuel Serrano                            */
;*    -------------------------------------------------------------    */
;*    HOP's lframes.                                                   */
;*=====================================================================*/

;*---------------------------------------------------------------------*/
;*    The module                                                       */
;*---------------------------------------------------------------------*/
(module __hopwidget-lframe

   (library hop)

   (export  (<LFRAME> . ::obj)
	    (<LFLABEL> . ::obj)))

;*---------------------------------------------------------------------*/
;*    <LFRAME> ...                                                     */
;*---------------------------------------------------------------------*/
(define-tag <LFRAME> ((attrs) body)
   (<DIV> :data-hss-tag "hop-lframe"
      attrs
      (<DIV> :data-hss-tag "hop-lfborder"
         (<DIV> :data-hss-tag "hop-lfbody" body))))

;*---------------------------------------------------------------------*/
;*    <LFLABEL> ...                                                    */
;*---------------------------------------------------------------------*/
(define-tag <LFLABEL> ((attrs) body)
   (<DIV> :data-hss-tag "hop-lflabel"
      attrs
      (<SPAN> body)))
   
