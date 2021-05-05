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


# Print commands before executing and exit when any command fails
set -xe


initialize() {
  #
  ## Variable prep
  #
  cputhreads=$(nproc)
  is_amd_gpu=$(lspci | grep -i "vga\|3d" | grep -i "amd" 2> /dev/null || echo "")
  is_intel_gpu=$(lspci | grep -i "vga\|3d" | grep -i "intel" 2> /dev/null || echo "")
  is_nvidia_gpu=$(lspci | grep -i "vga\|3d" | grep -i "nvidia" 2> /dev/null || echo "")
  install_nvidia=""
  install_optimus=""
  has_tpm=$(cat /sys/class/tpm/tpm0/tpm_version_major 2> /dev/null || echo "")
  crda_region="US"

  return 0
}


install_essentials() {
  # Before proceeding enhance makepkg and mkinitcpio
  sudo sed -i "s/^#MAKEFLAGS=.*/MAKEFLAGS=\"-j${cputhreads}\"/g" /etc/makepkg.conf
  sudo sed -i "s/^COMPRESSXZ=.*/COMPRESSXZ=(xz -c -z - --threads=${cputhreads})/g" /etc/makepkg.conf
  sudo sed -i "s/^PKGEXT=.*/PKGEXT='.pkg.tar.xz'/g" /etc/makepkg.conf
  sudo sed -i "s/^#COMPRESSION=\"xz\"/COMPRESSION=\"xz\"/g" /etc/mkinitcpio.conf
  sudo sed -i "s/^#COMPRESSION_OPTIONS=()/COMPRESSION_OPTIONS=(-c -z - --threads=${cputhreads})/g" /etc/mkinitcpio.conf

  ### Begin core_pack generation
  ## Boilerplate
  # Base
  local core_pack="xorg-server xorg-xinit xorg-xinput xorg-xsetroot xorgproto"

  # Graphic Drivers
  if [[ -n "${is_amd_gpu}" ]]; then
    core_pack="${core_pack} xf86-video-amdgpu"
  fi

  if [[ -n "${is_intel_gpu}" ]]; then
    core_pack="${core_pack} xf86-video-intel"
  fi

  if [[ -n "${is_nvidia_gpu}" && -n "${install_nvidia}" ]]; then
    core_pack="${core_pack} nvidia-dkms"
  fi

  if [[ -n "${is_intel_gpu}" && -n "${is_nvidia_gpu}" && -n "${install_optimus}" ]]; then
    git clone https://aur.archlinux.org/optimus-manager.git
    cd optimus-manager
    makepkg -csi --noconfirm
    cd ..

    sudo sed -i "s/^auto_logout=.*/auto_logout=no/g" /usr/share/optimus-manager.conf
    sudo sed -i "s/^startup_mode=.*/startup_mode=intel/g" /usr/share/optimus-manager.conf
    sudo sed -i "s/^startup_auto_battery_mode=.*/startup_auto_battery_mode=intel/g" /usr/share/optimus-manager.conf
    sudo sed -i "s/^startup_auto_extpower_mode=.*/startup_auto_extpower_mode=intel/g" /usr/share/optimus-manager.conf
    sudo sed -i "s/^driver=.*/driver=intel/g" /usr/share/optimus-manager.conf
    sudo sed -i "s/^accel=.*/accel=sna/g" /usr/share/optimus-manager.conf
    sudo sed -i "s/^tearfree=.*/tearfree=yes/g" /usr/share/optimus-manager.conf
    sudo sed -i "s/^DRI=.*/DRI=3/g" /usr/share/optimus-manager.conf
  fi

  if [[ -n "${is_amd_gpu}" ]]; then
    sudo mkdir /etc/X11/xorg.conf.d/
    sudo cp etc/X11/xorg.conf.d/00_xenos_amd_gpu_configuration.conf /etc/X11/xorg.conf.d/
  fi

  if [[ -n "${is_intel_gpu}" && -z "${install_optimus}" ]]; then
    sudo mkdir /etc/X11/xorg.conf.d/
    sudo cp etc/X11/xorg.conf.d/00_xenos_intel_gpu_configuration.conf /etc/X11/xorg.conf.d/
  fi

  # GUI (1/2)
  # 2bwm utilizing Terminator as terminal
  core_pack="${core_pack} terminator"

  ## Programs by category
  # Audio and video
  core_pack="${core_pack} alsa-utils mpv"
  # Archiver
  core_pack="${core_pack} bzip2 gzip p7zip tar unrar xz zip"
  # Cleaner
  core_pack="${core_pack} bleachbit"
  # Download utilities
  core_pack="${core_pack} axel deluge-gtk youtube-dl"
  # Graphics
  core_pack="${core_pack} gimp inkscape qiv"
  # Misc utilities
  core_pack="${core_pack} bash-completion brightnessctl man-db man-pages neofetch pacman-contrib rsync slock tree xautolock xbindkeys xwallpaper"
  # Mounting
  core_pack="${core_pack} ntfs-3g udiskie"
  # Networking
  core_pack="${core_pack} crda networkmanager nm-connection-editor"
  # Office
  core_pack="${core_pack} howl libreoffice-fresh mupdf"
  # Security
  core_pack="${core_pack} haveged opendoas pwgen rng-tools"
  # Soft dependencies not linked in core packages
  core_pack="${core_pack} gnome-keyring gnome-themes-extra gtk-engine-murrine libsecret"
  # Themeing
  core_pack="${core_pack} arc-gtk-theme papirus-icon-theme ttf-roboto xcursor-vanilla-dmz"
  # Thermald
  if [[ -n "${is_intel_gpu}" ]]; then
    core_pack="${core_pack} thermald"
  fi
  # TPM 2.0
  if [[ "${has_tpm}" == 2 ]]; then
    core_pack="${core_pack} ccid opensc tpm2-abrmd tpm2-pkcs11 tpm2-tools"
  fi

  ### Begin install
  # Force archlinux-keyring refresh
  sudo pacman -Sy --noconfirm archlinux-keyring

  # Install core_pack
  sudo pacman -S --noconfirm $core_pack

  # GUI (2/2)
  git clone https://aur.archlinux.org/2bwm-git.git
  cd 2bwm-git
  sed -i "22 a cp ../../2bwm-tweaks/config.h ../src/2bwm-git/" PKGBUILD
  sed -i "23 a cp ../../2bwm-tweaks/definitions.h ../src/2bwm-git/" PKGBUILD
  makepkg -csi --noconfirm
  cd ..

  # Web Browser
  git clone https://aur.archlinux.org/brave-bin.git
  cd brave-bin
  makepkg -csi --noconfirm
  cd ..

  return 0
}


