#!/bin/sh
set -e

# prefixe du repo de l'image si ENV REPO_PREFIX est défini ou "communecter" par défaut
REPO_PREFIX=${REPO_PREFIX:-communecter}
DEPARTEMENT=${DEPARTEMENT:-974}

# verifier que  ../addok-data/dump.rdb  existe
if [ ! -f ../addok-data/dump.rdb ]; then
  echo "Les fichiers ../addok-data/dump.rdb doivent exister"
  exit 1
fi

# suprimer les fichiers dump.rdb s'il existe
if [ -f dump.rdb ]; then
  rm dump.rdb
fi

# copier ../addok-data/dump.rdb dans le répertoire courant
cp ../addok-data/dump.rdb dump.rdb

# Définir VERSION comme un horodatage (format : YYYYMMDDHHMMSS)
VERSION=$(date +"%Y%m%d%H%M%S")

TAG="latest"

echo "VERSION définie à : $VERSION"

# Construire et taguer l'image
docker build --pull --rm -t $REPO_PREFIX/addok-redis-$DEPARTEMENT:$VERSION .
docker tag $REPO_PREFIX/addok-redis-$DEPARTEMENT:$VERSION $REPO_PREFIX/addok-redis-$DEPARTEMENT:$VERSION
[ ! -z "$PUSH_IMAGE" ] && docker push $REPO_PREFIX/addok-redis-$DEPARTEMENT:$VERSION

# Tag supplémentaire pour la version "latest"
docker tag $REPO_PREFIX/addok-redis-$DEPARTEMENT:$VERSION $REPO_PREFIX/addok-redis-$DEPARTEMENT:$TAG
[ ! -z "$PUSH_IMAGE" ] && docker push $REPO_PREFIX/addok-redis-$DEPARTEMENT:$TAG
