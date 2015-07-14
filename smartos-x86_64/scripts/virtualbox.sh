#!/bin/bash

# Bail if we are not running inside VirtualBox.
if [[ ! $(/usr/sbin/prtdiag) =~ "VirtualBox" ]]; then
    exit 0
fi

mkdir -p /mnt/virtualbox
dev=$(lofiadm -a /var/tmp/VBoxGuest*.iso)
mount -o ro -F hsfs ${dev} /mnt/virtualbox
mkdir /var/tmp/virtualbox
pkgtrans -o /mnt/virtualbox/VBoxSolarisAdditions.pkg /var/tmp/virtualbox all
mkdir /opt/virtualbox
cp /var/tmp/virtualbox/SUNWvboxguest/reloc/opt/VirtualBoxAdditions/amd64/vboxfs      /opt/virtualbox
cp /var/tmp/virtualbox/SUNWvboxguest/reloc/opt/VirtualBoxAdditions/amd64/vboxfsmount /opt/virtualbox
cp /var/tmp/virtualbox/SUNWvboxguest/reloc/usr/kernel/drv/amd64/vboxguest            /opt/virtualbox
cp /var/tmp/virtualbox/SUNWvboxguest/reloc/usr/kernel/drv/vboxguest.conf             /opt/virtualbox

mkdir -p /opt/custom/method
mkdir -p /opt/custom/smf

cat <<EOF > /opt/custom/method/virtualbox
#!/bin/sh

# copy files in place
cp /opt/virtualbox/vboxfs          /kernel/fs/amd64/
cp /opt/virtualbox/vboxguest       /kernel/drv/amd64/
cp /opt/virtualbox/vboxguest.conf  /kernel/drv/
cp /opt/virtualbox/vboxfsmount     /sbin

# enable kernel driver
add_drv -m '* 0666 root sys' -i 'pci80ee,cafe' vboxguest
devfsadm -i vboxguest
ln -fns /devices/pci@0,0/pci80ee,cafe@4:vboxguest /dev/vboxguest
modload /kernel/fs/amd64/vboxfs

# make mount work with vboxfs
mkdir -p /etc/fs/vboxfs
ln -s ../../../sbin/vboxfsmount /etc/fs/vboxfs/mount
EOF

chmod 755 /opt/custom/method/virtualbox

cat <<EOF > /opt/custom/smf/virtualbox.xml
<?xml version="1.0"?>
<!DOCTYPE service_bundle SYSTEM "/usr/share/lib/xml/dtd/service_bundle.dtd.1">
 
<service_bundle type='manifest' name='virtualbox'>
<service
        name='virtualbox/setup'
        type='service'
        version='1'>
 
        <create_default_instance enabled='true' />
 
        <single_instance />
 
        <dependency
                name='fs-joyent'
                grouping='require_all'
                restart_on='none'
                type='service'>
                <service_fmri value='svc:/system/filesystem/smartdc' />
        </dependency>
 
        <exec_method
                type='method'
                name='start'
                exec='/opt/custom/method/virtualbox'
                timeout_seconds='0'>
        </exec_method>
 
        <exec_method
                type='method'
                name='stop'
                exec=':true'
                timeout_seconds='0'>
        </exec_method>
 
        <property_group name='startd' type='framework'>
                <propval name='duration' type='astring' value='transient' />
        </property_group>
 
        <stability value='Unstable' />
 
</service>
</service_bundle>
EOF

### Clean Up ###
rm -rf /var/tmp/virtualbox
umount /mnt/virtualbox
lofiadm -d ${dev}
rm -rf /mnt/virtualbox
