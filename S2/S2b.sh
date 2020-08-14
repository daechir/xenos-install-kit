#!/bin/bash
# Print commands before executing and exit when any command fails
set -xe


# Variables
is_amd_gpu=$(lspci | grep -e VGA -e 3D | grep "AMD" 2> /dev/null || echo "")
is_intel_gpu=$(lspci | grep -e VGA -e 3D | grep "Intel" 2> /dev/null || echo "")
is_nvidia_gpu=$(lspci | grep -e VGA -e 3D | grep "NVIDIA" 2> /dev/null || echo "")
has_tpm=$(ls /sys/class/tpm)
has_rtl=$(lspci | grep "RTL8821CE")
crda_region="US"


install_essentials() {
	### Begin core_pack generation
	## Boilerplate
	# Base
	core_pack="xorg-server xorg-xinput"

	# Graphic Drivers
	if [[ -n "${is_amd_gpu}" ]]; then
		core_pack="${core_pack} xf86-video-amdgpu"
	fi

	if [[ -n "${is_intel_gpu}" ]]; then
		core_pack="${core_pack} xf86-video-intel"
	fi

	if [[ -n "${is_nvidia_gpu}" ]]; then
		core_pack="${core_pack} nvidia-dkms"
	fi

	if [[ -n "${is_intel_gpu}" && -n "${is_nvidia_gpu}" ]]; then
		git clone https://aur.archlinux.org/optimus-manager.git
		cd optimus-manager
		makepkg -csi --noconfirm
		cd ..

		sudo sed -i "s/^pci_power_control=.*/pci_power_control=yes/g" /usr/share/optimus-manager.conf
		sudo sed -i "s/^auto_logout=.*/auto_logout=no/g" /usr/share/optimus-manager.conf
		sudo sed -i "s/^startup_mode=.*/startup_mode=intel/g" /usr/share/optimus-manager.conf
		sudo sed -i "s/^startup_auto_battery_mode=.*/startup_auto_battery_mode=intel/g" /usr/share/optimus-manager.conf
		sudo sed -i "s/^startup_auto_extpower_mode=.*/startup_auto_extpower_mode=intel/g" /usr/share/optimus-manager.conf
	fi

	# GUI
	core_pack="${core_pack} lxqt sddm"

	## Programs by category
	# Audio and video
	core_pack="${core_pack} alsa-utils pulseaudio-alsa pavucontrol-qt vlc"
	# Archiver
	core_pack="${core_pack} ntfs-3g p7zip unrar zip"
	# Cleaner
	core_pack="${core_pack} bleachbit"
	# Graphics
	core_pack="${core_pack} gimp inkscape"
	# Misc
	core_pack="${core_pack} bash-completion neofetch pacman-contrib xscreensaver"
	# Networking
	core_pack="${core_pack} crda network-manager-applet"
	# Office
	core_pack="${core_pack} howl libreoffice-fresh qpdfview"
	# Security
	core_pack="${core_pack} haveged rng-tools pwgen veracrypt"
	# Themeing
	core_pack="${core_pack} arc-gtk-theme papirus-icon-theme ttf-roboto xcursor-vanilla-dmz"
    # Thermal and power management
    core_pack="${core_pack} ethtool thermald tlp tlp-rdw x86_energy_perf_policy"
	# TPM 2.0
	if [[ -n "${has_tpm}" ]]; then
		core_pack="${core_pack} ccid opensc tpm2-abrmd tpm2-tools tpm2-pkcs11"
	fi
	# Web Browser
	core_pack="${core_pack} firefox"

	# Force archlinux-keyring refresh
	sudo pacman -Sy --noconfirm archlinux-keyring

	# Install core_pack
	sudo pacman -S --noconfirm $core_pack
}


