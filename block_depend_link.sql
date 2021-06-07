DECLARE

  V_STARTNODE VARCHAR2(200);  

  CURSOR L_STARTNODES IS SELECT DISTINCT A.UP_JOB_ID FROM TMP_DEPEND_PXL A;

BEGIN
         OPEN L_STARTNODES;
         LOOP
              FETCH L_STARTNODES INTO V_STARTNODE;
         EXIT WHEN L_STARTNODES%NOTFOUND;
              INSERT /*+ APPEND*/ INTO TMP_DEPEND_RS NOLOGGING ( LVL, DEPEND_LINK, DEPEND_ROOT )
              SELECT
                       LEVEL                                  AS   LVL
                     , CONNECT_BY_ROOT(T.UP_JOB_ID)           AS   DEPEND_ROOT		--结果树的根节点
                     , SYS_CONNECT_BY_PATH(T.JOB_ID,' <-- ')  AS   DEPEND_LINK		--非根节点依次拼接
                FROM TMP_DEPEND_PXL T
               START WITH T.UP_JOB_ID = V_STARTNODE				--结果树根节点
             CONNECT BY NOCYCLE PRIOR T.JOB_ID =  T.UP_JOB_ID;	--nocycle 表示消除树/图的环，prior 指定父节点的列
              COMMIT;
         END LOOP;
         CLOSE L_STARTNODES;    
END;

