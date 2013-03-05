#!/bin/bash

# ##### BEGIN GPL LICENSE BLOCK #####
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software Foundation,
# Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# ##### END GPL LICENSE BLOCK #####


# Author: qazav_szaszak - qazav3.0@gmail.com

# Description
# This scripts records only audio in the Elphel 353 camera. The microphone 
# should be plugged into Elphel's USB port. The name of the audio file has to
# be informed in the terminal, when running the script. The program arecord
# is used for the recording.

# This script should be inside Elphel's recording device and ran from there.

# Check http://szaszak.wordpress.com/linux/elphel-as-a-digital-cinema-camera
# for more information on how the recording workflow has been thought for
# the movie 'Floresta Vermelha' (Red Forest) - http://florestavermelha.org


MOUNT_POINT="/var/hdd";

if [ -z "$1" ]; then 
	# Sanity check. User must inform the name for the sound file.
	echo -e "\e[0;31mYou must inform a name for the sound file.\n\
	Re-run the script this way 'sh script.sh name_of_the_file'.\e[00m" && exit; 
	fi;

FILE_NAME="$1";
IDENTIFIER="USB Audio"; # change to Microphone's identifier
AUDIO_CARD=`/bin/arecord -l | grep "$IDENTIFIER" | grep -o "[0-9]" | head -1`;
AUDIO_DEVICE=`/bin/arecord -l | grep "$IDENTIFIER" | grep -o "[0-9]" | tail -1`;

/bin/arecord -f S16_LE -r 48000 --vumeter=mono -D hw:$AUDIO_CARD,$AUDIO_DEVICE $MOUNT_POINT/$FILE_NAME.wav
