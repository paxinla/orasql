-- Step 1:- Copy this script to a file named fragment.sql.
-- Step 2:- Connect as user SYS or SYSTEM.
-- Step 3:- Run Analyze on all the tables present in the schema  for which you want to find the fragmented table.
-- SQL> Analyze table <table_name> compute statistics ;
-- Step 4:- Execute the fragment.sql script.Note the script will prompt for Schema name.
-- SQL> @fragment.sql

REM This is an example SQL*Plus Script to find tables fragmentated below high water mark

set heading off verify off echo off
Spool fragment.sql

REM The below queries gives information about the size of the table with respect to the High water Mark
REM note that BLOCKS*8192 is BLOCKS times the block size: 8192.  Substitue your DB blocksize.
REM SELECT BLOCKS*8192/1024/1024 FROM  DBA_TABLES WHERE  TABLE_NAME='<TABLE_NAME>'  and    owner='<owner>'   ;
REM The below queries gives the actual size in MB used by the table in terms of data .
REM SELECT NUM_ROWS*AVG_ROW_LEN/1024/1024 FROM  DBA_TABLES WHERE TABLE_NAME='<TABLE_NAME>' and  owner='<owner'
REM
REM You can use the difference of the two sql statements specified above to get the table which
REM has fragementation below high water mark prompt Enter name(s) of schema for which you want to find
REM fragemented object.
PROMPT Please enter the schema name

SELECT TABLE_NAME ,  (BLOCKS *8192 / 1024/1024 ) - (NUM_ROWS*AVG_ROW_LEN/1024/1024)
"Data lower than HWM in MB"   FROM  DBA_TABLES WHERE  UPPER(owner) =UPPER('&OWNER') order by 2 desc;

Spool off

