*&---------------------------------------------------------------------*
*& Report ZSCIP_PIPELINE_TEST2
*&---------------------------------------------------------------------*
*& DEMO DATA - 파이프라인 테스트용 (E2E 재검증: Claude -> OpenClaw -> Git -> SAP)
*& 2025년 고객별 청구 매출액 (목업 데이터)
*&---------------------------------------------------------------------*
REPORT zscip_pipeline_test2.

TYPES: BEGIN OF ty_billing,
         kunnr TYPE kunnr,
         name1 TYPE name1_gp,
         netwr TYPE netwr,
       END OF ty_billing.

DATA: gt_billing TYPE STANDARD TABLE OF ty_billing,
      gs_billing TYPE ty_billing.

START-OF-SELECTION.

* DEMO DATA - 파이프라인 테스트용 (실제 테이블 미접근, 하드코딩 샘플)
  gs_billing-kunnr = '0000002000'.
  gs_billing-name1 = 'Zeta Holdings AG'.
  gs_billing-netwr = '3200000.00'.
  APPEND gs_billing TO gt_billing.

  gs_billing-kunnr = '0000002001'.
  gs_billing-name1 = 'Eta Components Ltd.'.
  gs_billing-netwr = '985400.25'.
  APPEND gs_billing TO gt_billing.

  gs_billing-kunnr = '0000002002'.
  gs_billing-name1 = 'Theta Foods Corp.'.
  gs_billing-netwr = '1470300.00'.
  APPEND gs_billing TO gt_billing.

  gs_billing-kunnr = '0000002003'.
  gs_billing-name1 = 'Iota Pharma S.A.'.
  gs_billing-netwr = '672850.90'.
  APPEND gs_billing TO gt_billing.

END-OF-SELECTION.

  WRITE: / '고객번호', 15 '고객명', 55 '2025년 청구액'.
  ULINE.
  LOOP AT gt_billing INTO gs_billing.
    WRITE: / gs_billing-kunnr, 15 gs_billing-name1, 55 gs_billing-netwr.
  ENDLOOP.