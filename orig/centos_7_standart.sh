unsupported_hardware

%pre

#!/bin/sh

if [ "($NAMESERVERS)" != "" ] && [ "($NAMESERVERS)" != "()" ]; then
        nslist="($NAMESERVERS)"
        sed -i -r '/^nameserver\s/d' /etc/resolv.conf
        for ns in ${nslist}; do
                echo "nameserver ${ns}" >> /etc/resolv.conf
        done
fi

if [ -n "($HDD_RAID)" ] && [ "($HDD_RAID)" != "()" ]; then
        case "($HDD_RAID)" in
                raid_0)
                fname=raid0.sh
                ;;
                raid_1)
                fname=raid1.sh
                ;;
                raid_5)
                fname=raid5.sh
                ;;
                raid_10)
                fname=raid10.sh
                ;;
                no_raid)
                fname=noraid.sh
                ;;
                *)
                fname=partition.sh
                ;;
        esac
else
        fname=partition.sh
fi
curl -k -o /tmp/part.sh "($SHAREDIR_FILE)${fname}"
if [ -n "($DISK_LAYOUT_FILE)" ] && [ "($DISK_LAYOUT_FILE)" != "()" ]; then
   curl -k -o /tmp/diskpart.txt "($DISK_LAYOUT_FILE)"
   curl -k -o /tmp/part.sh "($SHAREDIR_FILE)custom.sh"
fi
sh /tmp/part.sh force

%end
auth --useshadow --enablemd5
# Crete partition map
bootloader --location=mbr --append="consoleblank=0 fsck.repair=yes"
zerombr
clearpart --all --initlabel
firstboot --disable
# Disk partitioning information
%include /tmp/part-include
# System keyboard
keyboard us
# System language
lang en_US.UTF-8
# Installation logging level
logging --level=info
# Use NFS installation media
url --url ($MIRROR)/7/os/x86_64/
# Additional updates repo
repo --name="CentOS-Updates" --baseurl=($MIRROR)/7/updates/x86_64/ --cost=100
#Root password
rootpw ($PASS)
# SELinux configuration
selinux --disabled
# Text installation
text
# System timezone
timezone --utc ($TIMEZONE)

# Network
network --bootproto=static --ip=($IPv4) --netmask=($NETMASK)  --gateway=($GATEWAYv4) --nameserver=($NAMESERVERv4) --hostname=($HOSTNAME) --device=link

# Install OS instead of upgrade
install
%packages
@core
ntp
ntpdate
wget
vim
psmisc
grubby
-NetworkManager
-NetworkManager-team
-NetworkManager-tui
-NetworkManager-libnm
%end

%post
HSHORT=$(echo "($HOSTNAME)" | cut -d. -f1)
HSLAST=$(echo "($HOSTNAME)" | sed "s/${HSHORT}\.//")
sed -r -i "s/search.*/search ${HSLAST}/" /etc/resolv.conf
grep -q "($HOSTNAME)" /etc/hosts || echo "($IP) ($HOSTNAME)" >> /etc/hosts
echo "options timeout:3 attempts:3" >> /etc/resolv.conf

# Настройка сети
#echo "NETWORKING=yes" > /etc/sysconfig/network
#echo "HOSTNAME=($HOSTNAME)"
ETHDEV=$(ip route show | grep default | grep -Eo 'dev\ .+\ ' | awk '{print $2}'| head -1)
HWADDR=$(cat /etc/sysconfig/network-scripts/ifcfg-${ETHDEV} | awk -F= '/HWADDR/ {print $2}' | sed 's/"//g')
UUID=$(cat /etc/sysconfig/network-scripts/ifcfg-${ETHDEV} | awk -F= '/UUID/ {print $2}' | sed 's/"//g')

if [ "($TMPIPv4)" != "" ] && [ "($TMPIPv4)" != "()" ]; then
        # Это новая схема, тут могут быть 2 ip адреса
        TMPIPv4="($TMPIPv4)"
        MULTIIP=true
else
        if [ -n "($IPv6)" ]; then
                TMPIPv4=true
        else
                TMPIPv4=false
        fi
        MULTIIP=false
