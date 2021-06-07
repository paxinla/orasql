DECLARE
      V_TEST VARCHAR2(10);
      TEST_ERR EXCEPTION;			--自定义异常
      
BEGIN
      V_TEST := '201211092';


      IF LENGTH(V_TEST) <> 8 THEN	--自定义规则
         RAISE TEST_ERR;
      END IF;
      
EXCEPTION
      WHEN TEST_ERR 		--自定义异常触发时操作
	  THEN RAISE_APPLICATION_ERROR(-20007,'传入的日期（' || V_TEST ||'）错误，合法格式为：yyyymmdd!');

END;

