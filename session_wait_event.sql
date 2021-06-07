REM This script shows the wati events of the given session.
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

accept v_sessionId -
       prompt 'Enter session sid: '

COL sid                FORMAT 9999999990
COL event              FORMAT A30
COL blocking_session   FORMAT A16
COL sql_text           FORMAT A50

PRO == Wait events =============================================================================
    SELECT a.sid               AS SID
         , a.event             AS EVENT
         , a.blocking_session  AS BLOCKING_SESSION
         , b.sql_text          AS SQL_TEXT
      FROM v$session a
 LEFT JOIN v$sqlarea b
             ON b.hash_value = a.sql_hash_value
     WHERE a.sid = &&v_sessionId
;
PRO == Mutex usage ============================================================================= 
SELECT mt.mutex_type    AS MUTEX_TYPE
     , mt.location      AS THE_LOCATION
     , mt.sleeps        AS SLEEPS
     , mt.wait_time     AS WAIT_TIME
  FROM v$mutex_sleep mt
 WHERE mt.mutex_type = 'Cursor Pin'
;

undef v_sessionId

