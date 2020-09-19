#!/bin/bash
# This script serves to control several annoyances that are shipped preconfigured in Arch Linux.
#
# Author: Daechir
# Author URL: https://github.com/daechir
# Modified Date: 09/19/20
# Version: v1a


# Variables
nmfiles1=/etc/NetworkManager/conf.d/
nmfiles2=/usr/lib/NetworkManager/conf.d/
mimefiles1=/usr/share/applications/*
mimefiles2=/usr/lib/libreoffice/share/xdg/*
sysctlfiles1=/usr/lib/sysctl.d/


control_networkmanager() {
  rm -rf "${nmfiles1}"
  mkdir "${nmfiles1}"

  rm -rf "${nmfiles2}"
  mkdir "${nmfiles2}"
}


control_mimes() {
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
}


control_sysctl() {
  rm -rf "${sysctlfiles1}"
  mkdir "${sysctlfiles1}"
}


control_networkmanager
control_mimes
control_sysctl

