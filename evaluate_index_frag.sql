REM This script evaluates the fragment of an index,especially for OLTP database.
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

accept v_indexName -
       prompt 'Enter index name: '

      SELECT UI.INDEX_NAME
           , UI.STATUS
           , ROUND((1-(UI.NUM_ROWS*(IC.COL_LEN+10)/(UI.LEAF_BLOCKS*((SELECT VALUE FROM V$PARAMETER WHERE NAME = 'db_block_size')-192)*(1-UI.PCT_FREE/100))))*100
                  ,2
                  )        AS EST_FRAG_RATIO 
        FROM USER_INDEXES UI
   LEFT JOIN ( SELECT A.INDEX_NAME
                    , AVG(B.AVG_COL_LEN)  AS  COL_LEN
                 FROM USER_IND_COLUMNS A
                 JOIN USER_TAB_COLS B
                        ON B.COLUMN_NAME = A.COLUMN_NAME
                       AND B.TABLE_NAME = A.TABLE_NAME
                WHERE A.INDEX_NAME = UPPER('&&v_indexName')
                GROUP BY A.INDEX_NAME
             ) IC
                ON IC.INDEX_NAME = UI.INDEX_NAME
       WHERE UI.INDEX_NAME = UPPER('&&v_indexName')
; 

undef v_indexName
commit;
