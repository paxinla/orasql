set echo off                                     
set heading off                                  
set verify off                                   
set feedback off                                 
set show off                                     
set trim off                                     
set pages 0                                      
set concat on                                    
set lines 300                                    
set trimspool on                                 
set trimout on                                   
spool &1..ctl                                    
select 'LOAD DATA'||chr (10)||             
--       'INFILE '''||lower (table_name)||'.dat '''||
       '&2 into table '||table_name||chr (10)||     
--       'Append into table '||table_name||chr (10)||     
       'FIELDS TERMINATED BY "&3"'|| chr (10)||
       'TRAILING NULLCOLS'||chr (10)||'('        
from   user_tables                                
where  table_name = upper ('&4');                
select decode (rownum, 1, '   ', ' , ')||
       rpad (column_name, 33, ' ')||
       decode (data_type,
               'VARCHAR2', 'CHAR('||RTRIM(TO_CHAR(DATA_LENGTH+4)) ||')  NULLIF ('||column_name||'=BLANKS)'||' "trim(:'||column_name||')"',
               'FLOAT',    'DECIMAL EXTERNAL NULLIF('||column_name||'=BLANKS)',
               'NUMBER',   decode (data_precision, 0,
                           'INTEGER EXTERNAL NULLIF ('||column_name||
                           '=BLANKS)', decode (data_scale, 0,
                           'INTEGER EXTERNAL NULLIF ('||
                           column_name||'=BLANKS)',
                           'DECIMAL EXTERNAL NULLIF ('||
                           column_name||'=BLANKS)')),
               'DATE',     'DATE "YYYY-MM-DD"  NULLIF ('||column_name||'=BLANKS)',
               null)
from   
(select * from user_tab_columns
where  table_name = upper ('&4')
order  by column_id ) t;                           
select ')'                                       
from sys.dual;                                   
spool off 
quit                                      
