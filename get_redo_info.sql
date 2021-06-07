REM This script prints redo information.
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

PRO == Redo size ===============================================================================
SELECT A.PLATFORM_NAME  AS PLATFORM
     , B.REDOSIZE
  FROM v$database A
     , ( SELECT MAX(LEBSZ)  AS REDOSIZE
           FROM sys.x$kccle
       ) B
;
PRO == Redo actions ============================================================================
SELECT b.name
     , a.value
  FROM v$sysstat a
  JOIN v$statname b
         ON b.statistic# = a.STATISTIC#
 WHERE b.name IN (
    'redo write time', 'redo log space requests'
  , 'redo log space wait time', 'messages sent'
  , 'redo entries', 'redo size', 'redo synch writes'
  , 'redo wastage', 'redo writes', 'redo blocks written'
 )
;
