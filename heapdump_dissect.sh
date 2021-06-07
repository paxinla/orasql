#!/bin/ksh
################################################################################
##
## File name:   heapdump_dissect
## Purpose:     Dissecting heapdump
##
## Author:      Riyaj Shamsudeen
## Copyright:   Original script heapdump_analyzer: @Tanelpoder.com
##              Modified script heapdump_dissect : @OraInternals. 
##              These two scripts are protected under copyright laws.
##
## Uage         2) run ./heapdump_dissect <heapdump tracefile name>
##                 For example: ./heapdump_dissect ORCL_ora_4345.trc
##
## Other:       
##              Only take heapdumps when you know what you're doing!
##              Taking a heapdump on shared pool (when bit 2 in heapdump event
##              level is enabled) can hang your database for a while as it
##              holds shared pool latches for a long time if your shared pool
##              is big and heavily active.
##
## Thanks to:   Tanel Poder for his original tool heapdump_analyzer
##                And special thanks to Tanel for letting me to modify his script.   
##
################################################################################
echo
echo "  -- Heapdump dissect v1.00 by Riyaj Shamsudeen"
echo "    -- Based upon Tanel's script heapdump_analyzer  http://www.tanelpoder.com/files/scripts/heapdump_analyzer "
echo
echo " This script creates two files in /tmp/ directory "
echo "   1. /tmp/heapdump_dissect.lst - temporary file "
echo "   2. /tmp/heapdump_summary.lst - heap dump summary "

cat $1 | awk '
     /^HEAP DUMP heap name=/ { split($0,ht,"\""); HTYPE=ht[2]; doPrintOut = 1; }
     /^EXTENT/ { EXT=$1" " $2;  }
     /Chunk/{ if ( doPrintOut == 1 ) {
                split($0,sf,"\"");
                printf "%16s| %16s| %16s| %16s| %10d\n",  HTYPE, EXT, $5, sf[2], $4;
              }
     }
     /Total heap size/ {
              printf "%10d , %16s, %16s, %16s\n", $5, HTYPE, "TOTAL", "Total heap size";
              doPrintOut=0;
     }
    '  |grep EXTENT|sort >/tmp/heapdump_dissect.lst

echo  "Sub heap/type summary " > /tmp/heapdump_summary.lst
echo  "----------------------" >>/tmp/heapdump_summary.lst
echo  "Sub heap                      Type   Size"  >>/tmp/heapdump_summary.lst
echo  "---------------- -----------------   ---------"  >>/tmp/heapdump_summary.lst

cat /tmp/heapdump_dissect.lst | grep EXTENT|awk '
       BEGIN { FS="|"}
       { SizeOfElem [ $1 " " $3 ]+=$5;}
       END { for ( i in SizeOfElem )  { print i " " SizeOfElem [i]; } }
'|sort >> /tmp/heapdump_summary.lst
echo  "Sub heap level summary " >> /tmp/heapdump_summary.lst
echo  "----------------------" >>/tmp/heapdump_summary.lst
echo  "Sub heap                      Type   Allocation cmt  Size"  >>/tmp/heapdump_summary.lst
echo  "---------------- -----------------   --------------- --------"  >>/tmp/heapdump_summary.lst

cat /tmp/heapdump_dissect.lst | grep EXTENT|awk '
       BEGIN { FS="|"}
       { SizeOfElem [ $1 " " $3 " " $4 ]+=$5;}
       END { for ( i in SizeOfElem )  { print i " " SizeOfElem [i]; } }
'|sort >> /tmp/heapdump_summary.lst
echo  "Extent level summary " >> /tmp/heapdump_summary.lst
echo  "------------------ " >> /tmp/heapdump_summary.lst
echo "Sub heap          Extent             Type              Allocation cmt   Size"  >>/tmp/heapdump_summary.lst
echo  "---------------- -----------------   ---------------   --------------  --------"  >>/tmp/heapdump_summary.lst

cat /tmp/heapdump_dissect.lst | awk '
       BEGIN { FS="|"}
       { SizeOfElem [ $1 " " $2 " " $3 " " $4 ]+=$5;}
       END { for ( i in SizeOfElem )  { print i " " SizeOfElem [i]; } }
'|sort >> /tmp/heapdump_summary.lst
echo