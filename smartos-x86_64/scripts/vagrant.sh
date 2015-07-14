#!/bin/bash

# Vagrant specific
date > /etc/vagrant_box_build_time

# Installing vagrant keys
echo "*************************************************************"
echo "Switching system into user modifiable state"

svcadm disable -s persist-gz-files

echo "*************************************************************"
echo "Creating vagrant group"
groupadd vagrant

echo "*************************************************************"
echo "Creating vagrant user"
useradd -d /usbkey/vagrant -m -s /bin/bash -G vagrant vagrant
usermod -P'Primary Administrator' vagrant


echo "*************************************************************"
echo "Setting password for Vagrant user."
vagrant_shadow=$(/usr/lib/cryptpass "vagrant")
sed -e "s|^vagrant:[^\:]*:|vagrant:${vagrant_shadow}:|" /etc/shadow > /tmp/shadow \
  && chmod 400 /tmp/shadow && cp /tmp/shadow /etc/shadow


echo "*************************************************************"
echo "Setting password for root  user."
root_shadow=$(/usr/lib/cryptpass "vagrant")
sed -e "s|^root:[^\:]*:|root:${root_shadow}:|" /etc/shadow > /tmp/shadow \
  && chmod 400 /tmp/shadow && cp /tmp/shadow /etc/shadow


echo "*************************************************************"
echo "Switching system back into non-user modifiable state"
svcadm enable -s persist-gz-files


echo "*************************************************************"
echo "Configuring profile for vagrant user"

echo 'if [ -e $HOME/.bashrc ]; then' > /usbkey/vagrant/.bash_profile
echo '  . $HOME/.bashrc' >> /usbkey/vagrant/.bash_profile
echo 'fi' >> /usbkey/vagrant/.bash_profile
echo 'export PATH=/usr/bin:/usr/sbin/:smartdc/bin:/opt/local/bin:/opt/local/sbin:/usbkey/vagrant/bin' >> /usbkey/vagrant/.bash_profile

chown vagrant:other /usbkey/vagrant/.bash_profile


echo "*************************************************************"
echo "Configuring ssh access for vagrant user"
mkdir -p /usbkey/vagrant/.ssh
echo "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== vagrant insecure public key" > /usbkey/vagrant/.ssh/authorized_keys
if [[ -z "$(grep "PermitUserEnvironment yes" /usbkey/ssh/sshd_config)" ]]; then
  echo "PermitUserEnvironment yes" >> /usbkey/ssh/sshd_config
fi
echo 'PATH=/usr/bin:/usr/sbin/:smartdc/bin:/opt/local/bin:/opt/local/sbin:/usbkey/vagrant/bin' > /usbkey/vagrant/.ssh/environment
chown -R vagrant:other /usbkey/vagrant/.ssh
chmod -R 0700 /usbkey/vagrant/.ssh

mkdir -p /usbkey/vagrant/bin
echo '#!/usr/bin/bash' > /usbkey/vagrant/bin/sudo
echo 'pfexec $@' >> /usbkey/vagrant/bin/sudo
chmod -R 0777 /usbkey/vagrant/bin