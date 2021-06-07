/*查询指定表空间的使用情况*/
    SELECT t.tablespace_name           AS NAME
         , d.allocated                 AS ALLOCATED
         , u.used                      AS USED
         , f.free                      AS FREE
         , t.status                    AS STATUS
         , d.cnt                       AS CNT
         , t.contents                  AS CONTENTS
         , t.extent_management         AS extman
         , t.segment_space_management  AS segman
      FROM dba_tablespaces t
         , ( SELECT SUM(bytes)      AS ALLOCATED
                  , COUNT(file_id)  AS CNT
               FROM dba_data_files
              WHERE tablespace_name = '&1'
           ) d
         , ( SELECT SUM(bytes)      AS FREE
               FROM dba_free_space
              WHERE tablespace_name = '&1'
           ) f
         , ( SELECT SUM(bytes)      AS USED
               FROM dba_segments
              WHERE tablespace_name = '&1'
           ) u
     WHERE t.tablespace_name = '&1';
