REM This script prints sid and spid of this session.
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


SELECT a.sid
     , c.spid
  FROM (SELECT DISTINCT 
               SID 
          FROM v$mystat
       ) a
  JOIN v$session b
         ON b.sid = a.sid
  JOIN v$process c
         ON c.addr = b.paddr
;
