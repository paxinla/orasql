REM This script prints index events.
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

PRO == Split event =============================================================================
SELECT S.SID
     , N.NAME
     , S.VALUE
  FROM V$SESSTAT S
  JOIN V$STATNAME N
         ON N.STATISTIC# = S.STATISTIC#
 WHERE S.SID IN (SELECT SID FROM V$MYSTAT)
   AND S.VALUE > 0
   AND N.NAME LIKE '%split%'
;
PRO == ITL event ===============================================================================
SELECT EVENT
     , TOTAL_WAITS
  FROM V$SYSTEM_EVENT
WHERE EVENT IN ( 'enq: TX - allocate ITL entry'
               , 'enq: TX - index contention'
               )
;


