# DOSSIER PROJET

### Projet : Réseau social de collection et de gestion de jeux vidéo

### Rédacteur : Benjamin GUILLEMIN

### Date

---

# 1. LISTE DES COMPÉTENCES DU RÉFÉRENTIEL COUVERTES PAR LE PROJET

## 1.1. Développer une application sécurisée

### 1.1.1. Installer et configurer son environnement de travail en fonction du projet

J’installe l’ensemble des outils nécessaires au développement de l’application.
Je configure mon environnement avec :
– un IDE adapté,
– un gestionnaire de versions,
– un environnement d’exécution conforme à celui prévu en production,
– les conteneurs nécessaires à la base de données et aux services internes.

Je m’assure que toute la documentation technique concernant ces outils est comprise et appliquée.

### 1.1.2. Développer des interfaces utilisateur

Je développe les interfaces selon les maquettes et la charte graphique.
Je conçois des éléments visuels adaptés aux différents supports (ordinateur, tablette, mobile).
Je documente mon code et réalise des tests unitaires sur les composants concernés.
Je m’assure que les règles d’ergonomie, d’accessibilité et de sécurité sont respectées.

### 1.1.3. Développer des composants métier

Je mets en place les composants métier gérant les opérations principales :
– gestion d’utilisateur,
– gestion des bibliothèques de jeux,
– système de notation,
– ajout de commentaires,
– gestion d’amis.

Je documente tous les composants développés et réalise des tests unitaires associés.
Je mets en œuvre une démarche structurée en cas de dysfonctionnement et fais une veille régulière sur les problématiques de sécurité.

### 1.1.4. Contribuer à la gestion d’un projet informatique

Je planifie mes tâches selon un planning défini.
Je mets en place des outils collaboratifs adaptés à la méthodologie choisie.
Je mets à jour l’avancement du projet et alerte si des retards ou risques apparaissent.
Je rédige les comptes rendus de réunion.

---

## 1.2. Concevoir et développer une application sécurisée organisée en couches

### 1.2.1. Analyser les besoins et maquetter une application

J’analyse les besoins liés au réseau social et identifie les acteurs : visiteurs, membres, administrateurs.
Je produis les maquettes principales :
– page d’accueil,
– page de jeu,
– espace personnel,
– système d’ajout d’amis,
– fil d’activité.
J’organise l’enchaînement des écrans.

### 1.2.2. Définir l’architecture logicielle d’une application

Je définis une architecture multicouche comprenant :
– couche présentation,
– couche métier,
– couche d’accès aux données.

Je prends en compte les règles d’éco-conception et les exigences de sécurité.

### 1.2.3. Concevoir et mettre en place une base de données relationnelle

Je conçois un schéma conceptuel basé sur les entités principales :
– utilisateur,
– jeu,
– bibliothèque,
– note,
– commentaire,
– relation d’amitié.

Je crée une base de données de test comprenant un jeu d’essai réutilisable.
J’assure la sécurité, la confidentialité et l’intégrité des données.

### 1.2.4. Développer des composants d’accès aux données SQL et NoSQL

Je développe les composants permettant la création, la modification, la suppression et la consultation des données, en gérant :
– les conflits,
– les cas d’erreur,
– la validation des entrées.

Je réalise les tests unitaires sur chaque composant.

---

## 1.3. Préparer le déploiement d’une application sécurisée

### 1.3.1. Préparer et exécuter les plans de tests d’une application

Je crée un plan de tests couvrant l’ensemble des fonctionnalités.
Je réalise les tests sur un environnement dédié en vérifiant la cohérence des résultats.

### 1.3.2. Préparer et documenter le déploiement d’une application

Je rédige la procédure de déploiement.
Je décris les scripts et leur fonctionnement.
Je définis les environnements de test.

### 1.3.3. Contribuer à la mise en production dans une démarche DevOps

Je mets en place l’intégration continue.
J’utilise des outils de qualité de code et de tests automatisés.
Je interprète les rapports d’intégration continue.

