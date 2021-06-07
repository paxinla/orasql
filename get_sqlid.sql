REM This script gets the sql id by a comment
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

accept v_commentMark -
       prompt 'Enter comment mark: '

COL SQL_ID           FORMAT A15
COL CHILD_NUMBER     FORMAT 9999990
COL HASH_VALUE       FORMAT 999999999999999999990
COL ADDRESS          FORMAT A20
COL EXECUTIONS       FORMAT 9999990
COL SQL_TEXT         FORMAT A100

SELECT /*<!SIGAMOGA_KAMINOKE!>*/
       SQL_ID
     , CHILD_NUMBER
     , HASH_VALUE
     , ADDRESS
     , EXECUTIONS
     , SQL_TEXT
  FROM V$SQL
 WHERE PARSING_USER_ID = ( SELECT USER_ID
                             FROM ALL_USERS
                            WHERE USERNAME = USER
                         )
   AND COMMAND_TYPE IN (2, 3, 6, 7, 189)
   AND UPPER(SQL_TEXT) LIKE '%'|| TRIM(UPPER('&&v_commentMark'))||'%'
   AND UPPER(SQL_TEXT) NOT LIKE '%<!SIGAMOGA_KAMINOKE!>%'
;

undef v_commentMark
