#!/bin/bash

########################################

if [ -d "/opt/system/Tools/PortMaster/" ]; then
	controlfolder="/opt/system/Tools/PortMaster"
elif [ -d "/opt/tools/PortMaster/" ]; then
	controlfolder="/opt/tools/PortMaster"
else
	controlfolder="/roms/ports/PortMaster"
fi

source $controlfolder/control.txt

get_controls

cd $controlfolder

$ESUDO chmod 666 /dev/uinput

$ESUDO $controlfolder/oga_controls calendar.sh $param_device > /dev/null 2>&1 &

export TERM=linux
LANG=""
$ESUDO chmod 666 /dev/tty0
printf "\033c" > /dev/tty0
dialog --clear

########################################

userExit() {
$ESUDO kill -9 $(pidof oga_controls)
$ESUDO kill -9 $(pidof gptokeyb)
$ESUDO systemctl restart oga_events &
dialog --clear
printf "\033c" > /dev/tty0
exit 0
}

########################################

MainMenu() {
	local dialog_options=( 1 "Change Time" 2 "Change Date" 3 "Exit" )

	while true; do
		current_time=`date +%H:%M:%S`
		current_date=`date +%F`
		current_zone=`date +%Z`
		show_dialog=(dialog \
		--title "System Time" \
		--clear \
		--cancel-label "Exit" \
		--menu "$current_date $current_time $current_zone" 0 0 0)
	
		choices=$("${show_dialog[@]}" "${dialog_options[@]}" 2>&1 > /dev/tty0) || userExit

		for choice in $choices; do
			case $choice in
			1) ChangeTime ;;
			2) ChangeDate ;;
			3) userExit ;;
			esac
		done
		sleep 1
	done
}

########################################

ChangeTime() {
	show_dialog=(dialog --title "Time" --timebox "" 0 0)
	desired_time=$("${show_dialog[@]}" 2>&1 > /dev/tty0) || MainMenu
	if [ "$desired_time" != "" ]; then
		$ESUDO date +%T -s "$desired_time"
		$ESUDO hwclock --systohc --utc
	fi
}

########################################

ChangeDate() {
	show_dialog=(dialog --date-format "%Y-%m-%d" --title "Calendar" --no-cancel --calendar "Left to change day\nRight to change month" 0 0)
	desired_date=$("${show_dialog[@]}" 2>&1 > /dev/tty0) || MainMenu
	if [ "$desired_date" != "" ]; then
		current_time=`date +%H:%M:%S`
		$ESUDO date +%Y-%m-%d -s "$desired_date $current_time"
		$ESUDO hwclock --systohc --utc
	fi
}

########################################

MainMenu
userExit

########################################
