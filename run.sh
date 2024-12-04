#!/bin/bash

# Fonction pour afficher les erreurs et arrêter le script
function error_exit {
  echo "Erreur : $1"
  exit 1
}

REPO_PREFIX=${REPO_PREFIX:-communecter}

# Vérifier que le numéro de département est défini dans l'environnement
if [ -z "$DEPARTEMENT" ]; then
  error_exit "La variable d'environnement DEPARTEMENT n'est pas définie. Définissez-la avant d'exécuter ce script, par exemple : export DEPARTEMENT=974"
fi

echo ">>> Traitement pour le département : $DEPARTEMENT"

# Étape 1 : Lancer le build pour la data du département
echo ">>> Lancement du script de build pour le département $DEPARTEMENT"
DEPARTEMENT=$DEPARTEMENT ./build-data.sh || error_exit "Échec du build pour le département $DEPARTEMENT"

# Étape 2 : Arrêter le service Addok
echo ">>> Arrêt du service Addok"
docker-compose down || error_exit "Échec lors de l'arrêt du service Addok"

# Étape 3 : Supprimer l'ancien répertoire de données
echo ">>> Suppression de ./addok-data/addok.db et ./addok-data/dump.rdb et ./logs"
sudo rm -f ./addok-data/addok.db || error_exit "Impossible de supprimer ./addok-data/addok.db"
sudo rm -f ./addok-data/dump.rdb || error_exit "Impossible de supprimer ./addok-data/dump.rdb "
sudo rm -Rf ./logs || error_exit "Impossible de supprimer ./logs"

# Étape 4 : Vérifier que le fichier bundle existe
if [ ! -f "./dist/prebuilt-bundle.zip" ]; then
  error_exit "Le fichier ./dist/prebuilt-bundle.zip n'existe pas. Assurez-vous que le build a généré ce fichier."
fi
echo ">>> Fichier ./dist/prebuilt-bundle.zip trouvé avec succès"

# Étape 5 : Décompresser le bundle dans ./addok-data
echo ">>> Décompression de ./dist/prebuilt-bundle.zip dans ./addok-data"
unzip -o ./dist/prebuilt-bundle.zip -d ./addok-data || error_exit "Échec lors de la décompression du fichier bundle"

# addok-[DEPARTEMENT]
echo ">>> Création du répertoire ./addok-$DEPARTEMENT"
mkdir -p ./addok-$DEPARTEMENT || error_exit "Impossible de créer le répertoire ./addok-$DEPARTEMENT"

echo ">>> Création du Dockerfile dans /addok-$DEPARTEMENT"

cp ./addok-dep-template/Dockerfile ./addok-$DEPARTEMENT/Dockerfile

echo ">>> Création du fichier build.sh dans ./addok-$DEPARTEMENT"
cp ./addok-dep-template/build.sh ./addok-$DEPARTEMENT/build.sh

chmod +x ./addok-$DEPARTEMENT/build.sh

cd ./addok-$DEPARTEMENT
if [ "$PUSH_IMAGE" = "true" ]; then
  PUSH_IMAGE=true REPO_PREFIX=$REPO_PREFIX DEPARTEMENT=$DEPARTEMENT ./build.sh
else
  REPO_PREFIX=$REPO_PREFIX DEPARTEMENT=$DEPARTEMENT ./build.sh
fi
cd ..

# addok-redis-[DEPARTEMENT]
echo ">>> Création du répertoire ./addok-redis-$DEPARTEMENT"
mkdir -p ./addok-redis-$DEPARTEMENT || error_exit "Impossible de créer le répertoire ./addok-redis-$DEPARTEMENT"

echo ">>> Création du Dockerfile dans ./addok-redis-$DEPARTEMENT"
cp ./addok-redis-dep-template/Dockerfile ./addok-redis-$DEPARTEMENT/Dockerfile

echo ">>> Création du fichier build.sh dans ./addok-redis-$DEPARTEMENT"
cp ./addok-redis-dep-template/build.sh ./addok-redis-$DEPARTEMENT/build.sh

