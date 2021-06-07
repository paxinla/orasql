/*��ȡ��ǰ�û��������ֵ�*/
     SELECT DISTINCT
            utb.table_name            AS "����"
          , utb.comments              AS "������ע��"
          , utbc.column_name          AS "�ֶ���"
          , ucc.comments              AS "�ֶ�����ע��"
          , utbc.column_id            AS "�ֶ����"
          , CASE WHEN utbc.char_length = 0
                  AND (utbc.data_scale IS NULL OR utbc.data_precision IS NULL)
                 THEN utbc.data_type
                 WHEN utbc.char_length = 0
                 THEN utbc.data_type||'('||utbc.data_precision||','||utbc.data_scale||')'
                 ELSE utbc.data_type||'('||utbc.char_length||')'
            END                       AS "�ֶ�����"
          , DECODE( utbc.nullable
                  , 'N', NULL
                  , utbc.nullable
                  )                   AS "�Ƿ��Ϊ��"
          , CASE WHEN c.column_name IS NOT NULL
                 THEN 'Y'
                 ELSE NULL
            END                       AS "�Ƿ�����"
       FROM (    SELECT u.table_name
                      , utm.comments
                      , p.constraint_name
                   FROM user_tables u
              LEFT JOIN user_tab_comments utm
                          ON utm.table_name = u.table_name
              LEFT JOIN user_constraints p
                          ON p.owner = USER
                         AND p.table_name = u.table_name
                         AND p.constraint_type = 'P'
                  WHERE u.table_name LIKE 'GX%'
            ) utb
  LEFT JOIN user_tab_columns utbc
              ON utbc.table_name = utb.table_name
  LEFT JOIN user_col_comments ucc
              ON ucc.table_name = utbc.table_name
             AND ucc.column_name = utbc.column_name
  LEFT JOIN user_cons_columns c
              ON c.owner = USER
             AND c.table_name = utb.table_name
             AND c.column_name = utbc.column_name
             AND c.constraint_name = utb.constraint_name
      ORDER BY utb.table_name, utbc.column_id    
