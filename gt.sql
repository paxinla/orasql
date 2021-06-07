set echo off
set verify off
set feedback on
set timing on
set linesize 250

BEGIN 
    DBMS_STATS.GATHER_TABLE_STATS( OWNNAME => USER
                                 , TABNAME => UPPER('&1')
                                 , METHOD_OPT => 'FOR ALL COLUMNS SIZE AUTO'
                                 , CASCADE => TRUE
                                 ); 
END;
/
undef 1
