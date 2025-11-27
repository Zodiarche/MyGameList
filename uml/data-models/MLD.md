# MLD - Modèle Logique de Données

## MyGameList - Réseau Social de Collection de Jeux Vidéo

---

## Tables et Relations

### Table : USER_ACCOUNT

```sql
USER_ACCOUNT (
    user_id INT [PK],
    username VARCHAR(50) [UNIQUE, NOT NULL],
    email VARCHAR(255) [UNIQUE, NOT NULL],
    password VARCHAR(255) [NOT NULL],
    avatar VARCHAR(255),
    bio TEXT,
    registration_date DATETIME [NOT NULL, DEFAULT CURRENT_TIMESTAMP],
    role ENUM('member', 'administrator') [NOT NULL, DEFAULT 'member'],
    is_active BOOLEAN [NOT NULL, DEFAULT TRUE]
)
```

**Indexes:**

- PRIMARY KEY (user_id)
- UNIQUE INDEX idx_username (username)
- UNIQUE INDEX idx_email (email)
- INDEX idx_role (role)

---

### Table: GAME

```sql
GAME (
    game_id INT [PK],
    title VARCHAR(255) [NOT NULL],
    release_date DATE,
    metacritic INT [CHECK (metacritic >= 0 AND metacritic <= 100)],
    website VARCHAR(255),
    cover_image VARCHAR(255)
)
```

**Indexes:**

- PRIMARY KEY (game_id)
- INDEX idx_title (title)
- INDEX idx_release_date (release_date)

---

### Table : PLATFORM

```sql
PLATFORM (
    platform_id INT [PK],
    name VARCHAR(100) [UNIQUE, NOT NULL]
)
```

**Indexes:**

- PRIMARY KEY (platform_id)
- UNIQUE INDEX idx_name_platform (name)

---

### Table : GENRE

```sql
GENRE (
    genre_id INT [PK],
    name VARCHAR(50) [UNIQUE, NOT NULL]
)
```

**Indexes:**

- PRIMARY KEY (genre_id)
- UNIQUE INDEX idx_name_genre (name)

---

### Table : TAG

```sql
TAG (
    tag_id INT [PK],
    name VARCHAR(50) [UNIQUE, NOT NULL]
)
```

**Indexes:**

- PRIMARY KEY (tag_id)
- UNIQUE INDEX idx_name_tag (name)

---

### Table : DEVELOPER

```sql
DEVELOPER (
    developer_id INT [PK],
    name VARCHAR(100) [UNIQUE, NOT NULL]
)
```

**Indexes:**

- PRIMARY KEY (developer_id)
- UNIQUE INDEX idx_name_developer (name)

---

### Table : STORE

```sql
STORE (
    store_id INT [PK],
    name VARCHAR(100) [UNIQUE, NOT NULL],
    url VARCHAR(255) [COMMENT 'URL du magasin']
)
```

**Indexes:**

- PRIMARY KEY (store_id)
- UNIQUE INDEX idx_name_store (name)

---

### Table : PUBLISHER

```sql
PUBLISHER (
    publisher_id INT [PK],
    name VARCHAR(100) [UNIQUE, NOT NULL]
)
```

**Indexes:**

- PRIMARY KEY (publisher_id)
- UNIQUE INDEX idx_name_publisher (name)

---

### Table : LIBRARY

```sql
LIBRARY (
    library_id INT [PK],
    user_id INT [FK -> USER_ACCOUNT.user_id, NOT NULL],
    game_id INT [FK -> GAME.game_id, NOT NULL],
    status ENUM('to_play', 'playing', 'completed', 'abandoned') [NOT NULL, DEFAULT 'to_play'],
    added_at DATETIME [NOT NULL, DEFAULT CURRENT_TIMESTAMP],
    updated_at DATETIME,
    play_time INT [DEFAULT 0],
    owned_platform_id INT [FK -> PLATFORM.platform_id]
)
```

