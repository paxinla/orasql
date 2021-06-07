    SELECT 
             A.TABLE_NAME           AS "表名"
           , B.COMMENTS             AS "表中文注释"
           , A.COLUMN_NAME          AS "字段名"
           , (   SELECT COMMENTS
                   FROM ALL_COL_COMMENTS SS
                  WHERE SS.OWNER = A.OWNER 
                    AND SS.TABLE_NAME = A.TABLE_NAME 
                    AND SS.COLUMN_NAME = A.COLUMN_NAME
             )                      AS "字段中文注释"
           , A.COLUMN_ID            AS "字段序号"
           , CASE WHEN A.CHAR_LENGTH=0
                  THEN CASE WHEN (A.DATA_SCALE IS NULL) OR (A.DATA_PRECISION IS NULL)
                            THEN A.DATA_TYPE
                            ELSE A.DATA_TYPE || '(' || A.DATA_PRECISION || '' || A.DATA_SCALE || ')'
                       END
                  ELSE A.DATA_TYPE || '(' || A.CHAR_LENGTH || ')'
             END                    AS "字段类型"
           , A.NULLABLE             AS "是否可为空"
           , CASE (SELECT COUNT(1)
                        FROM USER_CONS_COLUMNS AA 
                        JOIN USER_CONSTRAINTS BB
                               ON AA.OWNER = BB.OWNER 
                              AND AA.TABLE_NAME = BB.TABLE_NAME 
                              AND AA.CONSTRAINT_NAME = BB.CONSTRAINT_NAME 
                        WHERE AA.OWNER = B.OWNER 
                          AND AA.TABLE_NAME = A.TABLE_NAME 
                          AND AA.COLUMN_NAME = A.COLUMN_NAME
                          AND BB.CONSTRAINT_TYPE = 'P'
                   )
                   WHEN 0
                   THEN ''
                   WHEN 1
                   THEN 'Y'
              END                AS "是否主键"
      FROM ALL_TAB_COLUMNS  A   
      JOIN ALL_TAB_COMMENTS B
             ON A.OWNER = 'PRIDATA' --schema名需根据需要修改
            AND A.OWNER = B.OWNER 
            AND A.TABLE_NAME = B.TABLE_NAME
     ORDER BY TT.GID,A.TABLE_NAME, A.COLUMN_ID