install_optionals() {
  # Install redshift-minimal
  git clone https://aur.archlinux.org/redshift-minimal.git
  cd redshift-minimal
  makepkg -csi --noconfirm
  cd ..

  # Install openvpn-update-systemd-resolved
  git clone https://aur.archlinux.org/openvpn-update-systemd-resolved.git
  cd openvpn-update-systemd-resolved
  makepkg -csi --noconfirm
  cd ..

  # Setup openvpn-update-systemd-resolved nsswitch.conf
  sudo sed -i "d" /etc/nsswitch.conf
  echo -e "# nsswitch.conf is not used in our system.\n# Its functionality instead is handled by /run/systemd/resolve/stub-resolv.conf." | sudo tee -a  /etc/nsswitch.conf > /dev/null

  # Setup openvpn-update-systemd-resolved stub-resolv.conf
  sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

  # Setup openvpn-update-systemd-resolved resolved.conf
  sudo cp etc/resolved.conf /etc/systemd

  #########################################################################################
  # Setup an unprivileged Openvpn daemon to house delevated Openvpn connections
  #
  # Note:
  # As of Openvpn v2.5.0 another user named openvpn is created for this purpose by default.
  # However for additional security we will still create our own.
  #########################################################################################
  sudo useradd -r -c "Unprivileged Openvpn daemon" -u 26000 -s /usr/bin/nologin -d / novpn
  sudo groupmod -g 26000 novpn

  # Setup xenos-control-defaults
  sudo cp usr/bin/xenos-control-defaults.sh /usr/bin/
  sudo chmod 700 /usr/bin/xenos-control-defaults.sh
  sudo cp etc/systemd/system/xenos-control-defaults.service /etc/systemd/system/

  # Setup xenos-control-dns
  sudo cp usr/bin/xenos-control-dns.sh /usr/bin/
  sudo chmod 700 /usr/bin/xenos-control-dns.sh

  # Setup xenos-setup-power-scheme
  sudo cp usr/bin/xenos-setup-power-scheme.sh /usr/bin/
  sudo chmod 700 /usr/bin/xenos-setup-power-scheme.sh
  sudo cp etc/systemd/system/xenos-setup-power-scheme.service /etc/systemd/system/

  # Setup xenos-* as immutable
  sudo chattr +i /usr/bin/xenos-control-defaults.sh /usr/bin/xenos-control-dns.sh /usr/bin/xenos-setup-power-scheme.sh

  return 0
}


