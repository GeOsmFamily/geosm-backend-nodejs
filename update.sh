#!/bin/bash

echo "====== Update GeOsm ======"
cd docker_geosm
docker build --no-cache  -t geosm .
echo "====== Mise à jour de GeOsm reussie ======"

update_docker () {
   echo "Hello World $1"
   cd /var/www/$1/docker
   docker-compose down
   docker-compose up -d
   docker  exec -i -t geosm_$1  /var/www/boot.sh

   echo "Le $1 a bien été mis à jour"
}

update_docker afs
update_docker bfa
update_docker civ
update_docker ethiopie
update_docker ghana
update_docker kenya
update_docker libye
update_docker madagascar
update_docker mali
update_docker maroc
update_docker nigeria
update_docker uganda
update_docker rdc
update_docker rwanda
update_docker senegal
update_docker tanzanie
update_docker togo
update_docker zambie
update_docker zimbabwe


