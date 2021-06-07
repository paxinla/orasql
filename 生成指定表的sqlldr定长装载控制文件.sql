SET ECHO OFF
SET COLSEP ','
SET TRIMSPOOL ON
SET VERIFY OFF
SET FEEDBACK OFF
SET FEED OFF
SET HEADING OFF
SET TERMOUT OFF
SET TIMING OFF
SET PAGESIZE 20000
SET LINESIZE 5000

SPOOL 'D:\FIXLOAD_&2.ctl';
 WITH FIX_LENGTH AS  
     (SELECT   A.TABLE_NAME  
             , A.COLUMN_ID  
             , A.COLUMN_NAME  
             , A.DATA_LENGTH  
             , SUM(P_OFFSET)OVER(PARTITION BY A.TABLE_NAME 
                                      ORDER BY A.COLUMN_ID
                                 )                            AS P_START  
             ,   SUM(P_OFFSET)OVER(PARTITION BY A.TABLE_NAME 
                                       ORDER BY A.COLUMN_ID
                                  ) 
               + DATA_LENGTH - 1                              AS P_END  
        FROM (SELECT   UTC.TABLE_NAME
                     , UTC.COLUMN_ID  
                     , UTC.COLUMN_NAME  
                     , UTC.DATA_LENGTH  
                     , LAG(UTC.DATA_LENGTH,1,1)OVER(PARTITION BY UTC.TABLE_NAME 
                                                        ORDER BY UTC.COLUMN_ID
                                                   )        AS P_OFFSET  
                     , SUM(UTC.DATA_LENGTH)OVER(PARTITION BY UTC.TABLE_NAME 
                                                    ORDER BY UTC.COLUMN_ID
                                               )            AS P_CONTINUOUS_SUMMATION  
                FROM USER_TAB_COLUMNS UTC
             ) A
     ) SELECT DISTINCT 
              'LOAD DATA ' || '&1' ||' INTO TABLE ' || TABLE_NAME
         FROM USER_TAB_COLUMNS  
        WHERE TABLE_NAME = '&2'  
       UNION ALL  
       SELECT *  
         FROM (SELECT DECODE( COLUMN_ID
                            , 1
                            , '('
                            , ''
                            ) 
                      || COLUMN_NAME 
                      || '  POSITION(' || P_START || ':' || P_END || ')' 
                      || DECODE( COLUMN_ID  
                               , MAX(COLUMN_ID)OVER(PARTITION BY TABLE_NAME)
                               , ' )'  
                               , ','
                               )  
                 FROM FIX_LENGTH  
                WHERE TABLE_NAME = '&2'  
                ORDER BY TABLE_NAME, COLUMN_ID
              );
SPOOL OFF;
QUIT;
