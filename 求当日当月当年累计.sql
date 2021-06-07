SELECT T.TRN_DATE          AS "数据日期"
     , T.AMT               AS "当日累计"
     , SUM(T.AMT)
       OVER(PARTITION BY TO_CHAR(T.TRN_DATE,'YYYYMM')
                ORDER BY T.TRN_DATE
           )               AS "当月累计"
     ,SUM(T.AMT)
      OVER(PARTITION BY TO_CHAR(T.TRN_DATE,'YYYY')
               ORDER BY T.TRN_DATE
          )                AS "当年累计"
  FROM pridata.TMP_SKY_4 T
