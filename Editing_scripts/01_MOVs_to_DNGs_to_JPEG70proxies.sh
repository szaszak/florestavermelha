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
#   movie2dng - https://gitorious.org/apertus/jp4tools or
#               http://wiki.elphel.com/index.php?title=Movie2dng
#   parallel - https://www.gnu.org/software/parallel/
#   mplayer



######### DESCRIPTION OF THE SCRIPT
######### This script creates (or checks the existence of) the folders
######### we are going to use; converts the recorded MOV files into
######### DNG sequences and these DNGs into JPEGs at 50% quality.
######### It then distributes all those files in their respective
######### folders and creates a text file (.i2l) that will be opened
######### and used in Cinelerra as movies, for editing.


 
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
CAPTURED_MOVIES="$BASE_FOLDER/00_Captured_Movies";
DONE_FOLDER="$CAPTURED_MOVIES/Done";
DNG_FOLDER="$BASE_FOLDER/01_DNG_Files";
TIF_FOLDER="$BASE_FOLDER/02_JPEG_and_TIF_Files";
XML_FOLDER="$BASE_FOLDER/03_Cinelerra_XML_Files";
I2L_FOLDER="$XML_FOLDER/00_Img2list_Files";
POST_FOLDER="$BASE_FOLDER/04_Post_Production_Files";

### OTHERS
EXTENSION_FILTER="*.mov"; # change here for a using a different extension.
MOVIES=(`ls $EXTENSION_FILTER | tr " " "\n"`); 
NUMBER_OF_MOVIES=`ls -l $EXTENSION_FILTER | wc -l`;
MOVIE_BASE_NAME=(`ls $EXTENSION_FILTER | tr " " "\n" | cut -d . -f 1`) 

# Important: if you change this value, also change it in the script #04, the 
#one that updates Cinelerra's XML file.
SHRINK="3"; echo "$SHRINK" > ".shrink"; 


######### Declaring Functions

function createSubFolders {
	echo -e "\e[2;32mThe folder $BASE_FOLDER exists.\nChecking the subfolders...\e[00m";
	if [ ! -d $CAPTURED_MOVIES ]; then mkdir $CAPTURED_MOVIES && echo "Folder $CAPTURED_MOVIES has been created and will be used."; fi;
	if [ ! -d $DONE_FOLDER ]; then mkdir $DONE_FOLDER && echo "Folder $DONE_FOLDER has been created and will be used."; fi;
	if [ ! -d $DNG_FOLDER ]; then mkdir $DNG_FOLDER && echo "Folder $DNG_FOLDER has been created and will be used."; fi;
	if [ ! -d $TIF_FOLDER ]; then mkdir $TIF_FOLDER && echo "Folder $TIF_FOLDER has been created and will be used."; fi;
	if [ ! -d $XML_FOLDER ]; then mkdir $XML_FOLDER && echo "Folder $XML_FOLDER has been created and will be used."; fi;
	if [ ! -d $POST_FOLDER ]; then mkdir $POST_FOLDER && echo "Folder $POST_FOLDER has been created and will be used."; fi;
	if [ ! -d $I2L_FOLDER ]; then mkdir $I2L_FOLDER && echo "Folder $I2L_FOLDER has been created and will be used."; fi;
	echo -en "\e[2;32mDone checking. Subfolders are OK.\e[00m";
}

function createAllFolders { 
	mkdir $BASE_FOLDER $CAPTURED_MOVIES $DONE_FOLDER $DNG_FOLDER $TIF_FOLDER $XML_FOLDER $POST_FOLDER $I2L_FOLDER;
	echo -e "\e[2;32mFolder $BASE_FOLDER and subfolders created.\e[00m";
}


######### Part 1: The Base Folder
######### Checks if a BASE_FOLDER exists. If it does not, creates it.
######### The same happens for the subfolders. It also creates a
######### script for previewing the post production files
######### to be placed at the $POST_FOLDER.

if [ -d $BASE_FOLDER ]; then 
	createSubFolders;
