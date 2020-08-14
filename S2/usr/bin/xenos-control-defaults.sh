#!/bin/bash
# This script serves to control several annoyances that are re-occuring after updates.
#
# Author: Daechir
# Author URL: https://github.com/daechir
# Modified Date: 07/30/20
# Version: v1


# Variables
nmfile="/usr/lib/NetworkManager/conf.d/20-connectivity.conf"
mimefiles1=/usr/share/applications/*
mimefiles2=/usr/lib/libreoffice/share/xdg/*


control_defaults() {
  if [[ -f "${nmfile}" ]]; then
    rm -f "${nmfile}"
  fi

  for mime in $mimefiles1
  do
    local mimefiles1grep=$(grep -i "MimeType" "${mime}")

    if [[ -n "${mimefiles1grep}" ]]; then
      sed -i "s/^MimeType=.*/MimeType=/g" "${mime}"
    fi
  done

  for mime in $mimefiles2
  do
    sed -i "s/^MimeType=.*/MimeType=/g" "${mime}"
  done

  update-desktop-database
}


control_defaults