fi

if [ "($NEXTHOPIPv4)" != "" ] && [ "($NEXTHOPIPv4)" != "()" ]; then
        VPU4=true
fi


if [ -n "($IPv6)" ]; then
        if [ "#${MULTIIP}" = "#false" ] || [ "#${TMPIPv4}" = "#true" ] && [ -z "${VPU4}" ]; then
                # либо старая схема, либо временный IPv4
                echo "NETWORKING=yes" > /etc/sysconfig/network
                echo "HOSTNAME=($HOSTNAME)" >> /etc/sysconfig/network

                cat > /etc/sysconfig/network-scripts/ifcfg-${ETHDEV} << EOF
DEVICE="${ETHDEV}"
BOOTPROTO="static"
DNS1="($NAMESERVERv6)"
HWADDR="${HWADDR}"
NM_CONTROLLED="no"
ONBOOT="yes"
TYPE="Ethernet"
UUID="${UUID}"
EOF
    fi

cat >> /etc/sysconfig/network << EOF
NETWORKING_IPV6=yes
IPV6_DEFAULTGW=($GATEWAYv6)
EOF

cat >> /etc/sysconfig/network-scripts/ifcfg-${ETHDEV} << EOF
IPV6ADDR="($IPv6)/($NETMASKv6)"
IPV6INIT="yes"
IPV6_AUTOCONF="no"
IPV6_DEFAULTGW="($GATEWAYv6)"
EOF

        if [ "($NEXTHOPIPv6)" != "" ] && [ "($NEXTHOPIPv6)" != "()" ]; then
                echo "SCOPE=\"peer ($NEXTHOPIPv6)\"" >> /etc/sysconfig/network-scripts/ifcfg-${ETHDEV}
                echo "ADDRESS0=0.0.0.0" > /etc/sysconfig/network-scripts/route-${ETHDEV}
                echo "NETMASK0=0.0.0.0" >> /etc/sysconfig/network-scripts/route-${ETHDEV}
                echo "GATEWAY0=($NEXTHOPIPv6)" >> /etc/sysconfig/network-scripts/route-${ETHDEV}
        fi
fi

if [ "($NEXTHOPIPv4)" != "" ] && [ "($NEXTHOPIPv4)" != "()" ] && [ "($IP)" != "($IPv6)" ]; then
        cat > /etc/sysconfig/network-scripts/ifcfg-${ETHDEV} << EOF
DEVICE="${ETHDEV}"
BOOTPROTO="static"
DNS1="($NAMESERVER)"
HWADDR="${HWADDR}"
NM_CONTROLLED="no"
ONBOOT="yes"
TYPE="Ethernet"
UUID="${UUID}"

IPADDR=($IP)
NETMASK=255.255.255.255
EOF

        echo "SCOPE=\"peer ($NEXTHOPIPv4)\"" >> /etc/sysconfig/network-scripts/ifcfg-${ETHDEV}
        echo "ADDRESS0=0.0.0.0" > /etc/sysconfig/network-scripts/route-${ETHDEV}
        echo "NETMASK0=0.0.0.0" >> /etc/sysconfig/network-scripts/route-${ETHDEV}
        echo "GATEWAY0=($NEXTHOPIPv4)" >> /etc/sysconfig/network-scripts/route-${ETHDEV}
fi

if [ "#${MULTIIP}" = "#true" ]; then
        if [ "($IPv4ALIASES)" != "" ] && [ "($IPv4ALIASES)" != "()" ]; then
                ipnum=1
                IPv4ALIASES="($IPv4ALIASES)"
                for ipv4alias in ${IPv4ALIASES}; do
                        echo "DEVICE=${ETHDEV}:${ipnum}" > /etc/sysconfig/network-scripts/ifcfg-${ETHDEV}:${ipnum}
                        echo "IPADDR=${ipv4alias}" >> /etc/sysconfig/network-scripts/ifcfg-${ETHDEV}:${ipnum}
                        echo "NETMASK=255.255.255.255" >> /etc/sysconfig/network-scripts/ifcfg-${ETHDEV}:${ipnum}
                        ipnum=$(expr ${ipnum} + 1)
                done
        fi
        if [ "($IPv6ALIASES)" != "" ] && [ "($IPv6ALIASES)" != "()" ]; then
                echo "IPV6ADDR_SECONDARIES=\"($IPv6ALIASES)\"" >> /etc/sysconfig/network-scripts/ifcfg-${ETHDEV}
        fi
