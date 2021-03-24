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
https="https://"
echo $new_url_backend
sed -i "s/'url_backend'/"'"'$https${new_url_backend,,}'"'"/g" environment.ts
sed -i "s/'url_frontend'/"'"'$https${new_url_frontend,,}'"'"/g" environment.ts
echo "====== Nom de l'instance ======"
read new_nom_instance
sed -i "s/'nomInstance'/"'"'${new_nom_instance^^}'"'"/g" environment.ts
sed -i "s/'langue'/"'"'${lang}'"'"/g" environment.ts

echo "====== Url du drapeau en png ======"
read new_url_drapeau
sed -i "s/'url_flag'/"'"'${new_url_drapeau}'"'"/g" environment.ts

echo "====== Configuration du Fichier environement Terminée ======"

echo "====== Configuration du Fichier Docker ======"
cd $path_projet/docker/
echo "====== Nom de l'instance docker ======"
read nom_instance_docker
sed -i 's/nom_instance/'${nom_instance_docker}'/g' "docker-compose.yml"
echo "====== Nom de l'image Docker à utiliser ======"
read nom_image_docker
sed -i 's/nom_image/'${nom_image_docker,,}'/g' "docker-compose.yml"
new_nom_container = "geosm_"${nom_image_docker,,}
sed -i 's/nom_container/'${new_nom_container}'/g' "docker-compose.yml"
echo "====== Nom du Port Backend ======"
read new_port_backend
sed -i 's/port_backend/'${new_port_backend}'/g' "docker-compose.yml"
echo "====== Nom du Port Frontend ======"
read new_port_frontend
sed -i 's/port_frontend/'${new_port_frontend}'/g' "docker-compose.yml"
echo "====== Configuration du Fichier Docker Terminée ======"

echo "====== Deploiement des images docker ======"
cd
chmod -R 777 $path_projet/docker
cd $path_projet/docker
docker-compose up -d
docker  exec -i -t "${new_nom_container}"   /var/www/boot.sh

echo "====== Deploiement Terminé ======"

echo "====== Création des couches ======"
docker exec -ti geosm_carto npm run initialiser_projet --projet=${db}
docker exec -ti geosm_carto npm run apply_style_projet --projet=${db}

echo "====== Création des couches Terminée ======"

echo "====== Configuration d'apache ======"
echo "====== Configuration Apache Frontend ======"
cp "/var/www/backend_nodejs/apache.txt" "/etc/apache2/sites-available/${new_url_frontend,,}.conf"
localhost="http://localhost:"
cd /etc/apache2/sites-available/
sed -i 's/server_name/'${new_url_frontend,,}'/g' "${new_url_frontend,,}.conf"
sed -i 's/port/'$localhost${new_port_frontend}'/g' "${new_url_frontend,,}.conf"
echo "====== Configuration Apache Frontend Terminée ======"

echo "====== Configuration Apache Backend ======"
cp "/var/www/backend_nodejs/apache.txt" "/etc/apache2/sites-available/${new_url_backend,,}.conf"
cd /etc/apache2/sites-available/

sed -i 's/server_name/'${new_url_backend,,}'/g' "${new_url_backend,,}.conf"
sed -i 's/port/'$localhost${new_port_backend}'/g' "${new_url_backend,,}.conf"
echo "====== Configuration Apache Backend Terminée ======"
echo "====== Activation Frontend ======"
a2ensite
echo "====== Activation Backend ======"
a2ensite

echo "====== Activation des sites terminées ======"

echo "====== Activation du SSL ======"
sudo certbot --apache -d ${new_url_backend,,} -d ${new_url_frontend,,}

echo "====== SSL Activé ======"



echo "====== Création de l'instance ${db} Terminée ======"
