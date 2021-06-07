CREATE OR REPLACE PACKAGE GX_PAK_LOG
AS
/***********************************************************************************
        功  能  ：  XX监管报表日志记录包
        日  期  ：  2013-04-11
        作  者  ：  PXL

  ================================ 异动记录 =========================================
     修改日期:
     修改人员:
     异动原因:
  ===================================================================================
  ********************************************************************************/

    L_V_USR_NM          VARCHAR2(15);   --用户名
    L_V_PROC_NM         VARCHAR2(25);   --例程名
    L_V_PROC_TYPE       VARCHAR2(20);   --例程类型

    PROCEDURE LOG_START( P_OUT_SEQ  OUT NUMBER );     --开始记录日志
    PROCEDURE LOG_WRITE(  P_IN_SEQ       IN NUMBER
                        , P_IN_SQLCODE   IN VARCHAR2    --阶段写入日志
                        , P_IN_SQLERRM   IN VARCHAR2 
                        , P_IN_SQLROWS   IN VARCHAR2
                        , P_IN_SUBNM     IN VARCHAR2 DEFAULT NULL
                        , P_IN_T_POS     IN INTEGER  DEFAULT 2
                       );
    PROCEDURE LOG_STOP(   P_IN_SEQ       IN NUMBER
                        , P_IN_SQLCODE   IN VARCHAR2
                        , P_IN_SQLERRM   IN VARCHAR2);      --结束记录日志
    PROCEDURE LOG_PARAM( P_OUT_USR_NM    OUT VARCHAR2
                       , P_OUT_PROC_NM   OUT VARCHAR2
                       , P_OUT_PROC_TYPE OUT VARCHAR2
                       );    --获取相应参数

END GX_PAK_LOG;


--==================================================================================

