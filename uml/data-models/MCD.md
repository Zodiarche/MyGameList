# MCD - Modèle Conceptuel de Données

## MyGameList - Réseau Social de Collection de Jeux Vidéo

---

## Entités et Attributs

### 1. user_account

- **user_id** (PK)
- username
- email
- password (hashed)
- avatar
- bio
- registration_date
- role (member, administrator)
- is_active (boolean)
- deleted_at (soft delete)

### 2. game

- **game_id** (PK)
- title
- slug
- release_date
- metacritic
- website
- cover_image

### 3. platform

- **platform_id** (PK)
- name (PC, PlayStation 5, Xbox Series X, Nintendo Switch, etc.)

### 4. genre

- **genre_id** (PK)
- name (Action, RPG, Adventure, Strategy, Sport, etc.)

### 5. tag

- **tag_id** (PK)
- name (multiplayer, solo, coop, competitive, etc.)

### 6. developer

- **developer_id** (PK)
- name

### 7. store

- **store_id** (PK)
- name
- url

### 8. publisher

- **publisher_id** (PK)
- name

### 9. library

- **library_id** (PK)
- user_id (FK)
- game_id (FK)
- status (to_play, playing, completed, abandoned)
- added_at
- updated_at
- play_time (in hours)
- owned_platform_id (FK to PLATFORM)

### 10. rating

- **rating_id** (PK)
- user_id (FK)
- game_id (FK)
- rating (value from 0 to 10)
- created_at
- updated_at

### 11. game_comment

- **comment_id** (PK)
- user_id (FK)
- game_id (FK)
- content
- created_at
- updated_at
- deleted_at (soft delete)

### 12. friendship

- **friendship_id** (PK)
- requester_user_id (FK)
- addressee_user_id (FK)
- status (pending, accepted, rejected, blocked)
- requested_at
- responded_at

### 13. report

- **report_id** (PK)
- reporter_user_id (FK)
- content_type (comment, user)
- content_id (FK to COMMENT or USER)
- reason
- description
- reported_at
- status (pending, processed, rejected)
- processed_at
- moderator_user_id (FK to USER)

---

## Relations

### Relations Principales

#### USER_ACCOUNT ↔ GAME

- **OWNS** (via LIBRARY) : Un utilisateur peut posséder plusieurs jeux, un jeu peut être possédé par plusieurs utilisateurs (N:M)
- **RATES** : Un utilisateur peut noter plusieurs jeux, un jeu peut être noté par plusieurs utilisateurs (N:M)
- **COMMENTS** : Un utilisateur peut commenter plusieurs jeux, un jeu peut être commenté par plusieurs utilisateurs (N:M via GAME_COMMENT)

#### USER_ACCOUNT ↔ USER_ACCOUNT

- **IS_FRIEND_WITH** (via FRIENDSHIP) : Un utilisateur peut avoir plusieurs amis (N:M avec statut)

#### GAME ↔ PLATFORM

- **AVAILABLE_ON** (via GAME_PLATFORM) : Un jeu peut être disponible sur plusieurs plateformes, une plateforme peut héberger plusieurs jeux (N:M)
  - Attribut de l'association : `platform_release_date` (date de sortie spécifique à la plateforme)

#### GAME ↔ DEVELOPERS

- **DEVELOPED_BY** : Un jeu peut être développé par plusieurs développeurs, un développeur peut développer plusieurs jeux (N:M)

#### GAME ↔ GENRE

- **BELONGS_TO** : Un jeu peut appartenir à plusieurs genres, un genre peut contenir plusieurs jeux (N:M)

#### GAME ↔ TAG

- **HAS_TAG** : Un jeu peut avoir plusieurs tags, un tag peut être associé à plusieurs jeux (N:M)

#### GAME ↔ STORES

- **AVAILABLE_IN** : Un jeu peut être disponible dans plusieurs magasins, un magasin peut proposer plusieurs jeux (N:M)

#### GAME ↔ PUBLISHERS

- **PUBLISHED_BY** : Un jeu peut être publié par plusieurs éditeurs, un éditeur peut publier plusieurs jeux (N:M)

#### USER_ACCOUNT → REPORT

- **REPORTS** : Un utilisateur peut faire plusieurs signalements (1:N)
- **IS_REPORTED** : Un utilisateur peut être signalé plusieurs fois (1:N)

#### USER_ACCOUNT → GAME_COMMENT

- **MODERATES** : Un administrateur peut modérer plusieurs commentaires (1:N)

---

## Cardinalités Détaillées

### USER_ACCOUNT - LIBRARY - GAME

- USER_ACCOUNT (1,N) ── possède ── (0,N) LIBRARY
- GAME (1,1) ── est dans ── (0,N) LIBRARY

### USER_ACCOUNT - RATING - GAME

- USER_ACCOUNT (1,1) ── attribue ── (0,N) RATING
- GAME (1,1) ── reçoit ── (0,N) RATING
- Contrainte : Un utilisateur ne peut noter qu'une seule fois un même jeu

### USER_ACCOUNT - GAME_COMMENT - GAME

- USER_ACCOUNT (1,1) ── écrit ── (0,N) GAME_COMMENT
- GAME (1,1) ── reçoit ── (0,N) GAME_COMMENT

### USER_ACCOUNT - FRIENDSHIP - USER_ACCOUNT

- USER_ACCOUNT (1,1) ── demande ── (0,N) FRIENDSHIP
- USER_ACCOUNT (1,1) ── reçoit ── (0,N) FRIENDSHIP

### GAME - PLATFORM

- GAME (0,N) ── disponible sur ── (1,N) PLATFORM
- Table d'association : GAME_PLATFORM

### GAME - GENRE

- GAME (0,N) ── appartient à ── (1,N) GENRE
- Table d'association : GAME_GENRE

