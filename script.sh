#!/bin/bash


# CREATE 3 PARTITIONS ROOT BOOT AND SWAP
# SETUP WITH lsblk fdisk and cfdisk
# SET sdb1 AS BIOS BOOT         # BOOT
# mkfs -v -t ext4 /dev/sdb2     # ROOT
# mkswap /dev/sdb3              # SWAP


apt upgrade -y
apt install git -y
apt install bison -y
apt install gawk -y
apt install texinfo -y

rm -rf /bin/sh
ln -s /bin/bash /bin/sh

rm -rf /usr/bin/awk
ln -s /usr/bin/gawk /usr/bin/awk

rm -rf /usr/bin/yacc
ln -s /usr/bin/bison /usr/bin/yacc

echo "export LFS=/mnt/lfs; umask 022" >> /root/.bashrc

mkdir -pv $LFS
mount -v -t ext4 /dev/sdb3 $LFS
swapon -v /dev/sdb2 
chown root:root $LFS
chmod 755 $LFS

mkdir -v $LFS/sources
chmod -v a+wt $LFS/sources

wget --input-file=https://mirror.koddos.net/lfs/lfs-packages/12.3/ --continue --directory-prefix=$LFS/sources

pushd $LFS/sources
  md5sum -c md5sums
popd

chown root:root $LFS/sources/*

mkdir -pv $LFS/{etc,var} $LFS/usr/{bin,lib,sbin}

for i in bin lib sbin; do
  ln -sv usr/$i $LFS/$i
done

case $(uname -m) in
  x86_64) mkdir -pv $LFS/lib64 ;;
esac

mkdir -pv $LFS/tools

groupadd lfs
useradd -s /bin/bash -g lfs -m -k /dev/null lfs

echo "admin
admin" > passwd_lfs

cat passwd_lfs | passwd lfs

chown -v lfs $LFS/{usr{,/*},var,etc,tools}
case $(uname -m) in
  x86_64) chown -v lfs $LFS/lib64;;
esac

[ ! -e /etc/bash.bashrc ] || mv -v /etc/bash.bashrc /etc/bash.bashrc.NOUSE

######################################## su - lfs

su - lfs

cat > ~/.bash_profile << "EOF"
exec env -i HOME=$HOME TERM=$TERM PS1='\u:\w\$ ' /bin/bash
EOF

cat > ~/.bashrc << "EOF"
set +h
umask 022
LFS=/mnt/lfs
LC_ALL=POSIX
LFS_TGT=$(uname -m)-lfs-linux-gnu
PATH=/usr/bin
if [ ! -L /bin ]; then PATH=/bin:$PATH; fi
PATH=$LFS/tools/bin:$PATH
CONFIG_SITE=$LFS/usr/share/config.site
export LFS LC_ALL LFS_TGT PATH CONFIG_SITE
EOF

######################################### su

[ ! -e /etc/bash.bashrc ] || mv -v /etc/bash.bashrc /etc/bash.bashrc.NOUSE

cat >> ~/.bashrc << "EOF"
export MAKEFLAGS=-j$(nproc)
EOF

