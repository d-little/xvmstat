#!/usr/bin/ksh93
#------------------------------------------------------------------------------------
# Script:  xvmstat.sh
# Date:    2013/12/05
# Author:  David Little - david.n.little@gmail.com
#  (C) 2015 by David Little The MIT License (MIT)
#------------------------------------------------------------------------------------
# Updated: 
#	2013/12/05 - DL - 0.0.0 First Draft!
#	2013/12/05 - DL - 0.0.1 Divided the numbers in the Memory Pages area by 1000 to save some space
#	2013/12/05 - DL - 0.0.2 the RunQ (r) colour coding is now based off its ratio to the CPU Count
#	2013/12/05 - DL - 0.0.3 Switched to using src_specialfont.sh
#	2013/12/06 - DL - 0.0.3 Fixed a couple of formatting bugs
#	2013/12/06 - DL - 0.0.4 Pretty big change, switched from straight `vmstat` to `vmstat -It`
#	2013/12/18 - DL - 0.0.5 Started the help page (called with -h argument)
#	2015/10/30 - DL - 1.0.0 Release for public consumption
VERSION="1.0.0"
UPDATED="2015/10/30"
#------------------------------------------------------------------------------------
# Purpose:
#  Make the 'vmstat' output actually useful. The more colours on screen, the worse things are.
#	
# Use:
#  Exactly the same as vmstat
#
# Comments:
# Useful Reading: 
#	http://www.ibmsystemsmag.com/aix/administrator/systemsmanagement/Examining-vmstat/?page=1
#	http://www.ibmsystemsmag.com/aix/administrator/systemsmanagement/Paging-Spaces-(1)/?page=1
#	
#   Remember the way nmon uses single-character graphs in case we ever want to use graphs:
# 		 Key(%): @=90 #=80 X=70 8=60 O=50 0=40 o=30 +=20 -=10 .=5 _=0% 
#    We can also use 
#------------------------------------------------------------------------------------
SCRIPTNAME=$(basename $0)

######
# Set up our traps
trap "CLEANUP 1" 2 3

#====================================================================================
# CLEANUP
CLEANUP()
{
	if [[ "${FIRSTHEADER}" != "" ]]; then
		printf "${BOX[CLL].BOLD} %-6s ${BOX[CHU].BOLD} %-6s ${BOX[CHU].BOLD} %-16s ${BOX[CHU].BOLD} %-37s ${BOX[CHU].BOLD} %-19s ${BOX[CHU].BOLD} %-25s ${BOX[CLR].BOLD}\n" "" "" "" "" ""|sed "s/ /${BOX[BMM].BOLD}/g"
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
	printf "${BOX[BVV].BOLD}${FONT[BOLD]}%-126s${FONT[NORMAL]}${BOX[BVV].BOLD}\n" " Sonic Toolkit 'vmstat' wrapper help and manual"
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
	echo "${BOX[BVV].BOLD}  ${FONT[BOLD]}r${FONT[NORMAL]} - Running Threads, Colour Coded vs. Number of CPUs (${SYSTEM_CPU})."
	echo "${BOX[BVV].BOLD}       ${FONT[NORMAL]}0->${SYSTEM_CPU_1_5}${FONT[NORMAL]}, ${FONT[YELLOW_F]}${SYSTEM_CPU_1_5}->${SYSTEM_CPU_1_2}${FONT[NORMAL]}, ${FONT[RED_F]}${SYSTEM_CPU_1_2}->${SYSTEM_CPU}${FONT[NORMAL]}, ${FONT[RED_B]}${SYSTEM_CPU}+${FONT[NORMAL]}"
	echo "${BOX[BVV].BOLD}  ${FONT[BOLD]}b${FONT[NORMAL]} - Threads waiting."
	echo "${BOX[BVV].BOLD}       ${FONT[NORMAL]}0->1${FONT[NORMAL]}, ${FONT[YELLOW_F]}2${FONT[NORMAL]}, ${FONT[RED_F]}3${FONT[NORMAL]}, ${FONT[RED_B]}4+${FONT[NORMAL]}"
	echo "${BOX[BVV].BOLD}  ${FONT[BOLD]}p${FONT[NORMAL]} - Mumber of threads waiting for disk io."
	echo "${BOX[BVV].BOLD}       ${FONT[NORMAL]}0->1${FONT[NORMAL]}, ${FONT[YELLOW_F]}2${FONT[NORMAL]}, ${FONT[RED_F]}3${FONT[NORMAL]}, ${FONT[RED_B]}4+${FONT[NORMAL]}"
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
	echo "${BOX[BVV].BOLD}   ${FONT[BOLD]}fr:sr${FONT[NORMAL]} - Ratio between pages freed vs. pages scanned in page-replacement algorithm."
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
	echo "${BOX[BVV].BOLD}   ${FONT[BOLD]}ent%${FONT[NORMAL]} - The percentage of entitled capacity consumed. Because the time base over which this data is computed can vary,"
	echo "${BOX[BVV].BOLD}           the entitled capacity percentage can sometimes exceed 100%. This excess is noticeable only with small "
	echo "${BOX[BVV].BOLD}           sampling intervals."
	printf "${BOX[CLL].BOLD}%-126s${BOX[CLR].BOLD}\n"|sed "s/ /${BOX[BMM].BOLD}/g"	
	exit 255
}
#------------------------------------------------------------------------------------

