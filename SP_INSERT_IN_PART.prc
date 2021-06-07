CREATE OR REPLACE PROCEDURE SP_INSERT_IN_PART ( P_IC_FTABLE IN VARCHAR2
                                              , P_IC_ITABLE IN VARCHAR2
                                              , P_IC_DATE   IN VARCHAR2
                                              , P_IN_STEP   IN INTEGER DEFAULT 3000000
                                              )
IS
/***********************************************************************************
        功  能  ：
        日  期  ：  2013-09-22
        作  者  ：  PXL
        使用范例：  SP_INSERT_IN_PART( 'BANCS_INVM_1'
                                     , 'TEMP_BANCS_INVM_1'
                                     , '20130922'
                                     );

  ===================================================================================
      参数说明  ：
        1、P_IC_FTABLE    目标全量表
        2、P_IC_ITABLE    增量表


  ================================ 异动记录 =========================================
     修改日期:
     修改人员:
     异动原因:
  ===================================================================================
  ********************************************************************************/

  L_VN_FTB_EXIST       NUMBER;          -- 全量表存在检测
  L_VN_ITB_EXIST       NUMBER;          -- 增量表存在检测
  L_VN_TMP_ITB_EXIST   NUMBER;          -- 临时增量表存在检测
  L_CC_LINE_SEP        CONSTANT CHAR(1)   := CHR(10);    --换行符

  L_VC_FTABLE          VARCHAR2(100);   -- 全量表名
  L_VC_ITABLE          VARCHAR2(100);   -- 增量表名
  L_VC_TMP_ITABLE      VARCHAR2(100);   -- 临时增量表名

  L_VC_FIDX_LST        VARCHAR2(1000);  -- 全量表索引列表
  L_VC_FPK_LST         CLOB;            -- 全量表主键列表
  L_VC_FPK_NM          VARCHAR2(20);    -- 全量表主键名
  L_VC_FPK_DDL         CLOB;            -- 全量表主键DDL
  L_VC_IPK_LST         CLOB;            -- 增量表主键列表
  L_VC_ON_PKS          CLOB;            -- 全量表和增量表的连接条件

  L_VN_PART_WIDTH      NUMBER;          -- 插入区间长度
  L_VN_PART_BEGIN      CONSTANT NUMBER  := 1; -- 插入区间开始
  L_VN_PART_END        NUMBER;          -- 插入区间结尾
  L_VR_PART_SPOINT   TMP_PART_INSERT%ROWTYPE;    -- 插入分区间的开头
  L_VR_PART_EPOINT   TMP_PART_INSERT%ROWTYPE;    -- 插入分区间的结尾

  L_VC_SQL             CLOB;            -- 动态SQL语句
  TYPE ROW_CURSOR IS REF CURSOR;
  L_VCUR_FROWID        ROW_CURSOR;      -- 全量表插入区间列表
  L_VCUR_IROWID        ROW_CURSOR;      -- 增量表插入区间列表
  L_VCUR_FINDEX        ROW_CURSOR;      -- 全量表索引列表

  /*自定义异常信息*/
  L_VE_TB_NM_WRONG_ERROR       EXCEPTION;    -- 表名错误
  L_VE_PK_MATCH_ERROR          EXCEPTION;    -- 主键不匹配异常

BEGIN

