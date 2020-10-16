#!/bin/bash
# This script sets up a power saving scheme without all the bloat.
#
# Author: Daechir
# Author URL: https://github.com/daechir
# Modified Date: 10/15/20
# Version: v1a


hot_remove_nvidia(){
  local has_nvidia_gpu=$(lspci | grep -e VGA -e 3D | grep -i "nvidia" 2> /dev/null || echo "")
  local xorg_using_intel=$(grep -i 'driver "intel"' /etc/X11/xorg.conf.d/10-optimus-manager.conf 2> /dev/null || echo "")

  if [[ -n "${has_nvidia_gpu}" && -n "${xorg_using_intel}" ]]; then
    local nvidia_vga_id=$(lspci | grep -e VGA -e 3D | grep -i "nvidia" | awk '{print $1}')
    local nvidia_audio_id=$(lspci | grep -e Audio | grep -i "nvidia" | awk '{print $1}')

    # Hot remove nvidia devices to save power
    echo 1 | tee "/sys/bus/pci/devices/0000:${nvidia_vga_id}/remove" > /dev/null
    echo 1 | tee "/sys/bus/pci/devices/0000:${nvidia_audio_id}/remove" > /dev/null
  fi

  return 0
}

setup_power_scheme(){
  # Set audio to power saving
  echo 1 | tee /sys/module/snd_hda_intel/parameters/power_save > /dev/null
  echo 1 | tee /sys/module/snd_hda_intel/parameters/power_save_controller > /dev/null

  # Set CPU Governor to power saving
  for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
  do
    echo "powersave" | tee "${cpu}" > /dev/null
  done

  # Set PCI to autosuspend
  echo "auto" | tee /sys/block/sd*/device/power/control > /dev/null

  for pci in /sys/bus/pci/devices/*/power/control
  do
    echo "auto" | tee "${pci}" > /dev/null
  done

  for pci in /sys/bus/pci/devices/*/ata*/power/control
  do
    echo "auto" | tee "${pci}" > /dev/null
  done

  # Set SATA to power saving
  for sata in /sys/class/scsi_host/host*/link_power_management_policy
  do
    echo "min_power" | tee "${sata}" > /dev/null
  done

  # Set sysctl parameters
  echo 5 | tee /proc/sys/vm/laptop_mode > /dev/null
  echo 20 | tee /proc/sys/vm/dirty_ratio > /dev/null
  echo 10 | tee /proc/sys/vm/dirty_background_ratio > /dev/null
  echo 6000 | tee /proc/sys/vm/dirty_expire_centisecs > /dev/null
  echo 1500 | tee /proc/sys/vm/dirty_writeback_centisecs > /dev/null
  echo 6000 | tee /proc/sys/fs/xfs/xfssyncd_centisecs > /dev/null

  # Set USB to autosuspend
  for usb in /sys/bus/usb/devices/*/power/control
  do
    echo "auto" | tee "${usb}" > /dev/null
  done

  return 0
}


hot_remove_nvidia
setup_power_scheme

exit 0

