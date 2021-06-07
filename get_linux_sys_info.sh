#!/bin/sh

###=========================================================
###   Generate a simple report to provide basic information
### about the system.
###
### 2014-11-19   panxinlei
###=========================================================

REPORT_FILE=LinuxSysInf_$(whoami)@$(hostname)_$(date +%Y%m%d%H%M).rpt
ITEM_SEQ=0

write_log(){
    wtyp=$1
    wmsg=$2
    case "${wtyp}" in
        "E" ) incseq
              echo "[$(date +'%F %X')] $2" | tee -ai ${REPORT_FILE}
           ;;
    
        "W" ) echo "${wmsg}" >> ${REPORT_FILE}
           ;;
    
        * ) echo "Wrong write type!"
         ;;
    esac
}

incseq(){
    ITEM_SEQ=$(expr ${ITEM_SEQ} + 1)
}

###---------------------------------------------------------
touch ${REPORT_FILE}
clear

write_log "W" "======================================================="
write_log "W" "=********* Report on $(date +'%F %X') *********="
write_log "W" "======================================================="
write_log "W" ""
write_log "W" "--[ System Info ]-------------------------------------"
write_log "W" ""
write_log "E" "${ITEM_SEQ}.  Host Name: $(hostname)"
write_log "E" "${ITEM_SEQ}.  Net Interface:"
write_log "W" "`ifconfig -a`"
write_log "E" "${ITEM_SEQ}.  Kernel Version: $(cat /proc/version)"
write_log "E" "${ITEM_SEQ}.  Kernel boot parameters: $(cat /proc/cmdline)"
write_log "E" "${ITEM_SEQ}.  OS Version: $(cat /etc/*-release)"
write_log "E" "${ITEM_SEQ}.  Run time: $(uptime)"
write_log "E" "${ITEM_SEQ}.  Vmstat: "
write_log "W" "`vmstat 1 10`"
write_log "W" ""
write_log "W" "--[ CPU Info ]----------------------------------------"
write_log "W" ""
write_log "E" "${ITEM_SEQ}.  CPU Type: $(uname -m)"
write_log "E" "${ITEM_SEQ}.  Core Numbers: $(grep processor /proc/cpuinfo | wc -l)"
write_log "E" "${ITEM_SEQ}.  Core Detail: "
write_log "W" "`cat /proc/cpuinfo`"
write_log "W" ""
write_log "W" "--[ Memory Info ]-------------------------------------"
write_log "W" ""
write_log "E" "${ITEM_SEQ}.  Memory Summary: "
write_log "W" "`free`"
write_log "E" "${ITEM_SEQ}.  Memory Detail: "
write_log "W" "`cat /proc/meminfo`"
write_log "W" ""
write_log "W" "--[ Disk/Flash Info ]---------------------------------"
write_log "W" ""
write_log "E" "${ITEM_SEQ}.  Device Summary: $(ls -1 /dev | grep -E '^[h|s]d.?' | xargs -I {} echo /dev/{})"
write_log "E" "${ITEM_SEQ}.  Current Disk: $(fdisk -l)"
write_log "E" "${ITEM_SEQ}.  Partition Info: "
write_log "W" "`cat /etc/fstab`"
write_log "E" "${ITEM_SEQ}.  Partition Usage: "
write_log "W" "`df -h`"
write_log "E" "${ITEM_SEQ}.  Mount Summary: "
write_log "W" "`mount -l`"
write_log "W" ""
write_log "W" "--[ Processes/Threads Info ]--------------------------"
write_log "W" ""
write_log "E" "${ITEM_SEQ}.  Kernel Parameter Limit: "
write_log "W" "`ulimit -a`"
write_log "E" "${ITEM_SEQ}.  P/T Info: "
write_log "W" "`top -d 1 -n 1; echo`"
write_log "W" ""
write_log "W" "==============       End   Report        =============="
write_log "W" ""
unix2dos ${REPORT_FILE}
write_log "W" ""
echo "A Report ${REPORT_FILE} has been generated."
