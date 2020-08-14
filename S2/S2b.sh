#!/bin/bash
# Print commands before executing and exit when any command fails
set -xe


# Variables
cputhreads=$(nproc)
is_amd_gpu=$(lspci | grep -e VGA -e 3D | grep "AMD" 2> /dev/null || echo "")
is_intel_gpu=$(lspci | grep -e VGA -e 3D | grep "Intel" 2> /dev/null || echo "")
is_nvidia_gpu=$(lspci | grep -e VGA -e 3D | grep "NVIDIA" 2> /dev/null || echo "")
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
  core_pack="xorg-server xorg-xbacklight xorg-xinit xorg-xinput xorg-xsetroot xorgproto"

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

  # GUI Part 1
  # 2bwm utilizing Terminator as terminal
  # Items listed above that aren't in core_pack here are found below due to make depends
  core_pack="${core_pack} terminator"

  ## Programs by category
  # Audio and video
  core_pack="${core_pack} alsa-utils mpv"
  # Archiver
  core_pack="${core_pack} bzip2 gzip libunrar p7zip tar unrar xz zip"
  # Cleaner
  core_pack="${core_pack} bleachbit"
  # File manager
  core_pack="${core_pack} doublecmd-gtk2"
  # Graphics
  core_pack="${core_pack} gimp inkscape qiv"
  # Misc
  core_pack="${core_pack} bash-completion gnome-keyring neofetch opendoas pacman-contrib slock xautolock xbindkeys xwallpaper"
  # Mounting
  core_pack="${core_pack} ntfs-3g udiskie"
  # Networking
  core_pack="${core_pack} crda networkmanager nm-connection-editor"
  # Office
  core_pack="${core_pack} howl libreoffice-fresh mupdf"
  # Security
  core_pack="${core_pack} haveged pwgen rng-tools veracrypt"
  # Themeing
  core_pack="${core_pack} arc-gtk-theme gnome-themes-extra gtk-engine-murrine papirus-icon-theme ttf-roboto xcursor-vanilla-dmz"
  # Thermal and power management
  core_pack="${core_pack} ethtool thermald tlp tlp-rdw upower x86_energy_perf_policy"
  # Torrent
  core_pack="${core_pack} transmission-gtk"
  # TPM 2.0
  if [[ "${has_tpm}" == 2 ]]; then
    core_pack="${core_pack} ccid opensc tpm2-abrmd tpm2-pkcs11 tpm2-tools"
  fi
  # Web Browser
  core_pack="${core_pack} firefox"

  # Force archlinux-keyring refresh
  sudo pacman -Sy --noconfirm archlinux-keyring

  # Install core_pack
  sudo pacman -S --noconfirm $core_pack

  # GUI Part 2
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

  # Setup NetworkManager settings
  echo -e "[connection]\nconnection.llmnr=0\nconnection.mdns=0" | sudo tee -a  /etc/NetworkManager/conf.d/00_force_settings.conf > /dev/null
  echo -e "[connection]\nconnection.llmnr=0\nconnection.mdns=0" | sudo tee -a  /usr/lib/NetworkManager/conf.d/00_force_settings.conf > /dev/null

  # Setup nsswitch.conf
  sudo sed -i "1,2!d" /etc/nsswitch.conf
  echo -e "\nhosts: files dns resolve myhostname\nhosts: files resolve dns myhostname\nhosts: files resolve myhostname" | sudo tee -a  /etc/nsswitch.conf > /dev/null

  # Setup stub-resolv.conf symbolic link
  sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

  # Setup Systemd resolved settings
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
}