---

# 2. CAHIER DES CHARGES

## 2.1. Description de l’existant

Aucune version antérieure n’existe.
Le projet répond au besoin de réunir dans un même espace les joueurs souhaitant gérer leur collection de jeux vidéo, échanger avec leurs amis, partager leurs avis et découvrir de nouveaux jeux.
Le marché comporte des solutions centrées sur la notation ou sur l’achat, mais peu de services orientés sur la collection personnelle et l’interaction sociale.

## 2.2. Reprise de l’existant

Aucun élément antérieur n’est repris.
Aucun nom de domaine, aucun hébergement, aucune donnée préalable.

## 2.3. Principes de référencement

Le site doit apparaître dans les recherches liées :
– aux collections de jeux vidéo,
– aux avis,
– aux listes de jeux.
Le contenu doit être structuré pour être facilement interprété par les moteurs de recherche.

## 2.4. Exigences de performances et de volumétrie

### 2.4.1. Volumétrie attendue

Le projet doit gérer un catalogue d'environ **897 447 jeux vidéo** provenant de sources externes (API RAWG). Cette volumétrie importante impose des contraintes strictes de performance.

**Volumes estimés** :

- ~900 000 jeux
- ~50 000 utilisateurs (objectif première année)
- ~10 000 utilisateurs actifs simultanés (pic)
- ~2 000 000 entrées de bibliothèque
- ~500 000 notes
- ~200 000 commentaires

### 2.4.2. Objectifs de performance

| Opération | SLA Cible | Notes |
|-----------|-----------|-------|
| Page d'accueil | < 500ms | Avec cache |
| Recherche de jeux | < 300ms | Avec cache + index |
| Classements | < 200ms | Avec cache Redis |
| Détail d'un jeu | < 300ms | Avec cache |
| Bibliothèque utilisateur | < 400ms | Pagination requise |
| Authentification | < 200ms | Session Redis |

### 2.4.3. Stratégie de mise en cache

Face à la volumétrie importante, une **stratégie de cache progressive** est mise en place.

#### **Phase 1 : Base de Données Optimisée (PostgreSQL) - PRIORITAIRE**

**Index critiques** (à implémenter en premier) :

```sql
-- Full-text search sur 897k jeux (ESSENTIEL)
CREATE INDEX idx_game_title_gin ON game USING gin(to_tsvector('english', title));

-- Classements et statistiques
CREATE INDEX idx_rating_game_avg ON rating(game_id, rating);
CREATE INDEX idx_library_status ON library(user_id, status);

-- Recherche multicritères
CREATE INDEX idx_game_platform ON game_platform(platform_id, game_id);
CREATE INDEX idx_game_genre ON game_genre(genre_id, game_id);
```

#### **Phase 2 : Sessions Utilisateur (Redis) - SIMPLE**

Redis est utilisé **uniquement** pour stocker les sessions d'authentification (usage le plus simple et standard).

**Configuration de base** :

```javascript
// Backend - express-session + Redis
import session from 'express-session';
import RedisStore from 'connect-redis';
import { createClient } from 'redis';

const redisClient = createClient({
  url: 'redis://redis:6379'
});
redisClient.connect();

app.use(session({
  store: new RedisStore({ client: redisClient }),
  secret: process.env.SESSION_SECRET,
  resave: false,
  saveUninitialized: false,
  cookie: {
    httpOnly: true,
    maxAge: 24 * 60 * 60 * 1000 // 24h
  }
}));
```

**Avantages** :

- ✅ Configuration minimale (5 lignes)
- ✅ Gestion automatique par express-session
- ✅ Pas de code cache à écrire
- ✅ Logout instantané

#### **Phase 3 : Cache Frontend (React Query) - SANS REDIS**

React Query gère automatiquement le cache côté client sans configuration Redis.

**Configuration simple** :