#====================================================================================
# GetOpts
GETOPTS()
{
	while getopts h name;	do
		case ${name} in
			h)
				USAGE
				;;
			*)		# unknown flag
				USAGE
				;;
		esac
	done
}
#------------------------------------------------------------------------------------

#====================================================================================
# Print Header
PRINTHEADER()
{
	
	if [[ "${FIRSTHEADER}" == "" ]]; then
		#printf "${BOX[CUL]} %107s ${BOX[CUR]}\n"|sed "s/ /${BOX[BMM]}/g"
		export FIRSTHEADER="TRUE"
		printf "${BOX[CUL].BOLD} %-6s ${BOX[CHD].BOLD} %-6s ${BOX[CHD].BOLD} %-16s ${BOX[CHD].BOLD} %-37s ${BOX[CHD].BOLD} %-19s ${BOX[CHD].BOLD} %-25s ${BOX[CUR].BOLD}\n" "" "" "" "" ""|sed "s/ /${BOX[BMM].BOLD}/g"
	else
		printf "${BOX[CVR].BOLD} %-6s ${BOX[CMX].BOLD} %-6s ${BOX[CMX].BOLD} %-16s ${BOX[CMX].BOLD} %-37s ${BOX[CMX].BOLD} %-19s ${BOX[CMX].BOLD} %-25s ${BOX[CVL].BOLD}\n" "" "" "" "" ""|sed "s/ /${BOX[BMM].BOLD}/g"		
	fi
	printf "${BOX[BVV].BOLD} ${FONT[BOLD]}%-6s ${BOX[BVV].BOLD} ${FONT[BOLD]}%-6s ${BOX[BVV].BOLD} ${FONT[BOLD]}%-16s ${BOX[BVV].BOLD} ${FONT[BOLD]}%-37s ${BOX[BVV].BOLD} ${FONT[BOLD]}%-19s ${BOX[BVV].BOLD} ${FONT[BOLD]}%-25s ${BOX[BVV].BOLD}\n" "Time" "Thrds" "Pages" "Paging" "Faults" "CPU Percentages"
	printf "${BOX[CVR].BOLD} %-6s ${BOX[CMX].BOLD} %-6s ${BOX[CMX].BOLD} %-16s ${BOX[CMX].BOLD} %-37s ${BOX[CMX].BOLD} %-19s ${BOX[CMX].BOLD} %-25s ${BOX[CVL].BOLD}\n" "" "" "" "" ""|sed "s/ /${BOX[BMM].BOLD}/g"
	###################
	# Section headers
	printf "${BOX[BVV].BOLD}" #First border
	printf "%8s${BOX[BVV].BOLD}" "hh:mm:ss" # r
	##
	# Process queues
	printf "%2s${BOX[BVV].DULL}" "r" # r
	printf "%2s${BOX[BVV].DULL}" "b" # b
	printf "%2s${BOX[BVV].BOLD}" "p" # p
	##
	# Memory
	printf "%9s${BOX[BVV].DULL}" "Active" # memory-avm
	printf "%8s${BOX[BVV].BOLD}" "Free" #memory-free
	##
	# Paging
	printf "%5s${BOX[BVV].DULL}" "fi"
	printf "%5s${BOX[BVV].DULL}" "fo"
	printf "%3s${BOX[BVV].DULL}" "pi"
	printf "%3s${BOX[BVV].DULL}" "po"
	printf "%6s${BOX[BVV].DULL}" "freert"
	printf "%6s${BOX[BVV].DULL}" "scanrt"
	printf "%5s${BOX[BVV].BOLD}" "fr:sr"
	##
	# Faults
	printf "%5s${BOX[BVV].DULL}" "intrp"
	printf "%8s${BOX[BVV].DULL}" "syscalls"
	printf "%6s${BOX[BVV].BOLD}" "cntxsw"
	##
	# CPU Percentages
	printf "%-3s${BOX[BVV].DULL}" "usr"
	printf "%-3s${BOX[BVV].DULL}" "sys"
	printf "%-3s${BOX[BVV].DULL}" "idl"
	printf "%-3s${BOX[BVV].DULL}" "wai"
	printf "%-5s${BOX[BVV].DULL}" "pc"
	printf "%-5s${BOX[BVV].BOLD}" "ent%"
	printf "\n"
}
#------------------------------------------------------------------------------------

