#!/usr/bin/ksh93
SRC_SPECIALFONT_VERSION=0.0.0

#====================================================================================
typeset -A FONT=( 
	[UNDERLINE]="\033[4m" 
	[NORMAL]="\033[0m"
	[BOLD]="\033[37;1m"
	[BLACK_F]="\033[0;30m"
	[RED_F]="\033[0;31m"
	[GREEN_F]="\033[0;32m"
	[BROWN_F]="\033[0;33m"
	[BLUE_F]="\033[0;34m"
	[PURPLE_F]="\033[0;35m"
	[CYAN_F]="\033[0;36m"
	[LIGHTGRAY_F]="\033[0;37m"
	[DARKGRAY_F]="\033[1;30m"
	[LIGHTRED_F]="\033[1;31m"
	[LIGHTGREEN_F]="\033[1;32m"
	[YELLOW_F]="\033[1;33m"
	[LIGHTBLUE_F]="\033[1;34m"
	[PINK_F]="\033[1;35m"
	[LIGHTCYAN_F]="\033[1;36m"
	[WHITE_F]="\033[1;37m"
	[BLACK_B]="\033[40m"
	[RED_B]="\033[41m"
	[GREEN_B]="\033[42m" 
	[YELLOW_B]="\033[43m"
	[BLUE_B]="\033[44m"
	[MAGENTA_B]="\033[45m"
	[CYAN_B]="\033[46m"
	[WHITE_B]="\033[47m"
)

typeset -A FONT_FB1=( 
	[0]="${FONT[WHITE_F]}${FONT[BLUE_B]}" [1]="${FONT[BLACK_F]}${FONT[GREEN_B]}" [2]="${FONT[WHITE_F]}${FONT[MAGENTA_B]}" 
	[3]="${FONT[WHITE_F]}${FONT[CYAN_B]}" [4]="${FONT[BLACK_F]}${FONT[YELLOW_B]}" [5]="${FONT[WHITE_F]}${FONT[RED_B]}" 
	[6]="${FONT[BLACK_F]}${FONT[WHITE_B]}" [7]="${FONT[WHITE_F]}${FONT[BLACK_B]}"
)
FONT_FB1_COUNT=8
typeset -A FONT_FB2=( 
	[0]="${FONT[BLACK_F]}${FONT[CYAN_B]}" [1]="${FONT[BLACK_F]}${FONT[RED_B]}" [2]="${FONT[WHITE_F]}${FONT[YELLOW_B]}" 
	[3]="${FONT[WHITE_F]}${FONT[MAGENTA_B]}" [4]="${FONT[WHITE_F]}${FONT[BLUE_B]}" [5]="${FONT[MAGENTA_F]}${FONT[GREEN_B]}" 
	[6]="${FONT[BLACK_F]}${FONT[WHITE_B]}" [7]="${FONT[WHITE_F]}${FONT[BLACK_B]}"
)
FONT_FB2_COUNT=8
#====================================================================================


