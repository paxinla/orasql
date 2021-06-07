/* 导出登陆用户的存储过程
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

SPOOL './DDL4Procedure.sql';
    SELECT RPAD('-', 45, '-' )
||CHR(10)|| '-- File created on '||TO_CHAR(SYSDATE,'YYYY-MM-DD HH24:MI:SS')||' .'
||CHR(10)|| '-- Total export '||COUNT(DISTINCT OBJECT_NAME)||' procedure(s).'
||CHR(10)|| RPAD('-', 45, '-' )
      FROM USER_OBJECTS
     WHERE OBJECT_TYPE = 'PROCEDURE'
;
     SELECT 'set sqlblanklines on'
||CHR(10)|| 'set define off' 
       FROM DUAL
; 
WITH P AS (
    SELECT OBJECT_NAME  AS PRC_NAME
      FROM USER_OBJECTS
     WHERE OBJECT_TYPE = 'PROCEDURE'
) 
     SELECT TO_CLOB(RPAD('-', LENGTH(P.PRC_NAME)+18, '-' )) 
||CHR(10)|| TO_CLOB('---- Procedure : ' || P.PRC_NAME)
||CHR(10)|| TO_CLOB(RPAD('-', LENGTH(P.PRC_NAME)+18, '-' ))
||CHR(10)|| REPLACE(DBMS_METADATA.GET_DDL( OBJECT_TYPE => 'PROCEDURE'
                                 , NAME => P.PRC_NAME
                                 , SCHEMA => USER
                                 )
                    , '"'||USER||'".'
                    ,''
                     )        AS DDL_STR
       FROM P
;
     SELECT 'set define on'
||CHR(10)|| 'quit;' 
       FROM DUAL
; 
SPOOL OFF;
QUIT;
