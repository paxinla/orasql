CREATE OR REPLACE FUNCTION FUNC_CINDATE( DATESTR IN VARCHAR2
                                       , START_DATE IN VARCHAR2
                                       , END_DATE IN VARCHAR2
                                       , DATE_FMT IN VARCHAR2 DEFAULT 'YYYYMMDD')
RETURN NUMBER
IS
/***********************************************************************************
        功  能       :  判断一个表示日期的字符串所表示的日期是否在一个给定的日期
                        区间内。
        日  期       :  2012-11-21
        作  者       :  PXL
        使用范例     :  FUNC_CINDATE('20110904','20101123','20120502','YYYYMMDD')
        输入参数说明 :  第一个参数 DATESTR 表示要判断的字符串，其内容应表示一个日期，
                       第二个参数 START_DATE 表示日期区间的起始日期，
                       第三个参数 END_DATE 表示日期区间的结束日期，
                       第四个参数 DATE_FMT 表示日期字符串的格式。
        输出参数说明 :  返回 0 表示判断对象日期在指定日期区间内，且合法；
                       返回 1 表示输入的字符串不合法；
                       返回 2 表示判断对象合法，但比指定日期区间小；
                       返回 3 表示判断对象合法，但比指定日期区间大；
                       返回 -1 其他错误。
  ===================================================================================
      功能说明  :   判断一个内容符合日期格式的字符串是否在指定日期区间内，
                   如：201100904 在 区间 20101123-20120502内，同时要检验该字符串是否
                   合法，如 20120631 就是不合法的。
      其他说明  :
  ================================ 异动记录 =========================================
     修改日期:
     修改人员:
     异动原因:
  ===================================================================================
  ********************************************************************************/

  V_DATE DATE;           --判断对象字符串转换成的日期
  V_STARTDATE DATE;      --日期区间起始日期字符串转换成的日期
  V_ENDDATE DATE;        --日期区间结束日期字符串转换成的日期

  TRANS_DATE_ERROR_MONTH01 EXCEPTION; --该异常关联系统错误ORA-01839
  PRAGMA EXCEPTION_INIT( TRANS_DATE_ERROR_MONTH01, -1839);
  TRANS_DATE_ERROR_MONTH02 EXCEPTION; --该异常关联系统错误ORA-01843
  PRAGMA EXCEPTION_INIT( TRANS_DATE_ERROR_MONTH02, -1843);

BEGIN

    V_DATE := TO_DATE( DATESTR, DATE_FMT );
    V_STARTDATE := TO_DATE( START_DATE, DATE_FMT );
    V_ENDDATE := TO_DATE( END_DATE, DATE_FMT );

    IF V_DATE BETWEEN V_STARTDATE AND V_ENDDATE
       THEN RETURN 0;
 ELSIF ( V_STARTDATE - V_DATE ) > 0
       THEN RETURN 2;
 ELSIF ( V_DATE - V_ENDDATE ) > 0
       THEN RETURN 3;
  ELSE RETURN -1;
   END IF;

EXCEPTION
    WHEN TRANS_DATE_ERROR_MONTH01
         THEN RETURN 1;
    WHEN TRANS_DATE_ERROR_MONTH02
         THEN RETURN 1;
    WHEN OTHERS
         THEN RETURN -1;
END;
/