chmod +x ./addok-redis-$DEPARTEMENT/build.sh

cd ./addok-redis-$DEPARTEMENT
if [ "$PUSH_IMAGE" = "true" ]; then
  PUSH_IMAGE=true REPO_PREFIX=$REPO_PREFIX DEPARTEMENT=$DEPARTEMENT ./build.sh
else
  REPO_PREFIX=$REPO_PREFIX DEPARTEMENT=$DEPARTEMENT ./build.sh
fi
cd ..

# addok-standalone-[DEPARTEMENT]
echo ">>> Création du répertoire ./addok-standalone-$DEPARTEMENT"
mkdir -p ./addok-standalone-$DEPARTEMENT || error_exit "Impossible de créer le répertoire ./addok-standalone-$DEPARTEMENT"

echo ">>> Création du Dockerfile dans ./addok-standalone-$DEPARTEMENT"
cp ./addok-standalone-dep-template/Dockerfile ./addok-standalone-$DEPARTEMENT/Dockerfile

# addok-standalone-[DEPARTEMENT]/docker-entrypoint.sh
echo ">>> Création du fichier docker-entrypoint.sh dans ./addok-standalone-$DEPARTEMENT"
cp ./addok-standalone-dep-template/docker-entrypoint.sh ./addok-standalone-$DEPARTEMENT/docker-entrypoint.sh

# addok-standalone-[DEPARTEMENT]/build.sh
echo ">>> Création du fichier build.sh dans ./addok-standalone-$DEPARTEMENT"
cp ./addok-standalone-dep-template/build.sh ./addok-standalone-$DEPARTEMENT/build.sh

chmod +x ./addok-standalone-$DEPARTEMENT/build.sh

cd ./addok-standalone-$DEPARTEMENT
# si PUSH_IMAGE existe rajouter PUSH_IMAGE=true avant ./build.sh
if [ "$PUSH_IMAGE" = "true" ]; then
  PUSH_IMAGE=true REPO_PREFIX=$REPO_PREFIX DEPARTEMENT=$DEPARTEMENT ./build.sh
else
  REPO_PREFIX=$REPO_PREFIX DEPARTEMENT=$DEPARTEMENT ./build.sh
fi
cd ..

# Étape 6 : Nettoyer les fichiers temporaires
echo ">>> Nettoyage des fichiers temporaires"
rm -Rf ./addok-$DEPARTEMENT
rm -Rf ./addok-redis-$DEPARTEMENT
rm -Rf ./addok-standalone-$DEPARTEMENT
rm -Rf ./data
rm -Rf ./dist


# créer le fichier docker-compose-[$DEPARTEMENT].yml
echo ">>> Création du fichier docker-compose-$DEPARTEMENT.yml"
cat <<EOF > ./docker-compose-$DEPARTEMENT.yml
version: '3.8'

services:
  addok:
    image: $REPO_PREFIX/addok-$DEPARTEMENT
    ports:
    - "7878:7878"
    links:
    - addok-redis:redis
    environment:
      WORKERS: 1
      WORKER_TIMEOUT: 30
      LOG_QUERIES: 0
      LOG_NOT_FOUND: 0
      SLOW_QUERIES: 200
  addok-redis:
    image: $REPO_PREFIX/addok-redis-$DEPARTEMENT
    privileged: true
    cap_add:
      - SYS_PTRACE
EOF

# créer le fichier docker-compose-standalone-[$DEPARTEMENT].yml
echo ">>> Création du fichier docker-compose-standalone-$DEPARTEMENT.yml"
cat <<EOF > ./docker-compose-standalone-$DEPARTEMENT.yml
version: '3.8'

services:
  addok:
    image: $REPO_PREFIX/addok-standalone-$DEPARTEMENT
    privileged: true
    cap_add:
      - SYS_PTRACE
    ports:
    - "7878:7878"
    environment:
      WORKERS: 1
      WORKER_TIMEOUT: 30
      LOG_QUERIES: 0
      LOG_NOT_FOUND: 0
      SLOW_QUERIES: 200
EOF


echo ">>> Script terminé avec succès"
