CREATE OR REPLACE FUNCTION STR2MD5 ( INPUT_STRING VARCHAR2)
--===================================================================================
--撰寫日期  : 2013/03/04
--撰寫人員  : PXL
--功能描述  : 将输入的字符串用MD5加密，并返回加密结果
--输入类型  : varchar2
--返回类型  : varchar2
--===================================================================================
--異動記錄 
--===================================================================================
--修改日期:
--修改人員:
--異動原因:
--===================================================================================
RETURN VARCHAR2
IS

       RESULT_STRING VARCHAR2(50);

BEGIN

       RESULT_STRING := RAWTOHEX(DBMS_OBFUSCATION_TOOLKIT.MD5(input => UTL_RAW.CAST_TO_RAW(INPUT_STRING)));
       RETURN RESULT_STRING;

END STR2MD5;
/
