#!/bin/bash
# Print commands before executing and exit when any command fails
set -xe


# Variables
cputhreads=$(nproc)
is_intel_cpu=$(lscpu | grep -i "intel(r)" 2> /dev/null || echo "")
is_amd_gpu=$(lspci | grep -e VGA -e 3D | grep -i "amd" 2> /dev/null || echo "")
is_intel_gpu=$(lspci | grep -e VGA -e 3D | grep -i "intel" 2> /dev/null || echo "")
is_nvidia_gpu=$(lspci | grep -e VGA -e 3D | grep -i "nvidia" 2> /dev/null || echo "")
install_nvidia=""
install_optimus="1"
has_tpm=$(cat /sys/class/tpm/tpm0/tpm_version_major 2> /dev/null || echo "")
crda_region="US"


install_essentials() {
  # Before proceeding enhance makepkg
  sudo sed -i "s/^#MAKEFLAGS=.*/MAKEFLAGS=\"-j${cputhreads}\"/g" /etc/makepkg.conf
  sudo sed -i "s/^COMPRESSXZ=.*/COMPRESSXZ=(xz -c -z - --threads=${cputhreads})/g" /etc/makepkg.conf
  sudo sed -i "s/^COMPRESSZST=.*/COMPRESSZST=(zstd -c -z -q - --threads=${cputhreads})/g" /etc/makepkg.conf

  ### Begin core_pack generation
  ## Boilerplate
  # Base
  core_pack="xorg-server xorg-xinit xorg-xinput xorg-xsetroot xorgproto"

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

    sudo sed -i "s/^pci_power_control=.*/pci_power_control=yes/g" /usr/share/optimus-manager.conf
    sudo sed -i "s/^auto_logout=.*/auto_logout=no/g" /usr/share/optimus-manager.conf
    sudo sed -i "s/^startup_mode=.*/startup_mode=intel/g" /usr/share/optimus-manager.conf
    sudo sed -i "s/^startup_auto_battery_mode=.*/startup_auto_battery_mode=intel/g" /usr/share/optimus-manager.conf
    sudo sed -i "s/^startup_auto_extpower_mode=.*/startup_auto_extpower_mode=intel/g" /usr/share/optimus-manager.conf
    sudo sed -i "s/^driver=.*/driver=intel/g" /usr/share/optimus-manager.conf
    sudo sed -i "s/^accel=.*/accel=sna/g" /usr/share/optimus-manager.conf
    sudo sed -i "s/^tearfree=.*/tearfree=yes/g" /usr/share/optimus-manager.conf
    sudo sed -i "s/^DRI=.*/DRI=3/g" /usr/share/optimus-manager.conf
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
  core_pack="${core_pack} bash-completion brightnessctl neofetch pacman-contrib slock xautolock xbindkeys xwallpaper"
  # Mounting
  core_pack="${core_pack} ntfs-3g udiskie"
  # Networking
  core_pack="${core_pack} crda networkmanager nm-connection-editor"
  # Office
  core_pack="${core_pack} howl libreoffice-fresh mupdf"
  # Security
  core_pack="${core_pack} haveged opendoas pwgen rng-tools veracrypt"
  # Soft dependencies not linked in core packages
  core_pack="${core_pack} gnome-keyring gnome-themes-extra gtk-engine-murrine"
  # Themeing
  core_pack="${core_pack} arc-gtk-theme papirus-icon-theme ttf-roboto xcursor-vanilla-dmz"
  # Thermal and power management
  core_pack="${core_pack} ethtool powertop thermald tlp tlp-rdw upower x86_energy_perf_policy"
  # TPM 2.0
  if [[ "${has_tpm}" == 2 ]]; then
    core_pack="${core_pack} ccid opensc tpm2-abrmd tpm2-pkcs11 tpm2-tools"
  fi
  # Web Browser
  core_pack="${core_pack} firefox"

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
  sudo sed -i "1,2!d" /etc/nsswitch.conf
  echo -e "\nhosts: files dns resolve myhostname\nhosts: files resolve dns myhostname\nhosts: files resolve myhostname" | sudo tee -a  /etc/nsswitch.conf > /dev/null

  # Setup openvpn-update-systemd-resolved stub-resolv.conf
  sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

  # Setup openvpn-update-systemd-resolved resolved.conf
  sudo sed -i "1,12!d" /etc/systemd/resolved.conf
  echo -e "\n[Resolve]\n#DNS=\nFallbackDNS=\nDomains=\nDNSSEC=yes\nDNSOverTLS=no\nMulticastDNS=no\nLLMNR=no\nCache=yes\nDNSStubListener=yes\nReadEtcHosts=yes\nResolveUnicastSingleLabel=no" | sudo tee -a  /etc/systemd/resolved.conf > /dev/null

  # Setup an unprivileged Openvpn daemon to house delevated Openvpn connections
  sudo useradd -r -c "Unprivileged Openvpn daemon" -u 26000 -s /usr/bin/nologin -d / novpn
  sudo groupmod -g 26000 novpn

  # Setup xenos-control-defaults
  sudo cp usr/bin/xenos-control-defaults.sh /usr/bin/
  sudo chmod +x /usr/bin/xenos-control-defaults.sh
  sudo cp etc/systemd/system/xenos-control-defaults.service /etc/systemd/system/
  sudo chmod 644 /etc/systemd/system/xenos-control-defaults.service

  # Setup xenos-control-dns
  sudo cp etc/NetworkManager/dispatcher.d/xenos-control-dns-0.sh /etc/NetworkManager/dispatcher.d/
  sudo chmod +x /etc/NetworkManager/dispatcher.d/xenos-control-dns-0.sh
  sudo cp usr/bin/xenos-control-dns-1.sh /usr/bin/
  sudo chmod +x /usr/bin/xenos-control-dns-1.sh
  sudo cp etc/systemd/system/xenos-control-dns-1.service /etc/systemd/system/
  sudo chmod 644 /etc/systemd/system/xenos-control-dns-1.service
  sudo cp usr/bin/xenos-control-dns-2.sh /usr/bin/
  sudo chmod +x /usr/bin/xenos-control-dns-2.sh
  sudo cp etc/systemd/system/xenos-control-dns-2.service /etc/systemd/system/
  sudo chmod 644 /etc/systemd/system/xenos-control-dns-2.service

  # Setup xenos-* as immutable
  sudo chattr -i /usr/bin/xenos-control-defaults.sh
  sudo chattr -i /etc/NetworkManager/dispatcher.d/xenos-control-dns-0.sh
  sudo chattr -i /usr/bin/xenos-control-dns-1.sh
  sudo chattr -i /usr/bin/xenos-control-dns-2.sh
}


