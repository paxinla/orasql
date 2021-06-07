    SELECT
             SRC.TBCOMMENTS              AS "������ע��"
           , SRC.TABLE_NAME              AS "����"
           , SRC.COLUMN_NAME             AS "�ֶ���"
           , SRC.COLCOMMENTS             AS "�ֶ�����ע��"
           , SRC.COLTYPE                 AS "�ֶ�����"
           , SRC.COLID                   AS "�ֶ����"
           , SRC.ISNULL                  AS "�Ƿ��Ϊ��"
           , SRC.ISPK                    AS "�Ƿ�����"
           , SRC.RN
      FROM (
                SELECT
                             UTBM.COMMENTS          AS TBCOMMENTS
                           , UTBC.TABLE_NAME        AS TABLE_NAME
                           , UTBC.COLUMN_NAME       AS COLUMN_NAME
                           , UCC.COMMENTS           AS COLCOMMENTS
                           , CASE WHEN UTBC.CHAR_LENGTH=0
                                  THEN 
                                       CASE WHEN UTBC.DATA_SCALE IS NULL 
                                              OR UTBC.DATA_PRECISION IS NULL
                                            THEN UTBC.DATA_TYPE
                                            ELSE UTBC.DATA_TYPE 
                                              || '(' || UTBC.DATA_PRECISION 
                                              || ',' || UTBC.DATA_SCALE 
                                              || ')'
                                       END
                                  ELSE UTBC.DATA_TYPE || '(' || UTBC.CHAR_LENGTH || ')'
                             END                    AS COLTYPE
                           , UTBC.COLUMN_ID         AS COLID
                           , UTBC.NULLABLE          AS ISNULL
                           , CASE WHEN UPC.CONSTRAINT_NAME IS NOT NULL
                                   AND INSTR(UPC.COLS , UTBC.COLUMN_NAME) > 0
                                  THEN '��'
                                  ELSE ' ' 
                             END                    AS ISPK
                      FROM USER_TAB_COLUMNS UTBC 
                      JOIN USER_TAB_COMMENTS UTBM
                             ON UTBC.TABLE_NAME = UTBM.TABLE_NAME
                 LEFT JOIN USER_COL_COMMENTS UCC
                             ON UCC.TABLE_NAME = UTBC.TABLE_NAME 
                            AND UCC.COLUMN_NAME = UTBC.COLUMN_NAME
                 LEFT JOIN USER_CONSTRAINTS UPK
                             ON UPK.TABLE_NAME = UCC.TABLE_NAME
                            AND UPK.CONSTRAINT_TYPE = 'P'
                 LEFT JOIN (  SELECT
                                       CONSTRAINT_NAME
                                     , LISTAGG(COLUMN_NAME,',')WITHIN GROUP (ORDER BY NULL) AS COLS
                                FROM USER_CONS_COLUMNS
                               WHERE TABLE_NAME = '&TABLE_NAME'
                               GROUP BY CONSTRAINT_NAME
                           ) UPC
                             ON UPC.CONSTRAINT_NAME = UPK.CONSTRAINT_NAME              
                     WHERE UTBC.TABLE_NAME = '&TABLE_NAME'
           ) SRC
      ORDER BY SRC.TABLE_NAME, SRC.COLID;