--================================ 初始化工作 ====================================
        /* 初始化本地参数 */
        L_VC_FTABLE       := UPPER(P_IC_FTABLE);
        L_VC_ITABLE       := UPPER(P_IC_ITABLE);
        L_VC_TMP_ITABLE   := L_VC_ITABLE||'_'||P_IC_DATE;
        L_VN_PART_WIDTH   := NVL( P_IN_STEP, 3000000 );  -- 默认以300万条记录为一个分段

        /* 传入参数检查 */
        SELECT COUNT(1)
          INTO L_VN_FTB_EXIST
          FROM USER_TABLES UT
         WHERE UT.TABLE_NAME = L_VC_FTABLE;
        SELECT COUNT(1)
          INTO L_VN_ITB_EXIST
          FROM USER_TABLES UT
         WHERE UT.TABLE_NAME = L_VC_ITABLE;

        IF ( L_VN_FTB_EXIST = 0 OR L_VN_ITB_EXIST = 0 ) THEN
            RAISE L_VE_TB_NM_WRONG_ERROR;
        END IF;


        /* 分别比较增量表、全量表的主键是否相同，不同则报错 */
        SELECT WMSYS.WM_CONCAT(COLUMN_NAME)
          INTO L_VC_FPK_LST
          FROM USER_CONS_COLUMNS
         WHERE CONSTRAINT_NAME = (SELECT CONSTRAINT_NAME
                                    FROM USER_CONSTRAINTS
                                   WHERE TABLE_NAME = L_VC_FTABLE
                                     AND CONSTRAINT_TYPE = 'P'
                                  );

        SELECT WMSYS.WM_CONCAT(COLUMN_NAME)
          INTO L_VC_IPK_LST
          FROM USER_CONS_COLUMNS
         WHERE CONSTRAINT_NAME = (SELECT CONSTRAINT_NAME
                                    FROM USER_CONSTRAINTS
                                   WHERE TABLE_NAME =  L_VC_ITABLE
                                     AND CONSTRAINT_TYPE = 'P'
                                  );

        IF L_VC_FPK_LST <> L_VC_IPK_LST THEN
            RAISE L_VE_PK_MATCH_ERROR;
        END IF;

        /* 生成全量表和增量表的连接条件 */
        SELECT LISTAGG( 'DST.'||A.COLUMN_NAME||' = SRC.'||A.COLUMN_NAME||L_CC_LINE_SEP
                      , ' AND ')
               WITHIN GROUP(ORDER BY A.POSITION)
          INTO L_VC_ON_PKS
          FROM USER_CONS_COLUMNS A
         WHERE A.CONSTRAINT_NAME = (SELECT B.CONSTRAINT_NAME
                                      FROM USER_CONSTRAINTS B
                                     WHERE B.TABLE_NAME = L_VC_FTABLE
                                       AND B.CONSTRAINT_TYPE = 'P'
                                   );
                                   
        /* 建立临时增量表，结构与全量表相同 */
        SELECT COUNT(1)
          INTO L_VN_TMP_ITB_EXIST
          FROM USER_TABLES UT
         WHERE UT.TABLE_NAME = L_VC_TMP_ITABLE;

        IF L_VN_TMP_ITB_EXIST <> 0 THEN
            EXECUTE IMMEDIATE 'DROP TABLE ' || L_VC_TMP_ITABLE;
        END IF;

        L_VC_SQL := 'CREATE TABLE ' || L_VC_TMP_ITABLE
                 || ' AS SELECT * FROM ' || L_VC_FTABLE || ' WHERE 1 = 2';
        EXECUTE IMMEDIATE L_VC_SQL;


