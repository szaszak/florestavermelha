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

# Script made for the 'Floresta Vermelha' (Red Forest) project. Check:
# http://szaszak.wordpress.com/digital_cinema_automation for more info and
# http://florestavermelha.org for the film production blog.


# Description
# When doing the post production of the film, using UFRaw to color grade the
# stills, it is convenient to check the progress you are making by checkinh
# which folders have already been worked on and which weren't. This script
# checks the folder where the selected DNGs for post-production are and outputs
# two lists: one with folders that have .ufraw confiuration files and the ones
# that don't.



######### SCRIPT VARIABLES

### FOLDERS
if [ -z "$1" ]; then 
	# Sanity check. User must inform the name of a folder.
	echo -e "\e[0;31mYou must declare the name of a folder to be used when running the script.\n\
	Re-run the script this way 'sh script.sh name_of_folder'.\e[00m" && exit; 
	fi;

FOLDER_NAME="$1";
if [ "${FOLDER_NAME#${FOLDER_NAME%?}}" = "/" ];	then 
	# if last character in $1 is "/"; then remove "/".
	FOLDER_NAME="${FOLDER_NAME%?}"; fi; 

BASE_FOLDER="`pwd`/$FOLDER_NAME";
POST_FOLDER="$BASE_FOLDER/04_Post_Production_Files";

echo -e "\n";
for i in `ls -d $POST_FOLDER/*/`; do
	NUMBER_OF_FILES=`find $i -maxdepth 1 -type f -name *.ufraw | wc -l`;
	if [ $NUMBER_OF_FILES -gt 0 ]; then
		FOLDER_BASENAME=`echo $i | xargs -n 1 basename`;
		echo -e "\e[2;34mFolder $FOLDER_BASENAME has one or more .ufraw files.\e[00m";
		fi;
	done;
	
echo -e "\n";
for i in `ls -d $POST_FOLDER/*/`; do
	NUMBER_OF_FILES=`find $i -maxdepth 1 -type f -name *.ufraw | wc -l`;
	if [ $NUMBER_OF_FILES -eq 0 ]; then
		FOLDER_BASENAME=`echo $i | xargs -n 1 basename`;
		echo -e "\e[2;31mFolder $FOLDER_BASENAME doesn't have .ufraw files.\e[00m";
		fi;
	done;
	
echo -e "\n";
