root_dir=/app/dlmain/test/pxl/tmp
target_dir=aa1/bb2/cc3/dd4/ee5/ff6

echo "Under: ${root_dir}"
echo "Make : ${target_dir}"

STRS=`echo ${target_dir} | awk -F'/' -v rootd="${root_dir}" '{ 
    dirNum=NF

    for(i=1; i<=dirNum; i++) {
         dirName[i] = $i
    }

    for(j=1; j<=dirNum; j++){
        conDirPath=rootd
        for(k=1; k<=j; k++){
            conDirPath = conDirPath "/" dirName[k];
        }
        print conDirPath;
    }
}' `

for item in $(echo ${STRS})
do
    comd="mkdir $item"

ftp -nv 11.111.11.11 <<EOFF
user dlmain dlmain 
bin
prompt off
${comd}
close
bye
EOFF

done
