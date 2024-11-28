FROM communecter/addok-standalone

# Copier uniquement les fichiers nécessaires au conteneur Addok
COPY addok.conf /etc/addok/addok.conf
COPY addok.db /data/addok.db
COPY dump.rdb /data/dump.rdb

# Copier le script d'entrée
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh
