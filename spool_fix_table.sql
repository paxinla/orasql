-- 生成导出指定表的定长文件的spool文件
SET ECHO OFF
SET TRIMSPOOL ON
SET VERIFY OFF
SET FEEDBACK OFF
SET FEED OFF
SET TIMING OFF
SET PAGESIZE 1000
SET NEWPAGE NONE
SET LINESIZE 1000
SET HEADING OFF
SET TERMOUT OFF

SPOOL './Fix_spool--&1..sql';
-- 导出 sqllplus 参数配置
     SELECT 'SET ECHO OFF'       FROM DUAL;
     SELECT 'SET TRIMSPOOL OFF'  FROM DUAL;
     SELECT 'SET VERIFY OFF'     FROM DUAL;
     SELECT 'SET FEEDBACK OFF'   FROM DUAL;
     SELECT 'SET FEED OFF'       FROM DUAL;
     SELECT 'SET HEADING OFF'    FROM DUAL;
     SELECT 'SET TERMOUT OFF'    FROM DUAL;
     SELECT 'SET TIMING OFF'     FROM DUAL;
     SELECT 'SET PAGESIZE 50000' FROM DUAL;
     SELECT 'SET NEWPAGE NONE'   FROM DUAL;
     SELECT 'SET LINESIZE '
         || SUM(DECODE( S.DATA_TYPE
                      , 'NUMBER', NVL2(S.DATA_PRECISION,S.DATA_PRECISION+1,S.DATA_LENGTH)
                      , 'DATE'  , 8
                      , S.DATA_LENGTH
                      ))
       FROM USER_TAB_COLUMNS S
      WHERE S.TABLE_NAME = UPPER('&1');
-- 导出 spool 头部
     SELECT 'COL TABLE_LINE     FORMAT A'
         || SUM(DECODE( CL.DATA_TYPE
                      , 'NUMBER', NVL2(CL.DATA_PRECISION,CL.DATA_PRECISION+1,CL.DATA_LENGTH)
                      , 'DATE'  , 8
                      , CL.DATA_LENGTH
                      ))
       FROM USER_TAB_COLUMNS CL
      WHERE CL.TABLE_NAME = UPPER('&1');
     SELECT 'SPOOL ''./&1..txt'';' FROM DUAL;
-- 定长导出部分
     SELECT 'SELECT ' FROM DUAL;
     SELECT
            DECODE(T.COLUMN_ID,1,'    ',' || ') 
         || CASE WHEN T.DATA_TYPE IN ( 'NUMBER', 'FLOAT')
                 THEN DECODE( T.DATA_SCALE 
                            , 0, 'LPAD(NVL(TRIM(' || T.COLUMN_NAME || '),'' ''),' || T.DATA_LENGTH || ', '' '''
                            , 'TO_CHAR(TRIM(' || T.COLUMN_NAME || '), '''
                            || LPAD('0',T.DATA_PRECISION-T.DATA_SCALE-1,'9') ||'.'
                            || LPAD('9',T.DATA_SCALE,'9')
                            ||''')' 
                            )
                 ELSE 'RPAD(NVL(TRIM(' || DECODE( T.DATA_TYPE
                                           , 'DATE' , 'TO_CHAR('||T.COLUMN_NAME||',''YYYYMMDD'')'
                                           , T.COLUMN_NAME
                                           ) 
                   || '), '' ''),' || DECODE( T.DATA_TYPE
                                           , 'DATE' , 8
                                           , T.DATA_LENGTH
                                           )
                   || ' , '' '' )'
            END
         || CASE WHEN T.COLUMN_ID = (SELECT COUNT(1) 
                                       FROM USER_TAB_COLUMNS 
                                      WHERE TABLE_NAME = UPPER('&1')
                                    )
                 THEN '     AS TABLE_LINE'
                 ELSE ' '
            END -- || CHR(10)
       FROM USER_TAB_COLUMNS T
      WHERE T.TABLE_NAME = UPPER('&1')
      ORDER BY T.COLUMN_ID;
     SELECT 'FROM &1;'   FROM DUAL;
-- 导出 spool 尾部
     SELECT 'SPOOL OFF;' FROM DUAL;
     SELECT 'QUIT;'      FROM DUAL;
SPOOL OFF;
QUIT;
