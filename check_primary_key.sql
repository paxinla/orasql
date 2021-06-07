      SELECT
             TB_DESC.TABLE_NAME         AS "表名"
           , NVL(TB_DESC.COMMENTS,'-')  AS "表中文注释"
           , TB_COLS.COLUMN_NAME        AS "字段名"
           , COL_DESC.COMMENTS          AS "字段中文注释"
           , TB_COLS.COLUMN_ID          AS "字段序号"
           , CASE WHEN TB_COLS.CHAR_LENGTH = 0
                   AND (   TB_COLS.DATA_SCALE IS NULL 
                        OR TB_COLS.DATA_PRECISION IS NULL
                       )
                  THEN TB_COLS.DATA_TYPE
                  WHEN TB_COLS.CHAR_LENGTH = 0
                   AND TB_COLS.DATA_SCALE IS NULL 
                   AND TB_COLS.DATA_PRECISION IS NULL
                  THEN TB_COLS.DATA_TYPE || '(' || TB_COLS.DATA_PRECISION || ',' || TB_COLS.DATA_SCALE || ')'
                  ELSE TB_COLS.DATA_TYPE || '(' || TB_COLS.CHAR_LENGTH || ')'
             END                       AS "字段类型"
           , TB_COLS.NULLABLE          AS "是否可为空"
           , CASE WHEN PK_COLS.COLUMN_NAME IS NULL
                  THEN ''
                  ELSE 'Y'
             END                        AS "是否主键"
           , NVL(TB_PK.CONSTRAINT_NAME,'')   AS "主键名"
           , NVL(TB_PK.STATUS,'')       AS "主键状态"
        FROM USER_TAB_COLUMNS   TB_COLS
   LEFT JOIN USER_TAB_COMMENTS  TB_DESC
               ON TB_DESC.TABLE_NAME = TB_COLS.TABLE_NAME
   LEFT JOIN USER_COL_COMMENTS  COL_DESC
               ON COL_DESC.TABLE_NAME = TB_COLS.TABLE_NAME 
              AND COL_DESC.COLUMN_NAME = TB_COLS.COLUMN_NAME
   LEFT JOIN USER_CONSTRAINTS TB_PK
               ON TB_PK.TABLE_NAME = TB_COLS.TABLE_NAME
              AND TB_PK.CONSTRAINT_TYPE = 'P'
   LEFT JOIN USER_CONS_COLUMNS PK_COLS
               ON PK_COLS.TABLE_NAME = TB_PK.TABLE_NAME
              AND PK_COLS.CONSTRAINT_NAME = TB_PK.CONSTRAINT_NAME
              AND PK_COLS.COLUMN_NAME = TB_COLS.COLUMN_NAME
       WHERE TB_COLS.TABLE_NAME LIKE 'GX%'
       ORDER BY TB_COLS.TABLE_NAME, TB_COLS.COLUMN_ID;