install_optionals() {
	# Install redshift-minimal
	git clone https://aur.archlinux.org/redshift-minimal.git
	cd redshift-minimal
	makepkg -csi --noconfirm
	cd ..

	# Install RTL8821CE Wireless AC drivers
	if [[ -n "${has_rtl}" ]]; then
		git clone https://aur.archlinux.org/rtl8821ce-dkms-git.git
		cd rtl8821ce-dkms-git
		sed -i "s/linux-headers/linux-hardened-headers/g" PKGBUILD
		makepkg -csi --noconfirm
		cd ..

		echo -e "\n# Set RTL8821CE Wireless AC CRDA\noptions 8821ce rtw_country_code=${crda_region}" | sudo tee -a  /etc/modprobe.d/02_rtl8821ce.conf > /dev/null
	fi

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
	echo -e "\n[Resolve]\n#DNS=\nFallbackDNS=\nDomains=\nLLMNR=no\nMulticastDNS=no\nDNSSEC=allow-downgrade\nDNSOverTLS=opportunistic\nCache=yes\nDNSStubListener=yes\nReadEtcHosts=yes" | sudo tee -a  /etc/systemd/resolved.conf > /dev/null

	# Setup an unprivileged Openvpn daemon to house delevated Openvpn connections
	sudo useradd -r -c "Unprivileged Openvpn daemon" -u 26000 -s /usr/bin/nologin -d / novpn
	sudo groupmod -g 26000 novpn
	sudo sed -i "s|^HideShells=|HideShells=/usr/bin/nologin|g" /usr/lib/sddm/sddm.conf.d/default.conf

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
	sudo pacman -R --noconfirm dhcpcd

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

	if [[ -n "${is_intel_gpu}" && -n "${is_nvidia_gpu}" ]]; then
		sudo systemctl enable optimus-manager.service
	fi

	if [[ -n "${has_tpm}" ]]; then
		sudo systemctl enable tpm2-abrmd.service
		sudo systemctl enable pcscd.service
	fi

	sudo systemctl enable rngd.service
	sudo systemctl enable sddm.service
	sudo systemctl enable systemd-resolved.service
    sudo systemctl enable thermald.service
    sudo systemctl enable tlp.service
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

	# Fix pulseaudio bug where speakers and headphones share the same I/O
	# Some I/O's require the headphone channel to be merged with the speaker channel in order for the speakers to work
	if [[ -n "${is_intel_gpu}" ]]; then
		sudo mv /usr/share/pulseaudio/alsa-mixer/paths/analog-output-speaker.conf /usr/share/pulseaudio/alsa-mixer/paths/analog-output-speaker.bak
		sudo cp usr/share/pulseaudio/alsa-mixer/paths/analog-output-speaker.conf /usr/share/pulseaudio/alsa-mixer/paths/
	fi

	# Fix systemd hanging issues with c2
	sudo sed -i "s/^#DefaultTimeoutStopSec=90s/DefaultTimeoutStopSec=10s/g"  /etc/systemd/system.conf
	sudo sed -i "s/^#DefaultTimeoutStartSec=90s/DefaultTimeoutStartSec=10s/g"  /etc/systemd/system.conf

    # Fix thermald pre-defined profile errors
    sudo mkdir /etc/systemd/system/thermald.service.d/
	echo -e "[Service]\nStandardOutput=null" | sudo tee -a /etc/systemd/system/thermald.service.d/nostdout.conf > /dev/null
    sudo chmod -R 644 /etc/systemd/system/thermald.service.d/

    # Fix tlp intel power errors
    if [[ -n "${is_intel_gpu}" ]]; then
      sudo sed -i "s/^#CPU_ENERGY_PERF_POLICY_ON_AC=.*/CPU_ENERGY_PERF_POLICY_ON_AC=performance/g" /etc/tlp.conf
      sudo sed -i "s/^#CPU_ENERGY_PERF_POLICY_ON_BAT=.*/CPU_ENERGY_PERF_POLICY_ON_BAT=power/g" /etc/tlp.conf
      sudo sed -i "s/^#SATA_LINKPWR_ON_AC=.*/SATA_LINKPWR_ON_AC=\"max_performance\"/g" /etc/tlp.conf
      sudo sed -i "s/^#SATA_LINKPWR_ON_BAT=.*/SATA_LINKPWR_ON_BAT=\"medium_power\"/g" /etc/tlp.conf
    fi
}


harden_parts() {
	# Harden auditd
	sudo cp etc/audit/audit.rules /etc/audit/

	# Harden .bash_history
	echo -e "\n# Disable .bash_history\nexport HISTSIZE=0" | tee -a ~/.bashrc > /dev/null
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
		echo -e "\n# Blacklist AMD Ryzen sp5100_tco watchdog\n# /lib/modules/\$/kernel/drivers/watchdog/\ninstall sp5100_tco /bin/true" | sudo tee -a  /etc/modprobe.d/01_amd_ryzen_sp5100_tco.conf > /dev/null
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

	# Harden sudoedit
	echo "EDITOR=nano" | sudo tee -a /etc/environment > /dev/null

	# Harden sysctl
	sudo cp etc/00_xenos_hardening.conf /etc/sysctl.d/

	# Harden Systemd sleep
	sudo sed -i "s/^#AllowSuspend=yes/AllowSuspend=no/g" /etc/systemd/sleep.conf
	sudo sed -i "s/^#AllowHibernation=yes/AllowHibernation=no/g" /etc/systemd/sleep.conf
	sudo sed -i "s/^#AllowSuspendThenHibernate=yes/AllowSuspendThenHibernate=no/g" /etc/systemd/sleep.conf
	sudo sed -i "s/^#AllowHybridSleep=yes/AllowHybridSleep=no/g" /etc/systemd/sleep.conf
	sudo sed -i "s/^OnlyShowIn=.*/NoDisplay=true;/g" /usr/share/applications/lxqt-hibernate.desktop
	sudo sed -i "s/^OnlyShowIn=.*/NoDisplay=true;/g" /usr/share/applications/lxqt-suspend.desktop
	sudo sed -i "s/^OnlyShowIn=.*/NoDisplay=true;/g" /usr/share/applications/lxqt-leave.desktop

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


exit_installer() {
	# Prompt for shutdown
	read -p "Xenos post install complete. Press [Enter] key to shutdown..."
	sudo shutdown now
}


install_essentials
install_optionals
toggle_services
misc_fixes
harden_parts
exit_installer

