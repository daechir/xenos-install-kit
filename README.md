# Author
Author: Daechir <br/>
Author URL: https://github.com/daechir <br/>
License: GNU GPL <br/>
Modified Date: 03/28/21 <br/>
Version: v3c1


## Changelog
+ v3c1
  * S1.sh
    + Remove AMD iommu= parameter.
      * In some instances iommu=soft can cause iommu to fail altogether.
  * S2b.sh
    + xenos-control-defaults.sh:
      * Add /etc/profile.d.
    + Add new ctls.
    + Ship /etc/profile as a file instead of modifying the existing one.
    + Add man-db.service isolation.
    + Remove noatime from /etc/fstab.
      * The performance gain from this flag is neglible with newer XFS versions.
    + bashrc:
      * Restrict all PAGER requests to use less (In secure mode).
      * Restrict PATH environment variable.
      * Unset numerous other variables.
      * Enhance terminal further.


## Purpose
The Xenos Install Kit serves as a custom automated Arch Linux installer fine-tuned for specific use cases:

+ It's ideal for those who want a fully featured OS without too much bloat.
+ It's ideal for those who desire security above all else.
+ It's ideal for those who desire a stable system.
+ It's ideal for an intermediate to expert linux user.
+ It's ideal for those who are ok with troubleshooting issues on their own as:
  * The software may not always work as expected.
  * Or specific hardware may not always work as expected.


## Desired System Specs
PC Type: Laptop preferred <br/>
Architecture: x86_64 <br/>
BIOS Type: UEFI (EFI) <br/>
GPU: Integrated preferred (Non-optimus) <br/>
TPM: 2.0 supported <br/><br/>
Note: <br/>
Optimus enabled laptops are truly non-ideal for this installer or linux in general. <br/>
Please see the about optimus section below for more information.


## About Optimus
Optimus enabled systems have generally had poor support over the years in linux. <br/>
This is mostly due to the design concept and the lack of official support from Intel, AMD or NVIDIA. <br/>
As such until optimus-manager was released optimus support was very hacky. <br/>
However, this installer hasn't been created with these systems in mind. <br/>
This installer should work out of the box though if you have a integrated GPU alongside your dedicated GPU. <br/>
Beyond that you will have to disable the lockdown and module.sig_enforce kernel parameters to use custom modules like nvidia-dkms or bumblebee-dkms in order for optimus-manager to work. <br/>
From a security standpoint I don't recommend this for several reasons:

+ Without lockdown and module.sig_enforce enabled the attack surface of your entire system is vastly increased.
+ With the nvidia-dkms module in use you're effectively tainting the kernel with proprietary globs.
+ With the bumblebee-dkms module in use, which is nearly a decade old, the attack surface increases further.
+ With the use of the dedicated GPU a skilled attacker may be able to write malicious firmware to the card itself without your knowledge. This would essentially create a permanent backdoor that
is reoccurring across reinstalls until you update its firmware manually.
+ One can assume use of the dedicated GPU is intended for gaming on linux (most of the time). This alone will make you add other libraries in different architecture types to even play your games. In recent years these libraries have been the focus of many new types of privilege escalation attacks.

The list goes on and on. <br/>
Therefore this installer will never fully support optimus enabled laptops due to the fact it's out of the scope of the Xenos Install Kits' purpose.


## About Modprobe.d
In Xenos's /etc/modprobe.d files you will notice the use of /bin/true over /bin/false. <br/>
Contrary to many distros recommendations to use /bin/false we opt for /bin/true because /bin/true essentially utilizes reverse psychology. <br/>
Normally one would expect a blacklisted module to return with a hard "false" or "denied" when force loaded. <br/>
In our case blacklisted module's always return as "true" which will imply that it was loaded when infact it actually wasn't. <br/>
Semantically speaking both are correct but logically speaking /bin/true makes more sense to use when opting for additional security through obscurity.


## Features
Comprehensive System Auditing <br/>
Full Disk Encryption <br/>
Isolated or Sandboxed Systemd Services <br/>
Kernel CPU Mitigations <br/>
Kernel Module Restrictions <br/>
Kernel Hardening and Optimizations <br/>
Unique Independently Created Service Files and Scripts <br/>
Restricted Dbus services <br/>
Restricted Xorg server <br/><br/>
And much much more.


## Usage
Before using the Xenos Install Kit please atleast first attempt to install Arch Linux with their installation guide if you haven't already. <br/>
If you have already attempted to do so then make sure to read the purpose, desired system specs, about optimus, about modprobe.d and features sections above. <br/>
Lastly ensure that you have taken the time to audit the scripts. <br/>
First edit S1.sh and add:

+ A luks passphrase
+ A username
+ A password
+ Update any other variables like language or timezone

Second edit S2b.sh and update its variables as needed. <br/>
Third upload S1.sh to a host of your choice then also archive the entire S2 folder and upload it there. <br/>
Fourth insert the Arch USB, curl S1.sh only, chmod +x it and ./S1.sh. <br/>
Fifth boot into the barebones system, login, start dhcpcd.service, curl the archive of S2 from above, unpackage it,
chmod +x the sh files, sudo ./S2a.sh and finally ./S2b.sh.


## Sources
### S1 (Step 1)
#### S1 .sh
+ https://www.kernel.org/doc/html/latest/admin-guide/kernel-parameters.html
+ https://wiki.archlinux.org/index.php/Installation_Guide
+ https://wiki.archlinux.org/index.php/Dm-crypt/Device_encryption
+ https://wiki.archlinux.org/index.php/Dm-crypt/Encrypting_an_entire_system
+ https://wiki.archlinux.org/index.php/Systemd-boot
### S2 (Step 2)
#### S2a .sh
+ https://wiki.archlinux.org/index.php/Simple_stateful_firewall
#### S2b .sh
+ install_essentials()
  * https://wiki.archlinux.org/index.php/Makepkg
  * https://wiki.archlinux.org/index.php/Mkinitcpio
  * https://wiki.archlinux.org/index.php/Xorg
  * https://github.com/Askannz/optimus-manager/wiki
  * https://wiki.archlinux.org/index.php/List_of_Applications
  * https://wiki.archlinux.org/index.php/Smartcards
  * https://wiki.archlinux.org/index.php/Trusted_Platform_Module
  * https://github.com/venam/2bwm
+ install_optionals()
  * https://github.com/jonathanio/update-systemd-resolved
  * https://wiki.archlinux.org/index.php/Systemd-resolved
  * https://man.archlinux.org/man/core/systemd/systemd.net-naming-scheme.7.en
  * https://developer.gnome.org/NetworkManager/stable/
+ misc_fixes()
  * https://man.archlinux.org/man/core/systemd/journald.conf.5.en
  * https://wiki.archlinux.org/index.php/Apparmor
  * https://wiki.archlinux.org/index.php/Lm_sensors
  * https://man.archlinux.org/man/core/systemd/user.conf.d.5.en
  * https://wiki.archlinux.org/index.php/Iw
+ harden_parts()
  * https://github.com/Neo23x0/auditd/blob/master/audit.rules
  * https://wiki.gnome.org/Accessibility/Documentation/GNOME2/Mechanics
  * https://wiki.archlinux.org/index.php/Security
  * https://github.com/Whonix/security-misc
  * https://madaidans-insecurities.github.io/guides/linux-hardening.html
  * https://man.archlinux.org/man/core/systemd/systemd.exec.5.en


