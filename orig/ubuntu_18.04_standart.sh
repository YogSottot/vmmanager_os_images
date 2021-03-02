d-i keyboard-configuration/xkb-keymap select us
d-i keyboard-configuration/modelcode        string  pc104
d-i keyboard-configuration/model    select  Generic 104-key PC
d-i netcfg/get_hostname string ($HOSTNAME)

# Mirrors
#d-i mirror/protocol string ftp
#d-i mirror/country string manual
#d-i mirror/ftp/hostname string ftp.ru.debian.org
#d-i mirror/ftp/directory string /debian
#d-i mirror/ftp/proxy string
d-i mirror/country string manual
d-i mirror/http/hostname string ($MIRROR)
d-i mirror/http/directory string /ubuntu
d-i mirror/http/proxy string ($HTTPPROXYv4)

d-i mirror/suite string bionic

d-i passwd/root-login boolean true
d-i passwd/make-user boolean false

d-i passwd/root-password-crypted password ($PASS_CRYPT)
openssh-server   openssh-server/permit-root-login       boolean true
d-i openssh-server/permit-root-login    boolean true

d-i clock-setup/utc boolean true

d-i time/zone string ($TIMEZONE)

d-i preseed/early_command string \
        anna-install parted-udeb ;\
        if [ "($NAMESERVERS)" != "" ] && [ "($NAMESERVERS)" != "()" ]; then \
                nslist="($NAMESERVERS)" ;\
                sed -i -r '/^nameserver\s/d' /etc/resolv.conf ;\
                for ns in ${nslist}; do \
                        echo "nameserver ${ns}" >> /etc/resolv.conf ;\
                done ;\
        fi

# Partitioning and hostname
d-i partman/early_command string \
HSHORT=$(echo "($HOSTNAME)" | cut -d. -f1) ;\
echo "${HSHORT}" > /etc/hostname ;\
sed -i "s/^($IP).*/($IP) ($HOSTNAME) ${HSHORT}/" /etc/hosts ;\
for DISK in $(list-devices disk); do \
  parted -s ${DISK} mklabel gpt; \
  parted -s ${DISK} mklabel msdos; \
  dd if=/dev/zero of=${DISK} bs=512 count=1; \
done; \
# https://bugs.launchpad.net/ubuntu/+source/mdadm/+bug/1030354 ;\
# http://dev.bizo.com/2012/07/mdadm-device-or-resource-busy.html ;\
sed -i -r '/if ! log-output/,/fi/ {s/(^\s*if)/sleep 2\nudevadm control --stop-exec-queue\nsleep 2\n\1/; s/(fi.*)/\1\nudevadm control --start-exec-queue/}' /bin/auto-raidcfg ;\
# Monkey patching ;\
sed -i -r '/while \[ -n "\$reci/i for ARR in $(cat /proc/mdstat |       cut -d: -f1 | grep md); do mdadm --stop /dev/${ARR} ; done ;\' /bin/auto-raidcfg ;\
if [ -n "($HDD_RAID)" ] && [ "($HDD_RAID)" != "()" ]; then \
        case "($HDD_RAID)" in \
                raid_0) fname=raid0.sh ;; \
                raid_1) fname=raid1.sh ;; \
                raid_5) fname=raid5.sh ;; \
                raid_10) fname=raid10.sh ;; \
                no_raid) fname=noraid.sh ;; \
                *) fname=partition.sh ;; \
        esac ;\
else \
        fname=partition.sh ;\
fi ;\
wget -O /tmp/part.sh --no-check-certificate "($SHAREDIR_FILE)${fname}" ;\
if [ -n "($DISK_LAYOUT_FILE)" ] && [ "($DISK_LAYOUT_FILE)" != "()" ]; then \
  wget --no-check-certificate -O /tmp/diskpart.txt "($DISK_LAYOUT_FILE)" ;\
  wget --no-check-certificate -O /tmp/part.sh "($SHAREDIR_FILE)custom.sh" ;\
fi ;\
sh /tmp/part.sh force


