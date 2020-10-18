#!/bin/bash
# This script serves to control several annoyances that are shipped preconfigured in Arch Linux.
#
# Author: Daechir
# Author URL: https://github.com/daechir
# Modified Date: 10/18/20
# Version: v1c


control_folders(){
  local folders=(
    "/etc/NetworkManager/conf.d/"
    "/etc/xdg/autostart/"
    "/usr/lib/NetworkManager/conf.d/"
    "/usr/lib/sysctl.d/"
  )

  for folder in "${folders[@]}"
  do
    rm -rf "${folder}"
    mkdir "${folder}"
  done

  return 0
}

control_mimes(){
  local mimefiles1=/usr/share/applications/*
  local mimefiles2=/usr/lib/libreoffice/share/xdg/*
  local mimefilesgrep="reset"

  for mime in $mimefiles1
  do
    mimefilesgrep=$(grep -i "MimeType" "${mime}")

    if [[ -n "${mimefilesgrep}" ]]; then
      sed -i "s/^MimeType=.*/MimeType=/g" "${mime}"
    fi
  done

  for mime in $mimefiles2
  do
    mimefilesgrep=$(grep -i "MimeType" "${mime}")

    if [[ -n "${mimefilesgrep}" ]]; then
      sed -i "s/^MimeType=.*/MimeType=/g" "${mime}"
    fi
  done

  update-desktop-database

  return 0
}


control_folders
control_mimes

exit 0

