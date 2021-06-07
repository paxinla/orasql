REM This script evalutes the select factor of a table.
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

accept v_tabName -
       prompt 'Enter table name: '

COL CONSTRAINT_NAME     FORMAT A25
COL CONSTRAINT_TYPE     FORMAT A15
COL CONSTRAINT_COLS     FORMAT A50
COL INDEX_NAME          FORMAT A25
COL INDEX_TYPE          FORMAT A15
COL INDEX_COLS          FORMAT A50 
COL TABLE_NAME          FORMAT A30
COL NUMROWS             FORMAT A10
COL BLOCKS              FORMAT 9999999990
COL COLUMN_NAME         FORMAT A35
COL NUM_DISTINCT        FORMAT 999999999990
COL IDEAL_SELECTIVITY   FORMAT 90.999
COL NULLABLE            FORMAT A8
COL NUM_NULLS           FORMAT 999999990

PRO ============================================================================================
SELECT C.CONSTRAINT_NAME
     , C.CONSTRAINT_TYPE
     , WM_CONCAT(CC.COLUMN_NAME) AS CONSTRAINT_COLS
  FROM USER_CONSTRAINTS C
  JOIN USER_CONS_COLUMNS CC
         ON CC.OWNER = C.OWNER
        AND CC.CONSTRAINT_NAME = C.CONSTRAINT_NAME
        AND CC.TABLE_NAME = C.TABLE_NAME
 WHERE C.CONSTRAINT_TYPE IN ('P', 'F')
   AND C.OWNER = USER
   AND C.TABLE_NAME = UPPER('&&v_tabName')
 GROUP BY  C.CONSTRAINT_NAME, C.CONSTRAINT_TYPE
;
PRO ============================================================================================
   SELECT I.INDEX_NAME
        , I.INDEX_TYPE
        , WM_CONCAT(IC.COLUMN_NAME||'('||LOWER(IC.DESCEND)||')')  AS INDEX_COLS
     FROM USER_INDEXES I
LEFT JOIN USER_IND_COLUMNS IC
           ON IC.INDEX_NAME = I.INDEX_NAME
          AND IC.TABLE_NAME = I.TABLE_NAME
    WHERE IC.COLUMN_NAME IS NOT NULL
      AND I.TABLE_OWNER = USER
      AND I.TABLE_NAME = UPPER('&&v_tabName')
    GROUP BY I.INDEX_NAME, I.INDEX_TYPE
;
PRO ============================================================================================
SELECT T.TABLE_NAME
     , C.COLUMN_NAME
     , T.NUM_ROWS
     , C.NUM_DISTINCT
     , ROUND(1/DECODE(C.NUM_DISTINCT,0,1,C.NUM_DISTINCT),3)   AS IDEAL_SELECTIVITY
     , T.BLOCKS
     , C.NULLABLE
     , C.NUM_NULLS
  FROM USER_TABLES T
  JOIN USER_TAB_COLS C
         ON C.TABLE_NAME = T.TABLE_NAME
 WHERE T.TABLE_NAME = UPPER('&&v_tabName')
 ORDER BY C.COLUMN_ID ASC
;

undef v_tabName
commit;