#====================================================================================
# Set up the boxes!
typeset -A BOX
BOX["CLR"]=( # Lower right hand corner
	NORM=$(echo "\033(0j\033(B\033[0m}") #)) 
	BOLD=$(echo "${FONT[BOLD]}\033(0j\033(B\033[0m${FONT[NORMAL]}") #)) 
	DULL=$(echo "${FONT[DARKGRAY_F]}\033(0j\033(B\033[0m${FONT[NORMAL]}") #))
)
BOX["CUR"]=( # Upper right hand corner
	NORM=$(echo "\033(0k\033(B\033[0m") #))
	BOLD=$(echo "${FONT[BOLD]}\033(0k\033(B\033[0m${FONT[NORMAL]}") #)) 
	DULL=$(echo "${FONT[DARKGRAY_F]}\033(0k\033(B\033[0m${FONT[NORMAL]}") #))
)
BOX["CUL"]=( # Upper left hand corner
	NORM=$(echo "\033(0l\033(B\033[0m") #))
	BOLD=$(echo "${FONT[BOLD]}\033(0l\033(B\033[0m${FONT[NORMAL]}") #))
	DULL=$(echo "${FONT[DARKGRAY_F]}\033(0l\033(B\033[0m${FONT[NORMAL]}") #))
)
BOX["CLL"]=( # Lower left hand corner
	NORM=$(echo "\033(0m\033(B\033[0m") #)) 
	BOLD=$(echo "${FONT[BOLD]}\033(0m\033(B\033[0m${FONT[NORMAL]}") #)) 
	DULL=$(echo "${FONT[DARKGRAY_F]}\033(0m\033(B\033[0m${FONT[NORMAL]}") #)) 
)
BOX["CMX"]=( # Midpoint X
	NORM=$(echo "\033(0n\033(B\033[0m") #)) 
	BOLD=$(echo "${FONT[BOLD]}\033(0n\033(B\033[0m${FONT[NORMAL]}") #))
	DULL=$(echo "${FONT[DARKGRAY_F]}\033(0n\033(B\033[0m${FONT[NORMAL]}") #)) 
)
BOX["BHH"]=( # High bar
	NORM=$(echo "\033(0o\033(B\033[0m") #)) 
	BOLD=$(echo "${FONT[BOLD]}\033(0o\033(B\033[0m${FONT[NORMAL]}") #)) 
	DULL=$(echo "${FONT[DARKGRAY_F]}\033(0o\033(B\033[0m${FONT[NORMAL]}") #)) 
)
BOX["BHM"]=( # Middle-high bar
	NORM=$(echo "\033(0p\033(B\033[0m") #))
	BOLD=$(echo "${FONT[BOLD]}\033(0p\033(B\033[0m${FONT[NORMAL]}") #)) 
	DULL=$(echo "${FONT[DARKGRAY_F]}\033(0p\033(B\033[0m${FONT[NORMAL]}") #)) 
)
BOX["BMM"]=( # Midbar
	NORM=$(echo "\033(0q\033(B\033[0m") #))
	BOLD=$(echo "${FONT[BOLD]}\033(0q\033(B\033[0m${FONT[NORMAL]}") #))
	DULL=$(echo "${FONT[DARKGRAY_F]}\033(0q\033(B\033[0m${FONT[NORMAL]}") #)) 
)
BOX["BML"]=( # Mid-Low bar
	NORM=$(echo "\033(0r\033(B\033[0m") #))
	BOLD=$(echo "${FONT[BOLD]}\033(0r\033(B\033[0m${FONT[NORMAL]}") #))
	DULL=$(echo "${FONT[DARKGRAY_F]}\033(0r\033(B\033[0m${FONT[NORMAL]}") #)) 
)
BOX["BLL"]=( # Lowbar
	NORM=$(echo "\033(0s\033(B\033[0m") #)) 
	BOLD=$(echo "${FONT[BOLD]}\033(0s\033(B\033[0m${FONT[NORMAL]}") #)) 
	DULL=$(echo "${FONT[DARKGRAY_F]}\033(0s\033(B\033[0m${FONT[NORMAL]}") #)) 
)
BOX["CVR"]=(  # Corner Vertical Midpoint Right
	NORM=$(echo "\033(0t\033(B\033[0m") #))
	BOLD=$(echo "${FONT[BOLD]}\033(0t\033(B\033[0m${FONT[NORMAL]}") #)) 
	DULL=$(echo "${FONT[DARKGRAY_F]}\033(0t\033(B\033[0m${FONT[NORMAL]}") #)) 
)
BOX["CVL"]=( # Corner Vertical Midpoint Left
	NORM=$(echo "\033(0u\033(B\033[0m") #)) 
	BOLD=$(echo "${FONT[BOLD]}\033(0u\033(B\033[0m${FONT[NORMAL]}") #)) 
	DULL=$(echo "${FONT[DARKGRAY_F]}\033(0u\033(B\033[0m${FONT[NORMAL]}") #)) 
)
BOX["CHU"]=( # Corner Horizontal Midpoint Up
	NORM=$(echo "\033(0v\033(B\033[0m") #)) 
	BOLD=$(echo "${FONT[BOLD]}\033(0v\033(B\033[0m${FONT[NORMAL]}") #))
	DULL=$(echo "${FONT[DARKGRAY_F]}\033(0v\033(B\033[0m${FONT[NORMAL]}") #))
)
BOX["CHD"]=(  # Corner Horizontal Midpoint Down
	NORM=$(echo "\033(0w\033(B\033[0m") #))
	BOLD=$(echo "${FONT[BOLD]}\033(0w\033(B\033[0m${FONT[NORMAL]}") #)) 
	DULL=$(echo "${FONT[DARKGRAY_F]}\033(0w\033(B\033[0m${FONT[NORMAL]}") #))
)
BOX["BVV"]=( # Vertical Bar
	NORM=$(echo "\033(0x\033(B\033[0m") #)) 
	BOLD=$(echo "${FONT[BOLD]}\033(0x\033(B\033[0m${FONT[NORMAL]}") #))
	DULL=$(echo "${FONT[DARKGRAY_F]}\033(0x\033(B\033[0m${FONT[NORMAL]}") #))
)
