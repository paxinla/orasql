SET ECHO OFF
SET TRIMSPOOL ON
SET VERIFY OFF
SET FEEDBACK OFF
SET FEED OFF
SET HEADING OFF
SET TERMOUT OFF
SET PAGESIZE 20000
SET LINESIZE 5000

SPOOL '&TARGET_DIR/user_table_stats.txt';
    SELECT
           'Table statistics'  || CHR(10)
        || LPAD('=',37,'=')    || CHR(10)
        || '         Owner : ' || USER               || CHR(10)
        || '    Table name : ' || UT.TABLE_NAME      ||CHR(10)
        || '    Tablespace : ' || UT.TABLESPACE_NAME ||CHR(10)
        || '   Partitioned : ' || UT.PARTITIONED     ||CHR(10)
        || ' Last analyzed : ' || TO_CHAR(UT.LAST_ANALYZED,'YYYY-MM-DD HH24:MI:SS') ||CHR(10)
        || '        Degree : ' || UT.DEGREE          ||CHR(10)
        || '        # Rows : ' || UT.NUM_ROWS        ||CHR(10)
        || '      # Blocks : ' || UT.BLOCKS          ||CHR(10)
        || '  Empty Blocks : ' || UT.EMPTY_BLOCKS    ||CHR(10)
        || '     Avg Space : ' || UT.AVG_SPACE       ||CHR(10)
        || 'Avg Row Length : ' || UT.AVG_ROW_LEN     ||CHR(10)
        || '  Monitoring ? : ' || UT.MONITORING      ||CHR(10)
        || '        Status : ' || UT.STATUS          ||CHR(10)
      FROM USER_TABLES UT
     WHERE UT.TABLE_NAME = UPPER('&TBNM');

     SELECT
           'Column Statistics'       || CHR(10)
        || LPAD('=',68,'=')          || CHR(10)
        || RPAD('Name', 30, ' ')     || '|'
        || LPAD('Null?', 8, ' ')     || '|'
        || LPAD('NDV', 5, ' ')       || '|'
        || LPAD('# Nulls', 5, ' ')   || '|'
        || LPAD('# Buckets', 6, ' ') || '|'
        || LPAD('AvgLen', 8, ' ')    || CHR(10)
        || LPAD('-',68,'-')          || CHR(10)
      FROM DUAL;
    SELECT
           RPAD(ATC.COLUMN_NAME, 30, ' ')
         , LPAD(ATC.NULLABLE, 8, ' ') 
         , LPAD(ATC.NUM_DISTINCT, 5, ' ')
         , LPAD(ATC.NUM_NULLS, 5, ' ')
         , LPAD(ATC.NUM_BUCKETS, 6, ' ')
         , LPAD(ATC.AVG_COL_LEN, 8, ' ') 
      FROM ALL_TAB_COLS ATC
     WHERE ATC.OWNER = USER
       AND ATC.TABLE_NAME = UPPER('&TBNM');


    SELECT
           'Index Information'  || CHR(10)
        || LPAD('=',68,'=')     || CHR(10)
        || LPAD('Index', 8,' ')        || '|'
        || RPAD('Name', 30,' ')        || '|'
        || LPAD('Blevel', 6,' ')       || '|'
        || LPAD('Leaf', 10,' ')        || '|'
        || LPAD('# rows', 10,' ')      || '|'
        || LPAD('Dist', 10,' ')        || '|'
        || LPAD('Cols', 10,' ')        || '|'
        || LPAD('LB/Key', 10,' ')      || '|'
        || LPAD('DB/Key', 10,' ')      || '|'
        || LPAD('ClustFactor', 10,' ') || '|'
        || LPAD('Uniq?', 5,' ')        || CHR(10)
        || LPAD('-',68,'-')            || CHR(10)
      FROM DUAL;
    SELECT
           LPAD(AI.INDEX_TYPE, 8, ' ')
         , RPAD(AI.INDEX_NAME, 30, ' ')
         , LPAD(AI.BLEVEL, 6, ' ')
         , LPAD(AI.LEAF_BLOCKS, 10, ' ')
         , LPAD(AI.NUM_ROWS, 10, ' ')
         , LPAD(AI.DISTINCT_KEYS, 10, ' ')
         , LPAD(AI.INCLUDE_COLUMN, 10, ' ')
         , LPAD(AI.AVG_LEAF_BLOCKS_PER_KEY, 10, ' ')
         , LPAD(AI.AVG_DATA_BLOCKS_PER_KEY, 10, ' ')
         , LPAD(AI.CLUSTERING_FACTOR, 10, ' ')
         , LPAD(DECODE( AI.UNIQUENESS
                      , 'UNIQUE', 'YES'
                      , 'NO'
                      )
               , 5
               , ' ')   
      FROM ALL_INDEXES AI
     WHERE AI.TABLE_OWNER = USER
       AND AI.TABLE_NAME = UPPER('&TBNM');

    SELECT
           'Index Column Information'   || CHR(10)
        || LPAD('=',68,'=')             || CHR(10)
        || RPAD('Index Name', 30, ' ')  || '|'
        || LPAD('Pos #', 10, ' ')       || '|'
        || LPAD('Order', 5, ' ')        || '|'
        || RPAD('Column Name', 30, ' ') || CHR(10)
        || LPAD('-',68,'-')             || CHR(10)
      FROM DUAL;
    SELECT
           LPAD(AIC.INDEX_NAME, 30, ' ')
         , RPAD(AIC.COLUMN_POSITION, 10, ' ')
         , LPAD(AIC.DESCEND, 5, ' ')
         , RPAD(AIC.COLUMN_NAME, 30, ' ')
      FROM ALL_IND_COLUMNS AIC
     WHERE AIC.TABLE_OWNER = USER
       AND AIC.TABLE_NAME = '&TBNM';

SPOOL OFF;
QUIT;
