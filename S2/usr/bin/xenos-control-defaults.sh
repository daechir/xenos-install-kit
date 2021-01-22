#!/bin/bash


#################################################
#
#           _______  _        _______  _______
# |\     /|(  ____ \( (    /|(  ___  )(  ____ \
# ( \   / )| (    \/|  \  ( || (   ) || (    \/
#  \ (_) / | (__    |   \ | || |   | || (_____
#   ) _ (  |  __)   | (\ \) || |   | |(_____  )
#  / ( ) \ | (      | | \   || |   | |      ) |
# ( /   \ )| (____/\| )  \  || (___) |/\____) |
# |/     \|(_______/|/    )_)(_______)\_______)
#
#
# This file is a part of the Xenos Install Kit.
# It adheres to the GNU GPL license.
#
# https://github.com/daechir/xenos-install-kit
#
# © 2020-2021
#
#
#################################################


control_folders(){
  local folders=(
    "/etc/NetworkManager/conf.d/*"
    "/etc/NetworkManager/dispatcher.d/*"
    "/etc/NetworkManager/dnsmasq-shared.d/*"
    "/etc/NetworkManager/dnsmasq.d/*"
    "/etc/xdg/autostart/*"
    "/usr/lib/NetworkManager/conf.d/*"
    "/usr/lib/NetworkManager/dispatcher.d/*"
    "/usr/lib/sysctl.d/*"
    "/usr/share/X11/xorg.conf.d/*"
  )

  for folder in "${folders[@]}"
  do
    for item in $folder
    do
      if [[ -f "${item}" ]]; then
        rm -f "${item}"
      fi

      if [[ -d "${item}" ]]; then
        rm -rf "${item}"
      fi
    done
  done

  return 0
}

control_mimes(){
  local mimefolders=(
    "/usr/share/applications/*"
    "/usr/lib/libreoffice/share/xdg/*"
  )

  for mime in "${mimefolders[@]}"
  do
    for mimefile in $mime
    do
      if [[ -f "${mimefile}" ]]; then
        local mimefilegrep=$(grep -i "MimeType" "${mimefile}")

        if [[ -n "${mimefilegrep}" ]]; then
          sed -i "s/^MimeType=.*/MimeType=/g" "${mimefile}"
        fi
      fi
    done
  done

  update-desktop-database

  return 0
}


control_folders
control_mimes

exit 0

