#!/bin/bash

for s in $(cat "./update_project.json" | jq -r "to_entries|map(\"\(.key)=\(.value|tostring)\")|.[]" ); do
    export $s
done

geosm_nodejs_dir='./'
list_projet='./projet.json'

echo "====== Mise à jour de la BD ======"

if [ $lang == 'en' ]
    then 
        pg_restore -U postgres -d $db  ./BD/template_en_bd.backup --verbose
        echo "template english"
elif [ $lang == 'ville' ]
    then
        pg_restore -U postgres -d $db  ./BD/template_ville_bd.backup --verbose
        echo "template ville"
else
        pg_restore -U postgres -d $db  ./BD/template_bd.backup --verbose
        echo "template french"
fi


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
git clone https://github.com/GeOsmFamily/geosm-frontend-final.git ./GeoOSM_Frontend
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


echo "====== Configuration du Fichier environement ======"
cd $path_projet/docker/client/environments
new_url_backend="admin${db}.geo.sm"
new_url_frontend="${db}.geo.sm"
echo $new_url_backend
sed -i "s+url_backend+https://$new_url_backend+g" environment.prod.ts
sed -i "s+urlFrontend+https://$new_url_frontend+g" environment.prod.ts
echo "====== Nom de l'instance ======"
#read new_nom_instance
echo $nom_instance
sed -i "s/nomInstance/${nom_instance^^}/g" environment.prod.ts
sed -i "s/langue/$lang/g" environment.prod.ts

echo "====== Code ISO du pays ======"
#read new_country_code
sed -i "s+code_country+$country_code+g" environment.prod.ts
cp $path_projet/docker/client/environments/environment.prod.ts $path_projet/docker/client/environments/environment.ts
echo "====== Configuration du Fichier environement Terminée ======"

echo "====== Configuration du Fichier Docker ======"
cd $path_projet/docker/
echo "====== Nom de l'instance docker ======"
#read nom_instance_docker
sed -i "s/nom_instance/$nom_instance_docker/g" docker-compose.yml
echo "====== Nom de l'image Docker à utiliser ======"
#read nom_image_docker
sed -i "s/nom_image/${nom_image_docker,,}/g" docker-compose.yml
new_nom_container="geosm_${nom_instance_docker,,}"
cat docker-compose.yml
echo $new_nom_container
sed -i "s/nom_container/${new_nom_container,,}/g" docker-compose.yml
cat docker-compose.yml
echo "====== Nom du Port Backend ======"
#read new_port_backend
sed -i "s/port_backend/$port_backend/g" docker-compose.yml
echo "====== Nom du Port Frontend ======"
#read new_port_frontend
sed -i "s/port_frontend/$port_frontend/g" docker-compose.yml
echo "====== Configuration du Fichier Docker Terminée ======"

echo "====== Deploiement des images docker ======"
cd
chmod -R 777 $path_projet/docker
cd $path_projet/docker
docker-compose down
docker-compose up -d
docker  exec -i -t "${new_nom_container}"   /var/www/boot.sh

echo "====== Deploiement Terminé ======"

#echo "====== Suppression des fichiers QGS ======"
#cd /var/www/geosm/$db/
#rm -r *.qgs
#cd $path_projet/docker

echo "====== Configuration d'apache ======"

echo "====== Desactivation Frontend ======"
a2dissite ${new_url_frontend,,}
echo "====== Desactivation Backend ======"
a2dissite ${new_url_backend,,}

echo "====== Configuration Apache Frontend ======"
cp "/var/www/backend_nodejs/apache.txt" "/etc/apache2/sites-available/${new_url_frontend,,}.conf"
localhost="http://localhost"
cd /etc/apache2/sites-available/
sed -i "s/server_name/${new_url_frontend,,}/g" "${new_url_frontend,,}.conf"
sed -i "s+port/+$localhost:$port_frontend/+g" "${new_url_frontend,,}.conf"
echo "====== Configuration Apache Frontend Terminée ======"

echo "====== Configuration Apache Backend ======"
cp "/var/www/backend_nodejs/apache.txt" "/etc/apache2/sites-available/${new_url_backend,,}.conf"
cd /etc/apache2/sites-available/
sed -i "s/server_name/${new_url_backend,,}/g" "${new_url_backend,,}.conf"
sed -i "s+port/+$localhost:$port_backend/+g" "${new_url_backend,,}.conf"
echo "====== Configuration Apache Backend Terminée ======"

echo "====== Activation Frontend ======"
a2ensite ${new_url_frontend,,}
echo "====== Activation Backend ======"
a2ensite ${new_url_backend,,}

apachectl configtest
service apache2 restart

echo "====== Activation des sites terminées ======"

echo "======Installation du SSL ======="
sudo certbot --apache -d ${new_url_frontend,,} -d ${new_url_backend,,} --redirect
echo "======Installation du SSL Terminée ======="

echo "========== Mise à jour de la BD ==========="
curl https://api.geo.sm/api/v1/${nom_instance,,}/updateosm

echo "========= SUPPRESSION DU SHAPEFILE ========="
rm -r /var/www/backend_nodejs/shp/${db}

echo "====== Mise à jour de l'instance ${db} Terminée ======"






