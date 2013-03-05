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

# You must have installed on your system:
#   parallel - https://www.gnu.org/software/parallel/
#   gawk
#   sed


######### DESCRIPTION OF THE SCRIPT
######### This script uses the final EDL to generate a human-readable
######### list of all the image sequences that were used in the movie
######### and creates links to them. These links will be in respective
######### subfolders inside the Post Production folder (POST_FOLDER).
######### From there, you can start doing the photographic treatment.



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
XML_FOLDER="$BASE_FOLDER/03_Cinelerra_XML_Files";
POST_FOLDER="$BASE_FOLDER/04_Post_Production_Files";
SUB_POST_FOLDERS="DNGs_for_Post_Production";
SCRIPT_FOR_PREVIEWING="00_preview_movies_from_ufraw_reference_file_FLIPPED.sh";

### OTHERS
FINAL_XML=`ls $XML_FOLDER/*_final.xml`; # Change for selecting proper XML
LINKS_FOR_CREATION=(`grep '\<ASSET SRC=.*i2l\>' $FINAL_XML | cut -d '"' -f 2 | tr "/" "\n" | grep .i2l | cut -d "." -f 1`);


######### Part 1: Creating a human-readable reference file
######### Creates a file called 'List_of_DNGs_for_post_production.txt'
######### that will be stored at $POST_FOLDER. This is a reference for
######### the photographer to know precisely which frames have been
######### used in the Cinelerra's timeline.
	
grep "EDIT STARTSOURCE=" $FINAL_XML | cut -d">" -f1,2 | cut -d"=" -f1,2,4,5 > temp_readableXML.txt && sed -ie 's/<EDIT STARTSOURCE="/- frames /g' temp_readableXML.txt && sed -ie 's/" CHANNEL="/ to /g' temp_readableXML.txt && sed -ie 's/"><FILE SRC=/ File: /g' temp_readableXML.txt && grep File temp_readableXML.txt > temp_readableXML2.txt && gawk '{ $8 = $5 + $3; $9 = $3+1 ;print $6,$7,$1,$2,$9,$4,$8 }' temp_readableXML2.txt > temp_readableXML3.txt && cat temp_readableXML3.txt | grep ".i2l" | sort -n -k 2,7 > $POST_FOLDER/List_of_DNGs_for_post_production.txt && rm temp_readableXML*.txt*


######### NEW SCRIPT VARIABLES
### THE EDITS USED
POST_PRODUCTION_LIST=`ls $POST_FOLDER/List_of_DNGs_for_post_production.txt`;
NUMBER_OF_EDITS_USED=(`cat $POST_PRODUCTION_LIST | wc -l`);
EDITS_BASE_NAME=(`sed "s/\// /g" $POST_PRODUCTION_LIST | tr " " "\n" | grep ".i2l" | cut -d "." -f 1`);
RANGE_FROM=(`sed "s/ to /to/g" $POST_PRODUCTION_LIST | tr " " "\n" | egrep "[0-9]{1,}to[0-9]{1,}" | sed "s/to/ /g" | cut -d " " -f 1`);
RANGE_TO=(`sed "s/ to /to/g" $POST_PRODUCTION_LIST | tr " " "\n" | egrep "[0-9]{1,}to[0-9]{1,}" | sed "s/to/ /g" | cut -d " " -f 2`);
NUMBER_OF_LINKS=`cat $POST_PRODUCTION_LIST | grep ".i2l" | wc -l`;


######### Part 2: Creating links for the Post Production DNGs
######### This will create the $SUB_POST_FOLDERS folder inside
######### each DNG folder that has files that have been used
######### in the movie. Then, it will create symbolic links to
######### every image that has been used in Cinelerra's timeline
######### inside this folder, isolating them from the rest.

for ((i=0; i < $NUMBER_OF_EDITS_USED; i++ )) do
	cd $DNG_FOLDER/${EDITS_BASE_NAME[i]};

	if [ ! -d $SUB_POST_FOLDERS ]; then
		mkdir $SUB_POST_FOLDERS && cp .*.fps $SUB_POST_FOLDERS && cp .*.size $SUB_POST_FOLDERS; 
	fi;

	DNGS_IN_FOLDER=(`ls *.dng`);
		for ((j=${RANGE_FROM[i]}-1; j < ${RANGE_TO[i]}; j++ )) do
			if [ ! -f $DNG_FOLDER/${EDITS_BASE_NAME[i]}/$SUB_POST_FOLDERS/${DNGS_IN_FOLDER[j]} ]; then
			ln -s $DNG_FOLDER/${EDITS_BASE_NAME[i]}/${DNGS_IN_FOLDER[j]} $DNG_FOLDER/${EDITS_BASE_NAME[i]}/$SUB_POST_FOLDERS;
			fi
		done;
		
	cd - > /dev/null;
done;


######### Part 3: Creating Post Production folder links
######### Creates symbolic links to the folders of every img2list file
######### used in project (files that exist in Cinelerra's Media folder).
######### The links will be created at $POST_FOLDER.

for (( i=0; i < $NUMBER_OF_LINKS; i++ )); do
	if [ ! -d $POST_FOLDER/${EDITS_BASE_NAME[i]} ]; then 
		ln -s $DNG_FOLDER/${EDITS_BASE_NAME[i]}/$SUB_POST_FOLDERS/ $POST_FOLDER/${EDITS_BASE_NAME[i]} && \
		echo "Created symbolic link for folder: ${EDITS_BASE_NAME[i]}."; 
		fi;
	done;
	

######### Part 4: Copies the script for previewing the
######### JPEGs as videos to each of the Post Production
######### folders.

for i in `ls -d $POST_FOLDER/*/`; do 
	cp $POST_FOLDER/.$SCRIPT_FOR_PREVIEWING $i/$SCRIPT_FOR_PREVIEWING; 
	done


######### End of the script.
