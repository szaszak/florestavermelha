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
# When running the automation scripts, there may have ocurred some error that
# passed unnoticed. So maybe not every folder inside our project may have
# the files .size and .fps that we use as reference for other automation 
# scripts in the workflow. This script checks if all the folders that have
# DNGs also have these two reference files in it and outputs the folders that
# do not have them. The idea is to use it together with the script
# "Fix_size_and_fps_files_in_folders.sh".


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
DNG_FOLDER="$BASE_FOLDER/01_DNG_Files";

function removeEmptyFilesList {
	if [ -f empty_size_files.txt ]; then rm empty_size_files.txt; fi;
	if [ -f empty_fps_files.txt ]; then rm empty_fps_files.txt; fi;
	}

removeEmptyFilesList;

find $DNG_FOLDER -maxdepth 2 -type f -size 0 -name *.size >> empty_size_files.txt;
find $DNG_FOLDER -maxdepth 2 -type f -size 0 -name *.fps >> empty_fps_files.txt;	

echo -e "\n";
echo -e "\e[2;31mThe following .size files are empty:\e[00m";
cat empty_size_files.txt;
	
echo -e "\n";
echo -e "\e[2;31mThe following .fps files are empty:\e[00m";
cat empty_fps_files.txt;
echo -e "\n";

removeEmptyFilesList;
