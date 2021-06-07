## ==============================================================
## 功能：在ftp109的***目录中取出业务更新的csv文件导入
##       86库的临时表XXX里，再将spool出来
##       的结果压为tar.gz文件放到业务目录下
## 作者：PXL    2013/03/01
## 
## ==============================================================

### 今日日期 ###
  shlogdate=`date +"%Y%m%d"` 
  

######################## 控制变量 ##########################################
### FTP配置信息，通常在FTP109###
FTP_IP=11.111.111.109
FTP_USER=ftpuser14
FTP_PASSWORD=da4u2t

### 指定业务目录和数据源文件，文件名中的日期和业务约定为YYYYMMDD ###
SRC_FILE_PATH=/js
SRC_FILES=szit2013000940_${shlogdate}_D*.csv
### 指定本地接收目录,这个是指在调度机器上的 ###
LOCAL_PATH=/dwsrc/wrktmp/local
### 指定sql*loadr控制文件目录,这个是指在调度机器上的;skip,direct参数在下文命令中设置 ###
CTL_FILE_PATH=/dwsys/mis/ctl/local
CTL_FILE_A=szit2013-000940_dg.ctl
DATA_FILE=szit2013000940_${shlogdate}_DS.csv
### 指定spool文件目录,这个是指在调度机器上的###
SPL_SQL_PATH=/dwsys/mis/proc/local
SPL_SQL=spool_szit2013-000940_mr.sql
SPL_FAIL_SQL=szit2013-000940_spool_fa.sql  ## spool失败提示
# 结果文件压缩包名
TAR_FILE= szit2013-000940_${shlogdate}.tar
# spool结果文件名
SPL_FAIL_FILE=szit2013-000940-出错提示_${shlogdate}.csv    ## 带有失败提示信息的csv文件
SPL_FILE=小明-szit2013-000940-XX市违规签发支票出票人名单-单位空头支票_${shlogdate}.csv


### 数据库配置信息###
DB_USER=misqry
DB_PASSWORD=this-is-secret
DB_ADDR=11.111.111.86/oramis




############################################################################
# BEGINNING OF MAIN
############################################################################
## 从业务目录获得文件,事先约定好文件名
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

### 判断本地目录下是否有获取到更新的数据源文件
### 如果取到则继续处理，若未取到更新文件则退出
if [ ! -f ${SRC_FILES} ]
then
	exit 0
fi

### sql*loader 装载文件
sqlldr ${DB_USER}/${DB_PASSWORD}@${DB_ADDR} control=${CTL_FILE_PATH}/${CTL_FILE_A} data=${LOCAL_PATH}/${DATA_FILE} bad=${LOCAL_PATH}/${DATA_FILE}.BAD log=${LOCAL_PATH}/${DATA_FILE}.log skip=1 no_index_errors=true errors=10000
ldr_status_a=$?


if [ ${ldr_status_a} -eq 0 ] 
then   
### 装载成功，则spool取数结果到业务目录下
sqlplus ${DB_USER}/${DB_PASSWORD}@${DB_ADDR} @${SPL_SQL_PATH}/${SPL_SQL} ${shlogdate}

cd ${LOCAL_PATH}
tar -cvf ${TAR_FILE} ${SPL_FILE}
gzip ${TAR_FILE} 

### FTP结果文件送到业务目录下
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
### 装载失败则向业务目录发送提醒
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