toggle_systemctl() {
  ### Disable some unused services, sockets and targets
  ## Start with dhcpcd, which is removed later
  sudo systemctl stop dhcpcd.service 2> /dev/null
  sudo systemctl disable dhcpcd.service

  local systemctl=(
    "avahi-daemon.service"
    "avahi-dnsconfd.service"
    "systemd-coredump@.service"
    "systemd-hibernate-resume@.service"
    "systemd-hibernate.service"
    "systemd-homed.service"
    "systemd-hybrid-sleep.service"
    "systemd-rfkill.service"
    "systemd-suspend-then-hibernate.service"
    "systemd-suspend.service"
    "systemd-userdbd.service"
    "systemd-coredump.socket"
    "systemd-rfkill.socket"
    "systemd-userdbd.socket"
    "bluetooth.target"
    "hibernate.target"
    "hybrid-sleep.target"
    "printer.target"
    "remote-cryptsetup.target"
    "remote-fs-pre.target"
    "remote-fs.target"
    "sleep.target"
    "suspend-then-hibernate.target"
    "suspend.target"
  )

  for ctl in "${systemctl[@]}"
  do
    sudo systemctl stop "${ctl}" 2> /dev/null
    sudo systemctl disable "${ctl}"
    sudo systemctl mask "${ctl}"
  done

  ### Enable all necessary services
  ## This consists of all services installed with core_pack from S1.sh and S2b.sh.
  sudo systemctl enable apparmor.service
  sudo systemctl enable auditd.service
  sudo systemctl enable haveged.service
  sudo systemctl enable NetworkManager.service

  if [[ -n "${is_intel_gpu}" && -n "${is_nvidia_gpu}" && -n "${install_optimus}" ]]; then
    sudo systemctl enable optimus-manager.service
  fi

  if [[ "${has_tpm}" == 2 ]]; then
    sudo systemctl enable tpm2-abrmd.service
    sudo systemctl enable pcscd.service
  fi

  sudo systemctl enable rngd.service
  sudo systemctl enable systemd-resolved.service
  sudo systemctl enable thermald.service
  sudo systemctl enable tlp.service
  sudo systemctl enable upower.service
  sudo systemctl enable xenos-control-defaults.service
}


misc_fixes() {
  # Adjust journal file size
  sudo sed -i "s/^#SystemMaxUse=/SystemMaxUse=50M/g" /etc/systemd/journald.conf

  # Fix apparmor boot time hanging issue
  sudo sed -i "s/^#write-cache/write-cache/g" /etc/apparmor/parser.conf

  # Fix lm_sensors
  sudo sensors-detect --auto

  # Fix modprobe.d driver customizations
  if [[ -n "${is_intel_cpu}" ]]; then
    sudo cp etc/modules/01_iwlwifi.conf /etc/modprobe.d/
  else
    sudo cp etc/modules/01_snd_hda_intel.conf /etc/modprobe.d/
  fi

  # Fix systemd hanging issues with c2
  sudo sed -i "s/^#DefaultTimeoutStopSec=90s/DefaultTimeoutStopSec=10s/g"  /etc/systemd/system.conf
  sudo sed -i "s/^#DefaultTimeoutStartSec=90s/DefaultTimeoutStartSec=10s/g"  /etc/systemd/system.conf

  # Optimize powertop power saving defaults
  sudo powertop --auto-tune

  # Optimize tlp power saving defaults
  sudo sed -i "s/^#CPU_ENERGY_PERF_POLICY_ON_AC=.*/CPU_ENERGY_PERF_POLICY_ON_AC=performance/g" /etc/tlp.conf
  sudo sed -i "s/^#CPU_ENERGY_PERF_POLICY_ON_BAT=.*/CPU_ENERGY_PERF_POLICY_ON_BAT=power/g" /etc/tlp.conf
  sudo sed -i "s/^#SATA_LINKPWR_ON_AC=.*/SATA_LINKPWR_ON_AC=\"max_performance\"/g" /etc/tlp.conf
  sudo sed -i "s/^#SATA_LINKPWR_ON_BAT=.*/SATA_LINKPWR_ON_BAT=\"medium_power\"/g" /etc/tlp.conf

  # Specify CRDA region
  echo -e "# Set CRDA region\ncountry=${crda_region}" | sudo tee -a /etc/wpa_supplicant/wpa_supplicant.conf > /dev/null
  sudo sed -i "s/^#WIRELESS_REGDOM=\"${crda_region}\"/WIRELESS_REGDOM=\"${crda_region}\"/g" /etc/conf.d/wireless-regdom
}


