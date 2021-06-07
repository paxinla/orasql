/* 该脚本用来检测数据库用户为输入用户的正在被锁的对象
 * 及相关的进程、SQL_ID和等待事件等信息。
 */
     SELECT TO_CHAR(C.LOGON_TIME,'YYYY/MM/DD HH24:MM:SS') AS LOGIN_TIME
          , C.STATUS          AS LOCKER_STATUS
          , A.ORACLE_USERNAME AS ORA_USR_NAME
          , A.OS_USER_NAME    AS OS_USR_NAME
          , A.LOCKED_MODE     AS LOCK_MODE
          , B.OBJECT_NAME     AS LOCK_OBJECT
          , B.OBJECT_TYPE     AS LOCK_OBJECT_TYPE
          , C.PROCESS         AS LOCKER_PID
          , C.MACHINE
          ||'('||C.TERMINAL
          ||'):'||C.PORT
          ||'@'||C.SID
          ||'%'||C.SERIAL#    AS LOCKER_MACHINE
          , C.PROGRAM         AS LOCKER_PROC
          , C.EVENT#||'#'||C.EVENT AS LOCKER_WAIT_EVENT
          , C.SQL_ID          AS LOCKER_SQL_ID
          , C.SQL_HASH_VALUE  AS LOCKED_SQL_HASHVAL
       FROM V$LOCKED_OBJECT A
  LEFT JOIN USER_OBJECTS B
              ON B.OBJECT_ID = A.OBJECT_ID
  LEFT JOIN V$SESSION C
              ON C.PROCESS = A.PROCESS
      WHERE A.ORACLE_USERNAME = '&ORA_USR'
      ;
