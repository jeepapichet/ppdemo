#!/bin/bash

####### Variables
PE_VERSION="2017.3.0"
IMAGE_NAME="registry.tld/puppet-enterprise:${PE_VERSION}"
ADMIN_PASSWORD="Cyberark1"
PUPPET_MASTER_HOSTNAME="puppet.cyberark.local"
PE_DOWNLOAD_LINK="LINK_TO_PE_DOWNLOAD"
TIMEZONE="Asia/Bangkok"
####### End Variables #######

apt-get update
apt-get install -y lsb-release wget

echo "${TIMEZONE}" > /etc/timezone && dpkg-reconfigure -f noninteractive tzdata

locale-gen en_US.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export LC_ALL=en_US.UTF-8

cd /root/puppet
. /etc/lsb-release
if [ ! -f puppet-enterprise-${PE_VERSION}-ubuntu-${DISTRIB_RELEASE}-amd64.tar.gz ]; then
  wget -O puppet-enterprise-${PE_VERSION}-ubuntu-${DISTRIB_RELEASE}-amd64.tar.gz ${PE_DOWNLOAD_LINK}
fi
tar zxf puppet-enterprise-${PE_VERSION}-ubuntu-${DISTRIB_RELEASE}-amd64.tar.gz
cd puppet-enterprise-${PE_VERSION}-ubuntu-${DISTRIB_RELEASE}-amd64

# Create a pe.conf file
cat > pe.conf <<'PECONF'
{
  "console_admin_password": "ADMIN_PASSWORD",
  "puppet_enterprise::puppet_master_host": "PUPPET_MASTER_HOSTNAME",
  "pe_install::puppet_master_dnsaltnames": [
    "puppet"
  ]
}
PECONF

# Configure pe.conf
sed -i "s/ADMIN_PASSWORD/${ADMIN_PASSWORD}/g" pe.conf && \
sed -i "s/PUPPET_MASTER_HOSTNAME/${PUPPET_MASTER_HOSTNAME}/g" pe.conf

./puppet-enterprise-installer -c pe.conf

# To complete the setup of this system
puppet agent -t


# Install CyberArk Conjur Module
puppet module install cyberark-conjur

# Create an ENTRYPOINT file
cat > /usr/local/bin/start-puppet-enterprise <<'ENTRYPOINT'
#!/bin/bash

# Turn on autosign
AUTOSIGN="${AUTOSIGN:-}"
if [[ -n "$AUTOSIGN" ]]; then
    echo "[ INFO ] * Turning on autosign..."
    puppet resource pe_file_line ensure=present line='autosign = true' path=/etc/puppetlabs/puppet/puppet.conf
    puppet config set autosign "$AUTOSIGN" --section master
fi

puppet resource service mcollective ensure=running enable=true
puppet resource service pxp-agent ensure=running enable=true
puppet resource service puppet ensure=running enable=true
puppet resource service pe-postgresql ensure=running enable=true
puppet resource service pe-activemq ensure=running enable=true
puppet resource service pe-puppetdb ensure=running enable=true
puppet resource service pe-nginx ensure=running enable=true
puppet resource service pe-puppetserver ensure=running enable=true
puppet resource service pe-orchestration-services ensure=running enable=true
puppet resource service pe-console-services ensure=running enable=true

####### </ Jeffery Bagirimvano >
ENTRYPOINT

# Change permissions
chmod +x /usr/local/bin/start-puppet-enterprise

# Doing a little clean up
cd /root/puppet
rm -fr puppet-enterprise-${PE_VERSION}-ubuntu-${DISTRIB_RELEASE}-amd64
