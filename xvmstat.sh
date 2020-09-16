#!/usr/bin/ksh93
#------------------------------------------------------------------------------------
# Script:  xvmstat.sh
# Date:    2013/12/05
# Author:  David Little - david.n.little@gmail.com
#  (C) 2015 by David Little The MIT License (MIT)
#------------------------------------------------------------------------------------
# Purpose:
#  Make the 'vmstat' output actually useful. The more colours on screen, the worse things are.
#
# Use:
#  xvmstat <time> <tics>
#
# Comments:
# Useful Reading:
#    http://www.ibmsystemsmag.com/aix/administrator/systemsmanagement/Examining-vmstat/?page=1
#    http://www.ibmsystemsmag.com/aix/administrator/systemsmanagement/Paging-Spaces-(1)/?page=1
#
#   Remember the way nmon uses single-character graphs in case we ever want to use graphs:
#          Key(%): @=90 #=80 X=70 8=60 O=50 0=40 o=30 +=20 -=10 .=5 _=0%
#------------------------------------------------------------------------------------
# Update Notes:
#    2015/10/30 - 1.0.0 Release for public consumption
#    2020/09/14 - Begin switch from `vmstat -It` to `vmstat -IWwt`
#------------------------------------------------------------------------------------

# To Do:
#  - Check SMT using lparstat -i, include that _somewhere_ in the calculations.
#  - Ignore runqueue on POWER9.  Keep for POWER7+8
#  - id+wa for different SMT's:
#  Any SMT: id+wa > 80: Always bad, over-provisioned
#    SMT8:
#      If id+wa: > 67, system is over-provisioned at the time of running.  Remove CPUs
#              : 5<x>67 - Perfect
#    SMT4:
#      If id+wa: x>40 - Not perfect
#              : 5<x>40 - Perfect
#              : 5>x - Bad
#    SEE PAGES 210+211++ on Earl's display!!!!!

# GLOBALS:
SCRIPTNAME=$(basename $0)

# Import the specialfont
source ./src_specialfont.sh

# Colour Thresholds
# Each 'column' has 4 thresholds, which are stored in THRESH[foobar][n], where n = (0|1|2|3)
#  Each value corresponds with a for loop later on, eg:
#  for COLUMN in THREAD_R THREAD_B THREAD_P THREAD_W ETC...; do
#    if VALUE <= THRESH[${COLUMN}][0]:
#       print value with NORMAL font highlight
#    elif VALUE > THRESH[${COLUMN}][0] and <= THRESH[${COLUMN}][1]
#       print value with BRIGHT font highlight
#    elif VALUE > THRESH[${COLUMN}][1] and <= THRESH[${COLUMN}][2]
#       print value with YELLOW font highlight
#    elif VALUE > THRESH[${COLUMN}][2] and <= THRESH[${COLUMN}][3]
#       print value with LIGHT_RED font highlight
#    else (aka VALUE > THRESH[${COLUMN}][3])
#       print value with RED font highlight
# NB: In the code, each 'elif' is simplified to just the <=, we dont need to check if it's bigger than the last if.