partman-partitioning    partman-partitioning/confirm_new_label  boolean true
partman-efi     partman-efi/non_efi_system      boolean true
# Skip question about not having swap partition
partman-basicfilesystems partman-basicfilesystems/no_swap boolean false

d-i partman-auto/purge_lvm_from_device boolean true
d-i partman-lvm/device_remove_lvm boolean true
d-i partman-md/device_remove_md boolean true
d-i partman-md/confirm boolean true
d-i partman-md/confirm_nooverwrite boolean true
d-i partman-partitioning/confirm_write_new_label boolean true
d-i partman/choose_partition select finish
d-i partman/confirm boolean true
d-i partman/confirm_nooverwrite boolean true
mdadm-udeb      mdadm/boot_degraded     boolean true

d-i partman/mount_style select traditional

# Apt

#d-i base-installer/install-recommends boolean true

#d-i base-installer/kernel/linux/initramfs-generators string initramfs-tools
#d-i base-installer/kernel/image string linux-image-amd64

d-i apt-setup/contrib boolean true
#d-i apt-setup/use_mirror boolean true

# Packages
d-i apt-setup/services-select multiselect security, volatile
tasksel tasksel/first multiselect ubuntu-minimal
d-i base-installer/kernel/image string linux-server
d-i pkgsel/include string openssh-server vim wget ifupdown
d-i pkgsel/update-policy select none

popularity-contest popularity-contest/participate boolean false

# Grub
d-i grub-installer/only_debian boolean true
d-i grub-installer/with_other_os boolean true
grub-pc grub2/linux_cmdline_default     string bootdegraded=true
d-i grub2/linux_cmdline_default     string nomdmonddf nomdmonisw bootdegraded=true
grub-pc grub2/linux_cmdline string bootdegraded=true

d-i finish-install/keep-consoles boolean true
d-i finish-install/reboot_in_progress note

