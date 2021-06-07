## ==============================================================
## ���ܣ���ftp109��***Ŀ¼��ȡ��ҵ����µ�csv�ļ�����
##       86�����ʱ��XXX��ٽ�spool����
##       �Ľ��ѹΪtar.gz�ļ��ŵ�ҵ��Ŀ¼��
## ���ߣ�PXL    2013/03/01
## 
## ==============================================================

### �������� ###
  shlogdate=`date +"%Y%m%d"` 
  

######################## ���Ʊ��� ##########################################
### FTP������Ϣ��ͨ����FTP109###
FTP_IP=11.111.111.109
FTP_USER=ftpuser14
FTP_PASSWORD=da4u2t

### ָ��ҵ��Ŀ¼������Դ�ļ����ļ����е����ں�ҵ��Լ��ΪYYYYMMDD ###
SRC_FILE_PATH=/js
SRC_FILES=szit2013000940_${shlogdate}_D*.csv
### ָ�����ؽ���Ŀ¼,�����ָ�ڵ��Ȼ����ϵ� ###
LOCAL_PATH=/dwsrc/wrktmp/local
### ָ��sql*loadr�����ļ�Ŀ¼,�����ָ�ڵ��Ȼ����ϵ�;skip,direct�������������������� ###
CTL_FILE_PATH=/dwsys/mis/ctl/local
CTL_FILE_A=szit2013-000940_dg.ctl
DATA_FILE=szit2013000940_${shlogdate}_DS.csv
### ָ��spool�ļ�Ŀ¼,�����ָ�ڵ��Ȼ����ϵ�###
SPL_SQL_PATH=/dwsys/mis/proc/local
SPL_SQL=spool_szit2013-000940_mr.sql
SPL_FAIL_SQL=szit2013-000940_spool_fa.sql  ## spoolʧ����ʾ
# ����ļ�ѹ������
TAR_FILE= szit2013-000940_${shlogdate}.tar
# spool����ļ���
SPL_FAIL_FILE=szit2013-000940-������ʾ_${shlogdate}.csv    ## ����ʧ����ʾ��Ϣ��csv�ļ�
SPL_FILE=С��-szit2013-000940-XX��Υ��ǩ��֧Ʊ��Ʊ������-��λ��ͷ֧Ʊ_${shlogdate}.csv


### ���ݿ�������Ϣ###
DB_USER=misqry
DB_PASSWORD=this-is-secret
DB_ADDR=11.111.111.86/oramis




############################################################################
# BEGINNING OF MAIN
############################################################################
## ��ҵ��Ŀ¼����ļ�,����Լ�����ļ���
ftp -nv ${FTP_IP}<<END_FTP
user ${FTP_USER} ${FTP_PASSWORD}
binary
prompt off
bin
lcd ${LOCAL_PATH}
cd ${SRC_FILE_PATH}
mget ${SRC_FILES}
close
bye
END_FTP

### �жϱ���Ŀ¼���Ƿ��л�ȡ�����µ�����Դ�ļ�
### ���ȡ�������������δȡ�������ļ����˳�
if [ ! -f ${SRC_FILES} ]
then
	exit 0
fi

### sql*loader װ���ļ�
sqlldr ${DB_USER}/${DB_PASSWORD}@${DB_ADDR} control=${CTL_FILE_PATH}/${CTL_FILE_A} data=${LOCAL_PATH}/${DATA_FILE} bad=${LOCAL_PATH}/${DATA_FILE}.BAD log=${LOCAL_PATH}/${DATA_FILE}.log skip=1 no_index_errors=true errors=10000
ldr_status_a=$?


if [ ${ldr_status_a} -eq 0 ] 
then   
### װ�سɹ�����spoolȡ�������ҵ��Ŀ¼��
sqlplus ${DB_USER}/${DB_PASSWORD}@${DB_ADDR} @${SPL_SQL_PATH}/${SPL_SQL} ${shlogdate}

cd ${LOCAL_PATH}
tar -cvf ${TAR_FILE} ${SPL_FILE}
gzip ${TAR_FILE} 

### FTP����ļ��͵�ҵ��Ŀ¼��
ftp -nv ${FTP_IP}<<END_FTP
user ${FTP_USER} ${FTP_PASSWORD}
binary
prompt off
bin
lcd ${LOCAL_PATH}
cd ${SRC_FILE_PATH}
mput "${TAR_FILE}.gz"
close
bye
END_FTP

  return 0
### װ��ʧ������ҵ��Ŀ¼��������
else
sqlplus ${DB_USER}/${DB_PASSWORD}@${DB_ADDR} @${SPL_SQL_PATH}/${SPL_FAIL_SQL} ${shlogdate}

ftp -nv ${FTP_IP}<<END_FTP
user ${FTP_USER} ${FTP_PASSWORD}
binary
prompt off
bin
lcd ${LOCAL_PATH}
cd ${SRC_FILE_PATH}
mput ${SPL_FAIL_FILE}
close
bye
END_FTP
  return 0
fi

###########################################################################################
# END OF THE SCRIPT
###########################################################################################
