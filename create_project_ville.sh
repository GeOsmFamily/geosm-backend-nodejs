#!/bin/bash

for s in $(cat "./new_project_config.json" | jq -r "to_entries|map(\"\(.key)=\(.value|tostring)\")|.[]" ); do
    export $s
done

geosm_nodejs_dir='./'
list_projet='./projet.json'

echo "====== Création et initialisation de la BD ======"
psql -c "DROP DATABASE $db"
psql -c "CREATE DATABASE $db"
echo "db created"
psql -d  $db -c "CREATE EXTENSION postgis"
psql -d $db -c "CREATE EXTENSION hstore"
psql -d $db -c "CREATE EXTENSION unaccent"
#psql CREATE EXTENSION postgis_topology
echo "extention created"
if [ $lang == 'en' ]
    then 
        pg_restore -U postgres -d $db  ./BD/template_en_bd.backup --verbose
        echo "template english"
elif [ $lang == 'es' ]
    then
        pg_restore -U postgres -d $db  ./BD/template_es_bd.backup --verbose
        echo "template espagnol"
elif [ $lang == 'ville' ]
    then
        pg_restore -U postgres -d $db  ./BD/template_ville_bd.backup --verbose
        echo "template ville"
else
        pg_restore -U postgres -d $db  ./BD/template_fr_bd.backup --verbose
        echo "template french"
fi
wget $path_pbf -O osm.pbf
echo "====== Création et initialisation de la BD terminé ======"

echo "====== import termine et telechargement du osm.pbf ======"
osm2pgsql --cache 10000 --number-processes 5 --extra-attributes --slim -G -c -U postgres -d $db -H localhost -W --hstore-all -S ./BD/default.style osm.pbf
echo "====== import du osm.pbf termine ======"

colones=`psql -d $db  -c "select distinct(action) as key from sous_categorie"`

echo "====== CReation des index ======"

for col in $colones; do
    echo "Creation des index sur la colomne $col"
    psql -d $db  -c "CREATE INDEX planet_osm_point${col}_idx on planet_osm_point($col)"
    psql -d $db  -c "CREATE INDEX planet_osm_polygon${col}_idx on planet_osm_polygon($col)"
    psql -d $db  -c "CREATE INDEX planet_osm_line${col}_idx on planet_osm_line($col)"
done

echo "====== creation des index sur les colomnes terminées ======"


echo "====== IMPORT DE LA ZONE D'INTERET ======"

psql -d $db -c "DROP TABLE IF EXISTS temp_table;"
ogr2ogr -f "PostgreSQL" PG:"host=localhost user=$user_bd dbname=$db password=$pass_bd"  $roi -nln temp_table -nlt MULTIPOLYGON  -lco GEOMETRY_NAME=geom -lco precision=NO
psql -d $db -c "UPDATE instances_gc SET geom = ST_Buffer(st_transform(limite.geom ,4326)::geography,10)::geometry, true_geom = st_transform(limite.geom,4326) FROM (SELECT * from temp_table limit 1) as limite WHERE instances_gc.id = 1;"
psql -d $db -c "TRUNCATE temp_table;"


echo "====== IMPORT DE LA ZONE D'INTERET TERMINE ======"

echo "====== CREATION DES REPERTOIRE POUR QGIS SERVEUR (GPKG,STYLE) ======"

mkdir -m 777 -p $geosm_dir$db/gpkg/
mkdir -m 777 -p $geosm_dir$db/style/
mkdir -m 777 -p $geosm_dir/style/

echo "====== CREATION DES REPERTOIRES POUR QGIS SERVEUR TERMINE ======"

echo "====== TELECHARGEMENT DES STYLES PAR DEFAUT DE GEOSM ======"

