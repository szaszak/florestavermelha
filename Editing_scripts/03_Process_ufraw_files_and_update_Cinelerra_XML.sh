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
######### This script is to be used during the post-processing stage, in which
######### the frames are being color corrected with the use of UFRaw, or after
######### this stage has been finished. It reads the .ufraw configuration files
######### to process all the DNGs in the Post Production folder and creates a
######### new Cinelerra XML file to reflect that. 


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
TIF_FOLDER="$BASE_FOLDER/02_JPEG_and_TIF_Files";
XML_FOLDER="$BASE_FOLDER/03_Cinelerra_XML_Files";
I2L_FOLDER="$XML_FOLDER/00_Img2list_Files";
POST_FOLDER="$BASE_FOLDER/04_Post_Production_Files";

######### NEW SCRIPT VARIABLES
### THE EDITS USED
POST_PRODUCTION_LIST=`ls $POST_FOLDER/List_of_DNGs_for_post_production.txt`;
BASE_EDITS_NAME=(`sed "s/\// /g" $POST_PRODUCTION_LIST | tr " " "\n" | grep ".i2l" | cut -d "." -f 1 | sort | uniq`);
NUMBER_OF_EDITS_TO_CHECK=(`cat $POST_PRODUCTION_LIST | tr " " "\n" | grep ".i2l" | sort | uniq | wc -l`);
#NUMBER_OF_EDITS_TO_CHECK=`find $y -maxdepth 1 -type f -name *.ufraw | wc -l`;

### THE XML VARIABLES
FINAL_XML=`find $XML_FOLDER -maxdepth 1 -name \*_final.xml`;
XML_BASE_NAME_FULL=`find $XML_FOLDER -maxdepth 1 -name \*_final.xml | cut -d "." -f 1`;
XML_BASE_NAME=`find $XML_FOLDER -maxdepth 1 -name \*_final.xml | tr "/" "\n" | grep "xml" | cut -d "." -f 1`;
XML_POST_INCOMPLETE="_post_incomplete.xml";
XML_POST_PRODUCED="_post_produced.xml";


### Check the folders that have .ufraw files and that will be worked in.
function checkFoldersToWorkIn {
	echo -e "\n";
		for y in `ls -d $POST_FOLDER/*/`; do
			NUMBER_OF_FILES=`find $y -maxdepth 1 -type f -name *.ufraw | wc -l`;
			if [ $NUMBER_OF_FILES -gt 0 ]; then
				FOLDER_BASENAME=`echo $y | xargs -n 1 basename`;
				echo -e "\e[2;34mFolder $FOLDER_BASENAME has .ufraw files and will be worked...\e[00m";
				fi;
			done;
	echo -e "\n";
		}


######### FUNCTIONS

### This function generates 8-bit TIFs for each DNG in the sequences that
### have been in Cinelerra's timeline. Notice: this will convert ALL DNGs from 
### that movie, even the ones that weren't used during editing!

function createTifs8bitsAll {
	NUMBER_OF_ORIGINAL_DNGS=`find $DNG_FOLDER/${BASE_EDITS_NAME[i]}/ -maxdepth 1 -name \*.dng | wc -l`;
	NUMBER_OF_TIFS=`find $TIF_FOLDER/${BASE_EDITS_NAME[i]}/ -maxdepth 1 -name \*.tif | wc -l`;
	if [ "$NUMBER_OF_ORIGINAL_DNGS" != "$NUMBER_OF_TIFS" ]; then 
		#echo "$NUMBER_OF_ORIGINAL_DNGS" "and" "$NUMBER_OF_TIFS" "at" "$FINAL_UFRAW";	
		sed -ie 's/<CreateID>2/<CreateID>0/g' $FINAL_UFRAW;
		sed -ie 's/<CreateID>1/<CreateID>0/g' $FINAL_UFRAW;
		BKP_FILE="$FINAL_UFRAW""e";	
		
		echo -e "\n\e[2;35mFolder ${BASE_EDITS_NAME[i]} is being processed. This will take some time...\e[00m";
		find $DNG_FOLDER/${BASE_EDITS_NAME[i]}/ -maxdepth 1 -name \*.dng | sort | \
			parallel -j +0 ufraw-batch --conf=$FINAL_UFRAW --out-type=tif --out-depth=8 --nozip --noexif --silent \
			--rotate 180 --out-path=$TIF_FOLDER/${BASE_EDITS_NAME[i]} --overwrite {}
		mv $BKP_FILE $FINAL_UFRAW;
	else echo -e "\e[0;35mFolder ${BASE_EDITS_NAME[i]} is OK and doesn't need reprocessing.\e[00m";
	fi
}