```typescript
// frontend/src/main.tsx
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 5 * 60 * 1000,  // 5 minutes
      cacheTime: 10 * 60 * 1000, // 10 minutes
    },
  },
});

// Utilisation dans les composants (exemple)
const { data, isLoading } = useQuery({
  queryKey: ['games', page],
  queryFn: () => fetch(`/api/games?page=${page}`).then(r => r.json()),
});
```

**Avantages** :

- ✅ Cache automatique en mémoire navigateur
- ✅ Pas de serveur Redis côté frontend
- ✅ Réutilisation des données entre composants
- ✅ Invalidation simple après mutations

#### **Phase 4 (OPTIONNELLE) : Cache Redis pour Données - SI BESOIN**

**À implémenter plus tard si les performances l'exigent**.

Cache Redis simple pour les classements uniquement :

```javascript
// Exemple SIMPLE - un seul endpoint
app.get('/api/games/ranking', async (req, res) => {
  const cacheKey = 'ranking:top20';

  // 1. Vérifier si en cache
  const cached = await redisClient.get(cacheKey);
  if (cached) {
    return res.json(JSON.parse(cached));
  }

  // 2. Sinon, aller en base
  const data = await db.query('SELECT * FROM game ORDER BY metacritic DESC LIMIT 20');

  // 3. Mettre en cache 10 minutes
  await redisClient.setEx(cacheKey, 600, JSON.stringify(data));

  return res.json(data);
});
```

**Pattern à répéter** : Check cache → Si absent, query DB → Stocker dans cache

#### **Phase 5 (FUTURE) : Base de Données Avancée**

**Vues matérialisées** (à implémenter si le projet évolue) :

```sql
-- Classement précalculé (optionnel - plus tard)
CREATE MATERIALIZED VIEW mv_game_rankings AS
SELECT
  g.game_id,
  g.title,
  g.cover_image,
  AVG(r.rating) as average_rating,
  COUNT(r.rating_id) as total_ratings
FROM game g
LEFT JOIN rating r ON g.game_id = r.game_id
GROUP BY g.game_id
ORDER BY average_rating DESC;
```

### 2.4.4. Résumé de l'Approche Progressive

**Étape 1 - OBLIGATOIRE (début de projet)** :

- ✅ Index PostgreSQL (performances de base)
- ✅ Redis pour sessions uniquement (simple)
- ✅ React Query frontend (automatique)

**Étape 2 - SI BESOIN (après premiers tests)** :

- ⚠️ Cache Redis pour classements (1 endpoint)
- ⚠️ Extension à d'autres endpoints si lenteur

**Étape 3 - OPTIONNEL (si projet grandit)** :

- 🔮 Vues matérialisées
- 🔮 CDN pour images
- 🔮 Elasticsearch pour recherche

**Complexité Redis** :

- **Phase 1** : Sessions uniquement → **Niveau débutant** ✅
- **Phase 2** : Cache simple (get/set) → **Niveau intermédiaire** ⚠️
- Documentation complète : Éviter pour MVP

### 2.4.5. Monitoring Simple

**Métriques essentielles** (logs console suffisants en dev) :

- Temps de réponse API (logs Node.js)
- Erreurs backend (console.error)
- Vérifier Redis actif : `docker ps`

**Outils optionnels** (production future) :

- Logs structurés : Winston
- Monitoring : PM2 ou équivalent

## 2.5. Multilinguisme & adaptations

Le site est proposé en français.
Une version anglaise est envisagée.
Le site doit rester lisible pour les personnes ayant des difficultés visuelles.

## 2.6. Description graphique et ergonomique

### 2.6.1. Charte graphique

– Logo minimaliste inspiré du jeu vidéo.
– Palette moderne et sombre, lisible.
– Police lisible (ex. sans-serif).
– Cohérence graphique sur l’ensemble du site.

### 2.6.2. Design et responsive design

Le site s’adapte aux différents supports.
L’interface privilégie la simplicité et la lisibilité.

## 2.7. Besoins fonctionnels « métier »

### 2.7.1. Utilisateurs du projet

- Visiteur
- Membre
- Administrateur

