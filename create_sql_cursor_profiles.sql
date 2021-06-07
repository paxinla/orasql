----------------------------------------------------------------------------------------
-- File name:   Create_SQL_cursor_profiles.sql
-- Purpose:     Create SQL Profile based on Outline hints in V$SQL.OTHER_XML.
-- Usage:       This scripts prompts for four values.
--              sql_id1: the sql_id of the statement to attach the profile sql_text (must be in the shared pool)
--              child_no1: the child_no of the statement from v$sql
--              sql_id2: the sql_id of the statement to attach the profile sql_hints (must be in the shared pool)
--              child_no2: the child_no of the statement from v$sql
--              profile_name: the name of the profile to be generated
--              category: the name of the category for the profile
--              force_macthing: a toggle to turn on or off the force_matching feature
-- Description: 
--              Based on a script by Kerry Osborne.
-- Mods:        www.easyora.net
---------------------------------------------------------------------------------------

set feedback off
set sqlblanklines on

accept sql_id1 -
       prompt 'Enter value for sql_id1(used to generate sql_text): ' -
       default 'X0X0X0X0'
accept child_no1 -
       prompt 'Enter value for child_no1 (used to generate sql_text) (0): ' -
       default '0'
accept sql_id2 -
       prompt 'Enter value for sql_id2(used to generate sql_hints): ' -
       default '&&sql_id1'
accept child_no2 -
       prompt 'Enter value for child_no2(used to generate sql_hints) (0): ' -
       default '0'
accept profile_name -
       prompt 'Enter value for profile_name (PROF_sqlid_planhash): ' -
       default 'X0X0X0X0'
accept category -
       prompt 'Enter value for category (DEFAULT): ' -
       default 'DEFAULT'
accept force_matching -
       prompt 'Enter value for force_matching (FALSE): ' -
       default 'false'

declare
    ar_profile_hints   sys.sqlprof_attr;
    cl_sql_text        clob;
    l_profile_name     varchar2(30); 
begin
    select sql_fulltext
         , decode( '&&profile_name'
                 , 'X0X0X0X0' , 'PROF_&&sql_id1'||'_'||plan_hash_value
                 , '&&profile_name'
                 )
      into cl_sql_text
         , l_profile_name
     from v$sql
    where sql_id = '&&sql_id1'
      and child_number = &&child_no1;

    select   --extractvalue(value(d), '/hint') as outline_hints
           extractvalue(d.column_value, '/hint')    as outline_hints
      bulk collect into ar_profile_hints
      from xmltable( '/*/outline_data/hint' passing ( select xmltype(other_xml) as xmlval
                                                        from v$sql_plan
                                                       where sql_id = '&&sql_id2'
                                                         and child_number = &&child_no2
                                                         and other_xml is not null
                                                    )
                   ) d;

    dbms_sqltune.import_sql_profile( sql_text => cl_sql_text
                                   , profile => ar_profile_hints
                                   , category => '&&category'
                                   , name => l_profile_name
                                   , force_match => &&force_matching
                                   -- replace => true
                                   );

    dbms_output.put_line(' ');
    dbms_output.put_line('SQL Profile '||l_profile_name||' created.');
    dbms_output.put_line(' ');

exception
when NO_DATA_FOUND then
  dbms_output.put_line(' ');
  dbms_output.put_line('ERROR: sql_id: '||'&&sql_id1'||' Child: '||'&&child_no1'||' not found in v$sql.');
  dbms_output.put_line(' ');
end;
/

undef sql_id1
undef child_no1
undef sql_id2
undef child_no2
undef profile_name
undef category
undef force_matching