toggle_services() {
  # Disable some unused services, sockets and targets
  sudo systemctl stop dhcpcd.service 2> /dev/null
  sudo systemctl disable dhcpcd.service

  # Systemd userdbd & homed
  sudo systemctl stop systemd-userdbd.service 2> /dev/null
  sudo systemctl disable systemd-userdbd.service
  sudo systemctl mask systemd-userdbd.service
  sudo systemctl stop systemd-userdbd.socket 2> /dev/null
  sudo systemctl disable systemd-userdbd.socket
  sudo systemctl mask systemd-userdbd.socket
  sudo systemctl stop systemd-homed.service 2> /dev/null
  sudo systemctl disable systemd-homed.service
  sudo systemctl mask systemd-homed.service

  # Systemd rfkill
  sudo systemctl mask systemd-rfkill.service
  sudo systemctl mask systemd-rfkill.socket

  # Systemd sleep
  sudo systemctl mask suspend.target 2> /dev/null
  sudo systemctl mask hibernate.target 2> /dev/null
  sudo systemctl mask hybrid-sleep.target 2> /dev/null
  sudo systemctl mask suspend-then-hibernate.target 2> /dev/null

  # Enable all necessary services
  # This consists of all services installed with core_pack from S1.sh and S2b.sh.
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

  # Fix CRDA region
  echo -e "# Set CRDA region\ncountry=${crda_region}" | sudo tee -a /etc/wpa_supplicant/wpa_supplicant.conf > /dev/null
  sudo sed -i "s/^#WIRELESS_REGDOM=\"${crda_region}\"/WIRELESS_REGDOM=\"${crda_region}\"/g" /etc/conf.d/wireless-regdom

  # Fix lm_sensors
  sudo sensors-detect --auto

  # Fix systemd hanging issues with c2
  sudo sed -i "s/^#DefaultTimeoutStopSec=90s/DefaultTimeoutStopSec=10s/g"  /etc/systemd/system.conf
  sudo sed -i "s/^#DefaultTimeoutStartSec=90s/DefaultTimeoutStartSec=10s/g"  /etc/systemd/system.conf

  # Fix thermald pre-defined profile errors
  sudo mkdir /etc/systemd/system/thermald.service.d/
  echo -e "[Service]\nStandardOutput=null" | sudo tee -a /etc/systemd/system/thermald.service.d/nostdout.conf > /dev/null
  sudo chmod -R 644 /etc/systemd/system/thermald.service.d/

  # Fix tlp power parameters
  sudo sed -i "s/^#CPU_ENERGY_PERF_POLICY_ON_AC=.*/CPU_ENERGY_PERF_POLICY_ON_AC=performance/g" /etc/tlp.conf
  sudo sed -i "s/^#CPU_ENERGY_PERF_POLICY_ON_BAT=.*/CPU_ENERGY_PERF_POLICY_ON_BAT=power/g" /etc/tlp.conf
  sudo sed -i "s/^#SATA_LINKPWR_ON_AC=.*/SATA_LINKPWR_ON_AC=\"max_performance\"/g" /etc/tlp.conf
  sudo sed -i "s/^#SATA_LINKPWR_ON_BAT=.*/SATA_LINKPWR_ON_BAT=\"medium_power\"/g" /etc/tlp.conf
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

  # Harden file permissions
  sudo sed -i "s/^umask 022/umask 077/g" /etc/profile

  # Harden modules
  # Kernel level
  sudo cp etc/modules/00_blacklisted.conf  /etc/modprobe.d/

  if [[ -n "${is_amd_gpu}" ]]; then
    echo -e "# Blacklist AMD Ryzen sp5100_tco watchdog\n# /lib/modules/\$/kernel/drivers/watchdog/\ninstall sp5100_tco /bin/true" | sudo tee -a  /etc/modprobe.d/01_amd_ryzen_sp5100_tco.conf > /dev/null
    echo -e "# Make Realtek ALC236 the first audio card\noptions snd-hda-intel id=Generic_1 index=0\noptions snd-hda-intel id=Generic index=1" | sudo tee -a  /etc/modprobe.d/02_snd_hda_intel.conf > /dev/null
  fi

  # Systemd level
  sudo cp etc/modules/00_whitelisted.conf /etc/modules-load.d/

  # Harden password hashes
  sudo sed -i "4 s/pam_unix.so sha512 shadow nullok/pam_unix.so sha512 shadow nullok rounds=65536/g" /etc/pam.d/passwd

  # Harden root account
  sudo sed -i "6 s/^#auth/auth/g" /etc/pam.d/su
  sudo sed -i "6 s/^#auth/auth/g" /etc/pam.d/su-l
  sudo sed -i "3 s/pam_tally2.so        /pam_tally2.so deny=3 unlock_time=600 /g" /etc/pam.d/system-login
  sudo sed -i "7 s/^$/auth optional pam_faildelay.so delay=5000000\n/g" /etc/pam.d/system-login
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

  # Harden file permisssions
  sudo chmod -R 700 /etc/NetworkManager/ /etc/openvpn/ /usr/lib/NetworkManager/ /usr/lib/openvpn/

  # Harden mount options
  sudo sed -i "6 s/rw,relatime/defaults,noatime/g" /etc/fstab
  sudo sed -i "9 s/rw,relatime/defaults,noatime,nosuid,nodev,noexec/g" /etc/fstab
  echo -e "\n/var /var ext4 defaults,bind,noatime,nosuid,nodev 0 0" | sudo tee -a  /etc/fstab > /dev/null
  echo "/home /home ext4 defaults,bind,noatime,nosuid,nodev,noexec 0 0" | sudo tee -a  /etc/fstab > /dev/null
  echo "tmpfs /tmp tmpfs defaults,noatime,nosuid,nodev,noexec 0 0" | sudo tee -a  /etc/fstab > /dev/null
  echo "tmpfs /dev/shm tmpfs defaults,noatime,nosuid,nodev,noexec 0 0" | sudo tee -a  /etc/fstab > /dev/null
  sudo mkdir /etc/systemd/system/systemd-logind.service.d/
  echo -e "[Service]\nSupplementaryGroups=proc" | sudo tee -a  /etc/systemd/system/systemd-logind.service.d/00_hide_pid.conf  > /dev/null
  sudo chmod -R 644 /etc/systemd/system/systemd-logind.service.d/
  echo "proc /proc proc noatime,nosuid,nodev,noexec,hidepid=2,gid=proc 0 0" | sudo tee -a  /etc/fstab > /dev/null
}


finalize_setup() {
  # Configure doas
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
toggle_services
misc_fixes
harden_parts
finalize_setup
exit_installer

