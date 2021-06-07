CREATE OR REPLACE FUNCTION FUNC_CINDATE( DATESTR IN VARCHAR2
                                       , START_DATE IN VARCHAR2
                                       , END_DATE IN VARCHAR2
                                       , DATE_FMT IN VARCHAR2 DEFAULT 'YYYYMMDD')
RETURN NUMBER
IS
/***********************************************************************************
        ��  ��       :  �ж�һ����ʾ���ڵ��ַ�������ʾ�������Ƿ���һ������������
                        �����ڡ�
        ��  ��       :  2012-11-21
        ��  ��       :  PXL
        ʹ�÷���     :  FUNC_CINDATE('20110904','20101123','20120502','YYYYMMDD')
        �������˵�� :  ��һ������ DATESTR ��ʾҪ�жϵ��ַ�����������Ӧ��ʾһ�����ڣ�
                       �ڶ������� START_DATE ��ʾ�����������ʼ���ڣ�
                       ���������� END_DATE ��ʾ��������Ľ������ڣ�
                       ���ĸ����� DATE_FMT ��ʾ�����ַ����ĸ�ʽ��
        �������˵�� :  ���� 0 ��ʾ�ж϶���������ָ�����������ڣ��ҺϷ���
                       ���� 1 ��ʾ������ַ������Ϸ���
                       ���� 2 ��ʾ�ж϶���Ϸ�������ָ����������С��
                       ���� 3 ��ʾ�ж϶���Ϸ�������ָ�����������
                       ���� -1 ��������
  ===================================================================================
      ����˵��  :   �ж�һ�����ݷ������ڸ�ʽ���ַ����Ƿ���ָ�����������ڣ�
                   �磺201100904 �� ���� 20101123-20120502�ڣ�ͬʱҪ������ַ����Ƿ�
                   �Ϸ����� 20120631 ���ǲ��Ϸ��ġ�
      ����˵��  :
  ================================ �춯��¼ =========================================
     �޸�����:
     �޸���Ա:
     �춯ԭ��:
  ===================================================================================
  ********************************************************************************/

  V_DATE DATE;           --�ж϶����ַ���ת���ɵ�����
  V_STARTDATE DATE;      --����������ʼ�����ַ���ת���ɵ�����
  V_ENDDATE DATE;        --����������������ַ���ת���ɵ�����

  TRANS_DATE_ERROR_MONTH01 EXCEPTION; --���쳣����ϵͳ����ORA-01839
  PRAGMA EXCEPTION_INIT( TRANS_DATE_ERROR_MONTH01, -1839);
  TRANS_DATE_ERROR_MONTH02 EXCEPTION; --���쳣����ϵͳ����ORA-01843
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
