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
# Basic script just to run x11vnc for streaming a very tiny portion of the
# screen to a mobile device. The idea is that this device can serve as
# monitor to a recording session when using Elphel cameras, that have 
# no monitor.

# Check http://szaszak.wordpress.com/linux/elphel-as-a-digital-cinema-camera
# for more information on how the recording workflow has been thought for
# the movie 'Floresta Vermelha' (Red Forest) - http://florestavermelha.org

# Options that must be chosen on the client side:
#	server-scaling=1/4
#	client-scaling=custom, 320x128
#	view only= true
#	update-ASAP=true or false, needs checking
x11vnc -forever -clip 516x224+0+85 -shared -viewonly -nodragging -noxdamage -notruecolor -speeds modem -fs 0.75
