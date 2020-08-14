#!/bin/bash
# Print commands before executing and exit when any command fails
set -xe


# Variables
has_lv=$(lvs)
has_vg=$(vgs)
has_pv=$(pvs)
volume="xvg"
drive="/dev/sda"
luks_password="$"
mirror_list="https://www.archlinux.org/mirrorlist/?country=US&protocol=https&ip_version=4&use_mirror_status=on"
is_intel_cpu=$(lscpu | grep "Intel" &> /dev/null && echo "yes" || echo "")
core_pack="apparmor base base-devel dhcpcd efibootmgr grub git linux-hardened linux-hardened-headers linux-firmware lvm2 nano unzip"
if [[ -n "${is_intel_cpu}" ]]; then
	core_pack="${core_pack} intel-ucode"
else
	core_pack="${core_pack} amd-ucode"
fi
timezone="America/New_York"
language="en_US.UTF-8"
hostname=$(cat /dev/urandom | tr -dc "a-zA-Z0-9" | fold -w 32 | head -n 1)
username="$"
userpass="$"
# Begin grub_cmdline generation
# Core security features
grub_cmdline="apparmor=1 security=apparmor audit=1"
# CPU mitigations
grub_cmdline="${grub_cmdline} spectre_v2=on"
grub_cmdline="${grub_cmdline} spec_store_bypass_disable=on"
grub_cmdline="${grub_cmdline} tsx=off tsx_async_abort=full,nosmt"
grub_cmdline="${grub_cmdline} mds=full,nosmt"
grub_cmdline="${grub_cmdline} l1tf=full,force"
grub_cmdline="${grub_cmdline} nosmt=force"
grub_cmdline="${grub_cmdline} kvm.nx_huge_pages=force"
# Distrust embedded CPU entropy
grub_cmdline="${grub_cmdline} random.trust_cpu=off"
# DMA hardening and misc fixes
if [[ -n "${is_intel_cpu}" ]]; then
	grub_cmdline="${grub_cmdline} intel_iommu=on modprobe.blacklist=nouveau pci=noaer"
else
	grub_cmdline="${grub_cmdline} amd_iommu=on acpi_backlight=vendor mem_encrypt=off"
fi
grub_cmdline="${grub_cmdline} efi=disable_early_pci_dma"
# Kernel hardening
grub_cmdline="${grub_cmdline} slab_nomerge"
grub_cmdline="${grub_cmdline} slub_debug=FZ"
grub_cmdline="${grub_cmdline} init_on_alloc=1 init_on_free=1"
grub_cmdline="${grub_cmdline} mce=0"
grub_cmdline="${grub_cmdline} pti=on"
grub_cmdline="${grub_cmdline} vsyscall=none"
grub_cmdline="${grub_cmdline} page_alloc.shuffle=1"
grub_cmdline="${grub_cmdline} lockdown=confidentiality"
grub_cmdline="${grub_cmdline} module.sig_enforce=1"
# Custom additions
grub_cmdline="${grub_cmdline} extra_latent_entropy"
grub_cmdline="${grub_cmdline} oops=panic"
grub_cmdline="${grub_cmdline} ipv6.disable=1"
grub_cmdline="${grub_cmdline} cryptdevice=/dev/${volume}/root:root:allow-discards root=/dev/mapper/root"
bootloader_id="Xenos"


setup_drive() {
	# Set the system time
	timedatectl set-ntp true

	# Wipe the drive
	if [[ -n "${has_lv}" ]]; then
		yes | lvremove "${volume}"
	fi

	if [[ -n "${has_vg}" ]]; then
		yes | vgremove "${volume}"
	fi

	if [[ -n "${has_pv}" ]]; then
		yes | pvremove "${drive}2"
	fi

	sgdisk -Z "${drive}"

	# Generate new GPT headers on the drive
	sgdisk -a 2048 -o "${drive}"

	#Partition				Size			Type						Code
	#-----------------------------------------------------------------------
	#/dev/sdx1				550M			EFI							ef00
	#/dev/sdx2				100%FREE		Linux LUKS					8300

	# Create the drive partitions
	sgdisk -n 1:0:+550M "${drive}"
	sgdisk -n 2:0:0 "${drive}"

	# Set the drive partition types
	sgdisk -t 1:ef00 "${drive}"
	sgdisk -t 2:8300 "${drive}"

	# Label the drive partitions
	sgdisk -c 1:"EFI" "${drive}"
	sgdisk -c 2:"Linux LUKS" "${drive}"

	# Format the drive partitions
	yes | mkfs.fat -F32 "${drive}1"

	yes | pvcreate "${drive}2"
	yes | vgcreate "${volume}" "${drive}2"
	yes | lvcreate -l 100%FREE -n root "${volume}"
	echo "${luks_password}" | cryptsetup -h sha512 -s 512 luksFormat /dev/mapper/"${volume}-root"
	echo "${luks_password}" | cryptsetup open /dev/mapper/"${volume}-root" root
	yes | mkfs.ext4 /dev/mapper/root

	# Mount the drive partitions
	mount /dev/mapper/root /mnt
	mkdir /mnt/boot
	mount "${drive}1" /mnt/boot
}


setup_system() {
	# Update /etc/pacman.d/mirrorlist automatically
	pacman -Syy
	pacman -S --noconfirm pacman-contrib
	curl "${mirror_list}" -o mirrorlist.pre
	sed -i "s/^#Server/Server/g" mirrorlist.pre
	rankmirrors -n 5 mirrorlist.pre > mirrorlist
	cp mirrorlist /etc/pacman.d/
	pacman -Syy

	# Begin pacstrap
	pacstrap /mnt $core_pack

	# Generate fstab
	genfstab -U /mnt >> /mnt/etc/fstab
}


enter_chroot() {
arch-chroot /mnt /bin/bash <<EOF
	# Set the timezone
	ln -sf /usr/share/zoneinfo/"${timezone}" /etc/localtime
	hwclock --systohc

	# Set the locale
	sed -i "s/^#${language}/${language}/g" /etc/locale.gen
	locale-gen
	echo "LANG=${language}" > /etc/locale.conf

	# Configure the networking
	echo "${hostname}" > /etc/hostname
	echo -e "127.0.0.1 localhost\n127.0.1.1 ${hostname}.localdomain ${hostname}" > /etc/hosts

	# Configure sudo
	sed -i "s/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/g" /etc/sudoers

	# Create our user
	useradd -m -g users -G wheel -s /bin/bash "${username}"
	echo "$username:$userpass" | chpasswd

	# Configure mkinitcpio for luks
	sed -i "s/^HOOKS=.*/HOOKS=(base udev autodetect keyboard modconf block encrypt lvm2 filesystems fsck)/g" /etc/mkinitcpio.conf
	mkinitcpio -p linux-hardened

	# Configure grub
	sed -i "s/^#GRUB_ENABLE_CRYPTODISK=y/GRUB_ENABLE_CRYPTODISK=y/g" /etc/default/grub
	sed -i 's|^GRUB_CMDLINE_LINUX=.*|GRUB_CMDLINE_LINUX="${grub_cmdline}"|g' /etc/default/grub
	grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id="${bootloader_id}" --recheck
	grub-mkconfig -o /boot/grub/grub.cfg

	# Exit chroot
	exit
EOF
}


exit_installer() {
	# Dismount all mounted partitions
	umount -R /mnt

	# Prompt for shutdown
	read -p "Xenos base install complete. Press [Enter] key to shutdown..."
	shutdown now
}


setup_drive
setup_system
enter_chroot
exit_installer

