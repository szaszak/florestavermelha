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
# Copies the .mov files recursively from an origin folder to a destination 
# folder. All files are placed inside this one destination folder - original
# structure of directories inside originary folder is not copied. The reason
# behind this is that the automation scripts used in the 'Floresta Vermelha" 
# (Red Forest) film start with all the movies placed inside a base folder.

# Check http://szaszak.wordpress.com/digital_cinema_automation for more info.


# VARIABLES
EXTENSION="*.mov";
ORIGIN_FOLDER="/home/livre/Desktop/elphel_recordings/"; # Change here for your folder's name.
DESTINATION_FOLDER="/home/livre/Desktop/destino"; # Change here for your folder's name.

# VARIABLES FOR COMPARISON
FILES_AT_ORIGIN_FOLDER=(`find $ORIGIN_FOLDER -name "$EXTENSION"`);
NAMES_OF_FILES_AT_ORIGIN_FOLDER=("${FILES_AT_ORIGIN_FOLDER[@]##*/}");
NUMBER_OF_FILES_ORIGIN="${#FILES_AT_ORIGIN_FOLDER[@]}";

FILES_AT_DESTINATION_FOLDER=(`find $DESTINATION_FOLDER -name "$EXTENSION"`);
NAMES_OF_FILES_AT_DESTINATION_FOLDER=("${FILES_AT_DESTINATION_FOLDER[@]##*/}");
NUMBER_OF_FILES_DEST="${#FILES_AT_DESTINATION_FOLDER[@]}";

if [ $NUMBER_OF_FILES_DEST != "0" ]; then
	COPY="0";
	for (( i=0; i < $NUMBER_OF_FILES_ORIGIN; i++)); do
		for (( k=0; k < $NUMBER_OF_FILES_DEST; k++)); do
			CHECK="0"; INDEX="";
			if [ ${NAMES_OF_FILES_AT_ORIGIN_FOLDER[$i]} == ${NAMES_OF_FILES_AT_DESTINATION_FOLDER[$k]} ]; then break;
			else CHECK="1"; INDEX="$i";
			fi
		
		done; 
				
		if [ $CHECK == "1" ]; then
			if [ ! -f $DESTINATION_FOLDER/${NAMES_OF_FILES_AT_ORIGIN_FOLDER[$INDEX]} ]; then
				cp ${FILES_AT_ORIGIN_FOLDER[$INDEX]} $DESTINATION_FOLDER; 
				COPY=$((COPY+1));
				echo "Copying ${NAMES_OF_FILES_AT_ORIGIN_FOLDER[$INDEX]}..."; 
			fi;
		fi;
	done
	if [ $COPY == 0 ]; then echo "There was no files that could have been copied.";
	else echo "Finished. Copied $COPY file(s)."
	fi

else for (( j=0; j < $NUMBER_OF_FILES_ORIGIN; j++ )); do
	if [ ! -f $DESTINATION_FOLDER/${NAMES_OF_FILES_AT_ORIGIN_FOLDER[$j]} ]; then
		cp ${FILES_AT_ORIGIN_FOLDER[$j]} $DESTINATION_FOLDER;
		fi;
	done
	echo "Finished. Copied everything."
fi
