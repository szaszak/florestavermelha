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
# Inspired by the work of Claudio Maléfico and his img2list for Cinelerra.

# Script made for the 'Floresta Vermelha' (Red Forest) project. Check:
# http://szaszak.wordpress.com/digital_cinema_automation for more info and
# http://florestavermelha.org for the film production blog.


# Description
# Creates a text file (.i2l) that contains the full-path references to all 
# images in the folder and that is readable by Cinelerra as a movie sequence
# instead of separate images.

# Run as: sh script_name.sh FPS (where "FPS" is an integer)
# Example: sh script_name.sh 24


### FOLDERS

if [ -z "$1" ]; then 
	# Sanity check. User must inform the name of a folder.
	echo -e "\e[0;31mYou must declare the FPS to be used when running the script.\n\
	Re-run the script this way 'sh script_name.sh FPS'.\e[00m" && exit; 
	fi;

### VARIABLES

IMG_FMT="tga" # can be "jpg" or anything; "tifs" from Blender may not work.
MOVIE_FPS="$1"; # read from terminal
IMG_SIZE=`identify ls *.$IMG_FMT | head -1 | tr " " "\n" | head -3 | tail -1`;
IMG_WIDTH=`echo $IMG_SIZE | cut -d "x" -f 1`;
IMG_HEIGTH=`echo $IMG_SIZE | cut -d "x" -f 2`;

### Create an i2l file for each movie to be read by Cinelerra.
 	FOLDER_PATH=`pwd`;
 	BASENAME=`pwd | xargs -n 1 basename`;
 	IMAGE_LIST=(`ls *.$IMG_FMT | tr " " "\n"`);
 	
 	echo "TGALIST" > $BASENAME.i2l;
 	echo "$MOVIE_FPS #FPS" >> $BASENAME.i2l;
 	echo "$IMG_WIDTH #Width" >> $BASENAME.i2l;
 	echo "$IMG_HEIGTH #Height" >> $BASENAME.i2l;
 	echo "#-------------------------------------" >> $BASENAME.i2l;
 	echo "#Now the paths to the images" >> $BASENAME.i2l;
 	echo "#-------------------------------------" >> $BASENAME.i2l;
 	
 	for (( j=0; j < `ls -l *.$IMG_FMT | wc -l`; j++ )); do
	 	echo $FOLDER_PATH/${IMAGE_LIST[j]} >> $BASENAME.i2l;
 	done;
 	

