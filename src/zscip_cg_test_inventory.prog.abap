REPORT zscip_cg_test_inventory.

SELECT-OPTIONS: s_matnr FOR mara-matnr.

START-OF-SELECTION.
  SELECT matnr meins FROM mara INTO TABLE @DATA(gt_mara) WHERE matnr IN @s_matnr.
  LOOP AT gt_mara INTO DATA(gs_mara).
    WRITE: / gs_mara-matnr, gs_mara-meins.
  ENDLOOP.