### GAME - TAG

- GAME (0,N) ── possède ── (0,N) TAG
- Table d'association : GAME_TAG

GAME_DEVELOPER

---

## Règles de Gestion

1. Un utilisateur doit avoir un email et un pseudo uniques
2. Un utilisateur ne peut noter qu'une seule fois un même jeu
3. Un utilisateur ne peut pas s'ajouter lui-même en ami
4. Une demande d'amitié ne peut être acceptée que par le destinataire
5. Un commentaire peut être modéré par n'importe quel administrateur
6. Un jeu doit avoir au moins un titre et peut avoir des informations optionnelles (genres, plateformes, développeurs, éditeurs, magasins)
7. Une note doit être comprise dans une échelle définie (ex: 0-10)
8. Un signalement doit avoir un motif
9. Seuls les membres peuvent ajouter des jeux à leur bibliothèque, noter ou commenter
10. Les visiteurs peuvent consulter les jeux et classements mais pas interagir
11. Un utilisateur ne peut signaler qu'une seule fois le même contenu
12. Les données personnelles sont protégées selon le RGPD
13. Les informations de jeu (platforms, developers, stores, genres, tags, publishers) sont gérées via des tables d'association normalisées
14. Le score Metacritic doit être compris entre 0 et 100 s'il est renseigné
15. Les tables PLATFORM, GENRE, TAG, DEVELOPER, STORE et PUBLISHER servent de référentiels pour la normalisation et les filtres

---

## Contraintes d'Intégrité

- **Intégrité d'entité** : Chaque entité possède une clé primaire unique et non nulle
- **Intégrité référentielle** : Toutes les clés étrangères doivent référencer des enregistrements existants
- **Intégrité de domaine** : Les attributs doivent respecter leurs types et contraintes (ex: email valide, note dans l'intervalle)
- **Contraintes métier** :
  - Pas de doublon utilisateur-jeu dans les notes
  - Statut d'amitié contrôlé
  - Rôles hiérarchiques respectés

---

## Diagramme Conceptuel

```text
┌──────────────┐          ┌──────────────┐              ┌──────────┐
│ USER_ACCOUNT │──┐    ┌──│   LIBRARY    │──────────────│   GAME   │
└──────────────┘  │    │  └──────────────┘              └──────────┘
       │      │        │                                      │
       │      │        │  ┌──────────────┐                   │
       │      └────────┼──│    RATING    │───────────────────┤
       │               │  └──────────────┘                   │
       │               │                                     │
       │               │  ┌──────────────┐                   │
       │               └──│ GAME_COMMENT │───────────────────┤
       │                  └──────────────┘                   │
       │                                                     │
       │         ┌──────────────┐                            │
       └─────────│  FRIENDSHIP  │                            │
       └─────────│              │                            │
                 └──────────────┘                            │
                                                             │
       ┌─────────────┐                                       │
       │   REPORT    │                                       │
       └─────────────┘                                       │
                                                             │
       ┌─────────────┐         ┌──────────────┐             │
       │  PLATFORM   │─────────│GAME_PLATFORM │─────────────┤
       └─────────────┘         └──────────────┘             │
                                                             │
       ┌─────────────┐         ┌──────────────┐             │
       │    GENRE    │─────────│ GAME_GENRE   │─────────────┤
       └─────────────┘         └──────────────┘             │
                                                             │
       ┌─────────────┐         ┌──────────────┐             │
       │     TAG     │─────────│  GAME_TAG    │─────────────┤
       └─────────────┘         └──────────────┘             │
                                                             │
       ┌─────────────┐         ┌──────────────┐             │
       │  DEVELOPER  │─────────│GAME_DEVELOPER│─────────────┤
       └─────────────┘         └──────────────┘             │
                                                             │
       ┌─────────────┐         ┌──────────────┐             │
       │  PUBLISHER  │─────────│GAME_PUBLISHER│─────────────┤
       └─────────────┘         └──────────────┘             │
                                                             │
       ┌─────────────┐         ┌──────────────┐             │
       │    STORE    │─────────│  GAME_STORE  │─────────────┘
       └─────────────┘         └──────────────┘
```

---

## Fonctions Stockées

### Gestion de la bibliothèque et des notes

- `sp_add_game_to_library(p_user_id, p_game_id, p_status, p_platform_id)` : Ajouter un jeu à la bibliothèque
- `sp_rate_game(p_user_id, p_game_id, p_rating)` : Noter un jeu

### Gestion des amitiés

- `sp_accept_friendship_request(p_friendship_id, p_addressee_user_id)` : Accepter une demande d'amitié

### Gestion des suppressions logiques

- `sp_soft_delete_user(p_user_id)` : Suppression logique d'un utilisateur
- `sp_soft_delete_comment(p_comment_id, p_user_id)` : Suppression logique d'un commentaire (propriétaire ou administrateur)
- `sp_restore_user(p_user_id)` : Restauration d'un utilisateur supprimé
- `sp_restore_comment(p_comment_id)` : Restauration d'un commentaire supprimé

---

## Triggers

### Validation des données

- `trg_friendship_no_self` : Empêche un utilisateur de s'ajouter lui-même en ami
- `trg_rating_validate` : Valide que les notes sont comprises entre 0 et 10
- `trg_game_metacritic_validate` : Valide que le score Metacritic est compris entre 0 et 100

### Vérification des rôles

- `trg_verify_moderator_report` : Vérifie que seul un administrateur peut modérer un signalement

### Mise à jour automatique

- `trg_library_updated_at` : Met à jour automatiquement `updated_at` dans `library`
- `trg_rating_updated_at` : Met à jour automatiquement `updated_at` dans `rating`
- `trg_game_comment_updated_at` : Met à jour automatiquement `updated_at` dans `game_comment`
