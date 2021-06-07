REM This script evaluates the index cluster factor
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

accept v_indexName -
       prompt 'Enter index name: '

PRO == Cluster factor ==========================================================================
SELECT I.INDEX_NAME
     , T.TABLE_NAME
     , I.CLUSTERING_FACTOR
     , T.NUM_ROWS
     , T.BLOCKS
  FROM USER_TABLES T
  JOIN USER_INDEXES I
        ON I.TABLE_NAME = T.TABLE_NAME
       AND I.TABLE_OWNER = USER
 WHERE I.INDEX_NAME = UPPER('&&v_indexName')
; 
ANALYZE INDEX &&v_indexName VALIDATE STRUCTURE;
PRO == Block usage =============================================================================
SELECT I.NAME
     , I.HEIGHT
     , ROUND((I.DEL_LF_ROWS_LEN/I.LF_ROWS_LEN)*100, 2)   AS RATIO
     , I.PCT_USED
     , UI.PCT_FREE
     , UI.INI_TRANS
  FROM INDEX_STATS I
  JOIN USER_INDEXES UI
         ON UI.INDEX_NAME = I.NAME
        AND I.NAME = UPPER('&&v_indexName')
; 

undef v_indexName
commit;
