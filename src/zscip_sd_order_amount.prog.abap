REPORT zscip_sd_order_amount LINE-SIZE 255.

DATA gv_line TYPE string.
DATA gv_amount TYPE string.
DATA gv_quantity TYPE string.
DATA gv_order_qty TYPE string.
DATA gv_received_qty TYPE string.
DATA gv_open_qty TYPE string.
DATA gv_delay_days TYPE string.
DATA gv_tab TYPE c LENGTH 1.

PARAMETERS p_vkorg TYPE vkorg DEFAULT ''.
PARAMETERS p_api TYPE c LENGTH 1 NO-DISPLAY.

TYPES: BEGIN OF ty_result,
         customer           TYPE vbak-kunnr,
         customer_name      TYPE kna1-name1,
         net_amount         TYPE vbak-netwr,
         currency           TYPE vbak-waerk,
       END OF ty_result.

DATA gt_result TYPE STANDARD TABLE OF ty_result WITH EMPTY KEY.
DATA gs_result TYPE ty_result.
DATA go_alv TYPE REF TO cl_salv_table.
DATA gx_salv TYPE REF TO cx_salv_msg.

START-OF-SELECTION.

  gv_tab = cl_abap_char_utilities=>horizontal_tab.

  SELECT kunnr, SUM( netwr ) AS net
  FROM vbak
  GROUP BY kunnr

  IF p_api = 'X'.
    CONCATENATE 'customer' 'net_amount'
      INTO gv_line SEPARATED BY gv_tab.
    WRITE: / gv_line.

    IF gt_result IS INITIAL.
      RETURN.
    ENDIF.

    LOOP AT gt_result INTO gs_result.
      CLEAR gv_amount.
      gv_amount = gs_result-net_amount.
      CONCATENATE gs_result-customer gs_result-net_amount
        INTO gv_line SEPARATED BY gv_tab.
      WRITE: / gv_line.
    ENDLOOP.

    RETURN.
  ENDIF.

  TRY.
      cl_salv_table=>factory(
        IMPORTING r_salv_table = go_alv
        CHANGING  t_table      = gt_result ).
      go_alv->display( ).
    CATCH cx_salv_msg INTO gx_salv.
      MESSAGE gx_salv->get_text( ) TYPE 'E'.
  ENDTRY.
