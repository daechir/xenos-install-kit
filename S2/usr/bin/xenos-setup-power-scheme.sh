#!/bin/bash
# This script sets up a power saving scheme without all the bloat.
#
# Author: Daechir
# Author URL: https://github.com/daechir
# Modified Date: 12/05/20
# Version: v1d


hot_remove_nvidia(){
  local has_nvidia_gpu=$(lspci | grep -e VGA -e 3D | grep -i "nvidia" 2> /dev/null || echo "")
  local xorg_using_intel=$(grep -i 'driver "intel"\|driver "modesetting"' /etc/X11/xorg.conf.d/* 2> /dev/null || echo "")

  if [[ -n "${has_nvidia_gpu}" && -n "${xorg_using_intel}" ]]; then
    local nvidia_vga_id=$(lspci | grep -e VGA -e 3D | grep -i "nvidia" | awk '{print $1}')
    local nvidia_audio_id=$(lspci | grep -e Audio | grep -i "nvidia" | awk '{print $1}')

    # Hot remove nvidia devices
    echo 1 | tee "/sys/bus/pci/devices/0000:${nvidia_vga_id}/remove" > /dev/null
    echo 1 | tee "/sys/bus/pci/devices/0000:${nvidia_audio_id}/remove" > /dev/null
  fi

  return 0
}

setup_power_scheme(){
  local audio_value=1
  local cpu_governor_value="powersave"
  local pci_value="auto"
  local sata_value="med_power_with_dipm"
  local laptop_mode_value=5
  local dirty_ratio_value=20
  local dirty_background_ratio_value=10
  local dirty_expire_centisecs_value=6000
  local dirty_writeback_centisecs_value=1500
  local xfssyncd_centisecs_value=6000
  local usb_value="auto"

  # Set audio value
  echo "${audio_value}" | tee /sys/module/snd_hda_intel/parameters/power_save > /dev/null
  echo "${audio_value}" | tee /sys/module/snd_hda_intel/parameters/power_save_controller > /dev/null

  # Set CPU governor value
  for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
  do
    echo "${cpu_governor_value}" | tee "${cpu}" > /dev/null
  done

  # Set PCI value
  echo "${pci_value}" | tee /sys/block/sd*/device/power/control > /dev/null

  for pci in /sys/bus/pci/devices/*/power/control
  do
    echo "${pci_value}" | tee "${pci}" > /dev/null
  done

  for pci in /sys/bus/pci/devices/*/ata*/power/control
  do
    echo "${pci_value}" | tee "${pci}" > /dev/null
  done

  # Set SATA value
  for sata in /sys/class/scsi_host/host*/link_power_management_policy
  do
    echo "${sata_value}" | tee "${sata}" > /dev/null
  done

  # Set SYSCTL value's
  echo "${laptop_mode_value}" | tee /proc/sys/vm/laptop_mode > /dev/null
  echo "${dirty_ratio_value}" | tee /proc/sys/vm/dirty_ratio > /dev/null
  echo "${dirty_background_ratio_value}" | tee /proc/sys/vm/dirty_background_ratio > /dev/null
  echo "${dirty_expire_centisecs_value}" | tee /proc/sys/vm/dirty_expire_centisecs > /dev/null
  echo "${dirty_writeback_centisecs_value}" | tee /proc/sys/vm/dirty_writeback_centisecs > /dev/null
  echo "${xfssyncd_centisecs_value}" | tee /proc/sys/fs/xfs/xfssyncd_centisecs > /dev/null

  # Set USB value
  for usb in /sys/bus/usb/devices/*/power/control
  do
    echo "${usb_value}" | tee "${usb}" > /dev/null
  done

  return 0
}


setup_power_scheme
hot_remove_nvidia

exit 0

