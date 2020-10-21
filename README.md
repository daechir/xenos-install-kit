# Author
Author: Daechir <br/>
Author URL: https://github.com/daechir <br/>
License: GNU GPL <br/>
Modified Date: 10/20/20 <br/>
Version: v2w


## Changelog
+ v2w
  * S2b.sh
    + Add /usr/share/X11/xorg.conf.d/ to xenos-control-defaults.sh.
    + Seperate modprobe.d customizations based on vendor.
    + Add Xorg server hardening.


## Purpose
The Xenos Install Kit serves as a custom automated Arch Linux installer fine tuned for specific use cases:
+ It's ideal for those who want a fully featured OS without too much bloat.
+ It's ideal for those who desire security above all else.
+ It's ideal for an intermediate to expert linux user.
+ It's ideal for those who are ok with troubleshooting issues on their own as:
  * The software may not always work as expected.
  * Or specific hardware may not always work as expected.

If any of the above criteria fit your use case then make sure to audit the scripts before use.


## Desired System Specs
PC Type: Desktop or laptop <br/>
Architecture: x86-64 <br/>
BIOS Type: UEFI (EFI) <br/>
CPU: Detected <br/>
GPU: Detected <br/>
Language: User defined (Default en_US.UTF-8) <br/>
Timezone: User defined (Default America/New_York) <br/>
TPM: 2.0 supported


## Features
Full Disk Encryption <br/>
Kernel CPU Mitigations <br/>
Kernel Module Restrictions <br/>
Kernel Hardening and Optimizations <br/>
Comprehensive System Auditing <br/>

And much much more.


## Sources
### S1 (Step 1)
#### S1 .sh
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
  * https://developer.gnome.org/NetworkManager/stable/
+ misc_fixes()
  * https://www.freedesktop.org/software/systemd/man/journald.conf
  * https://wiki.archlinux.org/index.php/Apparmor
  * https://wiki.archlinux.org/index.php/Lm_sensors
  * https://www.freedesktop.org/software/systemd/man/user.conf.d.html
  * https://wiki.archlinux.org/index.php/Iw
+ harden_parts()
  * https://github.com/Neo23x0/auditd/blob/master/audit.rules
  * https://wiki.gnome.org/Accessibility/Documentation/GNOME2/Mechanics
  * https://wiki.archlinux.org/index.php/Security
  * https://theprivacyguide1.github.io/linux_hardening_guide.html
  * https://obscurix.github.io
  * https://github.com/Whonix/security-misc
  * https://www.freedesktop.org/software/systemd/man/systemd.exec.html

