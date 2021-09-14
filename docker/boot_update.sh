#!/bin/bash
host=$(/sbin/ip route|awk '/default/ { print $3 }')

cp "/var/www/GeoOSM_Backend/.env" "/var/www/GeoOSM_Backend/.env_temp"
sed -i 's/localhost/'${host}'/g' "/var/www/GeoOSM_Backend/.env_temp"
cp "/var/www/GeoOSM_Backend/.env_temp" "/var/www/GeoOSM_Backend/.env"

cd  /var/www/GeoOSM_Backend/ && php artisan migrate && php artisan refresh:database_osm
cd  /var/www/GeoOSM_Frontend/ && npx ng build
cp /var/www/GeoOSM_Frontend/htaccess.txt /var/www/GeoOSM_Frontend/dist/.htaccess
a2dissite 000-default.conf 
a2ensite vhost-admin.conf
a2ensite vhost-client.conf
service apache2 reload
chmod -R 777 /var/www/GeoOSM_Backend/