fi
mkdir -p /root/.ssh
cat >> /root/.ssh/authorized_keys << EOF
($SSHPUBKEYS)
EOF

chkconfig --add ntp
sed -i -r 's/^(OPTIONS=")(.*)"/\1\2 -u"/' /etc/sysconfig/ntpdate
if [ ! "($HTTPPROXYv4)" = "()" ]; then
    # Стрипаем пробелы, если они есть
    PR=($HTTPPROXYv4)
    PR=$(echo ${PR} | sed "s/''//g" | sed 's/""//g')
    if [ -n "${PR}" ]; then
        echo "proxy=${PR}" >> /etc/yum.conf
        export http_proxy="${PR}"
        export HTTP_PROXY="${PR}"
    fi
fi
sed -i"ispbak" -r "s/^(mirrorlist=)/#\1/g; s/^#(baseurl=)/\1/g" /etc/yum.repos.d/*.repo
:
for file in /etc/yum.repos.d/*.repoispbak; do mv -f $file $(echo $file|sed 's/ispbak//'); done
sed -r -i "/proxy=/d" /etc/yum.conf
# SSD DISK begin
if [ -n "$(lsblk -io TYPE,DISC-GRAN,DISC-MAX,MOUNTPOINT | awk '$1 == "part" && $2 != "0B" && $3 != "0B" && $4 ~ /^\/.*/  {print $4}' | xargs)" ]; then
        SSD_PARTS="$(lsblk -io TYPE,DISC-GRAN,DISC-MAX,MOUNTPOINT | awk '$1 == "part" && $2 != "0B" && $3 != "0B" && $4 ~ /^\/.*/  {print $4}' | xargs)"

        # Creating cron task
        # start file
        echo '
#!/bin/sh

if [ ! -t 1 ]; then
        # Via cron
        hd=$(hexdump -n 1 -e "/1 \"%u\"" /dev/urandom)
        stime=$((hd % 60))
        sleep ${stime}
fi

SSD_PARTS=/
for part in ${SSD_PARTS} ; do
        fstrim ${part}
done

'> /etc/cron.daily/fstrim
        # end file

        chmod +x /etc/cron.daily/fstrim
        sed -i -r "s|^SSD_PARTS=.*|SSD_PARTS=\"${SSD_PARTS}\"|" /etc/cron.daily/fstrim

        # setting elevator in grub
        grubby --update-kernel=ALL --args="elevator=noop"
elif grep -q QEMU /proc/cpuinfo || dmesg | grep -q VirtualBox ; then
        # setting elevator in grub
        grubby --update-kernel=ALL --args="elevator=noop"
fi
# SSD DISK end

echo 'export HISTTIMEFORMAT="%h %d %H:%M:%S "' > /etc/profile.d/histtime.sh

# DNS start
if [ "($NAMESERVERS)" != "" ] && [ "($NAMESERVERS)" != "()" ]; then
        nslist="($NAMESERVERS)"
        sed -i -r '/DNS1=/d' /etc/sysconfig/network-scripts/ifcfg-${ETHDEV}
        num=0
        for ns in ${nslist}; do
                num=$((num + 1))
                echo "DNS${num}=${ns}" >> /etc/sysconfig/network-scripts/ifcfg-${ETHDEV}
        done
fi
# DNS end

if [ "($AFTER_INSTALL_SCRIPT_HTTPS)" != "" ] && [ "($AFTER_INSTALL_SCRIPT_HTTPS)" != "()" ]; then
        export HTTP_PROXY=""
        wget -O /tmp/post.script --no-check-certificate "($AFTER_INSTALL_SCRIPT_HTTPS)"
        chmod +x /tmp/post.script
        /tmp/post.script
fi
%end

%post --nochroot
cp /tmp/part-include /mnt/sysimage/root/

