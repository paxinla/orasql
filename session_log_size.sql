REM This script prints redo size,undo size and logical read of this session.
REM pxl@xxx.com  @2015-01-19

set echo off
set feedback off
set verify off
set timing off
set sqlblanklines on
set pagesize 200
set newpage 1
set heading on
set linesize 250

SELECT B.NAME
     , A.VALUE
  FROM V$MYSTAT A
  JOIN V$STATNAME B
         ON B.STATISTIC# = A.STATISTIC#
        AND B.NAME IN ( 'undo change vector size'
                      , 'redo size'
                      , 'session logical reads'
                      )
;