### This function assumes the cut for the video is already final - there won't
### be any future changes in Cinelerra's timeline (the project is "frozen"). It
### creates 8-bit TIFs for each DNG that has been used in the edits, and
### "dummy" (blank) TIFs for the remaining DNGs that belong to that sequence
### but are out of the cut.

### TODO: The process of creating "dummy" TIFs is quite slow, accounting for
### the slowest part of the whole workflow. It works, but the approach has
### to be reconsidered, either by simply ignoring the unused DNGs (must check
### if Cinelerra won't break this way) or by removing only the TIFs that have
### a size higher than "X", "X" being the size of the blank TIFs.

function createTifs8bitsFrozen {
	NUMBER_OF_ORIGINAL_DNGS=`find $DNG_FOLDER/${BASE_EDITS_NAME[i]}/ -maxdepth 1 -name \*.dng | wc -l`;
	NUMBER_OF_TIFS=`find $TIF_FOLDER/${BASE_EDITS_NAME[i]}/ -maxdepth 1 -name \*.tif | wc -l`; 
	
	if [ "$NUMBER_OF_ORIGINAL_DNGS" -gt "$NUMBER_OF_TIFS" ]; then 
		# $NUMBER_OF_TIFS considers the there may be a dummy tif in this folder.
		# That's why the check must be if $NUMBER_OF_ORIGINAL_DNGS is greater.
		
		#echo "Number of DNGS: $NUMBER_OF_ORIGINAL_DNGS x $NUMBER_OF_TIFS: Number of TIFS. Folder ${BASE_EDITS_NAME[i]}."
		sed -ie 's/<CreateID>2/<CreateID>0/g' $FINAL_UFRAW;
		sed -ie 's/<CreateID>1/<CreateID>0/g' $FINAL_UFRAW;
		BKP_FILE="$FINAL_UFRAW""e";	
		
		echo -e "\e[2;35mFolder ${BASE_EDITS_NAME[i]} is being processed. This will take some time...\e[00m";
		if [ `find $TIF_FOLDER/${BASE_EDITS_NAME[i]}/ -maxdepth 1 -name '*.tif' | wc -l` -gt 1 ]; 
            then rm $TIF_FOLDER/${BASE_EDITS_NAME[i]}/*.tif; fi;

		dngs=`find $CURRENT_FOLDER/ -maxdepth 1 -name '*.dng' | wc -l`;
		find $POST_FOLDER/${BASE_EDITS_NAME[i]}/ -maxdepth 1 -name \*.dng | sort | \
			parallel -j +0 'ufraw-batch --conf='$FINAL_UFRAW' --out-type=tif --out-depth=8 --nozip --noexif --silent \
			--rotate 180 --color-smoothing 3 --interpolation=ahd --out-path='$TIF_FOLDER/${BASE_EDITS_NAME[i]}' --overwrite {}; \
			tifs=`find '$TIF_FOLDER/${BASE_EDITS_NAME[i]}' -maxdepth 1 -name '*.tif' | wc -l`; \
			echo -en "\r\e[2;32m"Step '$(($i+1))' of '$NUMBER_OF_EDITS_TO_CHECK'. \
			Files processed: $((tifs-1)) out of '$dngs' - "\e[2;34m"$(((tifs-1)*100/'$dngs'))%..."\e[00m"';
            # Files processed: $tifs out of '$NUMBER_OF_ORIGINAL_DNGS' - "\e[2;34m"$((tifs*100/'$NUMBER_OF_ORIGINAL_DNGS'))%..."\e[00m"';


		### Optional:
        #Apply a filter in the TIFs to mask the debayer artefacts.
		#echo -e "\nUsing filters for files and finishing folder...";
		#find $TIF_FOLDER/${BASE_EDITS_NAME[i]}/ -maxdepth 1 -cmin 5 -name '*.tif' | parallel -j +0 mogrify -gaussian-blur 2 -unsharp 3x2+1+0 {};
        
        ### To leave this option enabled (uncommented) can compensate for the
        ### kind of blocks that can be seen in the video if you really zoom
        ### it in. The option is here for completeness sake, because it
        ### increases the processing time a lot and does not really improve
        ### video quality at all. The blocks, when the video is played, form
        ### a certain noise that is actually quite charming, similar to film.
		
		mv $BKP_FILE $FINAL_UFRAW;
		
		DNGS_FOR_CHECKING=(`find $DNG_FOLDER/${BASE_EDITS_NAME[i]}/ -maxdepth 1 -name \*.dng | tr "/" "\n" | grep ".dng" | sort`);
		DNGS_FOR_CHECKING_BN=(`find $DNG_FOLDER/${BASE_EDITS_NAME[i]}/ -maxdepth 1 -name \*.dng | tr "/" "\n" | grep ".dng" | cut -d "." -f "1" | sort`);
		TIFS_FOR_CHECKING=(`find $TIF_FOLDER/${BASE_EDITS_NAME[i]}/ -maxdepth 1 -type f -size +500 | sort`);
		NUMBER_OF_TIFS_FOR_CHECKING=`find $TIF_FOLDER/${BASE_EDITS_NAME[i]}/ -maxdepth 1 -type f -size +500 | wc -l`;
		MOVIE_FRAME=`cat $DNG_FOLDER/${BASE_EDITS_NAME[i]}/.*.size`;
		
		COPY="0";
		for (( j=0; j < $NUMBER_OF_ORIGINAL_DNGS; j++)); do
			for (( k=0; k < $NUMBER_OF_TIFS_FOR_CHECKING; k++)); do
				CHECK="0"; INDEX="";
				if [ "${DNGS_FOR_CHECKING[$j]}" == "${TIFS_FOR_CHECKING[$k]}" ]; then break;
				else CHECK="1"; INDEX="$j";
				fi
			done;
			
			if [ $CHECK == "1" ]; then
				if [ ! -f $TIF_FOLDER/${BASE_EDITS_NAME[i]}/${DNGS_FOR_CHECKING_BN[$INDEX]}.tif ]; then
					#convert -size $MOVIE_FRAME xc:white $TIF_FOLDER/${BASE_EDITS_NAME[i]}/${DNGS_FOR_CHECKING_BN[$INDEX]}.tif
					# Criar um arquivo-base como esse com um nome oculto (.name) e tentar criar 
					# links simbólicos que remetam a ele, mas tenham o nome do tif que tapa o buraco.
					if [ ! -f .dummy.tif ]; then
						convert -size $MOVIE_FRAME xc:white $TIF_FOLDER/${BASE_EDITS_NAME[i]}/.dummy.tif;
						ln -s .dummy.tif $TIF_FOLDER/${BASE_EDITS_NAME[i]}/${DNGS_FOR_CHECKING_BN[$INDEX]}.tif;
					else ln -s .dummy.tif $TIF_FOLDER/${BASE_EDITS_NAME[i]}/${DNGS_FOR_CHECKING_BN[$INDEX]}.tif;
					fi;
					COPY=$((COPY+1));
				fi;
			fi;
		done
		
	if [ $COPY != 0 ]; then echo -e "\nCreated $COPY blank TIFs at $TIF_FOLDER/${BASE_EDITS_NAME[i]} folder."; fi;
	else echo -e "\e[0;35mFolder ${BASE_EDITS_NAME[i]} is OK and doesn't need reprocessing.\n\tIf you must update this folder, do it manually.\e[00m"; 
	fi
}

### This function updates the original .i2l files in a new copy, now referring
### to the post-produced images (the TIF files instead of the JPEG ones).
function update_i2lFiles {
	cp "$I2L_FOLDER/$j.i2l" $I2L_FOLDER/$j'_post'.i2l
	sed -i 's/JPEGLIST/TIFFLIST/' $I2L_FOLDER/$j'_post'.i2l
	sed -i 's/.jpg/.tif/' $I2L_FOLDER/$j'_post'.i2l
}

### This function creates a copy of the "final" XML that has been used in
### Cinelerra and makes it point to the new .i2l files, created by the above
### function.

### TODO: This function has a simple bug. In case the XML file has a section
### of "Clips", it scrambles the counting (currently, you are not supposed
### to have a "Clips" section, but I'm aware that some people like to use this
### Cinelerra resourse). Make the script recognize and account (or ignore) a 
### "Clips" section, updating the count accordingly.
### If there is one clip, the line "FIRST_LINE_NUMBER="${LINE_NUMBERS[0]}";" 
### goes to [1] instead of [0].
function updateXML {
	LINE_NUMBERS=(`awk '/'$j'.i2l/ {print NR}' $WORKING_XML`);
	for k in ${LINE_NUMBERS[@]}; do
		sed -i ''$k's/.i2l/_post.i2l/' $WORKING_XML;
	done;
	
	FIRST_LINE_NUMBER="${LINE_NUMBERS[0]}";
	sed -i ''$((FIRST_LINE_NUMBER+2))'s/JPEG /TIFF /' $WORKING_XML;
}


### Start the work by checking which folders will be worked in...
checkFoldersToWorkIn;

### The proper work: reads and processes the .ufraw files in the Post 
### Production folder and process the DNGs according to their settings.
### Then, outputs a list of the status of the post-processing stage.
for ((i=0; i < $NUMBER_OF_EDITS_TO_CHECK; i++)); do
	CURRENT_FOLDER=$POST_FOLDER/${BASE_EDITS_NAME[i]};
		FINAL_UFRAW=`ls -t $CURRENT_FOLDER/* | grep "_final\.ufraw" | head -1`;
		GENERIC_UFRAW=`ls -t $CURRENT_FOLDER/* | grep "\.ufraw" | head -1`;
		
		#echo "final ufraw - $FINAL_UFRAW";
		#echo "generic ufraw - $GENERIC_UFRAW";
		
		if [ -n "$FINAL_UFRAW" ]; then
			createTifs8bitsFrozen
			#createTifs8bitsAll;
			echo "${BASE_EDITS_NAME[i]}" >> $POST_FOLDER/01_ufraws_are_final.txt;
			
		elif [ -n "$GENERIC_UFRAW" ]; then
			FINAL_UFRAW=$GENERIC_UFRAW;
			createTifs8bitsFrozen			
			#createTifs8bitsAll;
			echo "${BASE_EDITS_NAME[i]}" >> $POST_FOLDER/02_ufraws_are_ok.txt;
			
		else echo "${BASE_EDITS_NAME[i]}" >> $POST_FOLDER/03_ufraws_need_work.txt;
			
		fi;

	done;

if [ -f $POST_FOLDER/01_ufraws_are_final.txt ]; then 
	UFRAWS_ARE_FINAL=(`cat $POST_FOLDER/01_ufraws_are_final.txt | sort | uniq`); fi;
if [ -f $POST_FOLDER/02_ufraws_are_ok.txt ]; then
	UFRAWS_NEED_CHECKING=(`cat $POST_FOLDER/02_ufraws_are_ok.txt | sort | uniq`); fi;
if [ -f $POST_FOLDER/03_ufraws_need_work.txt ]; then
	UFRAWS_DONT_EXIST=(`cat $POST_FOLDER/03_ufraws_need_work.txt | sort | uniq`); fi;

if [ -z $UFRAWS_DONT_EXIST ]; then
	cp $FINAL_XML $XML_BASE_NAME_FULL$XML_POST_PRODUCED; 
	WORKING_XML=$XML_BASE_NAME_FULL$XML_POST_PRODUCED;
	echo -e "\n\e[2;32mIt seems you have finished working on the DNGs. Your Cinelerra EDL \
		\nis now final and it is called '$XML_BASE_NAME$XML_POST_PRODUCED'.\e[00m";

	elif [ ! -f $XML_BASE_NAME$XML_POST_PRODUCED ]; then
		WORKING_XML=$XML_BASE_NAME_FULL$XML_POST_INCOMPLETE;
		if [ ! -f $XML_BASE_NAME$XML_POST_INCOMPLETE ]; then cp $FINAL_XML $XML_BASE_NAME_FULL$XML_POST_INCOMPLETE; fi;
	echo -e "\n\e[2;32mIt seems you are still working on the DNGs. Your Cinelerra EDL will be updated \
			\nand called '$XML_BASE_NAME$XML_POST_INCOMPLETE' until you finish the job.\e[00m";
	
fi;



echo -e "\n\e[2;32mThe following folders had an .ufraw reference file marked as '_final':"
for j in ${UFRAWS_ARE_FINAL[@]}; do
	update_i2lFiles;
	updateXML
	echo -e "\e[0;32m$j\e[00m"; 
done;
echo -e "\e[0;35mCinelerra's EDL has been updated accordingly.\e[00m"



echo -e "\n\e[2;34mThe following folders had an .ufraw reference file that was used but \
		\nwere not marked as '_final'. Check if they are OK:"
for j in ${UFRAWS_NEED_CHECKING[@]}; do 
	update_i2lFiles;
	updateXML
	echo -e "\e[0;34m$j\e[00m"; 
	done;
echo -e "\e[0;35mEven though, Cinelerra's EDL has been updated accordingly.\e[00m"



echo -e "\n\e[2;31mThe following folders didn't have an .ufraw reference and need to be worked on:"
for j in ${UFRAWS_DONT_EXIST[@]}; do 
	echo -e "\e[0;31m$j\e[00m"; 
	done;
echo -e "\e[0;31mCinelerra's EDL has NOT been updated for these files.\e[00m"


cd $POST_FOLDER;
	if [ -f 01_ufraws_are_final.txt ]; then rm 01_ufraws_are_final.txt; fi;
	if [ -f 02_ufraws_are_ok.txt ]; then rm 02_ufraws_are_ok.txt; fi;
	if [ -f 03_ufraws_need_work.txt ]; then rm 03_ufraws_need_work.txt; fi;
cd - > /dev/null;
