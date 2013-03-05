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
# Adapted from the work of Carlos Padial, from Kinoraw project.

# Script made for the 'Floresta Vermelha' (Red Forest) project. Check:
# http://szaszak.wordpress.com/digital_cinema_automation for more info and
# http://florestavermelha.org for the film production blog.


# Description
# Converts the DNG files in a folder to OpenEXR format, to be used in Blender
# for color grading. You must have the following programs installed on your
# system for it to work:
#   parallel
#   qtpfsgui


NUMBER_OF_DNGS=`ls *.dng | wc -l`; #echo $NUMBER_OF_DNGS;
THREADS=`nproc`;

COUNTER="0";
while [ $COUNTER -lt $NUMBER_OF_DNGS ]; do
	TAIL_NUMBER=$THREADS;
	COUNTER=$((COUNTER+THREADS));
	if [ $COUNTER -gt $NUMBER_OF_DNGS ]; then
		DIFFERENCE=$((COUNTER-NUMBER_OF_DNGS));
		TAIL_NUMBER=$((THREADS-DIFFERENCE))
		COUNTER=$((COUNTER-DIFFERENCE));
		fi
	#echo "Counter = " $COUNTER " and tail = " $TAIL_NUMBER;
	echo "Processed files = $COUNTER out of $NUMBER_OF_DNGS";
	find . -name '*.dng' | sort | head -$COUNTER | tail -$TAIL_NUMBER | \
		parallel -j $THREADS qtpfsgui {} -e 0 -s {.}.exr
	done
