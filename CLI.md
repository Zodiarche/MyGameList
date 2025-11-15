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

### Démarrer uniquement le frontend

```powershell
docker compose -f docker-compose.dev.yml up frontend --build
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

### Voir les logs du frontend uniquement

```powershell
docker compose -f docker-compose.dev.yml logs -f frontend
```

### Reconstruire sans cache (clean build)

```powershell
docker compose -f docker-compose.dev.yml build --no-cache
```

### Redémarrer les conteneurs

```powershell
docker compose -f docker-compose.dev.yml restart
```

### Exécuter une commande dans le conteneur frontend

```powershell
docker compose -f docker-compose.dev.yml exec frontend sh
```

### Voir l'état des conteneurs

```powershell
docker compose -f docker-compose.dev.yml ps
```

## 🔧 NPM - Frontend (développement local sans Docker)

**Note** : Ces commandes doivent être exécutées depuis le dossier `frontend/`.

### Installer les dépendances

```powershell
cd frontend
npm install
```

### Démarrer le serveur de développement

```powershell
cd frontend
npm run dev
```

### Build de production

```powershell
cd frontend
npm run build
```

### Linter le code

```powershell
cd frontend
npm run lint
```

### Prévisualiser le build de production

```powershell
cd frontend
npm run preview
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

## 📝 NOTES

### Frontend

- **Port** : 5173
- **URL locale** : <http://localhost:5173>
- **Container** : mygamelist-frontend-dev

### Backend (à venir)

- **Port** : 3000 (à confirmer)
- **URL locale** : <http://localhost:3000>
- **Container** : mygamelist-backend-dev