#====================================================================================
# Import the specialfont
source ./src_specialfont.sh
#------------------------------------------------------------------------------------

#====================================================================================
GETOPTS "${@}"
shift $((OPTIND - 1))
vmstat_TICS=$1
vmstat_COUNT=$2
#------------------------------------------------------------------------------------

#====================================================================================
DISPLAYCOUNT=99999
typeset -a INFO
vmstat -It ${vmstat_TICS} ${vmstat_COUNT}|while read -A LINE; do
	if [[ "${LINE[0]}" == "System" ]]; then
		SYSTEM_CPU=${LINE[2]#*=}	
	elif [[ "${LINE[0]}" != ?(""|"System"|"kthr"|"--------"|"r") ]]; then
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
		
		#########
		# Time
		printf "%8s" "${LINE[20]}"
		printf "${BOX[BVV].BOLD}"
		
		###########
		# Let's colour code the run queue based off the number of CPUs in the system
		RUNQ=${LINE[0]}
		if (( RUNQ <= $((SYSTEM_CPU/1.5)) )); then
			printf "%2s" "${RUNQ}"
			INFO[RUNQ]=0
		elif (( RUNQ <= $((SYSTEM_CPU/1.2)) )); then
			printf "${FONT[YELLOW_F]}%2s${FONT[NORMAL]}" "${RUNQ}"
			INFO[RUNQ]=1
		elif (( RUNQ <= SYSTEM_CPU )); then
			printf "${FONT[RED_F]}%2s${FONT[NORMAL]}" "${RUNQ}"
			INFO[RUNQ]=2
		else
			printf "${FONT[RED_B]}%2s${FONT[NORMAL]}" "${RUNQ}"
			INFO[RUNQ]=3
		fi
		printf "${BOX[BVV].DULL}"
		
		###########
		# Let's colour code the wait queue run queue
		WAITB=${LINE[1]}
		case ${WAITB} in
			0|1) printf "%2s" "${LINE[1]}" # b
				INFO[WAITB]=0
			;;
			2)	printf "${FONT[YELLOW_F]}%2s${FONT[NORMAL]}" "${WAITB}" # b
				INFO[WAITB]=1
			;;
			3)	printf "${FONT[RED_F]}%2s${FONT[NORMAL]}" "${WAITB}" # b
				INFO[WAITB]=2
			;;
			*)	printf "${FONT[RED_B]}%2s${FONT[NORMAL]}" "${WAITB}" # b
				INFO[WAITB]=3
			;;
		esac
		printf "${BOX[BVV].DULL}"
				
		WAITP=${LINE[2]}
		case ${WAITP} in
			0) printf "%2s" "${WAITP}" # p
				INFO[WAITP]=0
			;;
			1)	printf "${FONT[YELLOW_F]}%2s${FONT[NORMAL]}" "${WAITP}" # p
				INFO[WAITP]=1
			;;
			2)	printf "${FONT[RED_F]}%2s${FONT[NORMAL]}" "${WAITP}" # p
				INFO[WAITP]=2
			;;
			*)	printf "${FONT[RED_B]}%2s${FONT[NORMAL]}" "${WAITP}" # p
				INFO[WAITP]=3
			;;
		esac
		printf "${BOX[BVV].BOLD}"

		MEM_AVM=${LINE[3]}
		printf "%9s${BOX[BVV].DULL}" "$((MEM_AVM))" #memory-avm
		MEM_FRE=${LINE[4]}
		printf "%8s${BOX[BVV].BOLD}" "$((MEM_FRE))" #memory-free
				
		PAGE_FI=${LINE[5]}
		case ${PAGE_FI} in
			?|??|???|????)	
				printf "%5s" "${PAGE_FI}"
				INFO[PAGE_FI]=0
			;;
			[123]???)	
				printf "${FONT[YELLOW_F]}%5s${FONT[NORMAL]}" "${PAGE_FI}"
				INFO[PAGE_FI]=1
			;;
			[456]???)
				printf "${FONT[RED_F]}%5s${FONT[NORMAL]}" "${PAGE_FI}"
				INFO[PAGE_FI]=2
			;;
			*)	
				printf "${FONT[RED_B]}%5s${FONT[NORMAL]}" "${PAGE_FI}"
				INFO[PAGE_FI]=3
			;;
		esac
		printf "${BOX[BVV].DULL}"
		PAGE_FO=${LINE[6]}
		case ${PAGE_FO} in
			?|??|???|????) 
				printf "%5s" "${PAGE_FO}"
				INFO[PAGE_FO]=0
			;;
			[123]???)	
				printf "${FONT[YELLOW_F]}%5s${FONT[NORMAL]}" "${PAGE_FO}"
				INFO[PAGE_FO]=1
			;;
			[456]???)	
				printf "${FONT[RED_F]}%5s${FONT[NORMAL]}" "${PAGE_FO}"
				INFO[PAGE_FO]=2
			;;
			*)	
				printf "${FONT[RED_B]}%5s${FONT[NORMAL]}" "${PAGE_FO}"
				INFO[PAGE_FO]=3
			;;
		esac
		printf "${BOX[BVV].DULL}"
		
		
		
		PAGE_PI=${LINE[7]}
		PAGE_PO=${LINE[8]}
		case ${PAGE_PI} in
			[0-9]) 
				printf "%3s" "${PAGE_PI}"
				INFO[PAGE_PI]=0
			;;
			[1-5][0-9])	
				printf "${FONT[YELLOW_F]}%3s${FONT[NORMAL]}" "${PAGE_PI}"
				INFO[PAGE_PI]=1
			;;
			[6-9][0-9])	
				printf "${FONT[RED_F]}%3s${FONT[NORMAL]}" "${PAGE_PI}"
				INFO[PAGE_PI]=2
			;;
			*)	printf "${FONT[RED_B]}%3s${FONT[NORMAL]}" "${PAGE_PI}"
				INFO[PAGE_PI]=3
			;;
		esac
		printf "${BOX[BVV].DULL}"
		case ${PAGE_PO} in
			[0-9]) printf "%3s" "${PAGE_PO}"
			INFO[PAGE_PO]=0
			;;
			[1-5][0-9])	printf "${FONT[YELLOW_F]}%3s${FONT[NORMAL]}" "${PAGE_PO}"
			INFO[PAGE_PO]=1
			;;
			[6-9][0-9])	printf "${FONT[RED_F]}%3s${FONT[NORMAL]}" "${PAGE_PO}"
			INFO[PAGE_PO]=2
			;;
			*)	printf "${FONT[RED_B]}%3s${FONT[NORMAL]}" "${PAGE_PO}"
			INFO[PAGE_PO]=3
			;;
		esac
		printf "${BOX[BVV].DULL}"
		
		
		PAGE_FR=${LINE[9]}
		PAGE_SR=${LINE[10]}		
		printf "%6s${BOX[BVV].DULL}" "${PAGE_FR}" #page-fr
		printf "%6s${BOX[BVV].DULL}" "${PAGE_SR}" #page-sr
		if (( PAGE_SR > 0 )); then
			RATIO=$((PAGE_SR/PAGE_FR))
			case ${RATIO} in
			 [0-4]) 
				printf "${FONT[NORMAL]}%5s${FONT[NORMAL]}" "1:${RATIO}"
				INFO[PAGE_SR]=0
			 ;;
			 [5-7]) 
				printf "${FONT[YELLOW_F]}%5s${FONT[NORMAL]}" "1:${RATIO}"
				INFO[PAGE_SR]=1
			 ;;
			 [8-9]) 
				printf "${FONT[RED_F]}%5s${FONT[NORMAL]}" "1:${RATIO}"
				INFO[PAGE_SR]=2
			 ;;
			 *) 
				printf "${FONT[RED_B]}%5s${FONT[NORMAL]}" "1:${RATIO}"
				INFO[PAGE_SR]=3
			 ;;
			esac
		else
			printf "${FONT[DARKGREY_F]}%5s${FONT[NORMAL]}" "n/a"
		fi
		printf "${BOX[BVV].BOLD}"
			
		printf "%5s${BOX[BVV].DULL}" "${LINE[11]}" #faults-in
		######
		#sy--reports number of system calls per second. 
		#If the value gets larger than 10,000 per second on a uniprocessor (or 10,000 per processor on an SMP), further investigation is required.
		# SYSTEM_CPU * 10,0000
		FAULTS_SY="${LINE[12]}"
		if (( FAULTS_SY <= $((SYSTEM_CPU*10000/1.4)) )); then
			printf "%8s" "${FAULTS_SY}"
			INFO[FAULTS_SY]=0
		elif (( FAULTS_SY <= $((SYSTEM_CPU*10000/1.2)) )); then
			printf "${FONT[YELLOW_F]}%8s${FONT[NORMAL]}" "${FAULTS_SY}"
			INFO[FAULTS_SY]=1
		elif (( FAULTS_SY <= SYSTEM_CPU*10000 )); then
			printf "${FONT[RED_F]}%8s${FONT[NORMAL]}" "${FAULTS_SY}"
			INFO[FAULTS_SY]=2
		else
			printf "${FONT[RED_B]}%8s${FONT[NORMAL]}" "${FAULTS_SY}"
			INFO[FAULTS_SY]=3
		fi
		printf "${BOX[BVV].DULL}"
		printf "%6s${BOX[BVV].BOLD}" "${LINE[13]}" #faults-cs

		printf "%3s${BOX[BVV].DULL}" "${LINE[14]}" # usr
		printf "%3s${BOX[BVV].DULL}" "${LINE[15]}" # sys
		printf "%3s${BOX[BVV].DULL}" "${LINE[16]}" # idl	
		
		###########
		# Let's colour code the wait cpu%
		WAITCPU=${LINE[17]}
		case ${WAITCPU} in
			[0123])
				printf "%3s" "${WAITCPU}"
				INFO[FAULTS_SY]=0
			;;
			[4-9])	
				printf "${FONT[YELLOW_F]}%3s${FONT[NORMAL]}" "${WAITCPU}"
				INFO[FAULTS_SY]=1
			;;
			1[0-5])	
				printf "${FONT[RED_F]}%3s${FONT[NORMAL]}" "${WAITCPU}"
				INFO[FAULTS_SY]=2
			;;
			*)	
				printf "${FONT[RED_B]}%3s${FONT[NORMAL]}" "${WAITCPU}"
				INFO[FAULTS_SY]=3
			;;
		esac
		printf "${BOX[BVV].DULL}"
		
		printf "%5s${BOX[BVV].DULL}" "${LINE[18]}" # pc
		
		############
		# Let's colour code ENT%
		ENTPERC=${LINE[19]}
		if ((ENTPERC<70)); then
			printf "${FONT[NORMAL]}%5s${FONT[NORMAL]}" "${ENTPERC}"
			INFO[ENTPERC]=0
		elif ((ENTPERC>=70 && ENTPERC<80)); then
			printf "${FONT[YELLOW_F]}%5s${FONT[NORMAL]}" "${ENTPERC}"
			INFO[ENTPERC]=1
		elif ((ENTPERC>=80 && ENTPERC<90)); then
			printf "${FONT[LIGHTRED_F]}%5s${FONT[NORMAL]}" "${ENTPERC}"
			INFO[ENTPERC]=2
		elif ((ENTPERC>=90 && ENTPERC<100)); then
			printf "${FONT[RED_F]}%5s${FONT[NORMAL]}" "${ENTPERC}"
			INFO[ENTPERC]=3
		else
			printf "${FONT[RED_B]}%5s${FONT[NORMAL]}" "${ENTPERC}"
			INFO[ENTPERC]=4
		fi
			
		printf "${BOX[BVV].BOLD}\n"
		#echo ${LINE[*]}
	fi
done

CLEANUP
