REPORT zscip_sd_sales_2025_cust.

*&---------------------------------------------------------------------*
*& Report ZSCIP_SD_SALES_2025_CUST
*& 2025년 고객별 매출액 조회
*&---------------------------------------------------------------------*

TABLES: kna1, vbrk, vbrp.

TYPES: BEGIN OF ty_sales,
         kunnr TYPE kna1-kunnr,    " 고객번호
         name1 TYPE kna1-name1,    " 고객명
         land1 TYPE kna1-land1,    " 국가
         ort01 TYPE kna1-ort01,    " 도시
         netwr TYPE vbrk-netwr,    " 순매출액
         waerk TYPE vbrk-waerk,    " 통화
       END OF ty_sales,
       BEGIN OF ty_alv,
         kunnr TYPE kna1-kunnr,    " 고객번호
         name1 TYPE kna1-name1,    " 고객명
         land1 TYPE kna1-land1,    " 국가
         ort01 TYPE kna1-ort01,    " 도시
         netwr TYPE vbrk-netwr,    " 총매출액
         waerk TYPE vbrk-waerk,    " 통화
       END OF ty_alv.

DATA: gt_sales TYPE TABLE OF ty_sales,
      gs_sales TYPE ty_sales,
      gt_alv   TYPE TABLE OF ty_alv,
      gs_alv   TYPE ty_alv.

DATA: gt_vbrk TYPE TABLE OF vbrk,
      gs_vbrk TYPE vbrk,
      gt_vbrp TYPE TABLE OF vbrp,
      gs_vbrp TYPE vbrp,
      gt_kna1 TYPE TABLE OF kna1,
      gs_kna1 TYPE kna1.

DATA: gv_datum_from TYPE sy-datum VALUE '20250101',
      gv_datum_to   TYPE sy-datum VALUE '20251231'.

*----------------------------------------------------------------------*
* Selection Screen
*----------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
PARAMETERS: p_gjahr TYPE gjahr DEFAULT '2025' OBLIGATORY.
SELECT-OPTIONS: s_kunnr FOR kna1-kunnr,
                s_land1 FOR kna1-land1,
                s_vkorg FOR vbrk-vkorg,
                s_fkdat FOR vbrk-fkdat DEFAULT '20250101' TO '20251231'.
SELECTION-SCREEN END OF BLOCK b1.

*----------------------------------------------------------------------*
* Initialization
*----------------------------------------------------------------------*
INITIALIZATION.
  TEXT-001 = '선택조건'.

*----------------------------------------------------------------------*
* Start-of-Selection
*----------------------------------------------------------------------*
START-OF-SELECTION.

  PERFORM get_data.
  PERFORM process_data.
  PERFORM display_data.

