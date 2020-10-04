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
is_intel_cpu=$(lscpu | grep -i "intel(r)" 2> /dev/null || echo "")
kernel_type="linux-hardened"
core_pack="apparmor base base-devel dhcpcd git ${kernel_type} ${kernel_type}-headers linux-firmware lvm2 nano unzip xfsprogs"
if [[ -n "${is_intel_cpu}" ]]; then
  cpu_type="intel"
else
  cpu_type="amd"
fi
core_pack="${core_pack} ${cpu_type}-ucode"
systemdboot_entry="title Arch Linux\nlinux /vmlinuz-${kernel_type}\ninitrd /${cpu_type}-ucode.img\ninitrd /initramfs-${kernel_type}.img\noptions"
timezone="America/New_York"
language="en_US.UTF-8"
hostname=$(cat /dev/urandom | tr -dc "a-zA-Z0-9" | fold -w 32 | head -n 1)
username="$"
userpass="$"
# Begin systemdboot_options generation
# Core security features
systemdboot_options="apparmor=1 security=apparmor audit=1"
# CPU mitigations
systemdboot_options="${systemdboot_options} spectre_v2=on"
systemdboot_options="${systemdboot_options} spec_store_bypass_disable=on"
systemdboot_options="${systemdboot_options} tsx=off tsx_async_abort=full,nosmt"
systemdboot_options="${systemdboot_options} mds=full,nosmt"
systemdboot_options="${systemdboot_options} l1tf=full,force"
systemdboot_options="${systemdboot_options} nosmt=force"
systemdboot_options="${systemdboot_options} kvm.nx_huge_pages=force"
# Distrust embedded CPU entropy
systemdboot_options="${systemdboot_options} random.trust_cpu=off"
# DMA hardening and misc fixes
if [[ -n "${is_intel_cpu}" ]]; then
  systemdboot_options="${systemdboot_options} intel_iommu=on modprobe.blacklist=nouveau pci=noaer"
else
  systemdboot_options="${systemdboot_options} amd_iommu=on acpi_backlight=vendor"
fi
systemdboot_options="${systemdboot_options} efi=disable_early_pci_dma"
# Kernel hardening
systemdboot_options="${systemdboot_options} slab_nomerge"
systemdboot_options="${systemdboot_options} slub_debug=FZ"
systemdboot_options="${systemdboot_options} init_on_alloc=1 init_on_free=1"
systemdboot_options="${systemdboot_options} mce=0"
systemdboot_options="${systemdboot_options} pti=on"
systemdboot_options="${systemdboot_options} vsyscall=none"
systemdboot_options="${systemdboot_options} page_alloc.shuffle=1"
systemdboot_options="${systemdboot_options} lockdown=confidentiality"
systemdboot_options="${systemdboot_options} module.sig_enforce=1"
# Custom additions
systemdboot_options="${systemdboot_options} extra_latent_entropy"
systemdboot_options="${systemdboot_options} oops=panic"
systemdboot_options="${systemdboot_options} debugfs=off"
systemdboot_options="${systemdboot_options} nowatchdog"
systemdboot_options="${systemdboot_options} ipv6.disable=1"
systemdboot_options="${systemdboot_options} cryptdevice=/dev/${volume}/root:root:allow-discards root=/dev/mapper/root"
systemdboot_options="${systemdboot_options} quiet rw"
systemdboot_entry="${systemdboot_entry} ${systemdboot_options}"


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
  yes | mkfs.xfs /dev/mapper/root

  # Mount the drive partitions
  mount /dev/mapper/root /mnt
  mkdir /mnt/boot
  mount "${drive}1" /mnt/boot
}


setup_system() {
  # Update /etc/pacman.d/mirrorlist automatically
  pacman -Syy
  pacman -S --noconfirm pacman-contrib
  curl -o mirrorlist.pre "${mirror_list}"
  sed -i "s/^#Server/Server/g" mirrorlist.pre
  rankmirrors -n 8 mirrorlist.pre > mirrorlist
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
  mkinitcpio -p "${kernel_type}"

  # Configure systemd-boot
  bootctl install
  sed -i d /boot/loader/loader.conf
  echo -e "default arch\ntimeout 0\neditor 0" > /boot/loader/loader.conf
  echo -e "${systemdboot_entry}" > /boot/loader/entries/arch.conf

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

