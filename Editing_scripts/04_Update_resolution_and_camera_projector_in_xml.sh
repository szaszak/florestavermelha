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

# Script made for the 'Floresta Vermelha' (Red Forest) film. For more info, check:
# http://szaszak.wordpress.com/digital_cinema_automation 
# http://szaszak.wordpress.com/linux/elphel-as-a-digital-cinema-camera
# and http://florestavermelha.org for the film production blog.


######### DESCRIPTION OF THE SCRIPT
######### 


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
XML_FOLDER="$BASE_FOLDER/03_Cinelerra_XML_Files";
XML=`ls $XML_FOLDER/*_final_post_produced.xml`; # find a way to chose the xml
BASE_XML_NAME=`echo $XML | tr "/" "\n" | grep ".xml" | cut -d "." -f 1`;

# This value must be equal to the 'shrink' value used in the first script, 
# the one that converts MOVs to DNGs and JPEGs.
PROXY_MULTIPLIER="3";
# TODO: Script should read this value automatically.


######### Part 1: Creates new XML version.
######### Enters $XML_FOLDER and creates a copy of the working XML
######### called "_updated". The script will work only on this
######### copy, so as to leave the original intact.

cd $XML_FOLDER;
cp $XML $BASE_XML_NAME'_updated.xml';
XML_TO_UPDATE=$BASE_XML_NAME'_updated.xml';


######### Part 2: Using easier numbers.
######### Cinelerra's XML has a different notation for negative
######### numbers. For example, a keyframe at position -0.34 will
######### read "3.400000e-01" at the XML. However, Cinelerra does 
######### recognize the usual, human-readable way (-0.34), so we'll
######### change those values to be easier to work with the scripts.

##### TODO: Update this section. Currently, it's not working for Camera Z.
sed -i -r 's/([0-9]*)\.([0]{6})e-01/0\.\1/g' $XML_TO_UPDATE;


### This fucntion updates the values in Cinelerra's XML for Camera (X and Y)
### and Projector (X and Y).
function updateXML {
	
	SECTION_OPENS=(`awk '/'$1'/ {print NR}' $XML_TO_UPDATE`);
	SECTION_CLOSES=(`awk '/'$2'/ {print NR}' $XML_TO_UPDATE`);
	
	MULTIPLIER="$3";
	
	NUMBER_OF_SECTIONS=${#SECTION_OPENS[@]};
	
	COUNTER="0";
	for ((i=0; i < $NUMBER_OF_SECTIONS; i++)); do
		LINES[i]=$((SECTION_CLOSES[i]-(SECTION_OPENS[i]+1)));
	
		for ((j=0; j < ${LINES[i]}; j++)); do
			LINE_NUMBERS[$COUNTER]="$((SECTION_OPENS[i]+j+1))"; # find the exact lines where replacement will happen
			LINE_CONTENTS[$COUNTER]=`cat $XML_TO_UPDATE | head -"${LINE_NUMBERS[$COUNTER]}" | tail -1`; # get lines content
			LINE_CONTENTS_MIDDLE[$COUNTER]=`echo "${LINE_CONTENTS[$COUNTER]}" | cut -d "\"" -f 4`; # get middle
			LINE_CONTENTS_MIDDLE_REPLACE[$COUNTER]=`echo "$(echo "scale=1; ${LINE_CONTENTS_MIDDLE[$COUNTER]}*$MULTIPLIER" | bc)"`; #multiply
	
			sed -i ''${LINE_NUMBERS[$COUNTER]}'s/VALUE="'${LINE_CONTENTS_MIDDLE[$COUNTER]}'"/VALUE="'${LINE_CONTENTS_MIDDLE_REPLACE[$COUNTER]}'"/' $XML_TO_UPDATE;
					
			COUNTER=$((COUNTER+1));
		done;
	done;
}


updateXML $"<CAMERA_X>" $"<\/CAMERA_X>" $"$PROXY_MULTIPLIER";
updateXML $"<CAMERA_Y>" $"<\/CAMERA_Y>"$"$PROXY_MULTIPLIER";

updateXML $"<PROJECTOR_X>" $"<\/PROJECTOR_X>" $"$PROXY_MULTIPLIER";
updateXML $"<PROJECTOR_Y>" $"<\/PROJECTOR_Y>" $"$PROXY_MULTIPLIER";


### Finishing off: fix decimal values
sed -i 's/VALOR="./VALOR="0./' $XML_TO_UPDATE; 

### Finishing off: updating resolution (width x height)
PROXY_W="768";
PROXY_H="320";
FULLRES_W="2304";
FULLRES_H="960";


sed -i 's/OUTPUTW="'$PROXY_W'" OUTPUTH="'$PROXY_H'"/OUTPUTW="'$FULLRES_W'" OUTPUTH="'$FULLRES_H'"/' $XML_TO_UPDATE; # Fix the project's size
    # Original:
    # sed -i 's/OUTPUTW="768" OUTPUTH="320"/OUTPUTW="2304" OUTPUTH="960"/' $XML_TO_UPDATE; # Fix the project's size
    #### TODO: Script has to read these values automatically.

sed -i 's/TRACK_W="'$PROXY_W'" TRACK_H="'$PROXY_H'"/TRACK_W="'$FULLRES_W'" TRACK_H="'$FULLRES_H'"/' $XML_TO_UPDATE; # Fix all tracks' sizes
    # Original:
    # sed -i 's/TRACK_W="768" TRACK_H="320"/TRACK_W="2304" TRACK_H="960"/' $XML_TO_UPDATE; # Fix all tracks' sizes
    #### TODO: Script has to read these values automatically.


I2L_FILES_LINES=(`awk '/ASSET SRC=(.*).i2l/ {print NR}' $XML_TO_UPDATE`);
for i in ${I2L_FILES_LINES[@]}; do
	REPLACE_LINE="$((i+4))"; # Fix (only) the .i2l files' sizes
	sed -i ''${REPLACE_LINE}'s/<VIDEO HEIGHT="'$PROXY_H'" WIDTH="'$PROXY_W'"/<VIDEO HEIGHT="'$FULLRES_H'" WIDTH="'$FULLRES_W'"/' $XML_TO_UPDATE;
        # Original
        # sed -i ''${REPLACE_LINE}'s/<VIDEO HEIGHT="320" WIDTH="768"/<VIDEO HEIGHT="960" WIDTH="2304"/' $XML_TO_UPDATE;
        #### TODO: Script has to read these values automatically.
done

cd - > /dev/null;