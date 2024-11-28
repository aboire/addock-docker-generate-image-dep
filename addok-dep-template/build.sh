#!/bin/sh
set -e

# prefixe du repo de l'image si ENV REPO_PREFIX est défini ou "communecter" par défaut
REPO_PREFIX=${REPO_PREFIX:-communecter}
DEPARTEMENT=${DEPARTEMENT:-974}

# verifier que  ../addok-data/addok.conf  et  ../addok-data/addok.db  existent
if [ ! -f ../addok-data/addok.conf ] || [ ! -f ../addok-data/addok.db ]; then
  echo "Les fichiers ../addok-data/addok.conf et ../addok-data/addok.db doivent exister"
  exit 1
fi

# suprimer les fichiers addok.conf et addok.db s'ils existent
if [ -f addok.conf ]; then
  rm addok.conf
fi
if [ -f addok.db ]; then
  rm addok.db
fi

# copier ../addok-data/addok.conf et ../addok-data/addok.db dans le répertoire courant
cp ../addok-data/addok.conf addok.conf
cp ../addok-data/addok.db addok.db

# Définir VERSION comme un horodatage (format : YYYYMMDDHHMMSS)
VERSION=$(date +"%Y%m%d%H%M%S")

TAG="latest"

echo "VERSION définie à : $VERSION"

# Construire et taguer l'image
docker build --pull --rm -t $REPO_PREFIX/addok-$DEPARTEMENT:$VERSION .
docker tag $REPO_PREFIX/addok-$DEPARTEMENT:$VERSION $REPO_PREFIX/addok-$DEPARTEMENT:$VERSION
# si PUSH_IMAGE est défini, pousser l'image sur le repo
[ ! -z "$PUSH_IMAGE" ] && docker push $REPO_PREFIX/addok-$DEPARTEMENT:$VERSION

# Tag supplémentaire pour la version "latest"
docker tag $REPO_PREFIX/addok-$DEPARTEMENT:$VERSION $REPO_PREFIX/addok-$DEPARTEMENT:$TAG
[ ! -z "$PUSH_IMAGE" ] && docker push $REPO_PREFIX/addok-$DEPARTEMENT:$TAG