Hiérarchie des rôles :

- Le Membre hérite des droits du Visiteur
- L’Administrateur hérite des droits du Membre

### 2.7.2. Informations relatives aux contenus

Les contenus gérés sont :

- fiches jeux
- images
- avis
- notes
- commentaires
- listes personnelles (bibliothèques)

Les droits d'utilisation des images et textes doivent être respectés.
Les données personnelles sont protégées selon le RGPD.

### 2.7.4. Gestion des images

#### **Images de jeux (cover_image)**

Les images de jeux proviennent d'une API externe (RAWG) et sont stockées sous forme d'URL.

**Stockage** :

- URLs externes uniquement (pas de stockage local)
- Format : `https://media.rawg.io/media/games/...`
- Pas de téléchargement nécessaire

**Exemple en base** :

```sql
UPDATE game SET cover_image = 'https://media.rawg.io/media/games/456/456.jpg'
WHERE game_id = 123;
```

#### **Avatars utilisateurs (avatar)**

Les avatars sont uploadés par les utilisateurs et nécessitent un stockage.

**Stockage Local** ✅

**Caractéristiques** :

- Taille maximale : 2 MB
- Formats acceptés : JPEG, PNG, WebP
- Résolution recommandée : 200x200 px
- Stockage : `backend/uploads/avatars/`

**Implémentation** :

```javascript
// Backend - Configuration Multer
import multer from 'multer';
import path from 'path';

const storage = multer.diskStorage({
  destination: 'uploads/avatars/',
  filename: (req, file, cb) => {
    const userId = req.session.userId;
    const ext = path.extname(file.originalname);
    cb(null, `user-${userId}${ext}`);
  }
});

const upload = multer({
  storage,
  limits: { fileSize: 2 * 1024 * 1024 }, // 2 MB
  fileFilter: (req, file, cb) => {
    const allowed = ['image/jpeg', 'image/png', 'image/webp'];
    cb(null, allowed.includes(file.mimetype));
  }
});

// Route upload
app.post('/api/user/avatar', requireAuth,
  upload.single('avatar'),
  async (req, res) => {
    const avatarUrl = `/uploads/avatars/user-${req.session.userId}.jpg`;
    await db.query('UPDATE user_account SET avatar = ? WHERE user_id = ?',
      [avatarUrl, req.session.userId]);
    res.json({ avatar: avatarUrl });
  }
);

// Servir les fichiers statiques
app.use('/uploads', express.static('uploads'));
```

**Stockage en base** :

```sql
-- user_account.avatar contient le chemin relatif
UPDATE user_account SET avatar = '/uploads/avatars/user-123.jpg'
WHERE user_id = 123;

-- Ou NULL si pas d'avatar
UPDATE user_account SET avatar = NULL WHERE user_id = 456;
```

#### **Sécurité uploads**

**Validations obligatoires** :

- Vérification MIME type (pas uniquement extension)
- Limite de taille stricte (2 MB)

**Protection** :

```javascript
// Vérifier le MIME type réel (pas l'extension)
import fileType from 'file-type';

const validateImage = async (filePath) => {
  const type = await fileType.fromFile(filePath);
  const allowed = ['image/jpeg', 'image/png', 'image/webp'];
  return allowed.includes(type?.mime);
};
```

### 2.7.3. Inventaire des besoins fonctionnels