typeset -A THRESH
THRESH["THREAD_R"][0]=0.8 # RUNQ highlight is based off the percentage of total CPUs in the system
THRESH["THREAD_R"][1]=0.9 #   0.9 means 90% of the CPU in the system 
THRESH["THREAD_R"][2]=1.0 #   1.0 = 100%, or as many Processes running as there are CPU
THRESH["THREAD_R"][3]=1.1 #   1.1 is 1.1x (110%) as many processes as CPU in the system.
THRESH["THREAD_B"][0]=1
THRESH["THREAD_B"][1]=3
THRESH["THREAD_B"][2]=4
THRESH["THREAD_B"][3]=6
THRESH["THREAD_P"][0]=1
THRESH["THREAD_P"][1]=3
THRESH["THREAD_P"][2]=4
THRESH["THREAD_P"][3]=6
THRESH["THREAD_W"][0]=1
THRESH["THREAD_W"][1]=3
THRESH["THREAD_W"][2]=4
THRESH["THREAD_W"][3]=6
THRESH["MEM_AVM"][0]=999999999999
THRESH["MEM_AVM"][1]=0
THRESH["MEM_AVM"][2]=0
THRESH["MEM_AVM"][3]=0
THRESH["MEM_FRE"][0]=999999999999 # TODO: Base off Availble Memory Free Percentages.
THRESH["MEM_FRE"][1]=0
THRESH["MEM_FRE"][2]=0
THRESH["MEM_FRE"][3]=0
THRESH["PAGE_FI"][0]=999999999999
THRESH["PAGE_FI"][1]=0
THRESH["PAGE_FI"][2]=0
THRESH["PAGE_FI"][3]=0
THRESH["PAGE_FO"][0]=999999999999
THRESH["PAGE_FO"][1]=0
THRESH["PAGE_FO"][2]=0
THRESH["PAGE_FO"][3]=0
THRESH["PAGE_PI"][0]=10
THRESH["PAGE_PI"][1]=40
THRESH["PAGE_PI"][2]=80
THRESH["PAGE_PI"][3]=100
THRESH["PAGE_PO"][0]=10
THRESH["PAGE_PO"][1]=40
THRESH["PAGE_PO"][2]=80
THRESH["PAGE_PO"][3]=100
THRESH["PAGE_FR"][0]=999999999999
THRESH["PAGE_FR"][1]=0
THRESH["PAGE_FR"][2]=0
THRESH["PAGE_FR"][3]=0
THRESH["PAGE_SR"][0]=999999999999
THRESH["PAGE_SR"][1]=0
THRESH["PAGE_SR"][2]=0
THRESH["PAGE_SR"][3]=0
THRESH["PAGE_FR2SR"][0]=4  # This is the ratio of FR to SR. ie: 0->1:4
THRESH["PAGE_FR2SR"][1]=6  #  1:6
THRESH["PAGE_FR2SR"][2]=8  #  1:8
THRESH["PAGE_FR2SR"][3]=10 # Anything over 1:10 is 'bad', scanning way more than freeing
THRESH["FAULT_IN"][0]=999999999999
THRESH["FAULT_IN"][1]=0
THRESH["FAULT_IN"][2]=0
THRESH["FAULT_IN"][3]=0
THRESH["FAULT_SY"][0]=0.8  # Gets converted into (CPU_count * 10000) * value
THRESH["FAULT_SY"][1]=0.9
THRESH["FAULT_SY"][2]=0.95
THRESH["FAULT_SY"][3]=1
THRESH["FAULT_CS"][0]=999999999999
THRESH["FAULT_CS"][1]=0
THRESH["FAULT_CS"][2]=0
THRESH["FAULT_CS"][3]=0
THRESH["CPU_US"][0]=75
THRESH["CPU_US"][1]=85
THRESH["CPU_US"][2]=95
THRESH["CPU_US"][3]=98
THRESH["CPU_SY"][0]=5
THRESH["CPU_SY"][1]=10
THRESH["CPU_SY"][2]=20
THRESH["CPU_SY"][3]=30
THRESH["CPU_ID"][0]=5
THRESH["CPU_ID"][1]=10
THRESH["CPU_ID"][2]=20
THRESH["CPU_ID"][3]=30
THRESH["CPU_WA"][0]=5
THRESH["CPU_WA"][1]=10
THRESH["CPU_WA"][2]=20
THRESH["CPU_WA"][3]=30
THRESH["CPU_PC"][0]=0.70    # Percentages of capacity being used of allocated CPU, converted later
THRESH["CPU_PC"][1]=0.85
THRESH["CPU_PC"][2]=1.00
THRESH["CPU_PC"][3]=1.50
THRESH["CPU_EC"][0]=70
THRESH["CPU_EC"][1]=85
THRESH["CPU_EC"][2]=100
THRESH["CPU_EC"][3]=150

# Column Widths
typeset -A CW
CW["TIME"]=8
CW["THREAD_R"]=2  # On larger systems, these are likely needed to be 3.
CW["THREAD_B"]=2
CW["THREAD_P"]=2
CW["THREAD_W"]=2
CW["MEM_AVM"]=9
CW["MEM_FRE"]=9
CW["PAGE_FI"]=7
CW["PAGE_FO"]=7
CW["PAGE_PI"]=2
CW["PAGE_PO"]=2
CW["PAGE_FR"]=7
CW["PAGE_SR"]=7
CW["PAGE_FR2SR"]=5
CW["FAULT_IN"]=8
CW["FAULT_SY"]=8
CW["FAULT_CS"]=6
CW["CPU_US"]=3
CW["CPU_SY"]=3
CW["CPU_ID"]=3
CW["CPU_WA"]=4
CW["CPU_PC"]=4
CW["CPU_EC"]=4

######
# Trap everything and send it to our cleanup routine.
trap "CLEANUP 1" 2 3

# ROW is used for every 'box' drawing'.  The symbols are replaced with 'boxes' as such:
#  {L} = Lefthand most box
#  {R} = Righthand most box
#  {M} = Middle-box
# The rest are printf thingys 
# BOX_ROW="{L} %-6s {M} %-9s {M} %-16s {M} %-37s {M} %-19s {M} %-25s {R}"