**Indexes:**

- PRIMARY KEY (library_id)
- INDEX idx_user (user_id)
- INDEX idx_game (game_id)
- UNIQUE INDEX idx_user_game (user_id, game_id)

**Constraints:**

- FOREIGN KEY (user_id) REFERENCES USER_ACCOUNT(user_id) ON DELETE CASCADE
- FOREIGN KEY (game_id) REFERENCES GAME(game_id) ON DELETE CASCADE
- FOREIGN KEY (owned_platform_id) REFERENCES PLATFORM(platform_id) ON DELETE SET NULL

---

### Table : RATING

```sql
RATING (
    rating_id INT [PK],
    user_id INT [FK -> USER_ACCOUNT.user_id, NOT NULL],
    game_id INT [FK -> GAME.game_id, NOT NULL],
    rating DECIMAL(3,1) [NOT NULL, CHECK (rating >= 0 AND rating <= 10)],
    created_at DATETIME [NOT NULL, DEFAULT CURRENT_TIMESTAMP],
    updated_at DATETIME
)
```

**Indexes:**

- PRIMARY KEY (rating_id)
- UNIQUE INDEX idx_user_game_rating (user_id, game_id)
- INDEX idx_game_rating (game_id)

**Constraints:**

- FOREIGN KEY (user_id) REFERENCES USER_ACCOUNT(user_id) ON DELETE CASCADE
- FOREIGN KEY (game_id) REFERENCES GAME(game_id) ON DELETE CASCADE
- UNIQUE (user_id, game_id) - Un utilisateur ne peut noter qu'une seule fois le même jeu
- CHECK (rating >= 0 AND rating <= 10)

---

### Table : GAME_COMMENT

```sql
GAME_COMMENT (
    comment_id INT [PK],
    user_id INT [FK -> USER_ACCOUNT.user_id, NOT NULL],
    game_id INT [FK -> GAME.game_id, NOT NULL],
    content TEXT [NOT NULL],
    created_at DATETIME [NOT NULL, DEFAULT CURRENT_TIMESTAMP],
    updated_at DATETIME
)
```

**Indexes:**

- PRIMARY KEY (comment_id)
- INDEX idx_user_game_comment (user_id)
- INDEX idx_game_game_comment (game_id)
- INDEX idx_created_at (created_at)
- FULLTEXT INDEX idx_fulltext_content (content)

**Constraints:**

- FOREIGN KEY (user_id) REFERENCES USER_ACCOUNT(user_id) ON DELETE CASCADE
- FOREIGN KEY (game_id) REFERENCES GAME(game_id) ON DELETE CASCADE

---

### Table : FRIENDSHIP

```sql
FRIENDSHIP (
    friendship_id INT [PK],
    requester_user_id INT [FK -> USER_ACCOUNT.user_id, NOT NULL],
    addressee_user_id INT [FK -> USER_ACCOUNT.user_id, NOT NULL],
    status ENUM('pending', 'accepted', 'rejected', 'blocked') [NOT NULL, DEFAULT 'pending'],
    requested_at DATETIME [NOT NULL, DEFAULT CURRENT_TIMESTAMP],
    responded_at DATETIME
)
```

**Indexes:**

- PRIMARY KEY (friendship_id)
- INDEX idx_requester (requester_user_id)
- INDEX idx_addressee (addressee_user_id)
- UNIQUE INDEX idx_friendship_unique (requester_user_id, addressee_user_id)
- INDEX idx_status (status)

**Constraints:**

- FOREIGN KEY (requester_user_id) REFERENCES USER_ACCOUNT(user_id) ON DELETE CASCADE
- FOREIGN KEY (addressee_user_id) REFERENCES USER_ACCOUNT(user_id) ON DELETE CASCADE
- CHECK (requester_user_id != addressee_user_id)

---

### Table : REPORT