| Thème          | Acteur         | Fonctionnalité                       | Finalité                              |
| -------------- | -------------- | ------------------------------------ | ------------------------------------- |
| Accès          | Visiteur       | Consulter la page d’accueil          | Découvrir la plateforme               |
| Accès          | Visiteur       | S’inscrire                           | Créer un compte                       |
| Accès          | Membre         | Se connecter / Se déconnecter        | Accéder à son espace personnel        |
| Découverte     | Visiteur       | Rechercher un jeu                    | Trouver un jeu                        |
| Découverte     | Visiteur       | Parcourir la liste des jeux          | Explorer le catalogue                 |
| Découverte     | Visiteur       | Consulter le classement              | Découvrir les jeux populaires         |
| Découverte     | Tous           | Consulter la fiche d’un jeu          | Visualiser les informations d’un jeu  |
| Profil         | Membre         | Gérer son profil                     | Mettre à jour ses informations        |
| Bibliothèque   | Membre         | Consulter sa bibliothèque            | Visualiser sa collection              |
| Bibliothèque   | Membre         | Ajouter un jeu à sa bibliothèque     | Enrichir sa collection                |
| Bibliothèque   | Membre         | Retirer un jeu de sa bibliothèque    | Mettre à jour sa collection           |
| Social         | Membre         | Rechercher un utilisateur            | Trouver d’autres membres              |
| Social         | Membre         | Envoyer une demande d’ami            | Créer une relation                    |
| Social         | Membre         | Accepter / Refuser une demande d’ami | Gérer ses relations                   |
| Social         | Membre         | Consulter la liste de ses amis       | Visualiser son réseau                 |
| Social         | Membre         | Consulter la collection d’un ami     | Explorer les collections des autres   |
| Notes          | Membre         | Noter un jeu                         | Donner son avis                       |
| Commentaires   | Membre         | Commenter un jeu                     | Partager son opinion                  |
| Commentaires   | Membre         | Gérer ses commentaires               | Modifier / supprimer ses commentaires |
| Sécurité       | Membre         | Signaler un contenu                  | Alerter en cas d’abus                 |
| Administration | Administrateur | Modérer les contenus                 | Garantir le respect des règles        |
| Administration | Administrateur | Gérer les comptes utilisateurs       | Administrer la plateforme             |

## 2.8. Budget

---

# 3. PRÉSENTATION DE L’ENTREPRISE ET DU SERVICE

## 3.1. Présentation de l’entreprise

Projet réalisé dans un cadre scolaire. L’organisation se concentre sur la création d’applications numériques. Les activités principales concernent la conception, le développement et la gestion de projets web.

## 3.2. Objectifs du projet

Créer un réseau social permettant aux joueurs de gérer et partager leurs collections de jeux.

## 3.3. Cible adressée

Public : joueurs de jeux vidéo, amateurs ou experts.
Segment : utilisateurs cherchant une plateforme centrée sur la collection et l’échange.

## 3.4. Processus utilisateur impacté

– Gestion de contenu
– Interaction sociale
– Découverte et recherche de jeux

---

# 4. GESTION DE PROJET

## 4.1. Intervenants sur le projet

Je réalise l’ensemble du développement.
Je joue les rôles : développeur, concepteur, testeur.

## 4.2. Méthodologie

J’utilise une méthode inspirée d’AGILE :
– travail par itérations,
– objectifs courts,
– retours réguliers.

## 4.3. Outils, planning et suivi

Outils : Git, ClickUp.
Je structure le projet en phases : analyse → tests → développement.

## 4.4. Objectifs de qualité

– assurer la maintenabilité,
– garantir une bonne expérience utilisateur,
– assurer une gestion propre des données.

---

# 5. SPÉCIFICATIONS FONCTIONNELLES

## 5.1. Contraintes et livrables

– beaucoup d’utilisateurs simultanés,
– disponibilité importante.
Livrables : cahier des charges, code source, script de BDD.

## 5.2. Architecture logicielle

Architecture en couches : présentation, métier, données.

## 5.3. Maquettes et enchainement des maquettes

## 5.4. MCD / MLD / MPD

## 5.6. Cas d’utilisation

Acteurs :

- Visiteur
- Membre
- Administrateur

Cas principaux :

- Consulter la page d’accueil
- S’inscrire
- Se connecter / Se déconnecter
- Rechercher un jeu
- Parcourir la liste des jeux
- Consulter le classement
- Consulter la fiche d’un jeu
- Gérer son profil
- Consulter sa bibliothèque
- Ajouter un jeu à sa bibliothèque
- Retirer un jeu de sa bibliothèque
- Rechercher un utilisateur
- Envoyer une demande d’ami
- Accepter / refuser une demande d’ami
- Consulter la liste de ses amis
- Consulter la collection d’un ami
- Noter un jeu
- Commenter un jeu
- Gérer ses commentaires
- Signaler un contenu
- Modérer les contenus (Admin)
- Gérer les comptes (Admin)

