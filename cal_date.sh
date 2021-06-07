#!/usr/env/bin ksh

inputDate=$1
inputN=$(echo $2 | xargs)

inputYear=$(echo ${inputDate} | cut -c1-4 | xargs)
inputMonth=$(echo ${inputDate} | cut -c5-6| xargs)
inputDay=$(echo ${inputDate} | cut -c7-8| xargs)

echo "Input Date: ${inputYear}/${inputMonth}/${inputDay}"
echo "Input N: ${inputN}"

year=${inputYear}
if [ ${inputN} -gt ${inputDay} ]; 
then
    month=$(expr ${inputMonth} - 1)
else
    month=${inputMonth}
fi
day=$(expr ${inputDay} - ${inputN})

if [ ${day} -lt 0 ]; 
then
    if [ ${month} -eq 0 ]; 
    then
        year=$(expr ${inputYear} - 1)
        month=12
        day=$(expr 31 - ${inputN} + ${inputDay})
    else
        case ${month} in
            1|3|5|7|8|10|12) day=$(expr 31 - ${inputN} + ${inputDay})
                          ;; 
            4|6|9|11) day=$(expr 30 - ${inputN} + ${inputDay}) 
                   ;; 
            2) if [ $(expr ${inputYear} % 4) -eq 0 ]; 
               then
                   if [ $(expr ${inputYear} % 400) -eq 0 ]; 
                   then
                       day=$(expr 29 - ${inputN} + ${inputDay})
                   elif [ $(expr ${inputYear} % 100) -eq 0 ];
                   then
                       day=$(expr 28 - ${inputN} + ${inputDay})
                   else 
                       day=$(expr 29 - ${inputN} + ${inputDay})
                   fi
               else
                       day=$(expr 28 - ${inputN} + ${inputDay})
               fi
            ;;
        esac
    fi
fi

if [ ${month} -lt 10 ]; 
then
    month='0'${month}
fi

if [ ${day} -lt 10 ]; 
then
    day='0'${day}
fi

echo "Cal: ${year}/${month}/${day}"