d-i preseed/late_command string \
        in-target rm -f /etc/apt/apt.conf ;\
        sed -i '/^#PermitRootLogin prohibit-password/a PermitRootLogin yes' /target/etc/ssh/sshd_config ;\
        if [ -n "($SSHPUBKEYS)" ]; then \
                mkdir -p /target/root/.ssh ;\
                chmod 700 /target/root/.ssh ;\
                echo "($SSHPUBKEYS)" > /target/tmp/keyfile ;\
                cat /target/tmp/keyfile | /target/usr/bin/base64 -d > /target/root/.ssh/authorized_keys ;\
                in-target rm -f /tmp/keyfile ;\
        fi ;\
        HSHORT=$(echo "($HOSTNAME)" | cut -d. -f1) ;\
        HSLAST=$(echo "($HOSTNAME)" | sed "s/${HSHORT}\.//") ;\
        echo "${HSHORT}" > /target/etc/hostname ;\
        sed -i "s/^($IP).*/($IP) ($HOSTNAME) ${HSHORT}/" /target/etc/hosts ;\
        sed -i "s/search.*/search ${HSLAST}/" /target/etc/resolvconf/resolv.conf.d/original ;\
  sed -i -r "s/#Domains=.*/Domains=${HSLAST}/" /target/etc/systemd/resolved.conf ;\
        ETHDEV=$(ip route show | grep default | grep -Eo 'dev\ .+\ ' | cut -d' ' -f2) ;\
        if [ "($TMPIPv4)" != "" ] && [ "($TMPIPv4)" != "()" ]; then \
                TMPIPv4="($TMPIPv4)" ;\
                MULTIIP=true ;\
        else \
                if [ -n "($IPv6)" ]; then \
                        TMPIPv4=true ;\
                else \
                        TMPIPv4=false ;\
                fi ;\
                MULTIIP=false ;\
        fi ;\
        if [ "($NEXTHOPIPv4)" != "" ] && [ "($NEXTHOPIPv4)" != "()" ]; then \
          VPU4=true ;\
        fi ;\
        if [ -n "($IPv6)" ]; then \
                if [ "#${MULTIIP}" = "#false" ] || [ "#${TMPIPv4}" = "#true" ] && [ -z "${VPU4}" ]; then \
                        echo "nameserver ($NAMESERVERv6)" > /target/etc/resolv.conf ;\
                        echo "nameserver ($NAMESERVERv6)" > /target/etc/resolvconf/resolv.conf.d/original ;\
                        sed -i "s/($IPv4)/($IPv6)/" /etc/hosts ;\
                        sed -i "s/($IPv4)/($IPv6)/" /target/etc/hosts ;\
                        echo "# The loopback network interface" > /target/etc/network/interfaces ;\
                        echo "auto lo" >> /target/etc/network/interfaces ;\
                        echo "iface lo inet loopback" >> /target/etc/network/interfaces ;\
                        echo "" >> /target/etc/network/interfaces ;\
                        echo "# The primary network interface" >> /target/etc/network/interfaces ;\
                        echo "auto ${ETHDEV}" >> /target/etc/network/interfaces ;\
                        echo "allow-hotplug ${ETHDEV}" >> /target/etc/network/interfaces ;\
                fi ;\
                echo "" >> /target/etc/network/interfaces ;\
                echo "iface ${ETHDEV} inet6 static" >> /target/etc/network/interfaces ;\
                echo -e "\taddress ($IPv6)" >> /target/etc/network/interfaces ;\
                echo -e "\tnetmask ($NETMASKv6)" >> /target/etc/network/interfaces ;\
                echo -e "\tgateway ($GATEWAYv6)" >> /target/etc/network/interfaces ;\
                if [ "($NEXTHOPIPv6)" != "" ] && [ "($NEXTHOPIPv6)" != "()" ]; then \
                        echo -e "pointopoint ($NEXTHOPIPv6)" >> /target/etc/network/interfaces ;\
                fi ;\
                if [ -n "($NAMESERVERv6)" ]; then \
                        echo -e "\tdns-nameservers ($NAMESERVERv6)" >> /target/etc/network/interfaces ;\
                fi ;\
                if [ "($IPv6ALIASES)" != "" ] && [ "($IPv6ALIASES)" != "()" ]; then \
                        ipnum=1 ;\
                        IPv6ALIASES="($IPv6ALIASES)" ;\
                        for ipv6alias in ${IPv6ALIASES}; do \
                                echo -e "\tup ip -6 addr add ${ipv6alias} dev ${ETHDEV}" >> /target/etc/network/interfaces ;\
                                echo -e "\tdown ip -6 addr del ${ipv6alias} dev ${ETHDEV}" >> /target/etc/network/interfaces ;\
                        done ;\
                fi ;\
        fi ;\
        if [ "($NEXTHOPIPv4)" != "" ] && [ "($NEXTHOPIPv4)" != "()" ] && [ "($IP)" != "($IPv6)" ]; then \
                echo "# The loopback network interface" > /target/etc/network/interfaces ;\
                echo "auto lo" >> /target/etc/network/interfaces ;\
                echo "iface lo inet loopback" >> /target/etc/network/interfaces ;\
                echo "" >> /target/etc/network/interfaces ;\
                echo "# The primary network interface" >> /target/etc/network/interfaces ;\
                echo "auto ${ETHDEV}" >> /target/etc/network/interfaces ;\
                echo "allow-hotplug ${ETHDEV}" >> /target/etc/network/interfaces ;\
                echo "iface ${ETHDEV} inet static" >> /target/etc/network/interfaces ;\
                echo -e "\taddress ($IP)" >> /target/etc/network/interfaces ;\
                echo -e "\tnetmask 255.255.255.255" >> /target/etc/network/interfaces ;\
                echo -e "\tgateway ($NEXTHOPIPv4)" >> /target/etc/network/interfaces ;\
                echo -e "\tpointopoint ($NEXTHOPIPv4)" >> /target/etc/network/interfaces ;\
                echo -e "\tdns-nameservers ($NAMESERVERv4)" >> /target/etc/network/interfaces ;\
                echo -e "\tdns-search ${HSLAST}" >> /target/etc/network/interfaces ;\
        fi ;\
        if [ "#${MULTIIP}" = "#true" ]; then \
                if [ "($IPv4ALIASES)" != "" ] && [ "($IPv4ALIASES)" != "()" ]; then \
                        ipnum=1 ;\
                        IPv4ALIASES="($IPv4ALIASES)" ;\
                        for ipv4alias in ${IPv4ALIASES}; do \
                                echo "" >> /target/etc/network/interfaces ;\
                                echo "auto ${ETHDEV}:${ipnum}" >> /target/etc/network/interfaces ;\
                                echo "allow-hotplug ${ETHDEV}:${ipnum}" >> /target/etc/network/interfaces ;\
                                echo "iface ${ETHDEV}:${ipnum} inet static" >> /target/etc/network/interfaces ;\
                                echo -e "\taddress ${ipv4alias}" >> /target/etc/network/interfaces ;\
                                echo -e "\tnetmask 255.255.255.255" >> /target/etc/network/interfaces ;\
                                ipnum=$(expr ${ipnum} + 1) ;\
                        done ;\
                fi ;\
        fi ;\
        test -f /usr/lib/finish-install.d/55netcfg-copy-config && sed -i '1a exit 0' /usr/lib/finish-install.d/55netcfg-copy-config ;\
        sed -i "s/dns-search.*/dns-search ${HSLAST}/" /target/etc/network/interfaces ;\
        if [ -f /tmp/grub_devices ]; then \
                for DISK in `cat /tmp/grub_devices | sed "s/\/dev\/sda//"`; do \
                        in-target grub-install ${DISK} ;\
                done ;\
        fi ;\
        sed -i -r 's/^(BLANK_TIME|POWERDOWN_TIME)=.*/\1=0/g' /target/etc/kbd/config ;\
        sed -i "s/FSCKFIX.*/FSCKFIX=yes/" /target/etc/default/rcS ;\
        in-target --pass-stdout lsblk -io TYPE,DISC-GRAN,DISC-MAX,MOUNTPOINT,FSTYPE | chroot /target awk '$1 == "part" && $2 != "0B" && $3 != "0B" && $4 ~ /^\/.*/ && $5 != "ext2" {print $4}' | chroot /target xargs >> /target/root/lsblk_raw ;\
        if [ -n "$(cat /target/root/lsblk_raw)" ]; then \
                echo -e '#!/bin/sh\nif [ ! -t 1 ]; then\n\t# Via cron\n\thd=$(hexdump -n 1 -e "/1 \"%u\"" /dev/urandom)\n\tstime=$((hd % 60))\n\tsleep ${stime}\nfi\n\n' > /target/etc/cron.daily/fstrim ;\
                echo "SSD_PARTS=\"$(cat /target/root/lsblk_raw)\"" >> /target/etc/cron.daily/fstrim ;\
                echo -e 'for part in ${SSD_PARTS} ; do\n\tfstrim ${part}\ndone\n' >> /target/etc/cron.daily/fstrim ;\
                chmod +x /target/etc/cron.daily/fstrim ;\
                sed -i -r 's/(^GRUB_CMDLINE_LINUX_DEFAULT=.*)("$)/\1 elevator=noop\2/' /target/etc/default/grub ;\
        elif grep -q QEMU /proc/cpuinfo || dmesg | grep -q VirtualBox ; then \
                sed -i -r 's/(^GRUB_CMDLINE_LINUX_DEFAULT=.*)("$)/\1 elevator=noop\2/' /target/etc/default/grub ;\
        fi ;\
        sed -i -r 's/(^GRUB_CMDLINE_LINUX_DEFAULT=.*)splash(.*"$)/\1\2/' /target/etc/default/grub ;\
        sed -i -r 's/(^GRUB_CMDLINE_LINUX_DEFAULT=.*)("$)/\1 fsck.repair=yes\2/' /target/etc/default/grub ;\
        in-target update-grub ;\
        if [ "($NAMESERVERS)" != "" ] && [ "($NAMESERVERS)" != "()" ]; then \
                nslist="($NAMESERVERS)" ;\
                sed -i -r "s/(^\sdns-nameservers).+/\1 ${nslist}/" /target/etc/network/interfaces ;\
    sed -i -r "s/#DNS=.*/DNS=${nslist}/" /target/etc/systemd/resolved.conf ;\
  else \
    nslist="($NAMESERVER)" ;\
    sed -i -r "s/#DNS=.*/DNS=${nslist}/" /target/etc/systemd/resolved.conf ;\
  fi ;\
        echo 'export HISTTIMEFORMAT="%h %d %H:%M:%S "' > /target/etc/profile.d/histtime.sh ;\
        if [ "($AFTER_INSTALL_SCRIPT_HTTPS)" != "" ] && [ "($AFTER_INSTALL_SCRIPT_HTTPS)" != "()" ]; then \
                export HTTP_PROXY="" ;\
                in-target wget -O /tmp/post.script --no-check-certificate "($AFTER_INSTALL_SCRIPT_HTTPS)" ;\
                chmod +x /target/tmp/post.script ;\
                in-target /tmp/post.script ;\
        fi ;\
        test -f /target/etc/default/ntpdate && sed -i -r 's/^(NTPOPTIONS=")(.*)"/\1\2 -u"/' /target/etc/default/ntpdate ;\
  if [ -d /sys/firmware/efi ]; then \
    if [ -f /tmp/first_efi_part ] && [ -f /tmp/second_efi_parts ] && [ -n "$(cat /tmp/first_efi_part)" ] && [ -n "$(cat /tmp/second_efi_parts)" ]; then \
      sync || : ;\
      cp /tmp/first_efi_part /tmp/second_efi-parts /target/root/ ;\
      orig_efi_part=$(cat /tmp/first_efi_part) ;\
      for efi_part in $(cat /tmp/second_efi_parts) ; do \
        umount ${orig_efi_part} ;\
        echo "dd if=${orig_efi_part} of=${efi_part}" >> /target/root/efi.log ;\
        dd if=${orig_efi_part} of=${efi_part} >> /target/root/efi.log 2>&1 ;\
        mount ${orig_efi_part} /target/boot/efi ;\
      done ;\
      blkid >> /target/root/efi.log ;\
      uuid=$(blkid ${orig_efi_part} | chroot /target awk '{print $2}') ;\
      echo "detected esp uuid=${uuid}" >> /target/root/efi.log ;\
      sed -i -r "/\/boot\/efi/s|${orig_efi_part}|${uuid}|" /target/etc/fstab >> /target/root/efi.log 2>&1 ;\
      efibootmgr >> /target/root/efi.log ;\
    fi ;\
    bindex=$(in-target --pass-stdout efibootmgr -v | grep BootCurrent | cut -d' ' -f2) 2>>/target/root/efi.log ;\
    corder=$(in-target --pass-stdout efibootmgr -v | grep BootOrder | cut -d' ' -f2 | sed "s/${bindex}//; s/\,\,/,/; s/(^\,|\,$)//;") 2>>/target/root/efi.log ;\
    echo "bindex=${bindex}" >> /target/root/efi.log ;\
    echo "corder=${corder}" >> /target/root/efi.log ;\
    in-target --pass-stdout efibootmgr -o ${bindex},${corder} >> /target/root/efi.log 2>&1 ;\
  fi ;\
        in-target wget -O /dev/null --no-check-certificate "($FINISHv4)"

# vim: expandtab ts=2
