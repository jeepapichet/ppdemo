#!/bin/bash -e

main() {

  THISDOMAIN="cyberark.local"

  echo "-----"
  echo "Stop and restart prod/dev webapp containers"

  # Start container using docker-compose
  docker-compose rm -sf prod-webapp
  docker-compose rm -sf dev-webapp

  docker-compose up -d prod-webapp
  docker-compose up -d dev-webapp

  updatehostsfile $(docker-compose ps -q dev-webapp)
  updatehostsfile $(docker-compose ps -q prod-webapp)

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