toggle_systemctl() {
  ### Disable some unused services, sockets and targets
  ## Start with dhcpcd, which is removed later
  sudo systemctl stop dhcpcd.service 2> /dev/null
  sudo systemctl disable dhcpcd.service

  local disablectl=(
    "alsa-restore.service"
    "alsa-state.service"
    "avahi-daemon.service"
    "avahi-dnsconfd.service"
    "canberra-system-bootup.service"
    "canberra-system-shutdown-reboot.service"
    "canberra-system-shutdown.service"
    "colord.service"
    "debug-shell.service"
    "emergency.service"
    "git-daemon@.service"
    "healthd.service"
    "NetworkManager-dispatcher.service"
    "NetworkManager-wait-online.service"
    "ninfod.service"
    "nscd.service"
    "rarpd@.service"
    "rdisc.service"
    "rescue.service"
    "rsyncd.service"
    "rsyncd@.service"
    "systemd-coredump@.service"
    "systemd-hibernate-resume@.service"
    "systemd-hibernate.service"
    "systemd-homed-activate.service"
    "systemd-homed.service"
    "systemd-hybrid-sleep.service"
    "systemd-journal-remote.service"
    "systemd-journal-upload.service"
    "systemd-networkd.service"
    "systemd-networkd-wait-online.service"
    "systemd-network-generator.service"
    "systemd-portabled.service"
    "systemd-rfkill.service"
    "systemd-suspend.service"
    "systemd-suspend-then-hibernate.service"
    "systemd-timedated.service"
    "systemd-timesyncd.service"
    "systemd-time-wait-sync.service"
    "systemd-userdbd.service"
    "wpa_supplicant-nl80211@.service"
    "wpa_supplicant@.service"
    "wpa_supplicant-wired@.service"
    "avahi-daemon.socket"
    "git-daemon.socket"
    "rsyncd.socket"
    "systemd-coredump.socket"
    "systemd-journal-remote.socket"
    "systemd-networkd.socket"
    "systemd-rfkill.socket"
    "systemd-userdbd.socket"
    "bluetooth.target"
    "emergency.target"
    "hibernate.target"
    "hybrid-sleep.target"
    "printer.target"
    "remote-cryptsetup.target"
    "remote-fs-pre.target"
    "remote-fs.target"
    "rescue.target"
    "sleep.target"
    "suspend.target"
    "suspend-then-hibernate.target"
  )

  for ctl in "${disablectl[@]}"
  do
    local ctlactive=$(systemctl status "${ctl}" | grep -i "active: active")
    local ctlexist=$(ls -la /usr/lib/systemd/system | grep -i "${ctl}")

    if [[ -n "${ctlactive}" ]]; then
      sudo systemctl stop "${ctl}" 2> /dev/null
    fi

    if [[ -n "${ctlexist}" ]]; then
      sudo systemctl disable "${ctl}"
    fi

    sudo systemctl mask "${ctl}"
  done

  ### Enable all necessary services
  ## This consists of all services installed with core_pack from S1.sh and S2b.sh.
  local enablectl=(
    "apparmor.service"
    "auditd.service"
    "haveged.service"
    "NetworkManager.service"
    "rngd.service"
    "systemd-resolved.service"
    "xenos-control-defaults.service"
    "xenos-setup-power-scheme.service"
  )

  if [[ -n "${is_intel_gpu}" ]]; then
	enablectl=("${enablectl[@]}" "upower.service" "thermald.service")
  fi

  if [[ -n "${is_intel_gpu}" && -n "${is_nvidia_gpu}" && -n "${install_optimus}" ]]; then
    enablectl=("${enablectl[@]}" "optimus-manager.service")
  fi

  if [[ "${has_tpm}" == 2 ]]; then
    enablectl=("${enablectl[@]}" "tpm2-abrmd.service" "pcscd.service")
  fi

  for ctl in "${enablectl[@]}"
  do
    sudo systemctl enable "${ctl}"
  done

  return 0
}


