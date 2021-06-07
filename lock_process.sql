col SERIAL# format 999999
col sid format 99999
col username format a10
col machine format a12
col program format a32
col sql_text format a100
set lines 9000
set pages 9000
set verify off
col sql_hash_value new_value hash_value head hash_value
select sid,serial#,username,status,program,machine,sql_hash_value,sql_id,
   to_char(logon_time,'yyyy/mm/dd hh24:mm:ss') as login_time
from v$session 
where sid=<sid>; 

select sql_text
from v$sqltext
where (hash_value, address) in
   (select sql_hash_value,sql_address
    from v$session
     where sid=<sid>)
 order by address,piece;


=========================
select ses.sid 
from v$session ses,v$process pro
where pro.spid=<ospid>
and ses.paddr=pro.addr;