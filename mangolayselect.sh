#!/bin/bash
# mangolaycycle.sh - in mangowc, this script will change the current tag
# if "select" is passed in as argument, will give a menu to select from
# (rofi command is used but can sub a different dmenu)
# the result is written to a tag rules file that can be sourced
# in mango config file (i.e. source=~/.config/mango/tagrules.conf)


# set layout to what is passed in as first argument
set_layout()
{
	mmsg -l $1
}

# switch layout to next one in list
cycle_next()
{
	# go to next layout in list
	mmsg -d switch_layout

}

# get current active tag number
get_tag_number()
{
	# current monitor is first parameter
	cur_mon="$1"
	# generate tag information using mango ipc
	mmsg -g -t > /tmp/currenttag
	# find info for active tag in a line eg.: HDMI-A-1 tag 2 1 0 0
	tagnum=$(grep 'tag [0-9] 1' /tmp/currenttag | grep "$cur_mon" | grep tag | cut -d " " -f 3)
	# return value
	echo $tagnum
}

get_layout_info()
{

	result=$(mmsg -g -o | grep "selmon 1")
	result_array=($result)
	current_monitor=${result_array[0]}
	result=$(mmsg -g -l | grep "$current_monitor")
    	result_array=($result)
	current_layout=${result_array[2]}
	
	# return layout abbreviation and monitor name
	local return_array=(${result_array[2]} ${current_monitor} )
	echo "${return_array[@]}"
}

if [[ $1 = "select" ]]; then

	listLayouts=""
	listLayouts+="Center Tile\n"
	listLayouts+="Deck\n"
	listLayouts+="Grid\n"
	listLayouts+="Monocle\n"
	listLayouts+="Right Tile\n"
	listLayouts+="Scroller\n"
	listLayouts+="Tile\n"
	listLayouts+="Tile Grid Mix\n"
	listLayouts+="Vertical Deck\n"
	listLayouts+="Vertical Grid\n"
	listLayouts+="Vertical Scroller\n"
	listLayouts+="Vertical Tile\n"
	
	
	# select with rofi (or some other dmenu mode thing)
	selection=$(echo -e "$listLayouts" | rofi -i -dmenu -p "Layout " -theme-str ' window { width: 15%; } listview { eachline: 12; } ')
	
	# need to get abbreviation corresponding to what was chosen
	case $selection in
		"Center Tile") layout_code="CT"	;;
		"Deck")	layout_code="K"	;;
		"Grid")	layout_code="G"	;;
		"Monocle") layout_code="M"	;;
		"Right Tile") layout_code="RT" ;;
		"Scroller")	layout_code="S"	;;
		"Tile")	layout_code="T"	;;
		"Tile Grid Mix") layout_code="TG" ;;
		"Vertical Scroller") layout_code="VS" ;;
		"Vertical Grid") layout_code="VG" ;;
		"Vertical Tile") layout_code="VT" ;;
		"Vertical Deck") layout_code="VK" ;;
		*)
			exit
		;;
	
	esac
	
	set_layout "$layout_code"

else
	cycle_next
fi


results=($(get_layout_info))
current_layout=${results[0]}
monitor_name=${results[1]}
tagnumber=($(get_tag_number $monitor_name))

case $current_layout in
	"G") layout_desc="Grid"	;;
	"M") layout_desc="Monocle" ;;
	"K") layout_desc="Deck"	;;
	"S") layout_desc="Scroller"	;;
	"T") layout_desc="Tile"	;;
	"TG") layout_desc="Tile Grid Mix" ;;
	"VS") layout_desc="Vertical Scroller" ;;
	"VT") layout_desc="Vertical Tile" ;;
	"VG") layout_desc="Vertical Grid" ;;
	"VK") layout_desc="Vertical Deck" ;;
	"CT") layout_desc="Center Tile"	;;
	"RT") layout_desc="Right Tile" ;;
	*)
		echo "$current_layout not mapped to any description"
		exit

	;;
esac

# show notification if you want
notify-send "$layout_desc layout [$current_layout]" -t 2500

# layout name has to be lower case and spaces replaced by _
layout_desc_lower_case="${layout_desc,,}"
layout_desc_lower_case="${layout_desc_lower_case// /_}"
new_rule="tagrule=id:$tagnumber,monitor_name:$monitor_name,layout_name:$layout_desc_lower_case"
search_for="tagrule=id:$tagnumber,monitor_name:$monitor_name,layout_name:"


# the following takes the current tag rule and writes it to
# a conf file which can be sourced in mango conf file
# so the rules will stay in effect on reloading/restarting mangowc
# i.e. source=~/.config/mango/tagrules.conf

config_file=~/.config/mango/tagrules.conf
temp_file=/tmp/tagrules.conf

# put the new rule into temp file
echo "$new_rule" > $temp_file

while read eachline; do
	# this is the line being replaced, so don't copy
	# from current file
	if [[ $eachline* = *"$search_for"* ]]; then
		# dummy code
		x=1
	# copy other eachline into new file
	else
		echo "$eachline" >> $temp_file
	fi

done <$config_file

# create new sorted list and output to config
cat $temp_file | sort -u > $config_file
