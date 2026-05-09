# HS3 RPi2 OS Image Optimization
Stripped Raspbian 9 (R9) OS for Z-Net Interface

### Target Device: 1GB USB Deployment for Raspberry Pi 2
---
Prerequisites
* MicroSD Card
* Linux Environment
* CloneZilla Live Media
* HomeSeer Rasp-Pi Image: http://www.homeseer.com/updates3/hs3pi3_image_070319.zip

# Phase 1: OS Debloating & Preparation
### Goal: Strip the Raspbian 9 environment to its absolute essentials to fit a 1GB physical constraint.

**1.1 Software Purge**
---
### Remove High-Capacity Suites
* sudo apt-get purge wolfram-engine
* sudo apt-get purge libreoffice*
* sudo apt-get purge mono-xsp4

### Dependency Cleanup

`sudo apt-get autoremove`

---

### Kernel & Module Slimming

Run `uname -r` to identify the active kernel.

Delete all inactive kernel versions in /lib/modules/[version].

---

### Localization & Documentation

Delete /usr/share/doc and /usr/share/man (keeping only English manuals).

`find /usr/share/doc -depth -type d -empty -exec rmdir {} \;`

`find /usr/share/man -mindepth 1 -maxdepth 1 -type d ! -name 'man*' ! -name 'en*' -exec rm -rf {} +`

Strip unused language packs in /usr/share/locale.

`sudo find /usr/share/locale -mindepth 1 -maxdepth 1 -type d ! -name 'en*' ! -name 'default' -exec rm -rf {} +`

Purge /var/lib/apt/lists, /tmp/*, and /var/tmp/*.

`sudo rm -rf /var/lib/apt/lists/*`
`sudo rm -rf /tmp/*`
`sudo rm -rf /var/tmp/*`

**1.2 Service Management**
---
Mask Services: Disable the following to reduce I/O and interference

`sudo systemctl mask avahi-daemon`

`sudo systemctl mask ModemManager (prevents serial port interference)`

apt-daily (Update downloader)

`sudo systemctl mask apt-daily.service`

`sudo systemctl mask apt-daily.timer`

apt-daily-upgrade (Upgrade installer)

`sudo systemctl mask apt-daily-upgrade.service`

`sudo systemctl mask apt-daily-upgrade.timer`

**1.3 Binary & Script Handshakes**
---
### ser2net Setup ###
Copy the attached R8 Pi 2 binary file to /usr/local/sbin/

Rename to ser2net

Set permissions `chmod +x /usr/local/sbin/ser2net`
---
### Configure the Serial-to-Network Bridge ###

*/etc/rc.local*

Add these lines just before exit 0 line

`sudo sh /var/www/Main/uzb.sh &`

`/usr/local/sbin/ser2net -c /etc/ser2net.conf -n > /dev/null 2>&1 &`

`/usr/local/HomeSeer/register_with_find.sh > /dev/null 2>&1 &`

sudo chmod +x /var/www/Main/uzb.sh to handle the hardware initialization.

---

*/etc/ser2net.conf*

Map the Z-Wave board on /dev/ttyAMA0 to TCP port 2001 by uncommenting (or adding) this line at the bottom of the file.

`2001:raw:0:/dev/ttyAMA0:115200 8DATABITS NONE 1STOPBIT -XONXOFF -RTSCTS`

This maps the Z-Wave board on /dev/ttyAMA0 to TCP port 2001.

---

 ### Z-Wave Radio Logic ###

Modify /etc/rc.local to include above the line printf "Setting audio output to analog...\n"

`modprobe ftdi_sio vendor=0x0403 product=0xc07f`

modprobe ftdi_sio...: This line manually forces the kernel to load the USB-to-serial driver for a specific device (Vendor 0403, Product c07f). This ensures the OS recognizes the Z-Wave radio hardware even if the default Raspbian kernel doesn't automatically map it to the serial driver.

`sudo sh /var/www/Main/uzb.sh &`: Launches the discovery script in the background to avoid hanging the boot process.

---

Create `/var/www/Main/uzb.txt` as a state flag to prevent redundant network requests.

This file's existence tells the /etc/rc.local script: "The Z-Wave radio has already been found and configured; do not overwrite /etc/ser2net.conf."

By checking for this file first, this prevents the system from performing unnecessary network requests (wget) or disk writes every time the Pi reboots, which helps preserve the lifespan of the USB drive.

# Phase 2: Filesystem & Partition
Goal: Shrink the logical filesystem and re-align partitions for the 1GB target.

**2.1 Filesystem Compression & Tuning**
--
⚠ USB must be unmounted to avoid corruption ⚠

### Disable Journaling ###

This frees hidden data blocks before imaging (phase 3).

`sudo tune2fs -O ^has_journal /dev/sdX#`

### Set Reserved Blocks ###

Reduces root-reserved space from 5% to 1% to maximize usable capacity on a 1GB drive.

`sudo tune2fs -m 1 /dev/sdX#`

Force Check: `sudo e2fsck -f /dev/sdX#`

### Shrink Filesystem ###

This utility will shrink the filesystem to the smallest possible size

`sudo resize2fs -M /dev/sdX#`

**2.2 Partition Table Re-alignment (fdisk)**
--
Delete Partition: Delete EXT4 partition

Recreate Partition: Create new logical partition

Signature: Choose `No` when asked to remove the ext4 signature.

# Phase 3: Cloning & Boot Redirection

Goal: Transfer the data and update the bootloader to recognize the USB drive.

**3.1 CloneZilla Backup**
--
### Choose expert mode ###

Only backup the EXT4 partition which subsequently prevents the NOOBS architecture when restoring the partition.

Active Flags: `-icds, -k, -c`

Disabled Flags: `-j2, -e1 auto, -e2, -r`

**3.2 CloneZilla Restoration**
--
### Re-enable Journaling ###

After the image restore completes, input these commands in the CloneZilla terminal.

`sudo tune2fs -j /dev/sdX#`

`sudo resize2fs /dev/sdX#`

Verify UUID

Run `blkid /dev/sdX#` to get the new PARTUUID.

**3.3 Bootloader Configuration**
--
Update /boot/cmdline.txt

Remove `console=serial0,115200` on the microSD and USB

Update root=PARTUUID=[new-uuid]

Update /etc/fstab: Map the root mount point to the new PARTUUID.

# Phase 4: Post-Boot Optimization

Goal: Finalize the zero-swap state and log rotation.

**4.1 Swap Management**
--
`sudo dphys-swapfile swapoff`

`sudo systemctl disable dphys-swapfile`

`sudo rm /var/swap`

Set `CONF_SWAPSIZE=0` in /etc/dphys-swapfile.

**4.2 Logging Constraints (/etc/systemd/journald.conf)**
--
Prevent logs from consuming excessive storage space.

`[Journal]`

`Storage=persistent`

`SystemMaxUse=10M`

`RuntimeMaxUse=10M`

`SystemMaxFileSize=2M`