harden_parts() {
  # Harden auditd
  sudo cp etc/audit/audit.rules /etc/audit/

  # Harden .bash_history
  echo -e "\n# Disable .bash_history\nexport HISTSIZE=0" | sudo tee -a /etc/profile > /dev/null

  # Harden coredumps
  sudo sed -i "1,12!d" /etc/systemd/coredump.conf
  echo -e "\n[Coredump]\nStorage=none\nProcessSizeMax=0" | sudo tee -a  /etc/systemd/coredump.conf > /dev/null
  sudo sed -i "s/^# End of file/* hard core 0/g" /etc/security/limits.conf
  echo -e "\n# End of file" | sudo tee -a  /etc/security/limits.conf > /dev/null

  # Harden file permissions (1/2)
  sudo sed -i "s/^umask 022/umask 077/g" /etc/profile
  sudo sed -i "s/umask=022/umask=077/g" /etc/pam.d/doas

  ## Harden modules
  # Kernel level
  sudo cp etc/modules/00_blacklisted.conf  /etc/modprobe.d/
  # Systemd level
  sudo cp etc/modules/00_whitelisted.conf /etc/modules-load.d/

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
  # Lastly lock root account
  sudo passwd -l root

  # Harden securetty
  sudo sed -i "1,2!d" /etc/securetty

  # Harden sysctl
  sudo cp etc/00_xenos_hardening.conf /etc/sysctl.d/

  # Harden Systemd sleep
  sudo sed -i "s/^#AllowSuspend=yes/AllowSuspend=no/g" /etc/systemd/sleep.conf
  sudo sed -i "s/^#AllowHibernation=yes/AllowHibernation=no/g" /etc/systemd/sleep.conf
  sudo sed -i "s/^#AllowSuspendThenHibernate=yes/AllowSuspendThenHibernate=no/g" /etc/systemd/sleep.conf
  sudo sed -i "s/^#AllowHybridSleep=yes/AllowHybridSleep=no/g" /etc/systemd/sleep.conf

  # Harden file permissions (2/2)
  sudo chmod -R 700 /etc/NetworkManager/ /etc/openvpn/ /usr/lib/NetworkManager/ /usr/lib/openvpn/

  # Harden mount options
  sudo sed -i "6 s/rw,relatime/defaults,noatime/g" /etc/fstab
  sudo sed -i "9 s/rw,relatime,fmask=0022,dmask=0022/defaults,noatime,nosuid,nodev,noexec,fmask=0077,dmask=0077/g" /etc/fstab
  echo -e "\n/var /var ext4 defaults,bind,noatime,nosuid,nodev 0 0" | sudo tee -a  /etc/fstab > /dev/null
  echo "/home /home ext4 defaults,bind,noatime,nosuid,nodev,noexec 0 0" | sudo tee -a  /etc/fstab > /dev/null
  echo "tmpfs /tmp tmpfs defaults,noatime,nosuid,nodev,noexec 0 0" | sudo tee -a  /etc/fstab > /dev/null
  echo "tmpfs /dev/shm tmpfs defaults,noatime,nosuid,nodev,noexec 0 0" | sudo tee -a  /etc/fstab > /dev/null
  sudo mkdir /etc/systemd/system/systemd-logind.service.d/
  echo -e "[Service]\nSupplementaryGroups=proc" | sudo tee -a  /etc/systemd/system/systemd-logind.service.d/00_hide_pid.conf  > /dev/null
  sudo chmod -R 644 /etc/systemd/system/systemd-logind.service.d/
  echo "proc /proc proc noatime,nosuid,nodev,noexec,hidepid=2,gid=proc 0 0" | sudo tee -a  /etc/fstab > /dev/null

  # Setup doas
  echo "permit :wheel" | sudo tee -a /etc/doas.conf > /dev/null

  # Remove unused packages
  sudo pacman -R --noconfirm dhcpcd sudo
}


exit_installer() {
  # Prompt for shutdown
  read -p "Xenos post install complete. Press [Enter] key to shutdown..."
  doas shutdown now
}


install_essentials
install_optionals
toggle_systemctl
misc_fixes
harden_parts
exit_installer

