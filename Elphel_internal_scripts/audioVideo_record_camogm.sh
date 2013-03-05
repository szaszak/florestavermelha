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


# Description
# This scripts starts AV recording in the Elphel camera. Audio must then be
# synced with video in a video editor later. The script kills all camogm and 
# autoexposure processes to free the processor for streaming and recording 
# only, without dropping frames. The camogm interface then 'freezes' (with the 
# live histogram) but can be made to run again by clicking on its 'update' icon.

# This script should be inside Elphel's recording device and ran from there.

# Check http://szaszak.wordpress.com/linux/elphel-as-a-digital-cinema-camera
# for more information on how the recording workflow has been thought for
# the movie 'Floresta Vermelha' (Red Forest) - http://florestavermelha.org

# The order of the scripts is:
# camogm_start.sh > record_camogm.sh > stopRecording_camogm.sh or
# camogm_start.sh > audioVideo_record_camogm.sh > audioVideo_stop_camogm.sh

MOUNT_POINT="/var/hdd";
RECORDING_PREFIX="$1"; # A prefix must be informed for later AV sync.

if [ -z "$1" ]; then 
	# Sanity check. User must inform the name for the sound file.
	echo -e "\e[0;31mYou must inform a name for the sound file.\n\
	Re-run the script this way 'sh script.sh name_of_the_file'.\e[00m" && exit; 
	fi;

echo "Started recording..."

killall camogm; #echo "All existing camogm processess killed."
killall autoexposure;

sh audio_rec.sh $1 &

echo "status; exif=1; format=mov; duration=60000; length=100000000000; prefix=$MOUNT_POINT/$1; start; status=/var/tmp/camogm.status" > /var/state/camogm_cmd &
