#!/bin/bash

for s in $(cat "./new_project_config.json" | jq -r "to_entries|map(\"\(.key)=\(.value|tostring)\")|.[]" ); do
    export $s
done

echo "====== Création du projet ======"
sudo chown -R postgres:postgres /var/www/
chmod +x ./create_project.sh
dos2unix ./create_project.sh
su - postgres

echo "====== Création du projet Terminée ======"




echo "====== Configuration du Fichier environement ======"
cd $path_projet/docker/client/environments
new_url_backend="admin${db}.geo.sm"
new_url_frontend="${db}.geo.sm"
echo $new_url_backend
sed -i "s+url_backend+https://$new_url_backend+g" environment.ts
sed -i "s+urlFrontend+https://$new_url_frontend+g" environment.ts
echo "====== Nom de l'instance ======"
#read new_nom_instance
echo $nom_instance
sed -i "s/nomInstance/${nom_instance^^}/g" environment.ts
sed -i "s/langue/$lang/g" environment.ts

echo "====== Url du drapeau en png ======"
#read new_url_drapeau
sed -i "s+url_flag+$url_drapeau+g" environment.ts

echo "====== Code ISO du pays ======"
#read new_country_code
sed -i "s+code_country+$country_code+g" environment.ts

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
docker-compose up -d
docker  exec -i -t "${new_nom_container}"   /var/www/boot.sh

echo "====== Deploiement Terminé ======"ù

echo "====== Suppression des fichiers QGS ======"
cd /var/www/geosm/$db/
rm -r *.qgs
cd $path_projet/docker

echo "====== Création des couches ======"
docker exec -ti geosm_carto npm run initialiser_projet --projet=${db}
docker exec -ti geosm_carto npm run apply_style_projet --projet=${db}

echo "====== Création des couches Terminée ======"

echo "====== Configuration d'apache ======"
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
a2ensite
echo "====== Activation Backend ======"
a2ensite

echo "====== Activation des sites terminées ======"

echo "====== Activation du SSL ======"
sudo certbot --apache -d ${new_url_backend,,} -d ${new_url_frontend,,}

echo "====== SSL Activé ======"

echo "========== Mise à jour de la BD ==========="
curl https://api.geosm.org/api/v1/${nom_instance,,}/updateosm

echo "========= SUPPRESSION DU SHAPEFILE ========="
rm -r /var/www/backend_nodejs/shp/${db}

echo "====== Création de l'instance ${db} Terminée ======"
