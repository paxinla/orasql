EM This script evaluates the fragment of an Table.
REM pxl@xxx.com  @2015-01-19

set echo off
set feedback off
set verify off
set timing off
set sqlblanklines on
set pagesize 20
set newpage 1
set heading on
set linesize 250

accept v_tableName -
       prompt 'Enter table name: '

SELECT TRUNC(PXL_FN_REAL_SIZE('&&v_tableName')/1024/1024,2) AS REAL_SIZE(MB)
     , US.BYTES/1024/1024   AS SEG_SIZE(MB)
     , TRUNC((1-PXL_FN_REAL_SIZE('&&v_tableName')/US.BYTES)*100,2)||'%'  AS FRAG_RATIO
  FROM USER_SEGMENTS US
 WHERE US.SEGMENT_NAME = '&&v_tableName'
;

undef v_tableName
commit;
