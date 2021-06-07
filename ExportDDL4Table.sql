/* 导出登陆用户的表结构
 * PXL  2014-04
 */
SET ECHO OFF
SET TRIMSPOOL ON
SET VERIFY OFF
SET FEEDBACK OFF
SET FEED OFF
SET TIMING OFF
SET LINESIZE 4000
SET PAGESIZE 1000
SET LONG 90000
SET NEWPAGE NONE
SET HEADING OFF
SET TERMOUT OFF
SET WRAP ON

BEGIN 
    DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM,'STORAGE',FALSE);
    DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM,'TABLESPACE',FALSE);
    DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM,'SEGMENT_ATTRIBUTES',FALSE);
    DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM,'PRETTY',TRUE);  
    DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM,'SQLTERMINATOR',TRUE);
    DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM,'CONSTRAINTS',FALSE);
END;
/

COL DDL_STR    FORMAT A30000

SPOOL './DDL4Table.sql';
     SELECT RPAD('-', 42, '-' )
||CHR(10)|| '-- File created on '||TO_CHAR(SYSDATE,'YYYY-MM-DD HH24:MI:SS')||' .'
||CHR(10)|| '-- Total export '||COUNT(TABLE_NAME)||' table(s).'
||CHR(10)|| RPAD('-', 42, '-' )
       FROM USER_TABLES
;
     SELECT 'set sqlblanklines on'
||CHR(10)|| 'set define off' 
       FROM DUAL
;
WITH U AS (
    SELECT TABLE_NAME
      FROM USER_TABLES 
) 
     SELECT TO_CLOB(RPAD('-', LENGTH(U.TABLE_NAME)+18, '-' )) 
||CHR(10)|| TO_CLOB('---- Table : ' || U.TABLE_NAME)
||CHR(10)|| TO_CLOB(RPAD('-', LENGTH(U.TABLE_NAME)+18, '-' ))
||CHR(10)|| REPLACE(DBMS_METADATA.GET_DDL( OBJECT_TYPE => 'TABLE'
                                 , NAME => U.TABLE_NAME
                                 , SCHEMA => USER
                                 )
                    , '"'||USER||'".'
                    ,''
                     )
||CHR(10)|| CASE WHEN TC.TABLE_NAME IS NOT NULL
                  AND TC.COMMENTS IS NOT NULL
                 THEN TO_CLOB('COMMENT ON TABLE '||U.TABLE_NAME||' IS '''||TC.COMMENTS||''';')
                 ELSE NULL
            END
||CHR(10)|| CASE WHEN CC.TABLE_NAME IS NOT NULL
                 THEN REPLACE( WM_CONCAT( 'COMMENT ON COLUMN '||U.TABLE_NAME||'.'||CC.COLUMN_NAME
                           || ' IS '''||CC.COMMENTS||''';')
                         , ';,'
                         ,';'||CHR(10)
                         )
                 ELSE NULL
            END
||CHR(10)|| CASE WHEN IDX.TABLE_NAME IS NOT NULL
                 THEN TO_CLOB(REPLACE(IDX_STR, '"'||USER||'".', ''))       
                 ELSE NULL
            END
||CHR(10)|| CASE WHEN UCON.TABLE_NAME IS NOT NULL
                 THEN TO_CLOB(REPLACE(UCON.CON_STR, '"'||USER||'".', ''))
                 ELSE NULL
            END                        AS DDL_STR
       FROM U
  LEFT JOIN USER_TAB_COMMENTS TC
              ON TC.TABLE_NAME = U.TABLE_NAME
  LEFT JOIN USER_COL_COMMENTS CC
              ON CC.TABLE_NAME = U.TABLE_NAME
             AND CC.COMMENTS IS NOT NULL
  LEFT JOIN (   SELECT I.TABLE_NAME
                     , LISTAGG( DBMS_METADATA.GET_DDL( OBJECT_TYPE => 'INDEX'
                                                     , NAME => I.INDEX_NAME
                                                     , SCHEMA => USER
                                                     )   
                              , CHR(10)
                              )
                       WITHIN GROUP (ORDER BY NULL)  AS IDX_STR
                  FROM USER_INDEXES I
                  JOIN USER_TABLES T
                         ON I.TABLE_NAME = T.TABLE_NAME
                 GROUP BY I.TABLE_NAME
            ) IDX
              ON IDX.TABLE_NAME = U.TABLE_NAME
  LEFT JOIN (   SELECT U.TABLE_NAME
                     , LISTAGG( DBMS_METADATA.GET_DDL( OBJECT_TYPE => 'CONSTRAINT'
                                                     , NAME => U.CONSTRAINT_NAME
                                                     , SCHEMA => USER
                                                     )
                              , CHR(10)
                              )   
                       WITHIN GROUP (ORDER BY NULL)  AS CON_STR
                  FROM USER_CONSTRAINTS U
                  JOIN USER_TABLES T
                         ON U.TABLE_NAME = T.TABLE_NAME
                 GROUP BY U.TABLE_NAME
            ) UCON
              ON UCON.TABLE_NAME = U.TABLE_NAME
      GROUP BY U.TABLE_NAME, IDX.TABLE_NAME, TC.TABLE_NAME, CC.TABLE_NAME
             , TC.COMMENTS , UCON.TABLE_NAME, UCON.CON_STR, IDX.IDX_STR
;
     SELECT 'set define on'
||CHR(10)|| 'quit;' 
       FROM DUAL
;
SPOOL OFF;
QUIT; 
