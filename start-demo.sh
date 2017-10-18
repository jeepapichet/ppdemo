#!/bin/bash -e


main() {

  THISDOMAIN="cyberark.local"

  echo "-----"
  echo "Bring up Conjur and Puppet Master"
  echo "-----"
  docker-compose down
  docker-compose up -d conjur
  docker-compose up -d puppet
  docker-compose up -d cli

  PUPPET_CONT_ID=$(docker-compose ps -q puppet)
  CONJUR_CONT_ID=$(docker-compose ps -q conjur)
  CLI_CONT_ID=$(docker-compose ps -q cli)

  echo "-----"
  echo "Update local hosts file on this machine"
  updatehostsfile $CONJUR_CONT_ID
  updatehostsfile $PUPPET_CONT_ID
  updatehostsfile $CLI_CONT_ID

  echo "-----"
  echo "Initializing Conjur"
  runInConjur /src/conjur-init.sh

  echo "-----"
  echo "Get certificate from Conjur"
  rm -f /tmp/conjur.pem
  docker cp -L $CONJUR_CONT_ID:/opt/conjur/etc/ssl/conjur.pem /tmp/conjur.pem

  echo "-----"
  echo "Copy certificate to CLI"
  docker cp -L ./conjur.conf $CLI_CONT_ID:/etc/conjur.conf
  docker cp -L /tmp/conjur.pem $CLI_CONT_ID:/etc/conjur.pem

  echo "-----"
  echo "Load Policy and secret value"
  runIncli conjur authn login -u admin -p Cyberark1
  runIncli conjur bootstrap -q
  runIncli conjur policy load --as-group=security_admin /src/puppetdemo-policy.yml

  runIncli conjur variable values add puppetdemo/dbpassword 'Pxn83kPARx1LO3lfios2'
  runIncli conjur variable values add puppetdemo/secretkey '$e(re1Fr0mConjur'

  echo "-----"
  echo "Copy certificate to Puppet"
  docker cp -L /tmp/conjur.pem $PUPPET_CONT_ID:/etc/conjur.pem

  echo "-----"
  echo "Start demo webapp nodes"

  docker-compose up -d dev-webapp
  docker-compose up -d prod-webapp

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

  conthostname=`docker inspect --format '{{ .Config.Hostname }}' $containername` 
  contipaddress=`docker inspect --format '{{ .NetworkSettings.Networks.ppdemo_default.IPAddress }}' $containername`

  echo "---- Update hosts file for $conthostname"
  grep -v $conthostname $processfile > $tmpfile
  echo -e $contipaddress '\t' $conthostname '\t' $conthostname'.'$THISDOMAIN >> $tmpfile
  mv $tmpfile $processfile
}



main "$@"