## 5.7. Fonctionnalités détaillées

Diagramme de séquences

Les fonctionnalités sont organisées autour de trois axes :

1. **Gestion de la collection personnelle**

   - Consultation de la bibliothèque
   - Ajout de jeux
   - Suppression de jeux

2. **Interaction sociale**

   - Recherche de membres
   - Envoi, acceptation et refus de demandes d’amis
   - Consultation des collections des amis

3. **Participation communautaire**

   - Notation des jeux
   - Publication de commentaires
   - Gestion de ses propres commentaires
   - Signalement de contenus inappropriés

4. **Administration**

   - Modération de l’ensemble des contenus
   - Gestion des comptes utilisateurs

---

# 6. SPÉCIFICATIONS TECHNIQUES

Technologies selon ton choix, par ex. :
– Front : JS (React)
– Back : NodeJS (Express)
– BDD : MySQL
– API : REST

---

# 7. RÉALISATIONS

---

# 8. ÉLÉMENTS DE SÉCURITÉ

---

# 9. PLAN DE TESTS

## 9.1. Stratégie de tests

### 9.1.1. Principes généraux

- **Pyramide des tests** : Privilégier les tests unitaires (base), puis tests d'intégration, puis tests E2E (sommet)
- **Couverture cible** : Minimum 80% pour le code métier critique
- **Automatisation** : Tous les tests doivent être automatisables et reproductibles
- **CI/CD** : Intégration dans le pipeline de déploiement

### 9.1.2. Types de tests par couche

#### **Frontend (Architecture modulaire)**

- **Tests unitaires des composants** : Logique isolée de chaque composant React
- **Tests d'intégration** : Interaction entre composants et hooks
- **Tests E2E** : Parcours utilisateur complets

#### **Backend (Architecture en couches)**

- **Tests unitaires** : Couche métier (services/controllers)
- **Tests d'intégration** : Couche d'accès aux données (models + BDD)
- **Tests API** : Routes et middlewares

---

## 9.2. Tests unitaires

### 9.2.1. Frontend (React + TypeScript)

**Outil** : Vitest

### 9.2.2. Backend (Node.js + Express)

**Outil** : Jest

## 9.3. Tests d'intégration

### 9.3.1. Backend - Couche données

**Objectif** : Tester les models avec une vraie base de données de test

**Configuration** :

- Base MySQL de test dédiée
- Reset de la BDD avant chaque suite de tests
- Seed data pour tests reproductibles

### 9.3.2. Frontend - Interaction composants

**Outil** : Vitest + MSW (Mock Service Worker)

---

## 9.4. Tests API (End-to-End Backend)

**Outil** : Supertest

---

## 9.5. Tests End-to-End (E2E)

**Outil** : Playwright

## 9.6. Tests de sécurité

### 9.6.1. Tests automatisés

| Type | Outil | Objectif |
|------|-------|----------|
| **Injection SQL** | sqlmap | Tester toutes les routes avec paramètres |
| **XSS** | OWASP ZAP | Scanner formulaires et champs texte |
| **CSRF** | Tests manuels | Vérifier tokens sur actions sensibles |
| **Dépendances** | `npm audit` | Scan vulnérabilités packages |

### 9.6.2. Scénarios de test sécurité

- Tentative accès route protégée sans token → 401
- Token expiré → 401
- Modification bibliothèque d'un autre user → 403
- Upload fichier malveillant (avatar) → Rejet
- Brute force mot de passe → Rate limiting

---

## 9.7. Tests de performance

**Outil** : k6

---

# 10. JEU D'ESSAI

---

# 11. VEILLE SUR LES VULNÉRABILITÉS

---
