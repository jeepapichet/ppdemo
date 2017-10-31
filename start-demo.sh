#!/bin/bash -e


main() {

  THISDOMAIN="cyberark.local"
  PROJECTNAME="ppdemo"   #change this if project folder is not ppdemo

  echo "-----"
  echo "Bring down all running services"
  docker-compose down

  echo "-----"
  echo "Bring up Conjur and Puppet Master"
  docker-compose up -d conjur
  docker-compose up -d puppet
  docker-compose up -d cli

  PUPPET_CONT_ID=$(docker-compose ps -q puppet)
  CONJUR_CONT_ID=$(docker-compose ps -q conjur)
  CLI_CONT_ID=$(docker-compose ps -q cli)

  echo "-----"
  echo "Initializing Conjur"
  runInConjur /src/conjur-init.sh

  echo "-----"
  echo "Get certificate from Conjur"
  rm -f /tmp/conjur.pem
  docker cp -L $CONJUR_CONT_ID:/opt/conjur/etc/ssl/conjur.pem /tmp

  echo "-----"
  echo "Copy Conjur config and certificate to CLI"
  docker cp -L ./conjur.conf $CLI_CONT_ID:/etc/conjur.conf
  docker cp -L /tmp/conjur.pem $CLI_CONT_ID:/etc/conjur.pem

  echo "-----"
  echo "Load demo policy and sample secret value"
  runIncli conjur authn login -u admin -p Cyberark1
  runIncli conjur bootstrap -q
  runIncli conjur policy load --as-group=security_admin /src/puppetdemo-policy.yml

  runIncli conjur variable values add puppetdemo/dbpassword 'white rabbit'
  runIncli conjur variable values add puppetdemo/secretkey 'Se(re1Fr0mConjur'

  echo "-----"
  echo "Copy Conjur certificate to Puppet"
  docker cp -L /tmp/conjur.pem $PUPPET_CONT_ID:/etc/conjur.pem

  echo "-----"
  echo "Start demo webapp nodes"
  docker-compose up -d dev-webapp
  docker-compose up -d prod-webapp

  echo "-----"
  echo "Update dev-webapp and prod-webapp container IP to local hosts file"
  updatehostsfile $(docker-compose ps -q dev-webapp)
  updatehostsfile $(docker-compose ps -q prod-webapp)

}

runInConjur() {
  docker-compose exec -T conjur "$@"
}

runIncli() {
  docker-compose exec -T cli "$@"
}

runInPuppet() {
  docker-compose exec -T puppet "$@"
}

wait_for_conjur() {
  docker-compose exec -T conjur bash -c 'while ! curl -sI localhost > /dev/null; do sleep 1; done'
}

updatehostsfile() {

  local containername="$1"
  local processfile=/etc/hosts
  local tmpfile=/tmp/${1}.tmp
  local knownhostsfile=~/.ssh/known_hosts

  conthostname=`docker inspect --format '{{ .Config.Hostname }}' $containername` 
  contipaddress=`docker inspect --format '{{ .NetworkSettings.Networks.'"$PROJECTNAME"'_default.IPAddress }}' $containername`

  echo "---- Update hosts file for $conthostname"
  grep -v $conthostname $processfile > $tmpfile
  echo -e $contipaddress '\t' $conthostname '\t' $conthostname'.'$THISDOMAIN >> $tmpfile
  mv $tmpfile $processfile

  echo "---- Remove host from ssh knownhosts"
  ssh-keygen -R $conthostname || true
}

main "$@"

