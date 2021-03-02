#!/bin/bash
 
clean_files() {
        # remove old ssh-keys
        rm -f /etc/ssh/*key*
        # generate new ssh keys
        export DEBIAN_FRONTEND=noninteractive
        dpkg-reconfigure openssh-server
        # delete this script
        sed -r -i '/bash \/dev\/sda/d' /etc/rc.local
        # disable starting of rc.local
        chmod -x /etc/rc.local
}
 
 
disk_format() {
        #sgdisk --delete=2  /dev/vda
        #sgdisk --largest-new=2 /dev/vda
        #partprobe /dev/vda
        growpart /dev/vda 2 -u auto
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
                resize2fs /dev/vda2
                update-rc.d -f resize_fs remove
                rm -f /etc/init.d/resize_fs
                exit 0
                ;;
        *)
                echo "service resize_fs start"
                exit 2
esac
 
EOF

chmod +x /etc/init.d/resize_fs
update-rc.d resize_fs defaults

}
 
network_configure() {
        echo "" > /etc/network/interfaces
        IPv4=($IPv4)
        NETMASK=($NETMASKv4)
        GATEWAYv4=($GATEWAYv4)
        IPv6=($IPv6)
        PREFIX=($NETMASKv6)
        GATEWAYv6=($GATEWAYv6)
        HOSTNAME=($HOSTNAME)

        HSHORT=$(echo "($HOSTNAME)" | cut -d. -f1)
        HSLAST=$(echo "($HOSTNAME)" | sed "s/${HSHORT}\.//")
        echo "${HSHORT}" > /etc/hostname
        sed -r -i "s/search.*/search ${HSLAST}/" /run/systemd/resolve/resolv.conf
        sed -r -i "s/search.*/search ${HSLAST}/" /run/systemd/resolve/stub-resolv.conf
        sed -i -r "s/Domains=.*/Domains=${HSLAST}/" /etc/systemd/resolved.conf

cat <<EOF > /etc/hosts
127.0.0.1       localhost

# The following lines are desirable for IPv6 capable hosts
::1     localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
EOF
        grep -q "($HOSTNAME)" /etc/hosts || echo "($IP) ($HOSTNAME) ${HSHORT}" >> /etc/hosts

 
        if [ -n "${GATEWAYv4}" ]; then
                GATEWAY=${GATEWAYv4}
        else
                GATEWAY=${GATEWAYv6}
        fi


        ETHDEV=$(ip route show | grep default | grep -Eo 'dev\ .+\ ' | awk '{print $2}'| head -1)
        HWADDR=$(ip link show ${ETHDEV} | awk '/link\/ether/ {print $2}' | tr [:lower:] [:upper:])
        UUID=$(uuidgen ${ETHDEV})

        if [ "($TMPIPv4)" != "" ] && [ "($TMPIPv4)" != "()" ]; then
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
                        echo "nameserver ($NAMESERVERv6)" > /etc/resolv.conf
                        echo "nameserver ($NAMESERVERv6)" > /etc/resolvconf/resolv.conf.d/original
                        sed -i "s/($IPv4)/($IPv6)/" /etc/hosts
                        sed -i "s/($IPv4)/($IPv6)/" /etc/hosts
                        echo "# The loopback network interface" > /etc/network/interfaces
                        echo "auto lo" >> /etc/network/interfaces
                        echo "iface lo inet loopback" >> /etc/network/interfaces
                        echo "" >> /etc/network/interfaces
                        echo "# The primary network interface" >> /etc/network/interfaces
                        echo "auto ${ETHDEV}" >> /etc/network/interfaces
                        echo "allow-hotplug ${ETHDEV}" >> /etc/network/interfaces
                fi
                echo "" >> /etc/network/interfaces
                echo "iface ${ETHDEV} inet6 static" >> /etc/network/interfaces
                echo -e "\taddress ($IPv6)" >> /etc/network/interfaces
                echo -e "\tnetmask ($NETMASKv6)" >> /etc/network/interfaces
                echo -e "\tgateway ($GATEWAYv6)" >> /etc/network/interfaces
                if [ "($NEXTHOPIPv6)" != "" ] && [ "($NEXTHOPIPv6)" != "()" ]; then
                        echo -e "pointopoint ($NEXTHOPIPv6)" >> /etc/network/interfaces
                fi
                if [ -n "($NAMESERVERv6)" ]; then
                        echo -e "\tdns-nameservers ($NAMESERVERv6)" >> /etc/network/interfaces
                fi
                if [ "($IPv6ALIASES)" != "" ] && [ "($IPv6ALIASES)" != "()" ]; then
                        ipnum=1
                        IPv6ALIASES="($IPv6ALIASES)"
                        for ipv6alias in ${IPv6ALIASES}; do \
                                echo -e "\tup ip -6 addr add ${ipv6alias} dev ${ETHDEV}" >> /etc/network/interfaces
                                echo -e "\tdown ip -6 addr del ${ipv6alias} dev ${ETHDEV}" >> /etc/network/interfaces
                        done
                fi
        fi
        if [ "($NEXTHOPIPv4)" != "" ] && [ "($NEXTHOPIPv4)" != "()" ] && [ "($IP)" != "($IPv6)" ]; then
                echo "# The loopback network interface" > /etc/network/interfaces
                echo "auto lo" >> /etc/network/interfaces
                echo "iface lo inet loopback" >> /etc/network/interfaces
                echo "" >> /etc/network/interfaces
                echo "# The primary network interface" >> /etc/network/interfaces
                echo "auto ${ETHDEV}" >> /etc/network/interfaces
                echo "allow-hotplug ${ETHDEV}" >> /etc/network/interfaces
                echo "iface ${ETHDEV} inet static" >> /etc/network/interfaces
                echo -e "\taddress ($IP)" >> /etc/network/interfaces
                echo -e "\tnetmask 255.255.255.255" >> /etc/network/interfaces
                echo -e "\tgateway ($NEXTHOPIPv4)" >> /etc/network/interfaces
                echo -e "\tpointopoint ($NEXTHOPIPv4)" >> /etc/network/interfaces
                echo -e "\tdns-nameservers ($NAMESERVERv4)" >> /etc/network/interfaces
                echo -e "\tdns-search ${HSLAST}" >> /etc/network/interfaces
        fi

        if [ "($IP)" != "($IPv6)" ]; then
        cat > /etc/network/interfaces << EOF
# The primary network interface
auto ${ETHDEV}
iface ${ETHDEV} inet static
        address ($IP)/24
        gateway ${GATEWAY}
        # dns-* options are implemented by the resolvconf package, if installed
        dns-nameservers ($NAMESERVERS)
        dns-search ${HSLAST}
EOF
        fi

        if [ "${MULTIIP}" = "true" ]; then \
                if [ "($IPv4ALIASES)" != "" ] && [ "($IPv4ALIASES)" != "()" ]; then
                        ipnum=1
                        IPv4ALIASES="($IPv4ALIASES)"
                        for ipv4alias in ${IPv4ALIASES}; do
                                echo "" >> /etc/network/interfaces
                                echo "auto ${ETHDEV}:${ipnum}" >> /etc/network/interfaces
                                echo "allow-hotplug ${ETHDEV}:${ipnum}" >> /etc/network/interfaces
                                echo "iface ${ETHDEV}:${ipnum} inet static" >> /etc/network/interfaces
                                echo -e "\taddress ${ipv4alias}" >> /etc/network/interfaces
                                echo -e "\tnetmask 255.255.255.255" >> /etc/network/interfaces
                                ipnum=$(expr ${ipnum} + 1)
                        done
                fi
        fi



        test -f /usr/lib/finish-install.d/55netcfg-copy-config && sed -i '1a exit 0' /usr/lib/finish-install.d/55netcfg-copy-config
        sed -i "s/dns-search.*/dns-search ${HSLAST}/" /etc/network/interfaces


        #if [ "($NAMESERVERS)" != "" ] && [ "($NAMESERVERS)" != "()" ]; then
        #nslist="($NAMESERVERS)"
        #sed -i -r '/^nameserver\s/d' /run/systemd/resolve/resolv.conf
        #for ns in ${nslist}; do
        #        echo "nameserver ${ns}" >> /run/systemd/resolve/resolv.conf
        #done
        #fi

# restart network
systemctl restart networking

# edit /etc/networks
NETWORK=$(echo ($IP) | sed 's/[^.]*$/0/')
sed -i -r "s/localnet.*/localnet ${NETWORK}/" /etc/networks

}

ssh_keys_add() {
cat >> /root/.ssh/authorized_keys << EOF
($SSHPUBKEYS)
EOF
}

clean_files
disk_format
resize_fs
network_configure
ssh_keys_add
chpasswd <<<"root:($PASS)"
wget -q -O /dev/null --no-check-certificate "($FINISH)"
reboot
