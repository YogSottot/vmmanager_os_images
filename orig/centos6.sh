#!/bin/sh
 
clean_files() {
        rm -f /etc/ssh/*key*
        sed -r -i '/sh \/dev\/sda/d' /etc/rc.local
}


disk_format() {
        fdisk /dev/vda <<EOF
c
d
3
n
p
3


w
EOF
}
 
resize_fs() {
        cat >> /etc/init.d/resize_fs << EOF
#!/bin/bash
#
# Resize fs
#
### BEGIN INIT INFO
# Default-Start:        1 2 3 4 5
# Default-Stop:         0 6
# Required-Start:
# Required-Stop?
# Short-Description:    Resize root filesystem
# Description:          Resize root filesystem
# Provides:             resize_fs
### END INIT INFO
 
. /etc/init.d/functions
 
case "\$1" in
        start|reload)
                resize2fs /dev/root
                chkconfig --del resize_fs
                rm -f /etc/init.d/resize_fs
                exit 0
                ;;
        *)
                echo "service resize_fs start"
                exit 2
esac
 
EOF
chmod +x /etc/init.d/resize_fs
chkconfig --add resize_fs
}
 
network_configure() {
        IPv4=($IPv4)
        NETMASK=($NETMASKv4)
        GATEWAYv4=($GATEWAYv4)
        IPv6=($IPv6)
        PREFIX=($NETMASKv6)
        GATEWAYv6=($GATEWAYv6)
        HOSTNAME=($HOSTNAME)
 
        if [ -n "${GATEWAYv4}" ]; then
                GATEWAY=${GATEWAYv4}
        else
                GATEWAY=${GATEWAYv6}
        fi
 
        # Removing udev rules
        rm -f /etc/udev/rules.d/70-persistent-net.rules
 
 
        # Configuring network
        sed -r -i '/HOSTNAME=.+/d; /GATEWAY=.+/d' /etc/sysconfig/network
cat >> /etc/sysconfig/network << EOF
HOSTNAME=${HOSTNAME}
GATEWAY=${GATEWAY}
EOF
 
        ip link set eth1 name eth0
        HWADDR=$(ip link show eth0 | awk '/link\/ether/ {print $2}' | tr [:lower:] [:upper:])
 
        cat > /etc/sysconfig/network-scripts/ifcfg-eth0 << EOF
DEVICE="eth0"
BOOTPROTO="static"
DNS1="($NAMESERVER)"
HWADDR="${HWADDR}"
NM_CONTROLLED="yes"
ONBOOT="yes"
TYPE="Ethernet"
EOF
 
        if [ -n "${IPv4}" ]; then
                cat >> /etc/sysconfig/network-scripts/ifcfg-eth0 << EOF
GATEWAY="${GATEWAYv4}"
IPADDR="${IPv4}"
NETMASK="${NETMASK}"
EOF
 
        else
                cat >> /etc/sysconfig/network-scripts/ifcfg-eth0 << EOF
IPV6INIT="yes"
IPV6ADDR="${IPv6}/${PREFIX}"
IPV6_DEFAULTGW="${GATEWAYv6}"
EOF
 
        finetwork_configure
 
        ifup eth0
}
 
clean_files
disk_format
resize_fs
echo "($PASS)" | passwd --stdin root
network_configure
wget -q -O /dev/null --no-check-certificate "($FINISH)"
reboot