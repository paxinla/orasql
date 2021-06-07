mymonth=`date +%m`
myday=`date +%d`
myyear=`date +%Y`
mymonth=`expr $mymonth + 0`
myday=`expr $myday - 1`
if [ $myday -eq 0 ]; 
then
    mymonth=`expr $mymonth - 1`
    if [ $mymonth -eq 0 ]; 
    then
        mymonth=12
        myday=31
        myyear=`expr $myyear - 1`
    else
        case $mymonth in
            1|3|5|7|8|10|12) myday=31
            ;;
            4|6|9|11) myday=30
            ;;
            2)
                if [ `expr $myyear % 4` -eq 0 ];
                then 
                    if [ `expr $myyear % 400` -eq 0 ];
                    then
                        myday=29
                    fi
                else
                    myday=28
                fi
            ;;
        esac
    fi
fi

case $myday in
    1|2|3|4|5|6|7|8|9) myday='0'$myday
esac

case $mymonth in
    1|2|3|4|5|6|7|8|9) mymonth='0'$mymonth
esac

echo $myyear$mymonth$myday
