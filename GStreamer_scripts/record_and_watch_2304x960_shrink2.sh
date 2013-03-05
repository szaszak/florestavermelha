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
# This script has been made for watching the video stream coming from an
# Elphel 353 camera while dumping the stream to a .mkv file inside $FOLDER.
# Many videos/streams can be recorded in sequence and their name will have
# a numeric differentiation so that they don't get overwritten. The camera 
# itself may or may not be recording the video to another device (say, an 
# external HDD). The preview here is at 1/2 resolution.

# Check http://szaszak.wordpress.com/linux/elphel-as-a-digital-cinema-camera
# for more information on how the recording workflow has been thought for
# the movie 'Floresta Vermelha' (Red Forest) - http://florestavermelha.org

#Tests were:
#	2304x960 (FLORESTA VERMELHA)
#	2272x960 (higher resolution tested, aspect 2.39)
#	2064x896 (between HD and fullHD);
#	2320x896 (fullHD equivalent);
#	2400x928 (2k equivalent);

ORIGINAL_WIDTH="2304";
ORIGINAL_HEIGHT="960";
NEW_WIDTH="$((ORIGINAL_WIDTH/2))";
NEW_HEIGHT="$((ORIGINAL_HEIGHT/2))";

FOLDER="Videos_Gstreamer";
FILE_NUMBER=$((`ls $FOLDER/*.mkv | wc -l`+1));

echo $FILE_NUMBER;

echo "Recording at $ORIGINAL_WIDTH""x""$ORIGINAL_HEIGHT" "; preview at $NEW_WIDTH""x""$NEW_HEIGHT"".";

gst-launch-0.10 rtspsrc location=rtsp://192.168.1.9:554 protocols=0x00000001 latency=100 ! rtpjpegdepay ! tee name=raw_tee ! queue ! jpegdec ! queue ! jp462bayer ! "video/x-raw-bayer, width=(int)$NEW_WIDTH, height=(int)$NEW_HEIGHT, format=(string)gbrg" ! queue ! bayer2rgb2 method=0 ! ffmpegcolorspace ! queue ! autovideosink raw_tee. ! queue ! videorate ! "image/jpeg, width=(int)2304, height=(int)960, framerate=(fraction)24/1" ! matroskamux ! filesink location=$FOLDER/s06b_t1_$FILE_NUMBER.mkv -e 