*&---------------------------------------------------------------------*
*&      Form  GET_DATA
*&---------------------------------------------------------------------*
FORM get_data.

  " 2025년 청구 문서 헤더 조회
  SELECT vbeln
         fkdat
         fkart
         kunrg
         vkorg
         netwr
         waerk
         fksto
    FROM vbrk
    INTO CORRESPONDING FIELDS OF TABLE gt_vbrk
   WHERE fkdat IN s_fkdat
     AND vkorg IN s_vkorg
     AND kunrg IN s_kunnr
     AND fksto EQ space.  " 취소되지 않은 문서만

  IF gt_vbrk[] IS INITIAL.
    MESSAGE '조회된 데이터가 없습니다.' TYPE 'S' DISPLAY LIKE 'W'.
    LEAVE LIST-PROCESSING.
  ENDIF.

  " 고객 마스터 조회
  SELECT kunnr
         name1
         land1
         ort01
    FROM kna1
    INTO CORRESPONDING FIELDS OF TABLE gt_kna1
   WHERE kunnr IN s_kunnr
     AND land1 IN s_land1.

  SORT gt_kna1 BY kunnr.

ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  PROCESS_DATA
*&---------------------------------------------------------------------*
FORM process_data.

  DATA: lv_netwr TYPE vbrk-netwr.

  LOOP AT gt_vbrk INTO gs_vbrk.
    CLEAR gs_sales.

    gs_sales-kunnr = gs_vbrk-kunrg.
    gs_sales-waerk = gs_vbrk-waerk.

    " 매출액 집계 (크레딧 메모는 차감)
    IF gs_vbrk-fkart(1) = 'S'.  " 크레딧 메모 유형
      gs_sales-netwr = gs_vbrk-netwr * -1.
    ELSE.
      gs_sales-netwr = gs_vbrk-netwr.
    ENDIF.

    " 고객 정보 추가
    READ TABLE gt_kna1 INTO gs_kna1
         WITH KEY kunnr = gs_sales-kunnr
         BINARY SEARCH.
    IF sy-subrc = 0.
      gs_sales-name1 = gs_kna1-name1.
      gs_sales-land1 = gs_kna1-land1.
      gs_sales-ort01 = gs_kna1-ort01.
    ENDIF.

    APPEND gs_sales TO gt_sales.
  ENDLOOP.

  " 고객별 매출액 합계
  SORT gt_sales BY kunnr waerk.

  LOOP AT gt_sales INTO gs_sales.
    AT NEW kunnr.
      CLEAR: gs_alv, lv_netwr.
      gs_alv-kunnr = gs_sales-kunnr.
      gs_alv-name1 = gs_sales-name1.
      gs_alv-land1 = gs_sales-land1.
      gs_alv-ort01 = gs_sales-ort01.
      gs_alv-waerk = gs_sales-waerk.
    ENDAT.

    lv_netwr = lv_netwr + gs_sales-netwr.

    AT END OF kunnr.
      gs_alv-netwr = lv_netwr.
      APPEND gs_alv TO gt_alv.
    ENDAT.
  ENDLOOP.

  SORT gt_alv BY netwr DESCENDING.

ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  DISPLAY_DATA
*&---------------------------------------------------------------------*
FORM display_data.

  DATA: lt_fieldcat TYPE slis_t_fieldcat_alv,
        ls_fieldcat TYPE slis_fieldcat_alv,
        ls_layout   TYPE slis_layout_alv,
        ls_variant  TYPE disvariant.

  " Field Catalog 설정
  CLEAR ls_fieldcat.
  ls_fieldcat-fieldname = 'KUNNR'.
  ls_fieldcat-seltext_l = '고객번호'.
  ls_fieldcat-col_pos   = 1.
  ls_fieldcat-outputlen = 10.
  APPEND ls_fieldcat TO lt_fieldcat.

  CLEAR ls_fieldcat.
  ls_fieldcat-fieldname = 'NAME1'.
  ls_fieldcat-seltext_l = '고객명'.
  ls_fieldcat-col_pos   = 2.
  ls_fieldcat-outputlen = 35.
  APPEND ls_fieldcat TO lt_fieldcat.

  CLEAR ls_fieldcat.
  ls_fieldcat-fieldname = 'LAND1'.
  ls_fieldcat-seltext_l = '국가'.
  ls_fieldcat-col_pos   = 3.
  ls_fieldcat-outputlen = 3.
  APPEND ls_fieldcat TO lt_fieldcat.

  CLEAR ls_fieldcat.
  ls_fieldcat-fieldname = 'ORT01'.
  ls_fieldcat-seltext_l = '도시'.
  ls_fieldcat-col_pos   = 4.
  ls_fieldcat-outputlen = 20.
  APPEND ls_fieldcat TO lt_fieldcat.

  CLEAR ls_fieldcat.
  ls_fieldcat-fieldname = 'NETWR'.
  ls_fieldcat-seltext_l = '총매출액'.
  ls_fieldcat-col_pos   = 5.
  ls_fieldcat-outputlen = 18.
  ls_fieldcat-do_sum    = 'X'.
  ls_fieldcat-datatype  = 'CURR'.
  APPEND ls_fieldcat TO lt_fieldcat.

  CLEAR ls_fieldcat.
  ls_fieldcat-fieldname = 'WAERK'.
  ls_fieldcat-seltext_l = '통화'.
  ls_fieldcat-col_pos   = 6.
  ls_fieldcat-outputlen = 5.
  APPEND ls_fieldcat TO lt_fieldcat.

  " Layout 설정
  ls_layout-zebra = 'X'.
  ls_layout-colwidth_optimize = 'X'.

  " ALV 출력
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_callback_program = sy-repid
      is_layout          = ls_layout
      it_fieldcat        = lt_fieldcat
      i_save             = 'A'
    TABLES
      t_outtab           = gt_alv
    EXCEPTIONS
      program_error      = 1
      OTHERS             = 2.

  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

ENDFORM.
