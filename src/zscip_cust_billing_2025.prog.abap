REPORT zscip_cust_billing_2025.

*&---------------------------------------------------------------*
*& Report ZSCIP_CUST_BILLING_2025
*& Written by Claude, committed via git (dev-generated).
*& Real query: customer billing totals from VBRK/VBRP (SD billing
*& documents), aggregated by sold-to party, for a selectable date
*& range (default: calendar year 2025). Cancelled billing docs
*& (FKSTO = 'X') are excluded. Read-only - SELECT statements only,
*& no writes to any SAP table.
*&---------------------------------------------------------------*

TABLES: vbrk.

SELECT-OPTIONS: s_fkdat FOR vbrk-fkdat DEFAULT '20250101' TO '20251231'.

TYPES: BEGIN OF ty_result,
 kunnr TYPE kna1-kunnr,
 name1 TYPE kna1-name1,
 netwr TYPE vbrp-netwr,
 END OF ty_result.

DATA: gt_vbrk TYPE STANDARD TABLE OF vbrk,
 gt_vbrp TYPE STANDARD TABLE OF vbrp,
 gt_result TYPE STANDARD TABLE OF ty_result,
 gs_result TYPE ty_result.

START-OF-SELECTION.

 SELECT * FROM vbrk
 INTO TABLE gt_vbrk
 WHERE fkdat IN s_fkdat
 AND fksto = space.

 IF gt_vbrk IS NOT INITIAL.
 SELECT * FROM vbrp
 INTO TABLE gt_vbrp
 FOR ALL ENTRIES IN gt_vbrk
 WHERE vbeln = gt_vbrk-vbeln.
 ENDIF.

 " Aggregate item net value per billing document, then per sold-to party
 LOOP AT gt_vbrk INTO DATA(ls_vbrk).
 DATA(lv_doc_sum) = 0.
 LOOP AT gt_vbrp INTO DATA(ls_vbrp) WHERE vbeln = ls_vbrk-vbeln.
 lv_doc_sum = lv_doc_sum + ls_vbrp-netwr.
 ENDLOOP.

 READ TABLE gt_result ASSIGNING FIELD-SYMBOL(<fs_result>)
 WITH KEY kunnr = ls_vbrk-kunag.
 IF sy-subrc = 0.
 <fs_result>-netwr = <fs_result>-netwr + lv_doc_sum.
 ELSE.
 APPEND VALUE ty_result( kunnr = ls_vbrk-kunag netwr = lv_doc_sum ) TO gt_result.
 ENDIF.
 ENDLOOP.

 " Resolve customer names
 LOOP AT gt_result ASSIGNING FIELD-SYMBOL(<fs_name>).
 SELECT SINGLE name1 FROM kna1
 INTO <fs_name>-name1
 WHERE kunnr = <fs_name>-kunnr.
 ENDLOOP.

 SORT gt_result BY netwr DESCENDING.

 WRITE: / 'Customer Billing Summary', s_fkdat-low, 'to', s_fkdat-high.
 ULINE.
 WRITE: / 'Customer No.', 20 'Customer Name', 50 'Billing Amount'.
 ULINE.

 LOOP AT gt_result INTO gs_result.
 WRITE: / gs_result-kunnr, 20 gs_result-name1, 50 gs_result-netwr CURRENCY 'USD'.
 ENDLOOP.
