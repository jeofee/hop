;*=====================================================================*/
;*    serrano/prgm/project/hop/2.0.x/runtime/hss.sch                   */
;*    -------------------------------------------------------------    */
;*    Author      :  Manuel Serrano                                    */
;*    Creation    :  Fri Apr  3 15:33:01 2009                          */
;*    Last change :  Fri Apr  3 15:34:23 2009 (serrano)                */
;*    Copyright   :  2009 Manuel Serrano                               */
;*    -------------------------------------------------------------    */
;*    The definition of the HSS macros                                 */
;*=====================================================================*/

;*---------------------------------------------------------------------*/
;*    directives                                                       */
;*---------------------------------------------------------------------*/
(directives (option (loadq "hss-expd.sch")))

;*---------------------------------------------------------------------*/
;*    define-hss-rule ...                                              */
;*---------------------------------------------------------------------*/
(define-expander define-hss-rule expand-define-hss-rule)