misc_fixes() {
  # Fix apparmor boot time hanging issue
  sudo sed -i "s/^#write-cache/write-cache/g" /etc/apparmor/parser.conf

  # Fix lm_sensors
  sudo sensors-detect --auto

  # Setup our specific CRDA region
  sed -i "s/ieee80211_regdom=/ieee80211_regdom=${crda_region}/g" etc/modprobe.d/optional/10_vendor_any.conf
  sudo sed -i "s/^#WIRELESS_REGDOM=\"${crda_region}\"/WIRELESS_REGDOM=\"${crda_region}\"/g" /etc/conf.d/wireless-regdom
  echo -e "# Set CRDA region\ncountry=${crda_region}" | sudo tee -a /etc/wpa_supplicant/wpa_supplicant.conf > /dev/null

  # Setup our modprobe.d driver customizations
  sudo cp etc/modprobe.d/optional/10_vendor_any.conf /etc/modprobe.d/

  if [[ -n "${is_intel_gpu}" ]]; then
    sudo cp etc/modprobe.d/optional/11_vendor_intel.conf /etc/modprobe.d/
  else
    sudo cp etc/modprobe.d/optional/11_vendor_amd.conf /etc/modprobe.d/
  fi

  return 0
}


harden_systemd_parts() {
  # Harden /etc/systemd/coredump.conf
  sudo sed -i "s/^#Storage=.*/Storage=none/g" /etc/systemd/coredump.conf
  sudo sed -i "s/^#ProcessSizeMax=.*/ProcessSizeMax=0/g" /etc/systemd/coredump.conf

  # Harden /etc/systemd/journald.conf
  sudo sed -i "s/^#Storage=.*/Storage=persistent/g" /etc/systemd/journald.conf
  sudo sed -i "s/^#Compress=.*/Compress=yes/g" /etc/systemd/journald.conf
  sudo sed -i "s/^#SystemMaxUse=.*/SystemMaxUse=50M/g" /etc/systemd/journald.conf
  sudo sed -i "s/^#ForwardToSyslog=.*/ForwardToSyslog=yes/g" /etc/systemd/journald.conf

  # Harden /etc/systemd/system.conf
  sudo sed -i "s/^#DumpCore=.*/DumpCore=no/g" /etc/systemd/system.conf
  sudo sed -i "s/^#CrashShell=.*/CrashShell=no/g" /etc/systemd/system.conf
  sudo sed -i "s/^#SystemCallArchitectures=.*/SystemCallArchitectures=native/g" /etc/systemd/system.conf
  sudo sed -i "s/^#DefaultTimeoutStartSec=.*/DefaultTimeoutStartSec=10s/g"  /etc/systemd/system.conf
  sudo sed -i "s/^#DefaultTimeoutStopSec=.*/DefaultTimeoutStopSec=10s/g"  /etc/systemd/system.conf
  sudo sed -i "s/^#DefaultLimitCORE=.*/DefaultLimitCORE=0/g" /etc/systemd/system.conf

  # Harden /etc/systemd/sleep.conf
  sudo sed -i "s/^#AllowSuspend=.*/AllowSuspend=no/g" /etc/systemd/sleep.conf
  sudo sed -i "s/^#AllowHibernation=.*/AllowHibernation=no/g" /etc/systemd/sleep.conf
  sudo sed -i "s/^#AllowSuspendThenHibernate=.*/AllowSuspendThenHibernate=no/g" /etc/systemd/sleep.conf
  sudo sed -i "s/^#AllowHybridSleep=.*/AllowHybridSleep=no/g" /etc/systemd/sleep.conf

  # Harden services at /etc/systemd/system/
  sudo cp -R usr/lib/systemd/system/ /etc/systemd/

  if [[ -n "${is_intel_gpu}" ]]; then
    sudo cp usr/lib/systemd/system-optional/upower.service /etc/systemd/system/
    sudo cp usr/lib/systemd/system-optional/thermald.service /etc/systemd/system/
  fi

  if [[ -n "${is_intel_gpu}" && -n "${is_nvidia_gpu}" && -n "${install_optimus}" ]]; then
    sudo cp usr/lib/systemd/system-optional/optimus-manager.service /etc/systemd/system/
  fi

  if [[ "${has_tpm}" == 2 ]]; then
    sudo cp usr/lib/systemd/system-optional/tpm2-abrmd.service /etc/systemd/system/
    sudo cp usr/lib/systemd/system-optional/pcscd.service /etc/systemd/system/
  fi

  return 0
}