else
	createAllFolders;
fi



######### Part 2: The Base Folder
######### Moves the movie files to the CAPTURED_MOVIES folder;
######### Convert the movies into sequences of DNG files;
######### Convert the DNG files into JPEG files at 50% quality;

#mv $EXTENSION_FILTER $CAPTURED_MOVIES;
for (( i=0; i < $NUMBER_OF_MOVIES; i++ )) do
	cd $CAPTURED_MOVIES; mkdir ${MOVIE_BASE_NAME[i]}; cd - > /dev/null;
	mv ${MOVIE_BASE_NAME[i]}.mov $CAPTURED_MOVIES/${MOVIE_BASE_NAME[i]};
	
	echo -e "\e[2;32mStep 1 of 3. Please wait...\e[00m";
	find $CAPTURED_MOVIES/${MOVIE_BASE_NAME[i]} -maxdepth 1 -name "$EXTENSION_FILTER" | parallel -j +0 movie2dng --dng {} {.};
	#Fully functional percentage counter:
	NUMBER_OF_DNGS=`find $CAPTURED_MOVIES/${MOVIE_BASE_NAME[i]} -name \*.dng | wc -l`;
	find $CAPTURED_MOVIES/${MOVIE_BASE_NAME[i]} -name '*.dng' | parallel -j +0 'ufraw-batch --wb=camera --exposure=auto --restore=hsv --clip=film --saturation=1,15 --base-curve=camera --black-point=auto --interpolation=bilinear --out-type=jpg --compression=70 --out-depth=8 --noexif --shrink '$SHRINK' --rotate 180 --silent {}; jpegs=`find '$CAPTURED_MOVIES/${MOVIE_BASE_NAME[i]}' -name '*.jpg' | wc -l` && echo -en "\r\e[2;32m"Step 2 of 3. Files processed: $jpegs out of '$NUMBER_OF_DNGS' - "\e[2;34m"$((jpegs*100/'$NUMBER_OF_DNGS'))%..."\e[00m"';
	
	mv $CAPTURED_MOVIES/${MOVIE_BASE_NAME[i]}/${MOVIE_BASE_NAME[i]}-*.dng $CAPTURED_MOVIES;
	mv $CAPTURED_MOVIES/${MOVIE_BASE_NAME[i]}/${MOVIE_BASE_NAME[i]}-*.jpg $CAPTURED_MOVIES;
	rmdir $CAPTURED_MOVIES/${MOVIE_BASE_NAME[i]};
	done;
 	


######### Part 3: The Working DNG and JPEG/TIF folders
######### Creates a working subfolder for movie inside the DNG and JPEG/TIF folders.
########### This way, the massive amount of files will be more easily manipulated.
######### Moves the DNG and JPEG files from the CAPTURED_MOVIES folder to theirs.
######### Inside each subfolder at $DNG_FOLDER:
######### Creates a reference for the movie FPS in a hidden .fps file;
######### Creates a reference for the movie size in a hidden .size file;
######### Creates a txt reference file for each JPEG sequence;
############ This files works as img2list files. They are stored in I2L_FOLDER.

