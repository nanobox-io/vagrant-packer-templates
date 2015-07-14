#!/bin/bash
echo "*************************************************************"
echo "Updating system to allow user modification"

mkdir -p /opt/custom/smf
mkdir -p /opt/custom/method

cat <<END > /opt/custom/method/install-gz-files
#!/usr/bin/bash

userfiles=( /etc/passwd /etc/shadow /etc/group /etc/ouser_attr /etc/user_attr \
            /etc/security/policy.conf /etc/security/auth_attr \
            /etc/security/exec_attr /etc/security/prof_attr )

case "\$1" in
'start')
  if [[ -n \$(/bin/bootparams | grep '^smartos=true') ]]; then
    touch \${userfiles[@]}
    sleep 1
    for file in \${userfiles[*]}; do
      ukf=/usbkey/\$(basename \${file})
      test -e \$ukf && touch \$ukf
    done

    if [[ -e /usbkey/user_attr ]]; then
      cp /usbkey/user_attr /etc/user_attr
    fi

    HOSTNAME=\$(hostname)
    cat <<EOF >/etc/inet/hosts
::1 localhost
127.0.0.1 localhost loghost \${HOSTNAME} \${HOSTNAME}.localdomain
EOF
  fi
  ;;
esac
END

cat <<END > /opt/custom/smf/install-gz-files.xml
<?xml version='1.0'?>
<!DOCTYPE service_bundle SYSTEM '/usr/share/lib/xml/dtd/service_bundle.dtd.1'>
<service_bundle type='manifest' name='export'>
  <service name='site/install-gz-files' type='service' version='0'>
    <create_default_instance enabled='true'/>
    <single_instance/>
    <dependency name='fs-local' grouping='require_all' restart_on='error' type='service'>
      <service_fmri value='svc:/system/filesystem/local'/>
    </dependency>
    <dependency name='fs-root' grouping='require_all' restart_on='error' type='service'>
      <service_fmri value='svc:/system/filesystem/root'/>
    </dependency>
    <method_context/>
    <exec_method name='start' type='method' exec='/opt/custom/method/install-gz-files start' timeout_seconds='60'/>
    <exec_method name='stop' type='method' exec=':true' timeout_seconds='60'/>
    <property_group name='startd' type='framework'>
    <propval name='duration' type='astring' value='transient'/>
    <propval name='ignore_error' type='astring' value='core,signal'/>
    </property_group>
    <property_group name='application' type='application'/>
    <stability value='Evolving'/>
    <template>
      <common_name>
      <loctext xml:lang='C'>Ensure </loctext>
      </common_name>
    </template>
  </service>
</service_bundle>
END

cat <<END > /opt/custom/method/persist-gz-files
#!/usr/bin/bash

# See http://wiki.smartos.org/display/DOC/Persistent+Users+and+RBAC+in+the+Global+Zone

persistent_files=( /etc/passwd /etc/shadow /etc/group /etc/ouser_attr /etc/user_attr \
                   /etc/security/policy.conf /etc/security/auth_attr \
                   /etc/security/exec_attr /etc/security/prof_attr )

ukeystor="/usbkey"

case "\$1" in
'start')
  if [[ -n \$(/bin/bootparams | grep '^smartos=true') ]]; then
    for file in \${persistent_files[*]}; do
      ukf=\${ukeystor}/\$(basename \$file)
      if [[ -z \$(/usr/sbin/mount -p | grep \$file) ]]; then
        if [[ \$file -ot \$ukf ]]; then
          cp \$ukf \$file
          echo "stor->sys: \$file"
        else
          cp \$file \$ukf
          echo "sys->stor: \$file"
        fi
 
        touch \$file \$ukf
        mount -F lofs \$ukf \$file
      fi
    done
  fi
  ;;
'stop')
  for file in \${persistent_files[*]}; do
    if [[ -n \$(/usr/sbin/mount -p | grep \$file) ]]; then
      umount \$file && touch \$file
    fi
  done
  ;;
*)
  echo "Usage: \$0 { start | stop }"
  echo "  When disabled, users can be modified in the SmartOS global zone"
  echo "  When enabled, users can not be modified"
  exit 1
  ;;
esac
END

cat <<END > /opt/custom/smf/persist-gz-files.xml
<?xml version='1.0'?>
<!DOCTYPE service_bundle SYSTEM '/usr/share/lib/xml/dtd/service_bundle.dtd.1'>
<service_bundle type='manifest' name='export'>
  <service name='site/persist-gz-files' type='service' version='0'>
    <create_default_instance enabled='true'/>
    <single_instance/>
    <dependency name='filesystem' grouping='require_all' restart_on='error' type='service'>
      <service_fmri value='svc:/system/filesystem/local'/>
    </dependency>
    <dependency name='userfiles' grouping='require_all' restart_on='error' type='service'>
      <service_fmri value='svc:/site/install-gz-files'/>
    </dependency>
    <method_context/>
    <exec_method name='start' type='method' exec='/opt/custom/method/persist-gz-files start' timeout_seconds='60'/>
    <exec_method name='stop' type='method' exec='/opt/custom/method/persist-gz-files stop' timeout_seconds='60'/>
    <property_group name='startd' type='framework'>
      <propval name='duration' type='astring' value='transient'/>
      <propval name='ignore_error' type='astring' value='core,signal'/>
    </property_group>
    <property_group name='application' type='application'/>
    <stability value='Evolving'/>
    <template>
      <common_name>
      <loctext xml:lang='C'>Mount user and RBAC data from /usbkey</loctext>
      </common_name>
    </template>
  </service>
</service_bundle>
END

chmod 755 /opt/custom/method/install-gz-files
chmod 755 /opt/custom/method/persist-gz-files
svccfg import /opt/custom/smf/install-gz-files.xml
svccfg import /opt/custom/smf/persist-gz-files.xml

echo "*************************************************************"
echo "In order to use tools such as usermod, please do the following:"
echo "  svcadm disable -s persist-userfiles"
echo "  useradd ..."
echo "  svcadm enable -s persist-userfiles"
echo
echo
echo "*************************************************************"