harden_other_parts() {
  # Harden auditd rules
  sudo cp etc/audit/audit.rules /etc/audit/

  # Harden at-spi* or accessibility (1/2)
  sudo chmod 600 /usr/lib/at-spi-bus-launcher /usr/lib/at-spi2-registryd
  sudo chattr +i /usr/lib/at-spi-bus-launcher /usr/lib/at-spi2-registryd

  # Harden consoles and ttys
  echo -e "\n+:(wheel):LOCAL\n-:ALL:ALL" | sudo tee -a /etc/security/access.conf > /dev/null
  sudo sed -i "1,2!d" /etc/securetty

  # Harden dbus related items (also at-spi* or accessibility (2/2))
  local dbusctl=(
    "/usr/share/dbus-1/accessibility-services/org.a11y.atspi.Registry.service"
    "/usr/share/dbus-1/services/org.a11y.Bus.service"
    "/usr/share/dbus-1/services/org.freedesktop.ColorHelper.service"
    "/usr/share/dbus-1/system-services/org.freedesktop.Avahi.service"
    "/usr/share/dbus-1/system-services/org.freedesktop.ColorManager.service"
    "/usr/share/dbus-1/system-services/org.freedesktop.home1.service"
    "/usr/share/dbus-1/system-services/org.freedesktop.network1.service"
    "/usr/share/dbus-1/system-services/org.freedesktop.nm_dispatcher.service"
    "/usr/share/dbus-1/system-services/org.freedesktop.portable1.service"
    "/usr/share/dbus-1/system-services/org.freedesktop.timedate1.service"
    "/usr/share/dbus-1/system-services/org.freedesktop.timesync1.service"
  )

  for ctl in "${dbusctl[@]}"
  do
    sudo sed -i "d" "${ctl}"
    sudo chmod 600 "${ctl}"
    sudo chattr +i "${ctl}"
  done

  # Harden limits.conf
  sudo sed -i "s/^# End of file/* hard core 0/g" /etc/security/limits.conf
  echo -e "* hard maxsyslogins 1\n\n# End of file" | sudo tee -a  /etc/security/limits.conf > /dev/null

  ## Harden modules
  # Early boot (Kernel init)
  for modprobe in etc/modprobe.d/required/*
  do
    sudo cp "${modprobe}" /etc/modprobe.d/
  done
  # Later boot (Systemd udevd)
  sudo cp etc/modules-load.d/00_whitelisted.conf /etc/modules-load.d/

  ## Harden pam.d
  # Password hashing, make dictionary attacks harder
  sudo sed -i "4 s/pam_unix.so sha512 shadow nullok/pam_unix.so sha512 shadow nullok rounds=65536/g" /etc/pam.d/passwd
  # SU elevation, even though SU will be disabled by locking root lets restrict it anyways
  sudo sed -i "6 s/^#auth/auth/g" /etc/pam.d/su
  sudo sed -i "6 s/^#auth/auth/g" /etc/pam.d/su-l
  # Login limits
  # 3 attempts within 5 minutes results in a 10 minute lockout
  # Additionally add a 5 second delay between each login
  echo -e "\ndeny = 3\nfail_interval = 300\nunlock_time = 600" | sudo tee -a  /etc/security/faillock.conf > /dev/null
  sudo sed -i "5 a auth optional pam_faildelay.so delay=5000000" /etc/pam.d/system-login
  # Disable pam_motd.so and pam_mail.so
  sudo sed -i "s|^session    optional   pam_motd.so          motd=/etc/motd|#session    optional   pam_motd.so          motd=/etc/motd|g" /etc/pam.d/system-login
  sudo sed -i "s|^session    optional   pam_mail.so          dir=/var/spool/mail standard quiet|#session    optional   pam_mail.so          dir=/var/spool/mail standard quiet|g" /etc/pam.d/system-login
  # Disable pam_systemd_home.so (systemd-homed intergration)
  sudo sed -i "s/^-auth      \[success=1 default=ignore\]  pam_systemd_home.so/#-auth      [success=1 default=ignore]  pam_systemd_home.so/g" /etc/pam.d/system-auth
  sudo sed -i "s/^-account   \[success=1 default=ignore\]  pam_systemd_home.so/#-account   [success=1 default=ignore]  pam_systemd_home.so/g" /etc/pam.d/system-auth
  sudo sed -i "s/^-password  \[success=1 default=ignore\]  pam_systemd_home.so/#-password  [success=1 default=ignore]  pam_systemd_home.so/g" /etc/pam.d/system-auth
  # Lastly lock root account
  sudo passwd -l root

  # Harden profile
  sudo cp etc/profile /etc/

  # Harden sshd
  sudo sed -i "s/^#Port.*/Port 18500/g"  /etc/ssh/sshd_config
  sudo sed -i "s/^#PermitRootLogin.*/PermitRootLogin no/g"  /etc/ssh/sshd_config
  sudo sed -i "s/^#StrictModes.*/StrictModes yes/g"  /etc/ssh/sshd_config
  sudo sed -i "s/^#PermitEmptyPasswords.*/PermitEmptyPasswords no/g"  /etc/ssh/sshd_config
  sudo sed -i "s/^#AllowAgentForwarding.*/AllowAgentForwarding no/g"  /etc/ssh/sshd_config
  sudo sed -i "s/^#AllowTcpForwarding.*/AllowTcpForwarding no/g"  /etc/ssh/sshd_config
  sudo sed -i "s/^#X11Forwarding.*/X11Forwarding no/g"  /etc/ssh/sshd_config
  sudo sed -i "s/^#PermitTTY.*/PermitTTY no/g"  /etc/ssh/sshd_config
  sudo sed -i "s/^#TCPKeepAlive.*/TCPKeepAlive no/g"  /etc/ssh/sshd_config
  sudo sed -i "s/^#PermitUserEnvironment.*/PermitUserEnvironment no/g"  /etc/ssh/sshd_config
  sudo sed -i "s/^#UseDNS.*/UseDNS no/g"  /etc/ssh/sshd_config

  # Harden sysctl
  sudo cp etc/00_xenos_hardening.conf /etc/sysctl.d/

  # Harden mount options
  sudo sed -i "6 s/rw,relatime/defaults/g" /etc/fstab
  sudo sed -i "9 s/rw,relatime,fmask=0022,dmask=0022/defaults,nosuid,nodev,noexec,fmask=0077,dmask=0077/g" /etc/fstab
  echo -e "\n/var /var xfs defaults,bind,nosuid,nodev 0 0" | sudo tee -a  /etc/fstab > /dev/null
  echo "/home /home xfs defaults,bind,nosuid,nodev,noexec 0 0" | sudo tee -a  /etc/fstab > /dev/null
  echo "tmpfs /tmp tmpfs defaults,nosuid,nodev,noexec 0 0" | sudo tee -a  /etc/fstab > /dev/null
  echo "tmpfs /dev/shm tmpfs defaults,nosuid,nodev,noexec 0 0" | sudo tee -a  /etc/fstab > /dev/null
  sudo mkdir /etc/systemd/system/systemd-logind.service.d/
  echo -e "[Service]\nSupplementaryGroups=proc" | sudo tee -a  /etc/systemd/system/systemd-logind.service.d/00_hide_pid.conf  > /dev/null
  echo "proc /proc proc nosuid,nodev,noexec,hidepid=2,gid=proc 0 0" | sudo tee -a  /etc/fstab > /dev/null

  # Harden file permissions
  sudo chmod -R 700 /etc/NetworkManager/ /etc/openvpn/ /usr/lib/NetworkManager/ /usr/lib/openvpn/
  sudo find /etc/systemd/system/ -type f -exec chmod 644 {} \;

  # Harden xorg
  mkdir ~/.local/
  mkdir ~/.local/share/
  mkdir ~/.local/share/xorg/
  cp tilde/local/share/xorg/00_xenos_xorg_hardening.conf ~/.local/share/xorg/

  # Setup .bash_profile
  cp tilde/bash_profile ~/.bash_profile

  # Setup .bashrc
  sudo cp tilde/bashrc /etc/skel/.bashrc
  cp tilde/bashrc ~/.bashrc

  # Setup .xinitrc
  cp tilde/xinitrc ~/.xinitrc

  # Setup doas
  echo "permit :wheel" | sudo tee -a /etc/doas.conf > /dev/null

  # Remove unused packages
  sudo pacman -Rns --noconfirm dhcpcd sudo

  return 0
}


exit_installer() {
  # Prompt for shutdown
  read -p "Xenos post install complete. Press [Enter] key to shutdown..."
  systemctl poweroff

  return 0
}


initialize
install_essentials
install_optionals
toggle_systemctl
misc_fixes
harden_systemd_parts
harden_other_parts
exit_installer

exit 0

