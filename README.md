# Addock Docker Generate Image Dep

Ce projet permet d'automatiser la génération d'images Docker pour un serveur Addok configuré avec des données spécifiques à un département. Addok est un moteur de recherche puissant pour les données d'adresses, et ce projet facilite son déploiement en intégrant directement les données d'un département.

## Fonctionnalités

- Génération automatique d'images Docker pour Addok, avec ou sans Redis.
- Intégration des données d'adresses pour un département spécifique.
- Génération de fichiers Docker Compose prêts à l'emploi.
- Nettoyage automatisé des fichiers temporaires après le processus.

## Images générées

Le script `run.sh` génère trois types d'images Docker pour chaque département :

1. **`addok-[DEPARTEMENT]`** : 
   - Serveur Addok basique.
   - Convient pour les environnements où les performances d'Addok seul sont suffisantes.

2. **`addok-redis-[DEPARTEMENT]`** : 
   - Addok accompagné d'un service Redis.
   - Améliore les performances pour des environnements où des données volumineuses sont utilisées ou des requêtes fréquentes sont attendues.

3. **`addok-standalone-[DEPARTEMENT]`** :
   - Version autonome combinant Addok et Redis dans une seule image.
   - Simplifie le déploiement pour des environnements avec des ressources limitées ou des configurations simples.

### Source des images

Les images de base utilisées pour générer celles de ce projet proviennent de ce repository : 
[aboire/addok-docker](https://github.com/aboire/addok-docker)

Les templates et configurations sont adaptés à partir de ce fork.

vous pouvez consulter le [README](https://github.com/aboire/addok-docker/blob/master/README.md) original pour plus d'informations sur les images de base.

## Prérequis

- **Docker** : Pour la gestion des conteneurs.
- **Docker Compose** : Pour orchestrer les services.

## Utilisation

### 1. Configuration de l'environnement

#### a. Définir les variables d'environnement

Les variables suivantes doivent être définies :

- `DEPARTEMENT` : Code du département (exemple : `974`).
- `REPO_PREFIX` (optionnel) : Préfixe du registre Docker (exemple : `communecter`).
- `PUSH_IMAGE` (optionnel) : Définir à `true` si vous souhaitez pousser les images générées vers un registre Docker.

Exemple de configuration :

```bash
export DEPARTEMENT=974
export REPO_PREFIX=communecter
export PUSH_IMAGE=true
```

#### b. Passer les variables en ligne de commande

Vous pouvez aussi passer les variables directement lors de l'exécution du script :

```bash
DEPARTEMENT=974 REPO_PREFIX=communecter PUSH_IMAGE=true ./run.sh
```

### 2. Exécution du script

Lancez le script `run.sh` pour générer les images Docker et les fichiers de configuration :

```bash
./run.sh
```

### 3. Résultats

Une fois le script terminé, vous obtiendrez :

#### Images Docker générées

- `REPO_PREFIX/addok-[DEPARTEMENT]`
- `REPO_PREFIX/addok-redis-[DEPARTEMENT]`
- `REPO_PREFIX/addok-standalone-[DEPARTEMENT]`

#### Fichiers Docker Compose générés

- `docker-compose-[DEPARTEMENT].yml` : Configure Addok et Redis comme services distincts.
- `docker-compose-standalone-[DEPARTEMENT].yml` : Configure Addok et Redis dans une seule image autonome.

### 4. Démarrage des services

#### Avec Docker Compose

Utilisez les fichiers Docker Compose générés pour démarrer les services :

##### Mode multi-conteneurs (Addok + Redis séparés)

```bash
docker-compose -f docker-compose-974.yml up -d
```

##### Mode autonome (Addok + Redis combinés)

```bash
docker-compose -f docker-compose-standalone-974.yml up -d
```

### 5. Tester le service

Après le démarrage du service, vous pouvez effectuer une recherche sur les adresses. Par exemple, pour rechercher l'adresse **"67 bis Chemin de la Piscine, 97411 Saint-Paul"**, exécutez la commande suivante :

```bash
curl "http://localhost:7878/search/?q=67+bis+Chemin+de+la+Piscine+97411+Saint-Paul"
```

Si le service est correctement configuré, la réponse inclura les coordonnées géographiques et d'autres informations liées à l'adresse.

## Nettoyage des fichiers temporaires

Le script `run.sh` nettoie automatiquement les fichiers temporaires créés pendant l'exécution.
