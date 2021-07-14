# Projet Python + Node JS GeOsm

## Pré requis

Installer les pré-recquis de requiements.md

## Installation

Le bon fonctionnement de GeOsm nécessite le respect des étapes suivantes..

##### 1. Déploiement du projet Node JS

```sh
$ git clone https://github.com/GeOsmFamily/geosm-backend-nodejs.git/ ./backend_nodejs
$ cd ./backend_nodejs/docker_geom_carto
$ docker-compose build --no-cache
$ docker-compose up -d
$ docker  exec -i -t geosm_carto  /home/keopx/boot_geosm_carto.sh
```

##### 2. Modification du projet Node JS

Editer le fichier config.js

| variable        | valeur attendue                                                                               |
| --------------- | --------------------------------------------------------------------------------------------- |
| path_style_qml  | empty path where we will store temporarely style files                                        |
| url_qgis_server | url de votre QGIS server sous la forme : http://xxx.xxx.xxx/ows/?map=                         |
| url_node_js     | url que vous donnerez à ce projet dans la partie 3 ci dessous (**www.backend_nodejs.geoosm**) |

Le projet Node JS est prèt sur le port 8080 !

##### 3. Configurer Apache ou Nginx pour associer un nom de domaine au projet node js

On appellera ce nom de domaine par la suite **www.backend_nodejs.geoosm**

❌ NB : les fichiers projet.json et config.js ne doivent jamais ètre supprimés de ce dossier, même lors d'une mise à jour du dépot !

## Création des images DOCKER

```
$ cd /var/www/backend_nodejs/docker_geosm
$ docker build --no-cache  -t geosm .
```

## Créer une instance geosm

##### 1. Editer le fichier backend_nodejs/new_project_config.json :

| variable            | valeur attendue                                                                                                                           |
| ------------------- | ----------------------------------------------------------------------------------------------------------------------------------------- |
| roi                 | path of the shapefile with the limit of your region of interest (1 feature in EPSG 4326)                                                  |
| path_pbf            | link to the osm.pbf of your region of interest                                                                                            |
| urlNodejs_backend   | link of backend geosm (**www.backend_nodejs.geoosm**) already install in your computer                                                    |
| path_projet         | empty or not existing path where you want to deploy geosm in your computer                                                                |
| geosm_dir           | empty or not existing path where you want to store geopackages files for qgis server to read them; This path can take multiple projects ! |
| lang                | french or english                                                                                                                         |
| db                  | name of database                                                                                                                          |
| user_bd             | user of Database                                                                                                                          |
| pass_bd             | password of Database                                                                                                                      |
| port_bd             | port of Database                                                                                                                          |
| country_code        | code ISO du pays                                                                                                                          |
| nom_instance        | nom de l'instance                                                                                                                         |
| nom_instance_docker | nom de l'instance (généralement le nom du pays en minuscule)                                                                              |
| nom_image_docker    | nom de l'image docker à utiliser (par defaut geosm)                                                                                       |
| port_backend        | port du backend                                                                                                                           |
| port_frontend       | port du frontend                                                                                                                          |

##### 2. Créer le projet :

```sh
$ sudo chown -R postgres:postgres /var/www/
$ chmod +x ./install_geosm.sh
$ dos2unix ./install_geosm.sh
$ ./install_geosm.sh
$ cd /var/www/backend_nodejs
$ ./create_project.sh
$ exit

```

PS: -Remplir les ports et les noter quelque part afin d'éviter les erreurs docker plutard

- Le code ISO du pays à remplir est le code ISO 3166
- il faut creer les entrées dns du frontend et du backend chez l'hebergeur

## Créer une instance differente de geosm

- Tout d'abord il faut mettre a jour le Dockerfile de geosm avec le lien des nouveaux dépots et creer une nouvelle image:

```sh
$ cd /var/www/backend_nodejs/docker_geosm
$ nano Dockerfile
$ docker build --no-cache  -t "nom_de_l'image" .
```

- Modifier le fichier create_project.sh avec l'url des nouveaux dépots

```sh
$ cd /var/www/backend_nodejs/
$ nano create_project.sh
```

- Puis relancer les commandes de creations d'une instance de la section précédente

## Mettre à jour une instance avec BD existante

- Tout d'abord il faut configurer le fichier update_project.json avec les paramètres du projet à modifier

```sh
$ cd /var/www/backend_nodejs
$ nano update_project.json
$ sudo chown -R postgres:postgres /var/www/
$ su - postgres
$ cd /var/www/backend_nodejs
$ chmod +x ./update_project.sh
$ dos2unix ./update_project.sh
$ ./update_project.sh

```

## Pour mettre à jour la BD OSM

```sh
# mettre à jour la BD (https://github.com/Magellium/magOSM/tree/master/database)

$ osmosis --read-replication-interval-init workingDirectory=/var/www/geosm/<name of database of project>/up-to-date
$ osmium fileinfo -e --progress -v /var/www/backend_nodejs/osm.pbf
$ nano /var/www/geosm/<name of database of project>/up-to-date/state.txt
    timestamp=osmosis_replication_timestamp - 24h (Ex 2020-04-28T20:59:03Z - 24h = 2020-04-27T20:59:03Z)
	sequenceNumber=osmosis_replication_sequence_number (Ex 2595)
$ nano /var/www/geosm/<name of database of project>/up-to-date/configuration.txt (le fichier existe déja normalement, il a été crée par la première commande avec osmosis)
    baseUrl=osmosis_replication_base_url (EX http://download.geofabrik.de/europe/france-updates)
    maxInterval=jours en secondes ( Pour une semaine : 7 * 24 * 3600 = 604800)
$ mkdir /var/www/geosm/<name of database of project>/up-to-date
$ mkdir /var/www/geosm/<name of database of project>/up-to-date/keepup-cron-logs/
$ chmod +x /var/www/geosm/<name of database of project>/up-to-date/update_osm_db.sh
$ cron tous les 5 jours à minuit : 0 0 */5 * *  /var/www/geosm/<name of database of project>/up-to-date/update_osm_db.sh > /var/www/geosm/france/up-to-date/keepup-cron-logs/keepup-cron.log 2>&1

```

## Existing replication

- Cameroun ([Cameroun](http://cameroun.geo.sm/))
- Suisse ([Data OSM](http://suisse.geo.sm/))

## Thanks

GEOSM is what it is because of some crazy people, company and free and open source projects. Let's name a few:

- SOGEFI CAMEROUN ([Website](http://sogefi.cm)): firstly, for the initial code system of the administrative panel, and for the beautiful design of the frontend
- OpenStreetMap ([OSM](http://osm.org))
- Openlayers ([Website](http://openlayers.com))
- QGIS SERVER ([Website](https://docs.qgis.org/3.4/en/docs/training_manual/qgis_server/index.html))
