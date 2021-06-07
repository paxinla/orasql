set echo off
set verify off
set feedback on
set timing on
set linesize 250

BEGIN 
    DBMS_STATS.GATHER_INDEX_STATS( OWNNAME => USER
                                 , INDNAME => UPPER('&1')
                                 );
END;
/

undef 1