if [ -d /sys/firmware/efi ]; then
  if [ -f /tmp/efi_second_part ]; then

    copy_efi() {
      echo "make dd first efi part ( ${1} ) to second ( ${2} ) and other" >> /mnt/sysimage/root/ks.log
      umount ${1}
      umount ${2}
      dd if=${1} of=${2} >> /mnt/sysimage/root/ks.log 2>&1
      mount ${1} /mnt/sysimage/efi
      blkid >> /mnt/sysimage/root/ks.log
#      cp -r /mnt/sysimage/efi/ /nomount/
#       efibootmgr --create-only --disk /dev/sdb --label "CentOS Backup" --load "\\EFI\\redhat\\grub.efi" >> /mnt/sysimage/root/ks.log 2>&1
    }

#    parted $(cat /tmp/efi_second_part) set 1 boot on
    first_part=$(df -P /mnt/sysimage/boot/efi | awk '$1 ~ /dev/ {print $1}')
    second_part=$(df -P /mnt/sysimage/nomount | awk '$1 ~ /dev/ {print $1}')
    third_part=$(df -P /mnt/sysimage/nomount1 | awk '$1 ~ /dev/ {print $1}')
    fourth_part=$(df -P /mnt/sysimage/nomount2 | awk '$1 ~ /dev/ {print $1}')
    cp /tmp/efi_second_part /mnt/sysimage/root/
    efibootmgr -v >> /mnt/sysimage/root/ks.log
    blkid >> /mnt/sysimage/root/ks.log
    echo "==============" >> /mnt/sysimage/root/ks.log
    if [ -n "${second_part}" ] && [ -n "${first_part}" ]; then
      copy_efi ${first_part} ${second_part}
      if [ -n "${third_part}" ]; then
        copy_efi ${first_part} ${third_part}
      fi
      if [ -n "${fourth_part}" ]; then
        copy_efi ${first_part} ${third_part}
      fi
    fi
    efibootmgr -v >> /mnt/sysimage/root/ks.log
  fi
  if [ -d /mnt/sysimage/nomount ]; then
    umount /mnt/sysimage/nomount >> /mnt/sysimage/root/ks.log 2>&1 || :
    sed -i -r '/nomount/d' /mnt/sysimage/etc/fstab >> /mnt/sysimage/root/ks.log 2>&1
  fi
  if [ -d /mnt/sysimage/nomount1 ]; then
    umount /mnt/sysimage/nomount1 >> /mnt/sysimage/root/ks.log 2>&1 || :
  fi
  if [ -d /mnt/sysimage/nomount1 ]; then
    umount /mnt/sysimage/nomount2 >> /mnt/sysimage/root/ks.log 2>&1 || :
  fi
  rmdir /mnt/sysimage/nomount || :
  rmdir /mnt/sysimage/nomount1 || :
  rmdir /mnt/sysimage/nomount2 || :
  if [ -f /tmp/efi_booted ]; then
    bindex=$(cat  /tmp/efi_booted)
    echo "Currently booted from ${bindex}" >> /mnt/sysimage/root/ks.log
    corder=$(efibootmgr -v | grep BootOrder | awk '{print $2}'| sed "s/${bindex}//; s/\,\,/,/; s/(^\,|\,$)//;")
    echo "Changing boot order to ${bindex},${corder}" >> /mnt/sysimage/root/ks.log
    efibootmgr -o ${bindex},${corder} >> /mnt/sysimage/root/ks.log
  fi
fi


# https://bugs.centos.org/view.php?id=8460
if [ ! -f /tmp/without_swap ]; then
        if ! grep -q swap /mnt/sysimage/etc/fstab ; then
                echo -e "/dev/md1\tnone\tswap\tdefaults\t0 0" >> /mnt/sysimage/etc/fstab
        fi
fi

sed -i -r 's/installonly_limit=5/installonly_limit=2/' /mnt/sysimage/etc/yum.conf

export HTTP_PROXY=""
wget -O /dev/null --no-check-certificate "($FINISHv4)"
# Reboot after installation
%end

reboot
# vim: ts=2 noexpandtab
(END)
