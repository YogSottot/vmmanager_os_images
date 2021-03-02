debug() {

cat >> /opt/vars << EOF
NETWORK=${NETWORK}

PASS_CRYPT=($PASS_CRYPT)
PASS=($PASS)

ETHDEV=${ETHDEV}

MULTIIP=${MULTIIP}
IPv4=($IPv4)
IPv4ALIASES=($IPv4ALIASES)
NEXTHOPIPv4=($NEXTHOPIPv4)
VPU4=${VPU4}
NETMASK=($NETMASK)
NETMASKv4=($NETMASKv4) 

IP=($IP)
GATEWAY=${GATEWAY}
NAMESERVERS=($NAMESERVERS)

TMPIPv4=($TMPIPv4)

FINISH=($FINISH)

EOF


}

debug

# ubuntu 18.04
disk_format() {
        gdisk /dev/vda <<EOF
d
2
n
2




w
y
EOF
}

# centos 7
disk_format() {
        fdisk /dev/vda <<EOF
d
2
n
p
2


w
EOF
}