#====================================================================================
# CLEANUP
CLEANUP()
{
    if [[ "${FIRSTHEADER}" != "" ]]; then
        printf "${BOX[CLL].BOLD}%${w_time}s${BOX[CHU].BOLD}%${w_thread}s${BOX[CHU].BOLD}%${w_mem}s${BOX[CHU].BOLD}%${w_page}s${BOX[CHU].BOLD}%${w_fault}s${BOX[CHU].BOLD}%${w_cpu}s${BOX[CLR].BOLD}\n" "" "" "" "" ""|sed "s/ /${BOX[BMM].BOLD}/g"
        printf "\n"
    fi
    [[ "${1}" != "" ]] && exit $1
    exit 0
}
#====================================================================================

#====================================================================================
USAGE()
{
    BOLD="\033[1m"
    NORM="\033[0m"
    SYSTEM_CPU=$(vmstat|awk '/^System/ {print $3}')
    SYSTEM_CPU=${SYSTEM_CPU#*=}
    typeset -F0 SYSTEM_CPU_1_5
    SYSTEM_CPU_1_5=$((SYSTEM_CPU/1.5))
    typeset -F0 SYSTEM_CPU_1_2
    SYSTEM_CPU_1_2=$((SYSTEM_CPU/1.2))

    printf "${BOX[CUL].BOLD}%-126s${BOX[CUR].BOLD}\n"|sed "s/ /${BOX[BMM].BOLD}/g"
    printf "${BOX[BVV].BOLD}${FONT[BOLD]}%-126s${FONT[NORMAL]}${BOX[BVV].BOLD}\n" " 'vmstat' wrapper help and manual"
    printf "${BOX[CVR].BOLD}%-126s${BOX[CVL].BOLD}\n"|sed "s/ /${BOX[BMM].BOLD}/g"
    #printf "${BOX[BVV].BOLD}%-126s${BOX[BVV].BOLD}\n" "${FONT[BOLD]}Usage:${FONT[NORMAL]} ${SCRIPTNAME} ( [ ${FONT[NORMAL]}-h${FONT[NORMAL]} ] | [ ${FONT[BOLD]}Interval${FONT[NORMAL]} [ ${FONT[BOLD]}Count${FONT[NORMAL]} ] ] )"
    echo "${BOX[BVV].BOLD} ${FONT[BOLD]}Usage:${FONT[NORMAL]}   ${SCRIPTNAME} ( [ ${FONT[NORMAL]}-h${FONT[NORMAL]} ] | [ ${FONT[BOLD]}Interval${FONT[NORMAL]} [ ${FONT[BOLD]}Count${FONT[NORMAL]} ] ] )"
    echo "${BOX[BVV].BOLD} ${FONT[BOLD]}Version:${FONT[NORMAL]} ${VERSION}"
    echo "${BOX[BVV].BOLD} ${FONT[BOLD]}Date:${FONT[NORMAL]}    ${UPDATED}"
    echo "${BOX[BVV].BOLD} ${FONT[BOLD]}Author:${FONT[NORMAL]}  David Little"

    printf "${BOX[CVR].BOLD}%-126s${BOX[CVL].BOLD}\n"|sed "s/ /${BOX[BMM].BOLD}/g"
    echo "${BOX[BVV].BOLD} ${FONT[BOLD]}Command Line Options:${FONT[NORMAL]}"
    echo "${BOX[BVV].BOLD}       ${FONT[BOLD]}-h${FONT[NORMAL]}: Display this help"
    echo "${BOX[BVV].BOLD} ${FONT[BOLD]}Interval${FONT[NORMAL]}: tba"
    echo "${BOX[BVV].BOLD}    ${FONT[BOLD]}Count${FONT[NORMAL]}: tba"

    printf "${BOX[CVR].BOLD}%-126s${BOX[CVL].BOLD}\n"|sed "s/ /${BOX[BMM].BOLD}/g"
    echo "${BOX[BVV].BOLD} ${FONT[BOLD]}Header Information${FONT[NORMAL]}"
    printf "${BOX[CVR].BOLD}%-126s${BOX[CVL].BOLD}\n"|sed "s/ /${BOX[BMM].BOLD}/g"
    echo "${BOX[BVV].BOLD} ${FONT[BOLD]}Thrds${FONT[NORMAL]}: Thread Information"
    printf "${BOX[CVR].BOLD}%-126s${BOX[CVL].BOLD}\n"|sed "s/ /${BOX[BMM].DULL}/g"
    echo "${BOX[BVV].BOLD}  ${FONT[BOLD]}r${FONT[NORMAL]} - Running Threads, Colour Coded vs. Number of lCPU (${SYSTEM_CPU})."
    echo "${BOX[BVV].BOLD}       ${FONT[NORMAL]}0->${SYSTEM_CPU_1_5}${FONT[NORMAL]}, ${FONT[YELLOW_F]}${SYSTEM_CPU_1_5}->${SYSTEM_CPU_1_2}${FONT[NORMAL]}, ${FONT[RED_F]}${SYSTEM_CPU_1_2}->${SYSTEM_CPU}${FONT[NORMAL]}, ${FONT[RED_B]}${SYSTEM_CPU}+${FONT[NORMAL]}"
    echo "${BOX[BVV].BOLD}  ${FONT[BOLD]}b${FONT[NORMAL]} - Threads waiting."
    echo "${BOX[BVV].BOLD}       ${FONT[NORMAL]}0->1${FONT[NORMAL]}, ${FONT[YELLOW_F]}2-3${FONT[NORMAL]}, ${FONT[RED_F]}4-6${FONT[NORMAL]}, ${FONT[RED_B]}7+${FONT[NORMAL]}"
    echo "${BOX[BVV].BOLD}  ${FONT[BOLD]}p${FONT[NORMAL]} - Number of threads waiting for disk io."
    echo "${BOX[BVV].BOLD}       ${FONT[NORMAL]}0->1${FONT[NORMAL]}, ${FONT[YELLOW_F]}2-3${FONT[NORMAL]}, ${FONT[RED_F]}4-6${FONT[NORMAL]}, ${FONT[RED_B]}7+${FONT[NORMAL]}"
    echo "${BOX[BVV].BOLD}  ${FONT[BOLD]}w${FONT[NORMAL]} - TBD."
    echo "${BOX[BVV].BOLD}       ${FONT[NORMAL]}0->1${FONT[NORMAL]}, ${FONT[YELLOW_F]}2-3${FONT[NORMAL]}, ${FONT[RED_F]}4-6${FONT[NORMAL]}, ${FONT[RED_B]}7+${FONT[NORMAL]}"
    printf "${BOX[CVR].BOLD}%-126s${BOX[CVL].BOLD}\n"|sed "s/ /${BOX[BMM].BOLD}/g"
    echo "${BOX[BVV].BOLD} ${FONT[BOLD]}Pages${FONT[NORMAL]}: Memory statistics "
    printf "${BOX[CVR].BOLD}%-126s${BOX[CVL].BOLD}\n"|sed "s/ /${BOX[BMM].DULL}/g"

    echo "${BOX[BVV].BOLD}   ${FONT[BOLD]}Active${FONT[NORMAL]} - Active virtual pages."
    echo "${BOX[BVV].BOLD}   ${FONT[BOLD]}Fre${FONT[NORMAL]} - Size of the free list."
    printf "${BOX[CVR].BOLD}%-126s${BOX[CVL].BOLD}\n"|sed "s/ /${BOX[BMM].BOLD}/g"
    echo "${BOX[BVV].BOLD}  ${FONT[BOLD]}Paging${FONT[NORMAL]}: Page faults and paging activity"
    printf "${BOX[CVR].BOLD}%-126s${BOX[CVL].BOLD}\n"|sed "s/ /${BOX[BMM].DULL}/g"

    echo "${BOX[BVV].BOLD}   ${FONT[BOLD]}fi${FONT[NORMAL]} - File page-ins per second."
    echo "${BOX[BVV].BOLD}   ${FONT[BOLD]}fo${FONT[NORMAL]} - File page-outs per second."
    echo "${BOX[BVV].BOLD}   ${FONT[BOLD]}pi${FONT[NORMAL]} - Pages paged in from paging space."
    echo "${BOX[BVV].BOLD}       ${FONT[NORMAL]}0->9${FONT[NORMAL]}, ${FONT[YELLOW_F]}10->59${FONT[NORMAL]}, ${FONT[RED_F]}60->99${FONT[NORMAL]}, ${FONT[RED_B]}100+${FONT[NORMAL]}"
    echo "${BOX[BVV].BOLD}   ${FONT[BOLD]}po${FONT[NORMAL]} - Pages paged out to paging space."
    echo "${BOX[BVV].BOLD}       ${FONT[NORMAL]}0->9${FONT[NORMAL]}, ${FONT[YELLOW_F]}10->59${FONT[NORMAL]}, ${FONT[RED_F]}60->99${FONT[NORMAL]}, ${FONT[RED_B]}100+${FONT[NORMAL]}"
    echo "${BOX[BVV].BOLD}   ${FONT[BOLD]}fr${FONT[NORMAL]} - Pages freed (page replacement)."
    echo "${BOX[BVV].BOLD}   ${FONT[BOLD]}sr${FONT[NORMAL]} - Pages scanned by page-replacement algorithm."
    echo "${BOX[BVV].BOLD}   ${FONT[BOLD]}sr/fr${FONT[NORMAL]} - Ratio between pages freed vs. pages scanned in page-replacement algorithm."
    echo "${BOX[BVV].BOLD}       ${FONT[NORMAL]}n/a->1:4${FONT[NORMAL]}, ${FONT[YELLOW_F]}1:5->1:7${FONT[NORMAL]}, ${FONT[RED_F]}1:5->1:9${FONT[NORMAL]}, ${FONT[RED_B]}1:10+${FONT[NORMAL]}"
    printf "${BOX[CVR].BOLD}%-126s${BOX[CVL].BOLD}\n"|sed "s/ /${BOX[BMM].BOLD}/g"
    echo "${BOX[BVV].BOLD}  ${FONT[BOLD]}Faults${FONT[NORMAL]}: Trap and interrupt rate averages per second"
    printf "${BOX[CVR].BOLD}%-126s${BOX[CVL].BOLD}\n"|sed "s/ /${BOX[BMM].DULL}/g"
    echo "${BOX[BVV].BOLD}   ${FONT[BOLD]}intrp${FONT[NORMAL]} - Device interrupts ('in' in classic vmstat)."
    echo "${BOX[BVV].BOLD}   ${FONT[BOLD]}syscalls${FONT[NORMAL]} - System calls ('sy' in classic vmstat); Colour coded based off 10,000 per CPU Count (${SYSTEM_CPU})."
    typeset -i tmp1=$((SYSTEM_CPU*10000/1.4))
    typeset -i tmp2=$((SYSTEM_CPU*10000/1.2))
    echo "${BOX[BVV].BOLD}       ${FONT[NORMAL]}0->${tmp1}${FONT[NORMAL]}, ${FONT[YELLOW_F]}$((${tmp1}+1))->${tmp2}${FONT[NORMAL]}, ${FONT[RED_F]}$((${tmp2}+1))->$((SYSTEM_CPU*10000 ))${FONT[NORMAL]}, ${FONT[RED_B]}$((SYSTEM_CPU*10000+1))+${FONT[NORMAL]}"
    echo "${BOX[BVV].BOLD}   ${FONT[BOLD]}cntxsw${FONT[NORMAL]} - Kernel thread context switches. ('cs' in classic vmstat)."
    printf "${BOX[CVR].BOLD}%-126s${BOX[CVL].BOLD}\n"|sed "s/ /${BOX[BMM].BOLD}/g"
    echo "${BOX[BVV].BOLD}  ${FONT[BOLD]}CPU Percentages${FONT[NORMAL]}: Breakdown of percentage usage of processor time."
    printf "${BOX[CVR].BOLD}%-126s${BOX[CVL].BOLD}\n"|sed "s/ /${BOX[BMM].DULL}/g"
    echo "${BOX[BVV].BOLD}   ${FONT[BOLD]}usr${FONT[NORMAL]} - User time."
    echo "${BOX[BVV].BOLD}   ${FONT[BOLD]}sys${FONT[NORMAL]} - System time."
    echo "${BOX[BVV].BOLD}   ${FONT[BOLD]}idl${FONT[NORMAL]} - Processor idle time."
    echo "${BOX[BVV].BOLD}   ${FONT[BOLD]}wai${FONT[NORMAL]} - Processor idle time during which the system had outstanding disk/NFS I/O request(s). See detailed description above."
    echo "${BOX[BVV].BOLD}   ${FONT[BOLD]}pc${FONT[NORMAL]} - Number of physical processors consumed. Displayed only if the partition is running with shared processor."
    echo "${BOX[BVV].BOLD}   ${FONT[BOLD]}ent%${FONT[NORMAL]} - The percentage of entitled capacity consumed."
    printf "${BOX[CLL].BOLD}%-126s${BOX[CLR].BOLD}\n"|sed "s/ /${BOX[BMM].BOLD}/g"
    exit 255
}
#------------------------------------------------------------------------------------

#====================================================================================
# GetOpts
GETOPTS()
{
    while getopts h name; do
        case ${name} in
            h)
                USAGE
                ;;
            *)        # unknown flag
                USAGE
                ;;
        esac
    done
}
#------------------------------------------------------------------------------------

