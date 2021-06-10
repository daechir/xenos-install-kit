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
    "/etc/profile.d/*"
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

control_suid(){
  local suid_binaries=(
    "apt"
    "apt-get"
    "ar"
    "aria2c"
    "arp"
    "ash"
    "at"
    "atobm"
    "awk"
    "base32"
    "base64"
    "basenc"
    "bash"
    "bpftrace"
    "bridge"
    "bsd-write"
    "bundler"
    "busctl"
    "busybox"
    "byebug"
    "c89"
    "c99"
    "cancel"
    "capsh"
    "cat"
    "certbot"
    "chage"
    "check_by_ssh"
    "check_cups"
    "check_log"
    "check_memory"
    "check_raid"
    "check_ssl_cert"
    "check_statusfile"
    "chfn"
    "chmod"
    "chown"
    "chroot"
    "chsh"
    "cobc"
    "column"
    "comm"
    "composer"
    "cowsay"
    "cowthink"
    "cp"
    "cpan"
    "cpio"
    "cpulimit"
    "crash"
    "crontab"
    "csh"
    "csplit"
    "csvtool"
    "cupsfilter"
    "curl"
    "cut"
    "dash"
    "date"
    "dd"
    "dialog"
    "diff"
    "dig"
    "dmesg"
    "dmsetup"
    "dnf"
    "docker"
    "dpkg"
    "dvips"
    "easy_install"
    "eb"
    "ed"
    "emacs"
    "env"
    "eqn"
    "ex"
    "exiftool"
    "expand"
    "expect"
    "facter"
    "file"
    "find"
    "finger"
    "flock"
    "fmt"
    "fold"
    "ftp"
    "fusermount"
    "gawk"
    "gcc"
    "gdb"
    "gem"
    "genisoimage"
    "ghc"
    "ghci"
    "gimp"
    "git"
    "grep"
    "gtester"
    "gzip"
    "hd"
    "head"
    "hexdump"
    "highlight"
    "hping3"
    "iconv"
    "iftop"
    "install"
    "ionice"
    "ip"
    "irb"
    "jjs"
    "join"
    "journalctl"
    "jq"
    "jrunscript"
    "ksh"
    "ksshell"
    "latex"
    "ld.so"
    "ldconfig"
    "less"
    "logsave"
    "look"
    "ltrace"
    "lua"
    "lualatex"
    "luatex"
    "lwp-download"
    "lwp-request"
    "mail"
    "make"
    "man"
    "mawk"
    "mlocate"
    "more"
    "mount"
    "mount.nfs"
    "msgattrib"
    "msgcat"
    "msgconv"
    "msgfilter"
    "msgmerge"
    "msguniq"
    "mtr"
    "mv"
    "mysql"
    "nano"
    "nawk"
    "nc"
    "netfilter-persistent"
    "newgrp"
    "nice"
    "nl"
    "nmap"
    "node"
    "nohup"
    "npm"
    "nroff"
    "nsenter"
    "ntfs-3g"
    "octave"
    "od"
    "openssl"
    "openvpn"
    "openvt"
    "paste"
    "pdb"
    "pdflatex"
    "pdftex"
    "perl"
    "pg"
    "php"
    "pic"
    "pico"
    "ping"
    "ping6"
    "pip"
    "pkexec"
    "pkg"
    "pppd"
    "pr"
    "pry"
    "psad"
    "psql"
    "puppet"
    "python"
    "rake"
    "readelf"
    "red"
    "redcarpet"
    "restic"
    "rev"
    "rlogin"
    "rlwrap"
    "rpm"
    "rpmquery"
    "rsync"
    "ruby"
    "run-mailcap"
    "run-parts"
    "rview"
    "rvim"
    "scp"
    "screen"
    "script"
    "sed"
    "service"
    "setarch"
    "sftp"
    "sg"
    "sh"
    "shuf"
    "slsh"
    "smbclient"
    "snap"
    "socat"
    "soelim"
    "sort"
    "split"
    "sqlite3"
    "ss"
    "ssh"
    "ssh-keygen"
    "ssh-keyscan"
    "start-stop-daemon"
    "stdbuf"
    "strace"
    "strings"
    "su"
    "sysctl"
    "systemctl"
    "tac"
    "tail"
    "tar"
    "taskset"
    "tbl"
    "tclsh"
    "tcpdump"
    "tcsh"
    "tee"
    "telnet"
    "tex"
    "tftp"
    "time"
    "timeout"
    "tmux"
    "top"
    "traceroute6.iputils"
    "troff"
    "ul"
    "umount"
    "unexpand"
    "uniq"
    "unshare"
    "update-alternatives"
    "uudecode"
    "uuencode"
    "valgrind"
    "vi"
    "view"
    "vigr"
    "vim"
    "vimdiff"
    "vipw"
    "virsh"
    "wall"
    "watch"
    "wc"
    "wget"
    "whois"
    "wish"
    "write"
    "xargs"
    "xelatex"
    "xetex"
    "xmodmap"
    "xmore"
    "xxd"
    "xz"
    "yelp"
    "yum"
    "zip"
    "zsh"
    "zsoelim"
    "zypper"
  )

  local suid_binary_paths=()

  for binary in "${suid_binaries[@]}"
  do
    local suid_binary_path="/usr/bin/${binary}"

    if [[ -f "${suid_binary_path}" ]]; then
      suid_binary_paths=("${suid_binary_paths[@]}" "${suid_binary_path}")
    fi
  done

  for binary_path in "${suid_binary_paths[@]}"
  do
    chmod -s "${binary_path}"
  done

  return 0
}


control_folders
control_mimes
control_suid

exit 0