CREATE OR REPLACE PACKAGE BODY GX_PAK_LOG
AS
/***********************************************************************************
        功  能  ：  为XX监管报表存储过程执行提供日志记录功能
        日  期  ：  2013-04-11
        作  者  ：  PXL
        使用范例：  1、 存储过程中需设置变量 L_N_LOGSEQ  NUMBER;  --日志记录用
                   2、 在存储过程的 BEGIN 后加上
                         GX_PAK_LOG.LOG_START( L_N_LOGSEQ );
                   3、 在存储过程内部需要的地方加上
                         GX_PAK_LOG.LOG_WRITE( L_N_LOGSEQ
                                             , SQLCODE
                                             , SQLERRM
                                             , SQL%ROWCOUNT
                                             , 'INSERT_INVM'   <--语句块名,可为NULL
                                             , 1            <--1表示为开始,2表示结束
                                             );
                   4、 在存储过程结尾的 END 前(EXCEPTION 前)加上
                         GX_PAK_LOG.LOG_STOP(  L_N_LOGSEQ 
                                             , SQLCODE
                                             , SQLERRM 
                                             );
                           
  ================================ 异动记录 =========================================
     修改日期:
     修改人员:
     异动原因:
  ===================================================================================
  ********************************************************************************/

    PROCEDURE LOG_START( P_OUT_SEQ  OUT NUMBER )
    /*
     *    在存储过程的开头调用此过程
     */
    IS
        L_ST_TIME   DATE;
    BEGIN
            LOG_PARAM( L_V_USR_NM, L_V_PROC_NM, L_V_PROC_TYPE );

            SELECT SYSDATE
              INTO L_ST_TIME
              FROM DUAL;

            P_OUT_SEQ := GX_SEQ_LOG.NEXTVAL;

            --写入日志
            INSERT /*+ APPEND*/ INTO GX_LOG_FIL NOLOGGING ( LOG_DATE, LOG_SEQ, USER_NAME
                                                          , OBJ_NAME, OBJ_TYPE, START_TIME
                                                          , END_TIME, ACT_STATUS, LOG_MSG )
            SELECT
                     TO_CHAR(L_ST_TIME,'YYYYMMDD')        AS  LOG_DATE
                   , P_OUT_SEQ                            AS  LOG_SEQ
                   , L_V_USR_NM                           AS  USER_NAME
                   , L_V_PROC_NM                          AS  OBJ_NAME
                   , L_V_PROC_TYPE                        AS  OBJ_TYPE
                   , L_ST_TIME                            AS  START_TIME
                   , TO_DATE('99991231','YYYY-MM-DD')     AS  END_TIME
                   , '0'                                  AS  ACT_STATUS
                   , 'LOG MESSAGE:  AT ' || TO_CHAR(L_ST_TIME, 'YYYY-MM-DD HH:MI:SS')
                   ||CHR(10)
                   ||'       PROC: ' || L_V_PROC_NM || ' START RUNNIING' AS LOG_MSG
              FROM DUAL;
            COMMIT;
    END;


    PROCEDURE LOG_WRITE ( P_IN_SEQ       IN NUMBER
                        , P_IN_SQLCODE   IN VARCHAR2    --阶段写入日志
                        , P_IN_SQLERRM   IN VARCHAR2
                        , P_IN_SQLROWS   IN VARCHAR2
                        , P_IN_SUBNM     IN VARCHAR2 DEFAULT NULL
                        , P_IN_T_POS     IN INTEGER  DEFAULT 2
                        )
    /*
     *   在存储过程未结束前可多次调用该过程
     */
    IS
        L_D_WDATE DATE;
    BEGIN
            SELECT SYSDATE
              INTO L_D_WDATE
              FROM DUAL;

            LOG_PARAM( L_V_USR_NM, L_V_PROC_NM, L_V_PROC_TYPE );

            INSERT /*+ APPEND*/ INTO GX_LOG_FIL NOLOGGING ( LOG_DATE, LOG_SEQ, USER_NAME
                                                          , OBJ_NAME, OBJ_TYPE, START_TIME
                                                          , END_TIME, ACT_STATUS, LOG_MSG )
            SELECT
                     TO_CHAR(L_D_WDATE,'YYYYMMDD')        AS  LOG_DATE
                   , P_IN_SEQ                             AS  LOG_SEQ
                   , L_V_USR_NM                           AS  USER_NAME
                   , L_V_PROC_NM
                     || NVL2( P_IN_SUBNM
                            , '.'||P_IN_SUBNM
                            , '')                         AS  OBJ_NAME
                   , L_V_PROC_TYPE                        AS  OBJ_TYPE
                   , CASE P_IN_T_POS WHEN 1
                                     THEN L_D_WDATE
                                     ELSE NULL
                     END                                  AS  START_TIME
                   , CASE P_IN_T_POS WHEN 2
                                     THEN L_D_WDATE
                                     ELSE NULL
                     END                                  AS  END_TIME
                   , CASE P_IN_SQLCODE WHEN '0'
                                       THEN '1'
                                       WHEN NULL
                                       THEN NULL
                                       ELSE '2'
                     END                                  AS  ACT_STATUS
                   , 'LOG MESSAGE:  AT ' || TO_CHAR(L_D_WDATE, 'YYYY-MM-DD HH:MI:SS')
                   ||CHR(10)
                   ||'       PROC: ' || L_V_PROC_NM||NVL2(P_IN_SUBNM,L_V_PROC_NM||'.'||P_IN_SUBNM,'')
                   ||CHR(10)
                   ||'   SQL_CODE: ' || P_IN_SQLCODE
                   ||CHR(10)
                   ||' SQL_ERRNUM: ' || P_IN_SQLERRM      
                   ||CHR(10)
                   ||'IMPACT ROWS: ' || P_IN_SQLROWS      AS  LOG_MSG
              FROM DUAL;
            COMMIT;

    END;

    PROCEDURE LOG_STOP(   P_IN_SEQ       IN NUMBER
                        , P_IN_SQLCODE   IN VARCHAR2
                        , P_IN_SQLERRM   IN VARCHAR2)
    /*
     *      更新存储过程执行记录
     */
    IS
        L_D_EDATE     DATE;
        L_C_TBLIST    CLOB;
    BEGIN
            SELECT SYSDATE
              INTO L_D_EDATE
              FROM DUAL;

            LOG_PARAM( L_V_USR_NM, L_V_PROC_NM, L_V_PROC_TYPE );

            SELECT
                   LISTAGG(T.REFERENCED_OWNER||'.'||T.REFERENCED_NAME,',')
                   WITHIN GROUP (ORDER BY NULL)
              INTO L_C_TBLIST
              FROM ALL_DEPENDENCIES T
             WHERE T.REFERENCED_TYPE = 'TABLE'
               AND T.OWNER = L_V_USR_NM
               AND T.NAME = L_V_PROC_NM;

            UPDATE GX_LOG_FIL DST
               SET   DST.END_TIME    =   L_D_EDATE
                   , DST.ACT_STATUS  =   DECODE(P_IN_SQLCODE,'0','1','2')
                   , DST.LOG_MSG     =   DST.LOG_MSG || CHR(10)
                                       ||'   SQL_CODE: ' || P_IN_SQLCODE
                                       ||CHR(10)
                                       ||' SQL_ERRNUM: ' || P_IN_SQLERRM
                                       ||CHR(10)
                                       ||'     TABLES: ' || L_C_TBLIST
             WHERE DST.LOG_SEQ = P_IN_SEQ
               AND DST.END_TIME = TO_DATE('99991231','YYYY-MM-DD')
               AND DST.LOG_DATE = TO_CHAR(L_D_EDATE,'YYYYMMDD');
            COMMIT;

    END;

    PROCEDURE LOG_PARAM ( P_OUT_USR_NM    OUT VARCHAR2
                        , P_OUT_PROC_NM   OUT VARCHAR2
                        , P_OUT_PROC_TYPE OUT VARCHAR2
                        )
    /*
     *     获取日志参数
     */
    IS
    BEGIN
            --获取当前用户名
            SELECT USER
              INTO L_V_USR_NM
              FROM DUAL;
            P_OUT_USR_NM := L_V_USR_NM;

            --获取例程名
            SELECT
                   SUBSTR( REGEXP_SUBSTR( TO_CHAR(DBMS_UTILITY.FORMAT_CALL_STACK)
                                        , L_V_USR_NM || '.*'
                                        , 1
                                        , 3
                                        )
                         , LENGTH( L_V_USR_NM ) + 2
                         , LENGTH(
                                    REGEXP_SUBSTR( TO_CHAR(DBMS_UTILITY.FORMAT_CALL_STACK)
                                                 , L_V_USR_NM || '.*'
                                                 , 1
                                                 , 3
                                                 )
                                 ) - LENGTH( L_V_USR_NM ) - 1
                         )
              INTO L_V_PROC_NM
              FROM DUAL;
              P_OUT_PROC_NM := L_V_PROC_NM;

            --获取例程类型
            SELECT OBJECT_TYPE
              INTO L_V_PROC_TYPE
              FROM ALL_OBJECTS
             WHERE OWNER = L_V_USR_NM
               AND OBJECT_NAME = L_V_PROC_NM;
             P_OUT_PROC_TYPE := L_V_PROC_TYPE;

    END;

END GX_PAK_LOG;