```sql
REPORT (
    report_id INT [PK],
    reporter_user_id INT [FK -> USER_ACCOUNT.user_id, NOT NULL],
    content_type ENUM('comment', 'user') [NOT NULL],
    content_id INT [NOT NULL],
    reason VARCHAR(255) [NOT NULL],
    description TEXT,
    reported_at DATETIME [NOT NULL, DEFAULT CURRENT_TIMESTAMP],
    status ENUM('pending', 'processed', 'rejected') [NOT NULL, DEFAULT 'pending'],
    processed_at DATETIME,
    moderator_user_id INT [FK -> USER_ACCOUNT.user_id]
)
```

**Indexes:**

- PRIMARY KEY (report_id)
- INDEX idx_reporter (reporter_user_id)
- INDEX idx_content_type (content_type, content_id)
- INDEX idx_status_report (status)
- INDEX idx_moderator (moderator_user_id)

**Constraints:**

- FOREIGN KEY (reporter_user_id) REFERENCES USER_ACCOUNT(user_id) ON DELETE CASCADE
- FOREIGN KEY (moderator_user_id) REFERENCES USER_ACCOUNT(user_id) ON DELETE SET NULL

---

### Table : GAME_PLATFORM (Table d'Association)

```sql
GAME_PLATFORM (
    game_id INT [FK -> GAME.game_id, NOT NULL],
    platform_id INT [FK -> PLATFORM.platform_id, NOT NULL],
    platform_release_date DATE
)
```

**Indexes:**

- PRIMARY KEY (game_id, platform_id)
- INDEX idx_platform_game (platform_id)

**Constraints:**

- FOREIGN KEY (game_id) REFERENCES GAME(game_id) ON DELETE CASCADE
- FOREIGN KEY (platform_id) REFERENCES PLATFORM(platform_id) ON DELETE CASCADE

---

### Table : GAME_GENRE (Table d'Association)

```sql
GAME_GENRE (
    game_id INT [FK -> GAME.game_id, NOT NULL],
    genre_id INT [FK -> GENRE.genre_id, NOT NULL]
)
```

**Indexes:**

- PRIMARY KEY (game_id, genre_id)
- INDEX idx_genre_game (genre_id)

**Constraints:**

- FOREIGN KEY (game_id) REFERENCES GAME(game_id) ON DELETE CASCADE
- FOREIGN KEY (genre_id) REFERENCES GENRE(genre_id) ON DELETE CASCADE

---

### Table : GAME_TAG (Table d'Association)

```sql
GAME_TAG (
    game_id INT [FK -> GAME.game_id, NOT NULL],
    tag_id INT [FK -> TAG.tag_id, NOT NULL]
)
```

**Indexes:**

- PRIMARY KEY (game_id, tag_id)
- INDEX idx_tag_game (tag_id)

**Constraints:**

- FOREIGN KEY (game_id) REFERENCES GAME(game_id) ON DELETE CASCADE
- FOREIGN KEY (tag_id) REFERENCES TAG(tag_id) ON DELETE CASCADE

---

### Table : GAME_DEVELOPER (Table d'Association)

```sql
GAME_DEVELOPER (
    game_id INT [FK -> GAME.game_id, NOT NULL],
    developer_id INT [FK -> DEVELOPER.developer_id, NOT NULL]
)
```

**Indexes:**

- PRIMARY KEY (game_id, developer_id)
- INDEX idx_developer_game (developer_id)

**Constraints:**

- FOREIGN KEY (game_id) REFERENCES GAME(game_id) ON DELETE CASCADE
- FOREIGN KEY (developer_id) REFERENCES DEVELOPER(developer_id) ON DELETE CASCADE

---

### Table : GAME_STORE (Table d'Association)

```sql
GAME_STORE (
    game_id INT [FK -> GAME.game_id, NOT NULL],
    store_id INT [FK -> STORE.store_id, NOT NULL]
)
```

**Indexes:**

