# Author
Author: Daechir <br/>
Author URL: https://github.com/daechir <br/>
License: GNU GPL <br/>
Modified Date: 07/11/20 <br/>
Version: v1


## Purpose
The Xenos Install Kit serves as a custom automated Arch Linux installer fine tuned for specific use cases:
+ It's ideal for those who want a fully featured OS without too much bloat.
+ It's ideal for those who desire security above all else.
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
### S2 (Step 2)
#### S2a .sh
+ https://wiki.archlinux.org/index.php/Simple_stateful_firewall
#### S2b .sh
+ install_essentials()
	* https://github.com/Askannz/optimus-manager
	* https://github.com/Askannz/optimus-manager/wiki/A-guide--to-power-management-options
+ install_optionals()
	* https://wiki.archlinux.org/index.php/Trusted_Platform_Module
	* https://github.com/jonathanio/update-systemd-resolved
	* https://github.com/jonathanio/update-systemd-resolved/issues/59
	* https://developer.gnome.org/NetworkManager/stable/NetworkManager.html
	* https://developer.gnome.org/NetworkManager/stable/NetworkManager.conf.html
	* https://wiki.archlinux.org/index.php/Systemd-resolved
+ misc_fixes()
	* https://www.freedesktop.org/software/systemd/man/journald.conf
	* https://wiki.archlinux.org/index.php/Iw
	* https://wiki.archlinux.org/index.php/Lm_sensors
	* https://wiki.archlinux.org/index.php/PulseAudio/Examples
	* https://www.freedesktop.org/software/systemd/man/user.conf.d.html
+ harden_parts()
	* https://github.com/Neo23x0/auditd/blob/master/audit.rules
	* https://wiki.archlinux.org/index.php/Security
	* ~~https://theprivacyguide1.github.io/linux_hardening_guide.html~~ (Link is deprecated)
	* https://obscurix.github.io
	* https://github.com/Whonix/security-misc

