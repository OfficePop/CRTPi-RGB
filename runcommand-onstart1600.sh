#!/usr/bin/env bash
#=====================================================================================================================================
#title           :	runcommand-onstart.sh TEMP
#=====================================================================================================================================

# get the system name
system=$1

# get the emulator name
emul=$2
emul_lr=${emul:0:2}

# get the full path filename of the ROM
rom_fp=$3
rom_bn=$3

# Game or Rom name
rom_bn="${rom_bn%.*}"
rom_bn="${rom_bn##*/}"

# Determine if arcade or fba then determine resolution, set hdmi_timings else goto console section
if [[ "$system" == "arcade" ]] || [[ "$system" == "fba" ]] || [[ "$system" == "mame-libretro" ]] || [[ "$system" == "neogeo" ]] ; then
	# get the line number matching the rom
	rom_ln=$(tac /opt/retropie/configs/all/resolution.ini | grep -w -n $rom_bn | cut -f1 -d":")
	
	# get resolution of rom
	rom_resolution=$(tac /opt/retropie/configs/all/resolution.ini | sed -n "$rom_ln,$ p" | grep -m 1 -F '[') 
	rom_resolution=${rom_resolution#"["}
	rom_resolution=${rom_resolution//]}
	rom_resolution=$(echo $rom_resolution | sed -e 's/\r//g')
	rom_resolution_width=$(echo $rom_resolution | cut -f1 -d"x")
	rom_resolution_height=$(echo $rom_resolution | cut -f2 -d"x")
	
# Set rom_resolution_height for 480p and 448p roms
	if [ $rom_resolution_height == "480" ]; then
		rom_resolution_height="240"
	elif [ $rom_resolution_height == "448" ]; then
		rom_resolution_height="224"
	fi	
	
# Create rom_name.cfg
	if ! [ -f "$rom_fp"".cfg" ]; then 
		touch "$rom_fp"".cfg" 
	fi
	
# Set custom_viewport_height
	if ! grep -q "custom_viewport_height" "$rom_fp"".cfg"; then
		echo -e "custom_viewport_height = ""\"$rom_resolution_height\"" >> "$rom_fp"".cfg" 2>&1
	fi
	
# determine if vertical  
	if grep -w "$rom_bn" /opt/retropie/configs/all/vertical.txt ; then 
		# Add vertical parameters (video_allow_rotate = "true")
		if ! grep -q "video_allow_rotate" "$rom_fp"".cfg"; then
			echo -e "video_allow_rotate = \"true\"" >> "$rom_fp"".cfg" 2>&1
		fi
		
		# Add vertical parameters (video_rotation = 3)
		if ! grep -q "video_rotation" "$rom_fp"".cfg"; then
			echo -e "video_rotation = \"3\"" >> "$rom_fp"".cfg" 2>&1
		fi	
		
		# Add integer scale parameters (video_scale_integer = true)
		if ! grep -q "video_scale_integer" "$rom_fp"".cfg"; then
			echo -e "video_scale_integer = \"true\"" >> "$rom_fp"".cfg" 2>&1
		fi
	fi

# set the custom_viewport_width 
	if ! grep -q "custom_viewport_width" "$rom_fp"".cfg"; then 
		echo -e "custom_viewport_width = ""\"1600\"" >> "$rom_fp"".cfg"  2>&1
	fi
fi

# determine and set variable resolutions for libretto cores
if [[ "$emul_lr" == "lr" ]]; then
		vcgencmd hdmi_timings 1600 1 73 157 204 240 1 4 3 15 0 0 0 60 0 32000000 1 > /dev/null #CRTPi 1600x240p Timing Adjusted
		tvservice -c "DMT 87" > /dev/null
		fbset -depth 8 && fbset -depth 16 && fbset -depth 24 -xres 1600 -yres 240 > /dev/null #24b depth
	fi

# otherwise -- determine and set variable resolutions for non-libretto cores	
elif
# for eDuke32 switch to 320x200p
	[[ "$system" == "eduke32" ]] ||
	[[ "$system" == "duke3d" ]] ||
	[[ "$system" == "scummvm" ]] ||
	[[ "$system" == "dosbox" ]] ||
	[[ "$system" == "pc" ]] ||
	[[ "$system" == "c64" ]] ; then
	vcgencmd hdmi_timings 320 1 10 30 40 200 1 28 3 36 0 0 0 60 0 6400000 1 > /dev/null #CRTPi 320x200p Adjusted
	tvservice -c "DMT 87" 
	fbset -depth 8 && fbset -depth 16 && fbset -depth 24 -xres 320 -yres 200 > /dev/null #24b depth
	
else
# for all other non-libretro emulators switch to 320x240p
	vcgencmd hdmi_timings 320 1 15 30 42 240 1 4 3 15 1 0 0 60 0 6400000 1 > /dev/null #CRTPi 320x240p Timing Adjusted
	tvservice -c "DMT 87" 
	fbset -depth 8 && fbset -depth 16 && fbset -depth 24 -xres 320 -yres 240 > /dev/null #24b depth
fi

#####