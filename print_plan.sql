REM This script prints execute plan of given sql_id.
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

accept v_sqlId -
       prompt 'Enter sql_id: '
accept v_childNum -
       prompt 'Enter child_number: ' -
       default 0

SELECT * FROM TABLE(dbms_xplan.display_cursor(trim('&&v_sqlId'),&&v_childNum,'ALLSTATS +PEEKED_BINDS +COST +BYTES'))
;

undef v_sqlId
undef v_childNum