#====================================================================================
# Print Header
#  Prints out the box-formatted header of the script. 
#  It is also called throughout the script when the number of lines displayed > the number of
#    lines on the terminal.
PRINTHEADER()
{
    # Widths:
    w_time=${CW[TIME]}
    w_thread="$((3+${CW[THREAD_R]}+${CW[THREAD_P]}+${CW[THREAD_B]}+${CW[THREAD_W]}))"
    w_mem="$((1+${CW[MEM_AVM]}+${CW[MEM_FRE]}))"
    w_page="$((6+${CW[PAGE_FI]}+${CW[PAGE_FO]}+${CW[PAGE_PI]}+${CW[PAGE_PO]}+${CW[PAGE_FR]}+${CW[PAGE_SR]}+${CW[PAGE_FR2SR]}))"
    w_fault="$((2+${CW[FAULT_IN]}+${CW[FAULT_SY]}+${CW[FAULT_CS]}))"
    w_cpu="$((5+${CW[CPU_US]}+${CW[CPU_SY]}+${CW[CPU_ID]}+${CW[CPU_WA]}+${CW[CPU_PC]}+${CW[CPU_EC]}))"
    if [[ "${FIRSTHEADER}" == "" ]]; then
        export FIRSTHEADER="TRUE"
        # Top box
        printf "${BOX[CUL].BOLD}%${w_time}s${BOX[CHD].BOLD}%${w_thread}s${BOX[CHD].BOLD}%${w_mem}s${BOX[CHD].BOLD}%${w_page}s${BOX[CHD].BOLD}%${w_fault}s${BOX[CHD].BOLD}%${w_cpu}s${BOX[CUR].BOLD}\n" "" "" "" "" ""|sed "s/ /${BOX[BMM].BOLD}/g"
    else
        # Top box when there are lines above
        printf "${BOX[CVR].BOLD}%${w_time}s${BOX[CMX].BOLD}%${w_thread}s${BOX[CMX].BOLD}%${w_mem}s${BOX[CMX].BOLD}%${w_page}s${BOX[CMX].BOLD}%${w_fault}s${BOX[CMX].BOLD}%${w_cpu}s${BOX[CVL].BOLD}\n" "" "" "" "" ""|sed "s/ /${BOX[BMM].BOLD}/g"
    fi

    ###################
    # Section Headers
    printf "${BOX[BVV].BOLD}"
    printf "${FONT[BOLD]}%-${w_time}s${BOX[BVV].BOLD}" "Time"
    printf "${FONT[BOLD]}%-${w_thread}s${BOX[BVV].BOLD}" "Threads"
    printf "${FONT[BOLD]}%-${w_mem}s${BOX[BVV].BOLD}" "Memory"
    printf "${FONT[BOLD]}%-${w_page}s${BOX[BVV].BOLD}" "Paging"
    printf "${FONT[BOLD]}%-${w_fault}s${BOX[BVV].BOLD}" "Faults"
    printf "${FONT[BOLD]}%-${w_cpu}s${BOX[BVV].BOLD}" "CPU Stats"
    printf "\n"
    printf "${BOX[CVR].BOLD}%${w_time}s${BOX[CMX].BOLD}%${w_thread}s${BOX[CMX].BOLD}%${w_mem}s${BOX[CMX].BOLD}%${w_page}s${BOX[CMX].BOLD}%${w_fault}s${BOX[CMX].BOLD}%${w_cpu}s${BOX[CVL].BOLD}\n" "" "" "" "" ""|sed "s/ /${BOX[BMM].BOLD}/g"
    ###################
    # Column headers
    printf "${BOX[BVV].BOLD}"
    printf "%${CW[TIME]}s${BOX[BVV].BOLD}" "hh:mm:ss"
    ##
    # Process queues
    printf "%${CW[THREAD_R]}s${BOX[BVV].DULL}" "r"
    printf "%${CW[THREAD_B]}s${BOX[BVV].DULL}" "b"
    printf "%${CW[THREAD_P]}s${BOX[BVV].DULL}" "p"
    printf "%${CW[THREAD_W]}s${BOX[BVV].BOLD}" "w"
    ##
    # Memory
    printf "%${CW[MEM_AVM]}s${BOX[BVV].DULL}" "Active"
    printf "%${CW[MEM_FRE]}s${BOX[BVV].BOLD}" "Free"
    ##
    # Paging
    printf "%${CW[PAGE_FI]}s${BOX[BVV].DULL}" "fi"
    printf "%${CW[PAGE_FO]}s${BOX[BVV].DULL}" "fo"
    printf "%${CW[PAGE_PI]}s${BOX[BVV].DULL}" "pi"
    printf "%${CW[PAGE_PO]}s${BOX[BVV].DULL}" "po"
    printf "%${CW[PAGE_FR]}s${BOX[BVV].DULL}" "freert"
    printf "%${CW[PAGE_SR]}s${BOX[BVV].DULL}" "scanrt"
    printf "%${CW[PAGE_FR2SR]}s${BOX[BVV].BOLD}" "sr/fr"
    ##
    # Faults
    printf "%${CW[FAULT_IN]}s${BOX[BVV].DULL}" "intrp"
    printf "%${CW[FAULT_SY]}s${BOX[BVV].DULL}" "syscalls"
    printf "%${CW[FAULT_CS]}s${BOX[BVV].BOLD}" "cntxsw"
    ##
    # CPU Percentages
    printf "%-${CW[CPU_US]}s${BOX[BVV].DULL}" "usr"
    printf "%-${CW[CPU_SY]}s${BOX[BVV].DULL}" "sys"
    printf "%-${CW[CPU_ID]}s${BOX[BVV].DULL}" "idl"
    printf "%-${CW[CPU_WA]}s${BOX[BVV].DULL}" "wai"
    printf "%-${CW[CPU_PC]}s${BOX[BVV].DULL}" "pc"
    printf "%-${CW[CPU_EC]}s${BOX[BVV].BOLD}" "ent"
    printf "\n"
}

