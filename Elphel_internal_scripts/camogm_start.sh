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
# This scripts prepares the Elphel camera to record at maximum quality.
# It kills all camogm and autoexposure processes to free the processor for
# streaming and recording only, without dropping frames. The camogm interface
# then 'freezes' (with the live histogram) but can be made to run again by
# clicking on its 'update' icon.

# This script should be inside Elphel's recording device and ran from there.

# Check http://szaszak.wordpress.com/linux/elphel-as-a-digital-cinema-camera
# for more information on how the recording workflow has been thought for
# the movie 'Floresta Vermelha' (Red Forest) - http://florestavermelha.org

# The order of the scripts is:
# camogm_start.sh > record_camogm.sh > stopRecording_camogm.sh or
# camogm_start.sh > audioVideo_record_camogm.sh > audioVideo_stop_camogm.sh


killall camogm; #echo "All existing camogm processess killed."
killall autoexposure;

camogm /var/state/camogm_cmd &

echo "status; exif 1; format=mov; duration=600; length=1000000000; status=/var/tmp/camogm.status" > /var/state/camogm_cmd &

echo "Camogm has started and is waiting for recording..."
