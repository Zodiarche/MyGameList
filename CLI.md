# CLI - MyGameList

Commandes essentielles pour le développement.

## 🚀 Démarrer le projet

```powershell
# Démarrer tous les services
docker compose -f docker-compose.dev.yml up -d --build
```

## 🛑 Arrêter le projet

```powershell
# Arrêter tous les conteneurs
docker compose -f docker-compose.dev.yml down

# Arrêter et supprimer les volumes (réinitialisation complète)
docker compose -f docker-compose.dev.yml down -v
```

## 🧪 Tester la base de données

```powershell
# Lancer les tests des triggers
.\scripts\run-db-tests.ps1
```

## 📝 Services disponibles

| Service | Port | URL |
|---------|------|-----|
| **Frontend** | 5173 | <http://localhost:5173> |
| **Backend** | 3001 | <http://localhost:3001> |
| **pgAdmin** | 5050 | <http://localhost:5050> |
| **PostgreSQL** | 5432 | localhost:5432 |
| **Redis** | 6379 | localhost:6379 |

### 🔑 Accès pgAdmin

- **Email** : `admin@mygamelist.dev`
- **Mot de passe** : `admin`

**Connexion à PostgreSQL dans pgAdmin :**

1. Clic droit sur "Servers" → "Register" → "Server"
2. **General** → Name : `MyGameList`
3. **Connection** :
   - Host : `postgres`
   - Port : `5432`
   - Database : `mygamelist`
   - Username : `dev_user`
   - Password : `dev_password`