#====================================================================================
# Print Base
#  Prints out the box-formatted base of the script. 
PRINTBASE() {
    printf "${BOX[CLL].BOLD} %-6s ${BOX[CHU].BOLD} %-9s ${BOX[CHU].BOLD} %-16s ${BOX[CHU].BOLD} %-37s ${BOX[CHU].BOLD} %-19s ${BOX[CHU].BOLD} %-25s ${BOX[CLR].BOLD}\n" "" "" "" "" ""|sed "s/ /${BOX[BMM].BOLD}/g"
}


#====================================================================================
# Main loop
#  Body of the script.  Pretend we're a real language so we can re-run main() if something
#  goes wrong but we want to restart/continue chooching
main() {
    DISPLAYCOUNT=99999
    typeset -A INFO
    typeset -A VALUES
    vmstat -IWwt ${vmstat_TICS} ${vmstat_COUNT}|while read -A LINE; do
        if [[ "${LINE[0]}" == "System" ]]; then
            #  Either the very first line of the vmstat output, or someone has DLPAR'd in the background.
            if [[ "${LINE[1]}" == "configuration:" ]]; then
                # Print out the system box at the top of the display
                # We actually replace this with the header from lparstat, it's the same, but more, information.
                # SYSTEM_INFORMATION=$(lparstat|grep '^System configuration')
                lparstat|grep '^System configuration'|read -A SYSTEM_INFORMATION
                SYSTEM_SMT="${SYSTEM_INFORMATION[4]#*=}"
                SYSTEM_CPU="${SYSTEM_INFORMATION[5]#*=}"
                SYSTEM_MEM="${SYSTEM_INFORMATION[6]#*=}"
                SYSTEM_PSIZE="${SYSTEM_INFORMATION[6]#*=}"
                SYSTEM_ENT="${SYSTEM_INFORMATION[8]#*=}"
                # Convert the THRESH[THREAD_R] multipliers into real values
                for V in ${!THRESH["THREAD_R"]}; do
                    t=$((${THRESH["THREAD_R"][${V}]}*${SYSTEM_CPU}))
                    THRESH["THREAD_R"][${V}]=${t}
                done
                # Convert the THRESH[FAULT_SY] multipliers into real values
                for V in ${!THRESH["FAULT_SY"]}; do
                    t=$((${SYSTEM_CPU} * 10000 / ${THRESH["FAULT_SY"][${V}]}))
                    THRESH["FAULT_SY"][${V}]=${t}
                done
                # Convert the THRESH[CPU_PC] multipliers into real values
                for V in ${!THRESH["CPU_PC"]}; do
                    t=$((${SYSTEM_ENT} * ${THRESH["CPU_PC"][${V}]}))
                    THRESH["CPU_PC"][${V}]=${t}
                done

                BOXLEN=$(echo ${SYSTEM_INFORMATION[*]}|wc -c)
                printf "${BOX[CUL].BOLD}%${BOXLEN}s ${BOX[CUR].BOLD}\n"|sed "s/ /${BOX[BMM].BOLD}/g"
                printf "${BOX[BVV].BOLD} %-s ${BOX[BVV].BOLD}\n" "${SYSTEM_INFORMATION[*]}"
                printf "${BOX[CLL].BOLD}%${BOXLEN}s ${BOX[CLR].BOLD}\n"|sed "s/ /${BOX[BMM].BOLD}/g"

            elif [[ "${LINE[1]} ${LINE[2]}" == "configuration changed." ]]; then
                # System configuration changed. The current iteration values may be inaccurate.
                PRINTBASE
                BOXLEN=$(echo ${LINE[*]}|wc -c)
                printf "${BOX[CUL].BOLD}%${BOXLEN}s ${BOX[CUR].BOLD}\n"|sed "s/ /${BOX[BMM].BOLD}/g"
                printf "${BOX[BVV].BOLD} %-s ${BOX[BVV].BOLD}\n" "${LINE[*]}"
                printf "${BOX[CLL].BOLD}%${BOXLEN}s ${BOX[CLR].BOLD}\n"|sed "s/ /${BOX[BMM].BOLD}/g"
                exit 99
            else
                printf "Unexpected vmstat output."
                exit 99
            fi

        elif [[ "${LINE[0]}" != ?(""|"System"|"kthr"|"---------------"|"r") ]]; then
            #   r   b   p   w        avm        fre    fi    fo    pi    po    fr     sr    in     sy    cs us sy id wa    pc    ec hr mi se
            VALUES[THREAD_R]=${LINE[0]}
            VALUES[THREAD_B]=${LINE[1]}
            VALUES[THREAD_P]=${LINE[2]}
            VALUES[THREAD_W]=${LINE[3]}
            VALUES[MEM_AVM]=${LINE[4]}
            VALUES[MEM_FRE]=${LINE[5]}
            VALUES[PAGE_FI]=${LINE[6]}
            VALUES[PAGE_FO]=${LINE[7]}
            VALUES[PAGE_PI]=${LINE[8]}
            VALUES[PAGE_PO]=${LINE[9]}
            VALUES[PAGE_FR]=${LINE[10]}
            VALUES[PAGE_SR]=${LINE[11]}
            VALUES[FAULT_IN]=${LINE[12]}
            VALUES[FAULT_SY]=${LINE[13]}
            VALUES[FAULT_CS]=${LINE[14]}
            VALUES[CPU_US]=${LINE[15]}
            VALUES[CPU_SY]=${LINE[16]}
            VALUES[CPU_ID]=${LINE[17]}
            VALUES[CPU_WA]=${LINE[18]}
            VALUES[CPU_PC]=${LINE[19]}
            VALUES[CPU_EC]=${LINE[20]}
            VALUES[TIME]=${LINE[21]}

            #====================================================================================
            COLS=$(tput cols)
            if (( COLS < 128 )); then
                echo "Screen must be at least 129 columns wide to use xvmstat."
                exit 1
            elif (( COLS > 128 && COLS < 180 )); then
                ADDITIONAL_INFO=1
            else
                ADDITIONAL_INFO=0
            fi
            ROWS=$(tput lines)
            if (( DISPLAYCOUNT > ROWS-3 )); then
                PRINTHEADER
                DISPLAYCOUNT=1
            fi
            ((DISPLAYCOUNT+=1))
            #====================================================================================
            printf "${BOX[BVV].BOLD}" #First border

            # Time
            printf "%${CW[TIME]}s" "${VALUES[TIME]}"
            printf "${BOX[BVV].BOLD}"

            COLUMNS=""
            COLUMNS="THREAD_R THREAD_B THREAD_P THREAD_W brk "
            COLUMNS+="MEM_AVM MEM_FRE brk "
            COLUMNS+="PAGE_FI PAGE_FO PAGE_PI PAGE_PO PAGE_FR PAGE_SR PAGE_FR2SR brk "
            COLUMNS+="FAULT_IN FAULT_SY FAULT_CS brk " 
            COLUMNS+="CPU_US CPU_SY CPU_ID CPU_WA CPU_PC CPU_EC brk"

            if (( ${VALUES[PAGE_SR]} > 0 )); then
                RATIO=$((${VALUES[PAGE_SR]}/${VALUES[PAGE_FR]}))
            else
                RATIO=0
            fi
            VALUES[PAGE_FR2SR]=${RATIO}

            for COLUMN in ${COLUMNS}; do
                if [[ "${COLUMN}" == "brk" ]]; then
                    # Print bold column break. 
                    printf "\b${BOX[BVV].BOLD}" # That \b erases the last 'dull' pipe
                else
                    val=${VALUES[${COLUMN}]}
                    # echo "=== ${COLUMN}=${val} :: ${THRESH[${COLUMN}][0]}"
                    # echo "${COLUMN} - ${val}"
                    if (( val <= ${THRESH[${COLUMN}][0]} )); then
                        colour="NORMAL"
                        INFO[${COLUMN}]=0
                    elif (( val <= ${THRESH[${COLUMN}][1]} )); then
                        colour="PURPLE_F"
                        INFO[${COLUMN}]=1
                    elif (( val <= ${THRESH[${COLUMN}][2]} )); then
                        colour="YELLOW_F"
                        INFO[${COLUMN}]=2
                    elif (( val <= ${THRESH[${COLUMN}][3]} )); then
                        colour="RED_F"
                        INFO[${COLUMN}]=3
                    else
                        colour="RED_B"
                        INFO[${COLUMN}]=4
                    fi
                    # printf "${FONT[${colour}]}"
                    # echo;echo;echo "CW:${COLUMN}:${CW[${COLUMN}]}s"
                    printf "${FONT[${colour}]}%${CW[${COLUMN}]}s${FONT[NORMAL]}" "${val}"
                    # printf ""
                    printf "${BOX[BVV].DULL}"
                fi
            done
            printf "\n"
        fi
    done
}
#====================================================================================
GETOPTS "${@}"
shift $((OPTIND - 1))
vmstat_TICS=$1
vmstat_COUNT=$2

main
CLEANUP
