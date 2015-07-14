#!/bin/bash

# Bail if we are not running inside VMWare.
if [[ ! $(/usr/sbin/prtdiag) =~ "VMware" ]]; then
    exit 0
fi

# Install the VMWare Tools from a solaris ISO.

#wget http://192.168.0.185/solaris.iso -P /tmp
mkdir -p /mnt/vmware
mount -o loop /home/vagrant/solaris.iso /mnt/vmware

cd /tmp
tar xzf /mnt/vmware/VMwareTools-*.tar.gz

umount /mnt/vmware
rm -fr /home/vagrant/solaris.iso

/tmp/vmware-tools-distrib/vmware-install.pl -d
rm -fr /tmp/vmware-tools-distrib