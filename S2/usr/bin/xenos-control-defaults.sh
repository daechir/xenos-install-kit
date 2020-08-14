#!/bin/bash
# This script serves to control several annoyances that are re-occuring after updates.
#
# Author: Daechir
# Author URL: https://github.com/daechir
# Modified Date: 07/11/20
# Version: v1


# Variables
nmfile="/usr/lib/NetworkManager/conf.d/20-connectivity.conf"
mimefiles1=( "firefox" "gimp" "howl" "libreoffice-base" "libreoffice-calc" "libreoffice-draw" "libreoffice-impress" "libreoffice-math" "libreoffice-writer" "org" "vlc" )
mimefiles2=( "base" "calc" "draw" "impress" "math" "writer" )


control_defaults() {
	if [[ -e "${nmfile}" ]]; then
		rm -rf "${nmfile}"
	fi

	for mime in "${mimefiles1[@]}"
	do
		sed -i "s/^MimeType=.*/MimeType=/g" /usr/share/applications/"$mime"*
	done

	for mime in "${mimefiles2[@]}"
	do
		sed -i "s/^MimeType=.*/MimeType=/g" /usr/lib/libreoffice/share/xdg/"$mime"*
	done

	update-desktop-database
}


control_defaults

