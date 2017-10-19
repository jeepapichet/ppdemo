#!/bin/bash

####### Variables
PE_VERSION="2017.3.1"
IMAGE_NAME="registry.tld/puppet-enterprise:${PE_VERSION}"
PUPPET_MASTER_HOSTNAME="puppet.cyberark.local"
####### End Variables #######

# Run/Test our image
docker rm -fv test-puppet-enterprise
docker run -d \
-h ${PUPPET_MASTER_HOSTNAME} \
--name test-puppet-enterprise \
-e 'AUTOSIGN=true' \
-e 'TERM=xterm' \
-e 'TZ=Asia/Bangkok' \
-p 443:443 \
-p 8140:8140 \
-p 8142:8142 \
-p 61613:61613 \
${IMAGE_NAME}

# Check the logs
docker logs -f test-puppet-enterprise