- PRIMARY KEY (game_id, store_id)
- INDEX idx_store_game (store_id)

**Constraints:**

- FOREIGN KEY (game_id) REFERENCES GAME(game_id) ON DELETE CASCADE
- FOREIGN KEY (store_id) REFERENCES STORE(store_id) ON DELETE CASCADE

---

### Table : GAME_PUBLISHER (Table d'Association)

```sql
GAME_PUBLISHER (
    game_id INT [FK -> GAME.game_id, NOT NULL],
    publisher_id INT [FK -> PUBLISHER.publisher_id, NOT NULL]
)
```

**Indexes:**

- PRIMARY KEY (game_id, publisher_id)
- INDEX idx_publisher_game (publisher_id)

**Constraints:**

- FOREIGN KEY (game_id) REFERENCES GAME(game_id) ON DELETE CASCADE
- FOREIGN KEY (publisher_id) REFERENCES PUBLISHER(publisher_id) ON DELETE CASCADE

---

## Schéma Relationnel Normalisé

Le modèle respecte la **3ème Forme Normale (3NF)** :

1. **1NF** : Tous les attributs sont atomiques
2. **2NF** : Pas de dépendance fonctionnelle partielle (toutes les clés sont simples ou les attributs dépendent de toute la clé)
3. **3NF** : Pas de dépendance fonctionnelle transitive

---

## Dépendances Fonctionnelles Principales

### USER_ACCOUNT

- user_id → username, email, password, avatar, bio, registration_date, role, is_active
- email → user_id
- username → user_id

### GAME

- game_id → title, release_date, metacritic, website, cover_image, platforms, developers, stores, genres, tags, publishers

### RATING

- (user_id, game_id) → rating, created_at, updated_at
- Un utilisateur ne peut noter qu'une seule fois un même jeu

### FRIENDSHIP

- (requester_user_id, addressee_user_id) → status, requested_at, responded_at

---

## Règles d'Intégrité

1. **Unicité** : Les emails et pseudos doivent être uniques
2. **Référence** : Toutes les clés étrangères doivent pointer vers des enregistrements existants
3. **Domaine** : Les notes doivent être comprises entre 0 et 10
4. **Cohérence** : Un utilisateur ne peut pas être ami avec lui-même
5. **Cascade** : La suppression d'un utilisateur supprime ses notes, commentaires et relations d'amitié
6. **Contrainte métier** : Un utilisateur ne peut noter qu'une seule fois le même jeu

---

## Diagramme des Dépendances

```
USER_ACCOUNT ──┬── LIBRARY ── GAME ──┬── GAME_PLATFORM ── PLATFORM
             │                     │
             ├── RATING ───────────├── GAME_GENRE ── GENRE
             │                     │
             ├── GAME_COMMENT ──────├── GAME_TAG ── TAG
             │                     │
             ├── FRIENDSHIP        ├── GAME_DEVELOPER ── DEVELOPER
             │    └── USER_ACCOUNT │
             │                     ├── GAME_STORE ── STORE
             └── REPORT            │
                  └── USER_ACCOUNT └── GAME_PUBLISHER ── PUBLISHER
```

---

## Optimisations

### Index Composites pour les Requêtes Fréquentes

- **LIBRARY** : (user_id, game_id) pour éviter les doublons
- **RATING** : (user_id, game_id) pour contrainte d'unicité
- **FRIENDSHIP** : (requester_user_id, addressee_user_id) pour unicité

### Index Simples pour les Recherches

- **GAME** : title, release_date, metacritic
- **GAME_COMMENT** : created_at (pour tri chronologique)
- **USER_ACCOUNT** : email, username, role

### Stratégies de Suppression

- **CASCADE** : Pour les données dépendantes (notes, commentaires, bibliothèque)
- **SET NULL** : Pour les références optionnelles (modérateur de signalement)
- **RESTRICT** : Empêcher la suppression si des références existent (peut être appliqué aux genres, plateformes)