rm -rf  ./backend_nodejs_temp
git clone https://github.com/GeOsmFamily/geosm-backend-nodejs.git/ ./backend_nodejs_temp
cp ./backend_nodejs_temp/python_script/style_default/*.qml $geosm_dir$db/style/
rm -rf  ./backend_nodejs_temp

echo "====== TELECHARGEMENT DES STYLES PAR DEFAUT DE GEOSM TERMINE ======"

echo "====== Telechargements des elements pour DOCKER ======"

rm -r $path_projet/docker/
mkdir -m 777 -p $path_projet/docker/
cp -r  $geosm_nodejs_dir/docker/ $path_projet/

mkdir -m 777 -p $path_projet/docker/public/upload
mkdir -m 777 -p $path_projet/docker/public/assets/images
mkdir -m 777 -p $path_projet/docker/public/assets/admin/images

mkdir -m 777 -p $path_projet/docker/client/

rm -rf  ./GeoOSM_Backend
git clone -b v8 https://github.com/GeOsmFamily/geosm-backend.git ./GeoOSM_Backend
mv ./GeoOSM_Backend/.env.example $path_projet/docker/public/.env.example
mv ./GeoOSM_Backend/public/assets/config_template.js $path_projet/docker/public/assets/config_template.js
mv ./GeoOSM_Backend/public/assets/images $path_projet/docker/public/assets/
mv ./GeoOSM_Backend/public/assets/admin/images $path_projet/docker/public/assets/admin/
rm -rf  ./GeoOSM_Backend

rm -rf  ./GeoOSM_Frontend
git clone https://github.com/GeOsmFamily/geoportail-frontend-final.git ./GeoOSM_Frontend
mv ./GeoOSM_Frontend/src/assets/ $path_projet/docker/client/
mv ./GeoOSM_Frontend/src/environments/ $path_projet/docker/client/environments/
cp $path_projet/docker/client/environments/environment-example.ts $path_projet/docker/client/environments/environment.prod.ts
sed -i "s+'path_qgis_value'+"'"'${geosm_dir}'"'"+g" $path_projet/docker/client/environments/environment.prod.ts
sed -i "s/'pojet_nodejs_value'/"'"'${db}'"'"/g" $path_projet/docker/client/environments/environment.prod.ts
cp $path_projet/docker/client/environments/environment.prod.ts $path_projet/docker/client/environments/environment.ts
chmod -R 755 $path_projet/docker/
rm -rf  ./GeoOSM_Frontend

cp $geosm_nodejs_dir/docker/htaccess.txt $path_projet/docker/client/htaccess.txt

echo "Creation du GeoJSON"

ogr2ogr -t_srs EPSG:4326 -f GeoJSON $path_projet/docker/client/assets/country.geojson $roi

echo "=========== CREATION DU GEOJSON TERMINEE ==============="

echo "====== Telechargements des elements pour DOCKER TERMINE======"

echo "====== CONFIGURATION DES FICHIERS DE CONFIG DE NODE JS ET LARAVEL ======"

jq --arg path_backend $path_projet"/docker/" --arg db $db --arg user_bd $user_bd --arg pass_bd $pass_bd --arg port_bd $port_bd --arg destination_style $geosm_dir$db/style/ --arg destination $geosm_dir$db/gpkg/ '.projet[$db] = {"destination_style":$destination_style,"destination":$destination,"database":$db,"user":$user_bd,"password":$pass_bd,"port":$port_bd,"path_backend":$path_backend}'  ${list_projet} |sponge  ${list_projet}

echo "Fichier de configuration pour NODE js crée"

cp $path_projet"/docker/public/assets/config_template.js" $path_projet"/docker/public/assets/config.js" 

jq -n  --arg rootApp "/var/www/GeoOSM_Backend/" --arg urlNodejs $urlNodejs_backend"importation" --arg urlNodejs_backend $urlNodejs_backend --arg urlBackend "https://admin"$db".geo.sm/" --arg projet_qgis_server $db '{"rootApp":$rootApp,"urlNodejs":$urlNodejs,"urlNodejs_backend":$urlNodejs_backend,"urlBackend":$urlBackend,"projet_qgis_server":$projet_qgis_server}' > $path_projet"/docker/public/assets/config.js"

sed  -i '1i var config_projet =' $path_projet"/docker/public/assets/config.js"

cp $path_projet"/docker/public/.env.example" $path_projet"/docker/public/.env"
sed -i 's/database_username/'${user_bd}'/g' $path_projet"/docker/public/.env"
sed -i 's/database_password/'${pass_bd}'/g' $path_projet"/docker/public/.env"
sed -i 's/database_name/'${db}'/g' $path_projet"/docker/public/.env"

echo "Fichier de configuration pour laravel crée"
echo "====== CONFIGURATION DES FICHIERS DE CONFIG DE NODE JS ET LARAVEL TERMINE ======"







echo "termne !!!!! !!! !"
exit




