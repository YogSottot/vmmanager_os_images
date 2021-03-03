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

# Подключаем файлы в /nfsshare/ к гиту
```bash
cd /opt/
git clone https://github.com/YogSottot/vmmanager_os_images/
```

```bash
# Создаём hook
cat .git/hooks/post-merge
#!/bin/sh

ln -f $GIT_DIR/../IMG_CentOS-7-amd64_ext4/metainfo.xml /nfsshare/IMG_CentOS-7-amd64_ext4/
ln -f $GIT_DIR/../IMG_CentOS-7-amd64_ext4/install.sh /nfsshare/IMG_CentOS-7-amd64_ext4/

ln -f $GIT_DIR/../IMG_Ubuntu-18.04-amd64/metainfo.xml /nfsshare/IMG_Ubuntu-18.04-amd64/
ln -f $GIT_DIR/../IMG_Ubuntu-18.04-amd64/install.sh /nfsshare/IMG_Ubuntu-18.04-amd64/

ln -f $GIT_DIR/../IMG_Ubuntu-20.04-amd64/metainfo.xml /nfsshare/IMG_Ubuntu-20.04-amd64/
ln -f $GIT_DIR/../IMG_Ubuntu-20.04-amd64/install.sh /nfsshare/IMG_Ubuntu-20.04-amd64/

ln -f $GIT_DIR/../IMG_Debian-10-amd64/metainfo.xml /nfsshare/IMG_Debian-10-amd64/
ln -f $GIT_DIR/../IMG_Debian-10-amd64/install.sh /nfsshare/IMG_Debian-10-amd64/
```

```bash
chmod +x .git/hooks/post-merge
```
