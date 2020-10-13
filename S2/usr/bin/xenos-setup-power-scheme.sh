#!/bin/bash
# This script setups a powersaving scheme without all the bloat.
#
# Author: Daechir
# Author URL: https://github.com/daechir
# Modified Date: 10/13/20
# Version: v1


setup_power_scheme(){
  # Set audio to power saving
  echo 5 | tee /sys/module/snd_hda_intel/parameters/power_save > /dev/null
  echo 1 | tee /sys/module/snd_hda_intel/parameters/power_save_controller > /dev/null

  # Set CPU Governor to power saving
  for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
  do
    echo "powersave" | tee "${cpu}" > /dev/null
  done

  # Set PCI to autosuspend
  for pci in /sys/bus/pci/devices/*/power/control
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


setup_power_scheme


exit 0