echo -e "\r\e[2;32mMoving DNG and JPEG files to their respective folders...\e[00m";
for (( i=0; i < $NUMBER_OF_MOVIES; i++ )) do
 	cd $TIF_FOLDER; mkdir ${MOVIE_BASE_NAME[i]}; cd - > /dev/null;
 	cd $DNG_FOLDER; mkdir ${MOVIE_BASE_NAME[i]}; cd - > /dev/null;
	
	mplayer $CAPTURED_MOVIES/${MOVIE_BASE_NAME[i]}.mov -vo null -ao null -frames 0 2>&1 /dev/null | egrep "(VIDEO)" | tr " " "\n" | egrep "[0-9]+x[0-9]+" > $CAPTURED_MOVIES/.${MOVIE_BASE_NAME[i]}.size
	mplayer $CAPTURED_MOVIES/${MOVIE_BASE_NAME[i]}.mov -identify -vo null -ao null -frames 0 2>&1 /dev/null | egrep "(VIDEO_FPS)" | cut -d "=" -f 2 > $CAPTURED_MOVIES/.${MOVIE_BASE_NAME[i]}.fps

	echo -en "\e[2;32mStep 3 of 3. Moving files for movie $i of $NUMBER_OF_MOVIES - \e[2;34m$((i*100/NUMBER_OF_MOVIES))% done - \e[00m";
 	mv $CAPTURED_MOVIES/${MOVIE_BASE_NAME[i]}-*.dng $DNG_FOLDER/${MOVIE_BASE_NAME[i]};
	mv $CAPTURED_MOVIES/.${MOVIE_BASE_NAME[i]}.size $DNG_FOLDER/${MOVIE_BASE_NAME[i]};
	mv $CAPTURED_MOVIES/.${MOVIE_BASE_NAME[i]}.fps $DNG_FOLDER/${MOVIE_BASE_NAME[i]};
 	mv $CAPTURED_MOVIES/${MOVIE_BASE_NAME[i]}-*.jpg $TIF_FOLDER/${MOVIE_BASE_NAME[i]};
 	
	### Read the atributes of each movie before creating the i2l files:
	MOVIE_FPS=`cat $DNG_FOLDER/${MOVIE_BASE_NAME[i]}/.${MOVIE_BASE_NAME[i]}.fps`;	
	IMAGE_WIDTH_1=`cat $DNG_FOLDER/${MOVIE_BASE_NAME[i]}/.${MOVIE_BASE_NAME[i]}.size | cut -d "x" -f 1`; # dividir por "shrink"
	IMAGE_WIDTH=$((IMAGE_WIDTH_1/SHRINK));
	IMAGE_HEIGTH_1=`cat $DNG_FOLDER/${MOVIE_BASE_NAME[i]}/.${MOVIE_BASE_NAME[i]}.size | cut -d "x" -f 2`; # dividir por "shrink"
	IMAGE_HEIGTH=$((IMAGE_HEIGTH_1/SHRINK));

	echo "${MOVIE_BASE_NAME[i]}: $MOVIE_FPS""fps, $IMAGE_WIDTH""x""$IMAGE_HEIGTH";
 	mv $CAPTURED_MOVIES/${MOVIE_BASE_NAME[i]}.mov $DONE_FOLDER;
 	
 	cd $TIF_FOLDER/${MOVIE_BASE_NAME[i]}; 	

	### Create an i2l file for each movie to be read by Cinelerra.
 	FOLDER_PATH=`pwd`;
 	IMAGE_LIST=(`ls *.jpg | tr " " "\n"`);
 	
 	echo "JPEGLIST" > ${MOVIE_BASE_NAME[i]}.i2l;
 	echo "$MOVIE_FPS #FPS" >> ${MOVIE_BASE_NAME[i]}.i2l;
 	echo "$IMAGE_WIDTH #Width" >> ${MOVIE_BASE_NAME[i]}.i2l;
 	echo "$IMAGE_HEIGTH #Height" >> ${MOVIE_BASE_NAME[i]}.i2l;
 	echo "#-------------------------------------" >> ${MOVIE_BASE_NAME[i]}.i2l;
 	echo "#Now the paths to the images" >> ${MOVIE_BASE_NAME[i]}.i2l;
 	echo "#-------------------------------------" >> ${MOVIE_BASE_NAME[i]}.i2l;
 	
 	for (( j=0; j < `ls -l *.jpg | wc -l`; j++ )); do
	 	echo $FOLDER_PATH/${IMAGE_LIST[j]} >> ${MOVIE_BASE_NAME[i]}.i2l;
 	done;
 	
 	cd - > /dev/null;
 	
 	mv $TIF_FOLDER/${MOVIE_BASE_NAME[i]}/${MOVIE_BASE_NAME[i]}.i2l $I2L_FOLDER;

done;

######### End of the script.