--============================= 分段插入数据 =================================
        -- 插入在全量表不在增量表的数据到临时表中
        /* 确定区间ROWID */
        L_VC_SQL := ' SELECT COUNT(1) '
                 || '   FROM '|| L_VC_FTABLE ||' DST '
                 || '  WHERE NOT EXISTS(SELECT 1 '
                 || '                     FROM '|| L_VC_ITABLE ||' SRC '
                 || '                    WHERE '|| L_VC_ON_PKS || ' )';
        EXECUTE IMMEDIATE L_VC_SQL INTO L_VN_PART_END;

        DBMS_OUTPUT.PUT_LINE('在全量表不在增量表记录数: '||L_VN_PART_END);

        EXECUTE IMMEDIATE 'TRUNCATE TABLE TMP_PART_INSERT';

        L_VC_SQL := 'INSERT /*+ APPEND*/ INTO TMP_PART_INSERT NOLOGGING ( PART_ID, PART_POINT )'
                 || 'SELECT   TT.CNT '
                 || '       , TT.ROWID ' 
                 || '  FROM ( SELECT DST.ROWID,ROW_NUMBER()OVER(ORDER BY DST.ROWID) CNT'
                 || '           FROM ' || L_VC_FTABLE || ' DST '
                 || '          WHERE NOT EXISTS(SELECT 1'
                 || '                             FROM ' || L_VC_ITABLE || ' SRC '
                 || '                            WHERE ' || L_VC_ON_PKS || ' )'
                 || '       )TT '
                 || ' WHERE MOD(TT.CNT, '||L_VN_PART_WIDTH||' ) = 0'
                 || '    OR TT.CNT IN ( '||L_VN_PART_BEGIN|| ' , '||L_VN_PART_END||' )';
        EXECUTE IMMEDIATE L_VC_SQL;
        COMMIT;

        /*  分段的头尾为 ‘1’ 和 ‘最大记录数’，中间每段插入的分段是一个左闭右开的区间。
         *  所以最后的分段的结束点的记录需要额外处理，单独插入。
         */
        OPEN L_VCUR_FROWID
         FOR SELECT PART_ID, PART_POINT
               FROM TMP_PART_INSERT;

        FETCH L_VCUR_FROWID
         INTO L_VR_PART_EPOINT;
        
        LOOP
            L_VR_PART_SPOINT := L_VR_PART_EPOINT;  -- 每个分段的起始点是上个分段的结束点

            FETCH L_VCUR_FROWID
             INTO L_VR_PART_EPOINT;
            EXIT WHEN L_VCUR_FROWID%NOTFOUND;

            L_VC_SQL := 'INSERT /*+ APPEND*/ INTO '||L_VC_TMP_ITABLE||' NOLOGGING '
                     || 'SELECT * FROM ' || L_VC_FTABLE || ' DST WHERE NOT EXISTS( '
                     || 'SELECT 1 FROM ' || L_VC_ITABLE || ' SRC WHERE '|| L_VC_ON_PKS
                     || ' ) AND DST.ROWID >= ''' || L_VR_PART_SPOINT.PART_POINT
                     || ''' AND DST.ROWID < ''' || L_VR_PART_EPOINT.PART_POINT || '''';
            EXECUTE IMMEDIATE L_VC_SQL;
            DBMS_OUTPUT.PUT_LINE('插入分段: '||L_VR_PART_SPOINT.PART_ID||' -- '
                                             ||L_VR_PART_EPOINT.PART_ID
                                );
            COMMIT;
        
        END LOOP;
        
        L_VC_SQL := 'INSERT /*+ APPEND*/ INTO '||L_VC_TMP_ITABLE||' NOLOGGING '
                 || 'SELECT * FROM ' || L_VC_FTABLE || ' DST WHERE NOT EXISTS( '
                 || 'SELECT 1 FROM ' || L_VC_ITABLE || ' SRC WHERE '|| L_VC_ON_PKS
                 || ' ) AND DST.ROWID = ''' || L_VR_PART_SPOINT.PART_POINT || '''';
        EXECUTE IMMEDIATE L_VC_SQL;
        DBMS_OUTPUT.PUT_LINE('插入记录: '||L_VR_PART_SPOINT.PART_ID);
        COMMIT;
        
        CLOSE L_VCUR_FROWID;


        -- 插入增量表的数据到临时表中
        L_VC_SQL := ' SELECT COUNT(1) '
                 || '   FROM '|| L_VC_ITABLE;
        EXECUTE IMMEDIATE L_VC_SQL INTO L_VN_PART_END;

        DBMS_OUTPUT.PUT_LINE('增量表记录数: '||L_VN_PART_END);

        EXECUTE IMMEDIATE 'TRUNCATE TABLE TMP_PART_INSERT';

        L_VC_SQL := 'INSERT /*+ APPEND*/ INTO TMP_PART_INSERT NOLOGGING ( PART_ID, PART_POINT )'
                 || 'SELECT   TT.CNT '
                 || '       , TT.ROWID ' 
                 || '  FROM ( SELECT DST.ROWID,ROW_NUMBER()OVER(ORDER BY DST.ROWID) CNT'
                 || '           FROM ' || L_VC_ITABLE || ' DST '
                 || '       )TT '
                 || ' WHERE MOD(TT.CNT, '||L_VN_PART_WIDTH||' ) = 0'
                 || '    OR TT.CNT IN ( '||L_VN_PART_BEGIN||' , '||L_VN_PART_END||' )';
        EXECUTE IMMEDIATE L_VC_SQL;
        COMMIT;

        /*  分段的头尾为 ‘1’ 和 ‘最大记录数’，中间每段插入的分段是一个左闭右开的区间。
         *  所以最后的分段的结束点的记录需要额外处理，单独插入。
         */
        OPEN L_VCUR_IROWID
         FOR SELECT PART_ID, PART_POINT
               FROM TMP_PART_INSERT;

        FETCH L_VCUR_IROWID
         INTO L_VR_PART_EPOINT;

        LOOP
            L_VR_PART_SPOINT := L_VR_PART_EPOINT;  -- 每个分段的起始点是上个分段的结束点

            FETCH L_VCUR_IROWID
             INTO L_VR_PART_EPOINT;
            EXIT WHEN L_VCUR_IROWID%NOTFOUND;

            L_VC_SQL := 'INSERT /*+ APPEND*/ INTO '||L_VC_TMP_ITABLE||' NOLOGGING '
                     || 'SELECT * FROM ' || L_VC_ITABLE || ' SRC '
                     || ' WHERE SRC.ROWID >= ''' || L_VR_PART_SPOINT.PART_POINT
                     || '''   AND SRC.ROWID < ''' || L_VR_PART_EPOINT.PART_POINT || '''';
            EXECUTE IMMEDIATE L_VC_SQL;
            DBMS_OUTPUT.PUT_LINE('插入分段: '||L_VR_PART_SPOINT.PART_ID||' -- '
                                             ||L_VR_PART_EPOINT.PART_ID
                                );
            COMMIT;

        END LOOP;
        
        L_VC_SQL := 'INSERT /*+ APPEND*/ INTO '||L_VC_TMP_ITABLE||' NOLOGGING '
                 || 'SELECT * FROM ' || L_VC_ITABLE || ' SRC '
                 || ' WHERE SRC.ROWID = ''' || L_VR_PART_SPOINT.PART_POINT|| '''';
        EXECUTE IMMEDIATE L_VC_SQL;
        DBMS_OUTPUT.PUT_LINE('插入记录: '||L_VR_PART_SPOINT.PART_ID);
        COMMIT;
        
        CLOSE L_VCUR_IROWID;


--========================== 插入数据完成后处理 ==============================
        -- 给临时表加索引，参考全量表的索引
        OPEN L_VCUR_FINDEX
         FOR SELECT DISTINCT INDEX_NAME
               FROM USER_INDEXES
              WHERE TABLE_NAME = L_VC_FTABLE;

        LOOP
             FETCH L_VCUR_FINDEX
              INTO L_VC_FIDX_LST;
             
             EXIT WHEN L_VCUR_FINDEX%NOTFOUND;
        
             SELECT    'CREATE INDEX ' || T.INDEX_NAME ||'_'||P_IC_DATE
                    || ' ON ' || L_VC_TMP_ITABLE
                    || ' ( ' || WMSYS.WM_CONCAT(T.COLUMN_NAME) || ' ) '
                    || ' TABLESPACE DS_INDX'
               INTO L_VC_SQL
               FROM USER_IND_COLUMNS T
              WHERE T.INDEX_NAME = L_VC_FIDX_LST
                AND T.TABLE_NAME = L_VC_FTABLE
              GROUP BY T.INDEX_NAME;

             EXECUTE IMMEDIATE L_VC_SQL;
             DBMS_OUTPUT.PUT_LINE('给临时表加索引: '||L_VC_SQL);

        END LOOP;
        CLOSE L_VCUR_FINDEX;

        -- 给临时表加主键，参考全量表的主键
        SELECT CONSTRAINT_NAME
          INTO L_VC_FPK_NM
          FROM USER_CONSTRAINTS
         WHERE TABLE_NAME = L_VC_FTABLE
           AND CONSTRAINT_TYPE = 'P';

        SELECT
                  'ALTER TABLE ' || L_VC_TMP_ITABLE
               || ' ADD CONSTRAINT ' || L_VC_FPK_NM ||'_'||P_IC_DATE||' '
               || SUBSTR( DBMS_METADATA.GET_DDL('CONSTRAINT', L_VC_FPK_NM)
                        , REGEXP_INSTR( DBMS_METADATA.GET_DDL('CONSTRAINT', L_VC_FPK_NM)
                                      , 'PRIMARY'
                                      )
                        , LENGTH(DBMS_METADATA.GET_DDL('CONSTRAINT', L_VC_FPK_NM))
                        )
          INTO L_VC_FPK_DDL
          FROM DUAL;

        EXECUTE IMMEDIATE L_VC_FPK_DDL;
        DBMS_OUTPUT.PUT_LINE('给临时表加主键' || L_VC_FPK_DDL);

        -- 重命名临时表为全量表，重命名全量表加上日期做备份
        L_VC_SQL := 'RENAME '|| L_VC_FTABLE ||' TO '|| L_VC_FTABLE||'_'||P_IC_DATE;
        EXECUTE IMMEDIATE L_VC_SQL;
        DBMS_OUTPUT.PUT_LINE(L_VC_SQL);

        L_VC_SQL := 'RENAME '|| L_VC_TMP_ITABLE ||' TO '|| L_VC_FTABLE;
        EXECUTE IMMEDIATE L_VC_SQL;
        DBMS_OUTPUT.PUT_LINE(L_VC_SQL);

--============================= 异常处理 =============================
EXCEPTION
        WHEN L_VE_PK_MATCH_ERROR
        THEN RAISE_APPLICATION_ERROR( -20078
                                    , '主键不匹配！'
                                    );

        WHEN L_VE_TB_NM_WRONG_ERROR
        THEN RAISE_APPLICATION_ERROR( -20079
                                    , '表不存在！'
                                    );

        WHEN OTHERS
        THEN RAISE;

END SP_INSERT_IN_PART;

