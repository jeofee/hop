;*=====================================================================*/
;*    Author      :  Florian Loitsch                                   */
;*    Copyright   :  2007-13 Florian Loitsch, see LICENSE file         */
;*    -------------------------------------------------------------    */
;*    This file is part of Scheme2Js.                                  */
;*                                                                     */
;*   Scheme2Js is distributed in the hope that it will be useful,      */
;*   but WITHOUT ANY WARRANTY; without even the implied warranty of    */
;*   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the     */
;*   LICENSE file for more details.                                    */
;*=====================================================================*/

(module mapping1-TO-BE-REMOVED
   (import export-desc
	   tools)
   (include "mapping.sch")
   (export *default-constant-runtime-var-mapping*
	   *call/cc-constant-runtime-var-mapping*))

(define *default-constant-runtime-var-mapping*
   (let ((ht (make-eq-hashtable)))
      (map (lambda (e)
	      (let ((desc (create-Export-Desc e #f #t)))
		 (with-access::Export-Desc desc (id)
		    (hashtable-put! ht id desc))))
	 (get-exports "runtime/runtime.sch"))
      ht))
(define *call/cc-constant-runtime-var-mapping*
   (let ((ht (make-eq-hashtable)))
      (map (lambda (e)
	      (let ((desc (create-Export-Desc e #f #t)))
		 (with-access::Export-Desc desc (id)
		    (hashtable-put! ht id desc))))
	 (get-exports "runtime/runtime-callcc.sch"))
      ht))
