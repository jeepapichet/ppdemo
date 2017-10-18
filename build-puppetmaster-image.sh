#!/bin/bash

####### Variables
PE_VERSION="2017.3.0"
IMAGE_NAME="my-puppet-enterprise:${PE_VERSION}"
PUPPET_MASTER_HOSTNAME="puppet.cyberark.local"
####### End Variables #######

# Make sure we have the latest version of ubuntu:14.04
#docker pull ubuntu:14.04

#Clean up old conatiner if exists
docker rm -f create-puppet-image

echo "step 1: Start Ubuntu container"
# Start a docker container that we're going to use
docker run -d -it --name create-puppet-image -h ${PUPPET_MASTER_HOSTNAME} -v $(pwd)/puppet-enterprise:/root/puppet:z ubuntu:14.04

echo "step 2: Install Puppet"
# Start the install in the container
docker exec -it create-puppet-image /root/puppet/install-puppet-in-docker.sh

echo "step 3: Stop image and commit to repository"

# Create our puppet enterprise image
docker stop create-puppet-image

docker commit \
-c 'EXPOSE 443' \
-c 'EXPOSE 8140' \
-c 'EXPOSE 8142' \
-c 'EXPOSE 61613' \
--change='CMD /usr/local/bin/start-puppet-enterprise && echo Started Puppet Enterprise && tail -f /var/log/puppetlabs/console-services/console-services*' \
create-puppet-image  ${IMAGE_NAME}

echo "step 4: Clean up image"
docker rm create-puppet-image
