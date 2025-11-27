# CLI - MyGameList

Commandes pratiques pour le développement. Ajoutez vos commandes au fur et à mesure du projet.

## 📦 DOCKER - Développement

**Note** : Les commandes Docker doivent être exécutées depuis la racine du projet (`MyGameList/`).

### Démarrer tous les services (avec rebuild)

```powershell
docker compose -f docker-compose.dev.yml up --build
```

### Démarrer en arrière-plan

```powershell
docker compose -f docker-compose.dev.yml up -d --build
```

### Arrêter tous les conteneurs

```powershell
docker compose -f docker-compose.dev.yml down
```

### Arrêter et supprimer les volumes (nettoie tout)

```powershell
docker compose -f docker-compose.dev.yml down -v
```

### Voir les logs en temps réel (tous les services)

```powershell
docker compose -f docker-compose.dev.yml logs -f
```

### Reconstruire sans cache (clean build)

```powershell
docker compose -f docker-compose.dev.yml build --no-cache
```

### Redémarrer les conteneurs

```powershell
docker compose -f docker-compose.dev.yml restart
```

### Voir l'état des conteneurs

```powershell
docker compose -f docker-compose.dev.yml ps
```

## 🧹 NETTOYAGE

### Supprimer node_modules du frontend et réinstaller

```powershell
cd frontend
rm -rf node_modules
npm install
```

### Supprimer le dossier dist du frontend

```powershell
cd frontend
rm -rf dist
```

### Nettoyer les images Docker non utilisées

```powershell
docker image prune -a
```

### Nettoyer tous les volumes Docker non utilisés

```powershell
docker volume prune
```

### Nettoyer tout Docker (images, conteneurs, volumes, réseaux)

```powershell
docker system prune -a --volumes
```

## 🗄️ BASE DE DONNÉES & CACHE

### PostgreSQL

```powershell
# Se connecter à PostgreSQL
docker exec -it mygamelist-postgres-dev psql -U dev_user -d mygamelist_dev

# Voir les tables
docker exec -it mygamelist-postgres-dev psql -U dev_user -d mygamelist_dev -c "\dt"

# Exécuter un fichier SQL
docker exec -i mygamelist-postgres-dev psql -U dev_user -d mygamelist_dev < database/schema.sql

# Backup de la base
docker exec -t mygamelist-postgres-dev pg_dump -U dev_user mygamelist_dev > backup.sql

# Restore d'un backup
docker exec -i mygamelist-postgres-dev psql -U dev_user -d mygamelist_dev < backup.sql
```

### Redis Cache

```powershell
# Se connecter à Redis CLI
docker exec -it mygamelist-redis-dev redis-cli

# Voir les statistiques du cache
docker exec -it mygamelist-redis-dev redis-cli INFO stats

# Voir l'utilisation mémoire
docker exec -it mygamelist-redis-dev redis-cli INFO memory

# Vider tout le cache (DEV uniquement)
docker exec -it mygamelist-redis-dev redis-cli FLUSHALL

# Voir toutes les clés (DEV uniquement)
docker exec -it mygamelist-redis-dev redis-cli KEYS "*"

# Voir une clé spécifique
docker exec -it mygamelist-redis-dev redis-cli GET "ranking:rating:page:1"

# Monitoring en temps réel
docker exec -it mygamelist-redis-dev redis-cli --stat
```

**Pour plus de commandes Redis** : voir [REDIS-CLI.md](./REDIS-CLI.md)

### Rafraîchir les vues matérialisées

```powershell
# Depuis PostgreSQL CLI
docker exec -it mygamelist-postgres-dev psql -U dev_user -d mygamelist_dev -c "REFRESH MATERIALIZED VIEW CONCURRENTLY mv_game_rankings;"
```

## 📝 NOTES

### Services

| Service | Port | URL | Container |
|---------|------|-----|-----------|
| **Frontend** | 5173 | http://localhost:5173 | mygamelist-frontend-dev |
| **Backend** | 3001 | http://localhost:3001 | mygamelist-backend-dev |
| **PostgreSQL** | 5432 | localhost:5432 | mygamelist-postgres-dev |
| **Redis** | 6379 | localhost:6379 | mygamelist-redis-dev |

### Credentials (DEV)

- **PostgreSQL**
  - User: `dev_user`
  - Password: `dev_password`
  - Database: `mygamelist_dev`

- **Redis**
  - Pas d'authentification en DEV

⚠️ **NE JAMAIS commit ces credentials** - À changer en production

## 📚 Documentation

- [Architecture Cache](./ARCHITECTURE-CACHE.md) - Stratégie de cache multi-niveaux
- [Redis CLI](./REDIS-CLI.md) - Commandes Redis détaillées
- [CDC](./CDC.md) - Cahier des charges complet

- **Port** : 3000
- **URL locale** : <http://localhost:3000>
- **Container** : mygamelist-backend-dev
