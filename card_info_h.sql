 DELETE FROM CARD_INFO_H T WHERE T.ETL_DATE = &1;
   TRUNCATE TABLE CARD_TMP;

    INSERT /*+APPEND*/ INTO CARD_TMP NOLOGGING(DATADATE, CARD_NO, AC_NO, SUB_AC_NO, ACCT_TYPE, CCY_CODE, BALANCE, ACT_STATUS, IS_PRIMARY)
    SELECT DISTINCT
        &1                        AS  DATADATE
        , CADM.OPC0_CARD_NO               AS  CARD_NO
        , '0'                             AS  AC_NO
        , LTRIM(LINK.OPC1_ACCOUNT, '0')   AS  SUB_AC_NO
        , INVM.CD03_ACCT_TYPE             AS  ACCT_TYPE
        , INVM.CD03_CURRENCY              AS  CCY_CODE
        , INVM.CD03_CURR_BAL              AS  BALANCE
        , INVM.CD03_CURR_STATUS           AS  ACT_STATUS
        , LINK.OPC1_IS_PRIMARY            AS  IS_PRIMARY
    FROM ODS.BANCS_CADM_M PARTITION(PART_&2) CADM
        LEFT JOIN ODS.BANCS_LINK_M PARTITION(PART_&2) LINK
        ON LINK.OPC1_CARD_NO = CADM.OPC0_CARD_NO
        LEFT JOIN ODS.BANCS_INVM_M PARTITION(PART_&2) INVM
        ON INVM.INVM_MEMB_CUST_AC = OPC1_ACCOUNT
        --AND INVM.CD03_CURR_STATUS = '00'
    WHERE CADM.OPC0_BIN_NO = '00006'          --�ڽ��в��ֿ�ֻ�����˻�
      AND CADM.OPC0_PROD_NO = '0000000008'
      AND INVM.CD03_CURRENCY <> 'XXX'
    UNION ALL
    SELECT
        &1                        AS  DATADATE
        , CADM.OPC0_CARD_NO               AS  CARD_NO
        , LTRIM(LINK.OPC1_ACCOUNT, '0')   AS  AC_NO
        , TO_CHAR(NVL(MR.SUB_AC_NO, '0')) AS  SUB_AC_NO
        , INVM.CD03_ACCT_TYPE             AS  ACCT_TYPE
        , INVM.CD03_CURRENCY              AS  CCY_CODE
        , INVM.CD03_CURR_BAL              AS  BALANCE
        , INVM.CD03_CURR_STATUS           AS  ACT_STATUS
        , LINK.OPC1_IS_PRIMARY            AS  IS_PRIMARY
    FROM ODS.BANCS_CADM_M PARTITION(PART_&2) CADM
        LEFT JOIN ODS.BANCS_LINK_M PARTITION(PART_&2) LINK
        ON LINK.OPC1_CARD_NO = CADM.OPC0_CARD_NO
        LEFT JOIN IDS.MAIN_SUB_AC_REL MR
        ON MR.AC_NO = LINK.OPC1_ACCOUNT
        LEFT JOIN ODS.BANCS_INVM_M PARTITION(PART_&2) INVM
        ON INVM.INVM_MEMB_CUST_AC = MR.SUB_AC_NO
        --AND INVM.CD03_CURR_STATUS = '00'
    WHERE (CADM.OPC0_BIN_NO <> '00006'
          OR CADM.OPC0_PROD_NO <> '0000000008')
       OR (CADM.OPC0_BIN_NO = '00006'
          AND CADM.OPC0_PROD_NO = '0000000008'
          AND INVM.CD03_CURRENCY = 'XXX');
    COMMIT;

    INSERT /*+APPEND*/ INTO CARD_INFO_H NOLOGGING(ETL_DATE, CARD_NO, CST_ID, NEW_CTF_NO, CST_NM, PROD_NO, BIN_NO, ATM_AC_NO, AC_NO
                                      , SUB_AC_NO, ACCT_TYPE, ACT_STATUS, CCY_CODE, BALANCE, OPN_BR, OPN_DATE, OPN_TELL, DES_DATE
                                      , CHN_DATE, STATUS, FEE_PERCENT, FEE_FREE_PERIOD, FEE_RESIDU, IS_PRIMARY, IS_SLEEPING, IS_PLKK
                                      , PARTITION_FLAG)
    SELECT DISTINCT
        &1
        , T.OPC0_CARD_NO
        , LTRIM(T.OPC0_CUST_NO, '0')
        , CASE WHEN f_pid15to18(CBI.MAIN_CTF_NO) IS NOT NULL
               THEN f_pid15to18(CBI.MAIN_CTF_NO)
               ELSE f_pid15to18(PL.CARD_ID)
               END                                  --�ȴӿͻ���Ϣ��ȡ֤���ţ����ȡ�����͵�����ϵͳȡ
        , CBI.CST_NM
        , T.OPC0_PROD_NO
        , T.OPC0_BIN_NO
        , LTRIM(T.OPC0_ATM_ACCOUNT, '0')            --����λ����Ϊ�գ��ձ�ʾ�ÿ���δ��Ч
        , NVL(AC_NO, '-')
        , NVL(SUB_AC_NO, '-')
        , TMP.ACCT_TYPE
        , TMP.ACT_STATUS
        , CCY_CODE
        , BALANCE
        , NVL(OPN_BR, T.OPC0_ISSUE_BRANCH)          --�ȴӽ��ױ���ȡ�����׻�������ȡ�������ٴӿ�����ȡ���л���
        , CASE WHEN TMP2.OPN_DATE IS NULL AND NVL(A.OPN_DATE, T.OPC0_ISSUE_DATE) < 20110911
               THEN NVL(NVL(A.OPN_DATE, T.OPC0_ISSUE_DATE), '99999999')
               ELSE TMP2.OPN_DATE
               END                      --�ȴӽ��ױ���ȡ���������ڣ���û�У���ȡĳ���͹����Ŀ������ݣ���û�У���ȡ����ķ�������
        , OPN_TELL
        , DES_DATE
        , NVL(CHN_DATE, T.OPC0_REISSUE_DATE)  --�ȴӽ��ױ�ȡ���������ڣ���ȡ��������ȡ������ط�������
        , T.OPC0_LIFE_STATUS
        , T.OPC0_ANNUAL_FEE_PERCENT
        , T.OPC0_ANNUAL_FREE_PERIOD
        , T.OPC0_ANNUAL_FEE_RESIDU
        , TMP.IS_PRIMARY
        , CASE WHEN MONTHS_BETWEEN(TO_DATE(T.OPC0_LAST_USE_DATE, 'YYYYMMDD'), TO_DATE(&1, 'YYYYMMDD')) > 12
               THEN 1
               ELSE 0
               END
        , CASE WHEN PL.CARD_NO IS NOT NULL
               THEN 1
               ELSE 0
               END
        , SUBSTR(&1, 1, 6)
    FROM ODS.BANCS_CADM_M PARTITION(PART_&2) T
        LEFT JOIN OPEN_CARD A           --ĳ���͹����ľ��߿�������
        ON T.OPC0_CARD_NO = A.CARD_NO
        LEFT JOIN CARD_TMP TMP
        ON TMP.CARD_NO = T.OPC0_CARD_NO
        LEFT JOIN
        (
            SELECT
                JNAL.OPC2_CARD_NO                              AS  CARD_NO
                , TO_CHAR(MAX(CASE WHEN OPC2_TXN_CODE IN (37301,37201,37203,37205)   --����������
                                   THEN JNAL.OPC2_TXN_BRANCH
                                   END))                       AS  OPN_BR
                , TO_CHAR(MAX(CASE WHEN OPC2_TXN_CODE IN (37301,37201,37203,37205)
                                   THEN JNAL.OPC2_TXN_DATE
                                   END))                       AS  OPN_DATE
                , TO_CHAR(MAX(CASE WHEN OPC2_TXN_CODE IN (37301,37201,37203,37205)
                                   THEN JNAL.OPC2_TXN_TELLER
                                   END))                       AS  OPN_TELL
                , TO_CHAR(MAX(CASE WHEN OPC2_TXN_CODE IN (37223)                     --����������
                                   THEN JNAL.OPC2_TXN_DATE
                                   END))                       AS  DES_DATE
                , TO_CHAR(MAX(CASE WHEN OPC2_TXN_CODE IN (37101, 37251)              --����������
                                   THEN JNAL.OPC2_TXN_DATE
                                   END))                       AS  CHN_DATE
            FROM ODS.BANCS_JNALM_F JNAL
            WHERE JNAL.OPC2_ERROR = '00000'                    --'00000'��ʾ�ɹ�����
              AND OPC2_TXN_CODE IN (37301,37201,37203,37205,37223,37101,37251)
            GROUP BY JNAL.OPC2_CARD_NO
        ) TMP2
        ON TMP2.CARD_NO = T.OPC0_CARD_NO
        LEFT JOIN IDS.CST_BSC_INF CBI
        ON CBI.CST_ID = LTRIM(T.OPC0_CUST_NO, '0')
        LEFT JOIN     --��������ϵͳ�в��ֿͻ���Ϣ��BANCS��û��
        (
            SELECT DISTINCT
                CASE WHEN P.PREF_CARD_NEW IS NOT NULL
                     THEN P.PREF_CARD_NEW
                     ELSE P.PREF_CARD
                     END                     CARD_NO   --�¿������Ҳ�������ȡԤ�ƿ�����
                , P.CARD_ID
            FROM ODS.PLSF_BCARD_TRAN_DETAIL_F P
            WHERE P.DEAL_FLAG = '59' --��������
        ) PL
        ON T.OPC0_CARD_NO = PL.CARD_NO
    ;
    COMMIT;
