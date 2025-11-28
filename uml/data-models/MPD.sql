-- ============================================
-- MPD - Modèle Physique de Données
-- MyGameList - Réseau Social de Collection de Jeux Vidéo
-- SGBD : PostgreSQL 16+
-- ============================================

-- Note: Ce script utilise la syntaxe \c qui nécessite psql
-- Si exécuté via Docker, la base sera créée automatiquement

-- ============================================
-- TYPES ENUM PERSONNALISÉS
-- ============================================

CREATE TYPE user_role AS ENUM ('member', 'administrator');
CREATE TYPE library_status AS ENUM ('to_play', 'playing', 'completed', 'abandoned');
CREATE TYPE friendship_status AS ENUM ('pending', 'accepted', 'rejected', 'blocked');
CREATE TYPE report_content_type AS ENUM ('comment', 'user');
CREATE TYPE report_status AS ENUM ('pending', 'processed', 'rejected');

-- ============================================
-- Table: USER_ACCOUNT
-- ============================================

CREATE TABLE user_account (
    user_id SERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL, -- Bcrypt hash of password
    avatar VARCHAR(255) DEFAULT NULL, -- Avatar URL
    bio TEXT DEFAULT NULL,
    registration_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    role user_role NOT NULL DEFAULT 'member',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    deleted_at TIMESTAMP DEFAULT NULL -- Date de suppression (soft delete)
);

CREATE INDEX idx_username ON user_account(username);
CREATE INDEX idx_email ON user_account(email);
CREATE INDEX idx_role ON user_account(role);
CREATE INDEX idx_is_active ON user_account(is_active);
CREATE INDEX idx_deleted_at ON user_account(deleted_at);

COMMENT ON TABLE user_account IS 'Table des utilisateurs';

-- ============================================
-- Table: GAME
-- ============================================

CREATE TABLE game (
    game_id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    slug VARCHAR(255) NOT NULL UNIQUE, -- URL SEO-friendly
    release_date DATE DEFAULT NULL,
    metacritic INTEGER DEFAULT NULL CHECK (metacritic IS NULL OR (metacritic >= 0 AND metacritic <= 100)), -- Score Metacritic (0-100)
    website VARCHAR(255) DEFAULT NULL, -- Site web officiel du jeu
    cover_image VARCHAR(255) DEFAULT NULL -- URL de l'image de couverture
);

CREATE INDEX idx_title ON game(title);
CREATE INDEX idx_slug ON game(slug);
CREATE INDEX idx_release_date ON game(release_date);
CREATE INDEX idx_metacritic ON game(metacritic);
CREATE INDEX idx_game_title_fulltext ON game USING gin(to_tsvector('english', title));

COMMENT ON TABLE game IS 'Table des jeux vidéo';

-- ============================================
-- Table: PLATFORM
-- ============================================

CREATE TABLE platform (
    platform_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE
);

CREATE INDEX idx_name_platform ON platform(name);

COMMENT ON TABLE platform IS 'Table des plateformes de jeu';

-- ============================================
-- Table: GENRE
-- ============================================

CREATE TABLE genre (
    genre_id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE
);

CREATE INDEX idx_name_genre ON genre(name);

COMMENT ON TABLE genre IS 'Table des genres de jeux';

-- ============================================
-- Table: TAG
-- ============================================

CREATE TABLE tag (
    tag_id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE
);

CREATE INDEX idx_name_tag ON tag(name);

COMMENT ON TABLE tag IS 'Table des tags de jeux';

-- ============================================
-- Table: DEVELOPER
-- ============================================

CREATE TABLE developer (
    developer_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE
);

CREATE INDEX idx_name_developer ON developer(name);

COMMENT ON TABLE developer IS 'Table des développeurs de jeux';

-- ============================================
-- Table: STORE
-- ============================================

CREATE TABLE store (
    store_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    url VARCHAR(255) DEFAULT NULL -- URL du magasin
);

CREATE INDEX idx_name_store ON store(name);

COMMENT ON TABLE store IS 'Table des magasins de jeux';

-- ============================================
-- Table: PUBLISHER
-- ============================================

CREATE TABLE publisher (
    publisher_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE
);

CREATE INDEX idx_name_publisher ON publisher(name);

COMMENT ON TABLE publisher IS 'Table des éditeurs de jeux';

-- ============================================
-- Table: LIBRARY
-- ============================================

CREATE TABLE library (
    library_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    game_id INTEGER NOT NULL,
    status library_status NOT NULL DEFAULT 'to_play',
    added_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT NULL,
    play_time INTEGER DEFAULT 0 CHECK (play_time >= 0), -- Temps de jeu en heures
    owned_platform_id INTEGER DEFAULT NULL, -- Plateforme sur laquelle l'utilisateur possède le jeu

    CONSTRAINT fk_library_user
        FOREIGN KEY (user_id) REFERENCES user_account(user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_library_game
        FOREIGN KEY (game_id) REFERENCES game(game_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_library_platform
        FOREIGN KEY (owned_platform_id) REFERENCES platform(platform_id)
        ON DELETE SET NULL
        ON UPDATE CASCADE,

    UNIQUE (user_id, game_id)
);

CREATE INDEX idx_user ON library(user_id);
CREATE INDEX idx_game ON library(game_id);
CREATE INDEX idx_status ON library(status);
CREATE INDEX idx_owned_platform ON library(owned_platform_id);
CREATE INDEX idx_library_user_status ON library(user_id, status);

COMMENT ON TABLE library IS 'Table des bibliothèques personnelles';

-- ============================================
-- Table: RATING
-- ============================================

CREATE TABLE rating (
    rating_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    game_id INTEGER NOT NULL,
    rating NUMERIC(3,1) NOT NULL CHECK (rating >= 0 AND rating <= 10), -- Note entre 0.0 et 10.0
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT NULL,

    CONSTRAINT fk_rating_user
        FOREIGN KEY (user_id) REFERENCES user_account(user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_rating_game
        FOREIGN KEY (game_id) REFERENCES game(game_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    UNIQUE (user_id, game_id)
);

CREATE INDEX idx_user_rating ON rating(user_id);
CREATE INDEX idx_game_rating ON rating(game_id);
CREATE INDEX idx_rating_value ON rating(rating);

COMMENT ON TABLE rating IS 'Table des notes attribuées aux jeux';

-- ============================================
-- Table: GAME_COMMENT
-- ============================================

CREATE TABLE game_comment (
    comment_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    game_id INTEGER NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT NULL,
    deleted_at TIMESTAMP DEFAULT NULL, -- Date de suppression (soft delete)

    CONSTRAINT fk_game_comment_user
        FOREIGN KEY (user_id) REFERENCES user_account(user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_game_comment_game
        FOREIGN KEY (game_id) REFERENCES game(game_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE INDEX idx_user_comment ON game_comment(user_id);
CREATE INDEX idx_game_comment ON game_comment(game_id);
CREATE INDEX idx_created_at ON game_comment(created_at DESC);
CREATE INDEX idx_deleted_at_comment ON game_comment(deleted_at);
CREATE INDEX idx_game_comment_game_date ON game_comment(game_id, created_at DESC);

-- Index full-text search
CREATE INDEX idx_fulltext_content ON game_comment USING gin(to_tsvector('french', content));

COMMENT ON TABLE game_comment IS 'Table des commentaires sur les jeux';

-- ============================================
-- Table: FRIENDSHIP
-- ============================================

CREATE TABLE friendship (
    friendship_id SERIAL PRIMARY KEY,
    requester_user_id INTEGER NOT NULL,
    addressee_user_id INTEGER NOT NULL,
    status friendship_status NOT NULL DEFAULT 'pending',
    requested_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    responded_at TIMESTAMP DEFAULT NULL,

    CONSTRAINT fk_friendship_requester
        FOREIGN KEY (requester_user_id) REFERENCES user_account(user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_friendship_addressee
        FOREIGN KEY (addressee_user_id) REFERENCES user_account(user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    UNIQUE (requester_user_id, addressee_user_id)
);

CREATE INDEX idx_requester ON friendship(requester_user_id);
CREATE INDEX idx_addressee ON friendship(addressee_user_id);
CREATE INDEX idx_status_friendship ON friendship(status);
CREATE INDEX idx_friendship_requester_status ON friendship(requester_user_id, status);
CREATE INDEX idx_friendship_addressee_status ON friendship(addressee_user_id, status);

COMMENT ON TABLE friendship IS 'Table des relations d''amitié';

-- ============================================
-- TRIGGERS : Validation auto-amitié
-- ============================================

CREATE OR REPLACE FUNCTION trg_friendship_no_self()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.requester_user_id = NEW.addressee_user_id THEN
        RAISE EXCEPTION 'Cannot add yourself as friend';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_friendship_no_self_insert
    BEFORE INSERT ON friendship
    FOR EACH ROW
    EXECUTE FUNCTION trg_friendship_no_self();

CREATE TRIGGER trg_friendship_no_self_update
    BEFORE UPDATE ON friendship
    FOR EACH ROW
    EXECUTE FUNCTION trg_friendship_no_self();

-- ============================================
-- TRIGGERS : Validation notes (rating)
-- ============================================

CREATE OR REPLACE FUNCTION trg_rating_validate()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.rating < 0 OR NEW.rating > 10 THEN
        RAISE EXCEPTION 'Rating must be between 0 and 10';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_rating_validate_insert
    BEFORE INSERT ON rating
    FOR EACH ROW
    EXECUTE FUNCTION trg_rating_validate();

CREATE TRIGGER trg_rating_validate_update
    BEFORE UPDATE ON rating
    FOR EACH ROW
    EXECUTE FUNCTION trg_rating_validate();

-- ============================================
-- TRIGGERS : Validation score Metacritic
-- ============================================

CREATE OR REPLACE FUNCTION trg_game_metacritic_validate()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.metacritic IS NOT NULL AND (NEW.metacritic < 0 OR NEW.metacritic > 100) THEN
        RAISE EXCEPTION 'Metacritic score must be between 0 and 100';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_game_metacritic_insert
    BEFORE INSERT ON game
    FOR EACH ROW
    EXECUTE FUNCTION trg_game_metacritic_validate();

CREATE TRIGGER trg_game_metacritic_update
    BEFORE UPDATE ON game
    FOR EACH ROW
    EXECUTE FUNCTION trg_game_metacritic_validate();

-- ============================================
-- Table: REPORT
-- ============================================

CREATE TABLE report (
    report_id SERIAL PRIMARY KEY,
    reporter_user_id INTEGER NOT NULL,
    content_type report_content_type NOT NULL,
    content_id INTEGER NOT NULL, -- ID du commentaire ou de l'utilisateur signalé
    reason VARCHAR(255) NOT NULL,
    description TEXT DEFAULT NULL,
    reported_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status report_status NOT NULL DEFAULT 'pending',
    processed_at TIMESTAMP DEFAULT NULL,
    moderator_user_id INTEGER DEFAULT NULL, -- Administrateur ayant traité le signalement

    CONSTRAINT fk_report_reporter
        FOREIGN KEY (reporter_user_id) REFERENCES user_account(user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_report_moderator
        FOREIGN KEY (moderator_user_id) REFERENCES user_account(user_id)
        ON DELETE SET NULL
        ON UPDATE CASCADE
);

CREATE INDEX idx_reporter ON report(reporter_user_id);
CREATE INDEX idx_moderator ON report(moderator_user_id);
CREATE INDEX idx_content_type ON report(content_type, content_id);
CREATE INDEX idx_status_report ON report(status);
CREATE INDEX idx_reported_at ON report(reported_at DESC);

COMMENT ON TABLE report IS 'Table des signalements de contenu';

-- ============================================
-- Table: GAME_PLATFORM (Association)
-- ============================================

CREATE TABLE game_platform (
    game_id INTEGER NOT NULL,
    platform_id INTEGER NOT NULL,
    platform_release_date DATE DEFAULT NULL, -- Date de sortie spécifique à cette plateforme

    PRIMARY KEY (game_id, platform_id),

    CONSTRAINT fk_game_platform_game
        FOREIGN KEY (game_id) REFERENCES game(game_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_game_platform_platform
        FOREIGN KEY (platform_id) REFERENCES platform(platform_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE INDEX idx_game_platform ON game_platform(game_id);
CREATE INDEX idx_platform_game ON game_platform(platform_id);

COMMENT ON TABLE game_platform IS 'Association Jeux-Plateformes';

-- ============================================
-- Table: GAME_GENRE (Association)
-- ============================================

CREATE TABLE game_genre (
    game_id INTEGER NOT NULL,
    genre_id INTEGER NOT NULL,

    PRIMARY KEY (game_id, genre_id),

    CONSTRAINT fk_game_genre_game
        FOREIGN KEY (game_id) REFERENCES game(game_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_game_genre_genre
        FOREIGN KEY (genre_id) REFERENCES genre(genre_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE INDEX idx_game_genre ON game_genre(game_id);
CREATE INDEX idx_genre_game ON game_genre(genre_id);

COMMENT ON TABLE game_genre IS 'Association Jeux-Genres';

-- ============================================
-- Table: GAME_TAG (Association)
-- ============================================

CREATE TABLE game_tag (
    game_id INTEGER NOT NULL,
    tag_id INTEGER NOT NULL,

    PRIMARY KEY (game_id, tag_id),

    CONSTRAINT fk_game_tag_game
        FOREIGN KEY (game_id) REFERENCES game(game_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_game_tag_tag
        FOREIGN KEY (tag_id) REFERENCES tag(tag_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE INDEX idx_game_tag ON game_tag(game_id);
CREATE INDEX idx_tag_game ON game_tag(tag_id);

COMMENT ON TABLE game_tag IS 'Association Jeux-Tags';

-- ============================================
-- Table: GAME_DEVELOPER (Association)
-- ============================================

CREATE TABLE game_developer (
    game_id INTEGER NOT NULL,
    developer_id INTEGER NOT NULL,

    PRIMARY KEY (game_id, developer_id),

    CONSTRAINT fk_game_developer_game
        FOREIGN KEY (game_id) REFERENCES game(game_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_game_developer_developer
        FOREIGN KEY (developer_id) REFERENCES developer(developer_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE INDEX idx_game_developer ON game_developer(game_id);
CREATE INDEX idx_developer_game ON game_developer(developer_id);

COMMENT ON TABLE game_developer IS 'Association Jeux-Développeurs';

-- ============================================
-- Table: GAME_STORE (Association)
-- ============================================

CREATE TABLE game_store (
    game_id INTEGER NOT NULL,
    store_id INTEGER NOT NULL,

    PRIMARY KEY (game_id, store_id),

    CONSTRAINT fk_game_store_game
        FOREIGN KEY (game_id) REFERENCES game(game_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_game_store_store
        FOREIGN KEY (store_id) REFERENCES store(store_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE INDEX idx_game_store ON game_store(game_id);
CREATE INDEX idx_store_game ON game_store(store_id);

COMMENT ON TABLE game_store IS 'Association Jeux-Magasins';

-- ============================================
-- Table: GAME_PUBLISHER (Association)
-- ============================================

CREATE TABLE game_publisher (
    game_id INTEGER NOT NULL,
    publisher_id INTEGER NOT NULL,

    PRIMARY KEY (game_id, publisher_id),

    CONSTRAINT fk_game_publisher_game
        FOREIGN KEY (game_id) REFERENCES game(game_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_game_publisher_publisher
        FOREIGN KEY (publisher_id) REFERENCES publisher(publisher_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE INDEX idx_game_publisher ON game_publisher(game_id);
CREATE INDEX idx_publisher_game ON game_publisher(publisher_id);

COMMENT ON TABLE game_publisher IS 'Association Jeux-Éditeurs';

-- ============================================
-- VUES UTILES
-- ============================================

-- Vue : Statistiques des jeux
CREATE OR REPLACE VIEW view_game_statistics AS
SELECT
    g.game_id,
    g.title,
    COUNT(DISTINCT CASE WHEN u_r.deleted_at IS NULL THEN r.user_id END) AS rating_count,
    ROUND(AVG(CASE WHEN u_r.deleted_at IS NULL THEN r.rating END)::numeric, 1) AS average_rating,
    COUNT(DISTINCT CASE WHEN gc.deleted_at IS NULL THEN gc.comment_id END) AS comment_count,
    COUNT(DISTINCT CASE WHEN u_l.deleted_at IS NULL THEN l.user_id END) AS owner_count
FROM game g
LEFT JOIN rating r ON g.game_id = r.game_id
LEFT JOIN user_account u_r ON r.user_id = u_r.user_id
LEFT JOIN game_comment gc ON g.game_id = gc.game_id
LEFT JOIN library l ON g.game_id = l.game_id
LEFT JOIN user_account u_l ON l.user_id = u_l.user_id
GROUP BY g.game_id, g.title;

-- Vue : Classement des jeux
CREATE OR REPLACE VIEW view_game_ranking AS
SELECT
    g.game_id,
    g.title,
    g.cover_image,
    ROUND(AVG(r.rating)::numeric, 1) AS average_rating,
    COUNT(r.rating_id) AS rating_count
FROM game g
INNER JOIN rating r ON g.game_id = r.game_id
INNER JOIN user_account u ON r.user_id = u.user_id AND u.deleted_at IS NULL
GROUP BY g.game_id, g.title, g.cover_image
HAVING COUNT(r.rating_id) >= 5
ORDER BY average_rating DESC, rating_count DESC;

-- Vue : Amis d'un utilisateur
CREATE OR REPLACE VIEW view_friends AS
SELECT
    f.requester_user_id AS user_id,
    f.addressee_user_id AS friend_id,
    u.username AS friend_username,
    u.avatar AS friend_avatar,
    u.bio AS friend_bio,
    f.responded_at AS friendship_date
FROM friendship f
INNER JOIN user_account u ON f.addressee_user_id = u.user_id AND u.deleted_at IS NULL
INNER JOIN user_account u_req ON f.requester_user_id = u_req.user_id AND u_req.deleted_at IS NULL
WHERE f.status = 'accepted'
UNION
SELECT
    f.addressee_user_id AS user_id,
    f.requester_user_id AS friend_id,
    u.username AS friend_username,
    u.avatar AS friend_avatar,
    u.bio AS friend_bio,
    f.responded_at AS friendship_date
FROM friendship f
INNER JOIN user_account u ON f.requester_user_id = u.user_id AND u.deleted_at IS NULL
INNER JOIN user_account u_addr ON f.addressee_user_id = u_addr.user_id AND u_addr.deleted_at IS NULL
WHERE f.status = 'accepted';

-- Vue : Commentaires avec auteur et jeu
CREATE OR REPLACE VIEW view_comment_with_author AS
SELECT
    gc.comment_id,
    gc.game_id,
    gc.user_id,
    gc.content,
    gc.created_at,
    gc.updated_at,
    gc.deleted_at,
    u.username AS author_username,
    u.avatar AS author_avatar,
    u.is_active AS author_is_active,
    g.title AS game_title,
    g.slug AS game_slug,
    g.cover_image AS game_cover
FROM game_comment gc
INNER JOIN user_account u ON gc.user_id = u.user_id
INNER JOIN game g ON gc.game_id = g.game_id
WHERE gc.deleted_at IS NULL
  AND u.deleted_at IS NULL;

-- Vue : Demandes d'amitié en attente
CREATE OR REPLACE VIEW view_friendship_pending_requests AS
SELECT
    f.friendship_id,
    f.requester_user_id,
    f.addressee_user_id,
    f.requested_at,
    u_req.username AS requester_username,
    u_req.avatar AS requester_avatar,
    u_req.bio AS requester_bio,
    u_addr.username AS addressee_username
FROM friendship f
INNER JOIN user_account u_req ON f.requester_user_id = u_req.user_id AND u_req.deleted_at IS NULL
INNER JOIN user_account u_addr ON f.addressee_user_id = u_addr.user_id AND u_addr.deleted_at IS NULL
WHERE f.status = 'pending';

-- Vue : Statistiques de bibliothèque utilisateur
CREATE OR REPLACE VIEW view_user_library_stats AS
SELECT
    l.user_id,
    COUNT(*) AS total_games,
    COUNT(*) FILTER (WHERE l.status = 'to_play') AS to_play_count,
    COUNT(*) FILTER (WHERE l.status = 'playing') AS playing_count,
    COUNT(*) FILTER (WHERE l.status = 'completed') AS completed_count,
    COUNT(*) FILTER (WHERE l.status = 'abandoned') AS abandoned_count,
    COALESCE(SUM(l.play_time), 0) AS total_play_time
FROM library l
INNER JOIN user_account u ON l.user_id = u.user_id AND u.deleted_at IS NULL
GROUP BY l.user_id;

-- Vue : Signalements avec détails
CREATE OR REPLACE VIEW view_report_with_details AS
SELECT
    r.report_id,
    r.content_type,
    r.content_id,
    r.reason,
    r.description,
    r.reported_at,
    r.status,
    r.processed_at,
    r.reporter_user_id,
    u_reporter.username AS reporter_username,
    u_reporter.email AS reporter_email,
    r.moderator_user_id,
    u_mod.username AS moderator_username
FROM report r
INNER JOIN user_account u_reporter ON r.reporter_user_id = u_reporter.user_id
LEFT JOIN user_account u_mod ON r.moderator_user_id = u_mod.user_id;

-- Vue : Bibliothèque enrichie
CREATE OR REPLACE VIEW view_enriched_library AS
SELECT
    l.library_id,
    l.user_id,
    l.game_id,
    g.title,
    g.cover_image,
    l.status,
    l.added_at,
    l.play_time,
    p.name AS platform,
    r.rating AS my_rating,
    ROUND(AVG(CASE WHEN u_r2.deleted_at IS NULL THEN r2.rating END)::numeric, 1) AS community_average_rating
FROM library l
INNER JOIN user_account u ON l.user_id = u.user_id AND u.deleted_at IS NULL
INNER JOIN game g ON l.game_id = g.game_id
LEFT JOIN platform p ON l.owned_platform_id = p.platform_id
LEFT JOIN rating r ON l.user_id = r.user_id AND l.game_id = r.game_id
LEFT JOIN rating r2 ON l.game_id = r2.game_id
LEFT JOIN user_account u_r2 ON r2.user_id = u_r2.user_id
GROUP BY l.library_id, l.user_id, l.game_id, g.title, g.cover_image,
         l.status, l.added_at, l.play_time, p.name, r.rating;

-- Vue : Détails complets d'un jeu (optimisation N+1)
CREATE OR REPLACE VIEW view_game_complete_details AS
SELECT
    g.game_id,
    g.title,
    g.cover_image,
    g.release_date,
    g.metacritic,
    g.website,
    -- Plateformes (agrégées en JSON)
    COALESCE(
        json_agg(
            DISTINCT jsonb_build_object('platform_id', p.platform_id, 'name', p.name)
        ) FILTER (WHERE p.platform_id IS NOT NULL),
        '[]'::json
    ) AS platforms,
    -- Genres (agrégés en JSON)
    COALESCE(
        json_agg(
            DISTINCT jsonb_build_object('genre_id', gen.genre_id, 'name', gen.name)
        ) FILTER (WHERE gen.genre_id IS NOT NULL),
        '[]'::json
    ) AS genres,
    -- Tags (agrégés en JSON)
    COALESCE(
        json_agg(
            DISTINCT jsonb_build_object('tag_id', t.tag_id, 'name', t.name)
        ) FILTER (WHERE t.tag_id IS NOT NULL),
        '[]'::json
    ) AS tags,
    -- Développeurs (agrégés en JSON)
    COALESCE(
        json_agg(
            DISTINCT jsonb_build_object('developer_id', d.developer_id, 'name', d.name)
        ) FILTER (WHERE d.developer_id IS NOT NULL),
        '[]'::json
    ) AS developers,
    -- Éditeurs (agrégés en JSON)
    COALESCE(
        json_agg(
            DISTINCT jsonb_build_object('publisher_id', pub.publisher_id, 'name', pub.name)
        ) FILTER (WHERE pub.publisher_id IS NOT NULL),
        '[]'::json
    ) AS publishers,
    -- Statistiques de notation
    ROUND(AVG(CASE WHEN u_r.deleted_at IS NULL THEN r.rating END)::numeric, 1) AS average_rating,
    COUNT(DISTINCT CASE WHEN u_r.deleted_at IS NULL THEN r.rating_id END) AS rating_count,
    -- Nombre de commentaires
    COUNT(DISTINCT CASE WHEN gc.deleted_at IS NULL THEN gc.comment_id END) AS comment_count
FROM game g
LEFT JOIN game_platform gp ON g.game_id = gp.game_id
LEFT JOIN platform p ON gp.platform_id = p.platform_id
LEFT JOIN game_genre gg ON g.game_id = gg.game_id
LEFT JOIN genre gen ON gg.genre_id = gen.genre_id
LEFT JOIN game_tag gt ON g.game_id = gt.game_id
LEFT JOIN tag t ON gt.tag_id = t.tag_id
LEFT JOIN game_developer gd ON g.game_id = gd.game_id
LEFT JOIN developer d ON gd.developer_id = d.developer_id
LEFT JOIN game_publisher gpr ON g.game_id = gpr.game_id
LEFT JOIN publisher pub ON gpr.publisher_id = pub.publisher_id
LEFT JOIN rating r ON g.game_id = r.game_id
LEFT JOIN user_account u_r ON r.user_id = u_r.user_id
LEFT JOIN game_comment gc ON g.game_id = gc.game_id
GROUP BY g.game_id, g.title, g.cover_image, g.release_date, g.metacritic, g.website;

-- ============================================
-- FONCTIONS STOCKÉES
-- ============================================

-- Fonction : Ajouter un jeu à la bibliothèque
CREATE OR REPLACE FUNCTION sp_add_game_to_library(
    p_user_id INTEGER,
    p_game_id INTEGER,
    p_status library_status,
    p_platform_id INTEGER
)
RETURNS VOID AS $$
BEGIN
    INSERT INTO library (user_id, game_id, status, owned_platform_id)
    VALUES (p_user_id, p_game_id, p_status, p_platform_id)
    ON CONFLICT (user_id, game_id) DO UPDATE SET
        status = EXCLUDED.status,
        owned_platform_id = EXCLUDED.owned_platform_id,
        updated_at = CURRENT_TIMESTAMP;
END;
$$ LANGUAGE plpgsql;

-- Fonction : Noter un jeu
CREATE OR REPLACE FUNCTION sp_rate_game(
    p_user_id INTEGER,
    p_game_id INTEGER,
    p_rating NUMERIC(3,1)
)
RETURNS VOID AS $$
BEGIN
    IF p_rating < 0 OR p_rating > 10 THEN
        RAISE EXCEPTION 'La note doit être comprise entre 0 et 10';
    END IF;

    INSERT INTO rating (user_id, game_id, rating)
    VALUES (p_user_id, p_game_id, p_rating)
    ON CONFLICT (user_id, game_id) DO UPDATE SET
        rating = EXCLUDED.rating,
        updated_at = CURRENT_TIMESTAMP;
END;
$$ LANGUAGE plpgsql;

-- Fonction : Accepter une demande d'amitié
CREATE OR REPLACE FUNCTION sp_accept_friendship_request(
    p_friendship_id INTEGER,
    p_addressee_user_id INTEGER
)
RETURNS VOID AS $$
DECLARE
    v_rows_updated INTEGER;
BEGIN
    UPDATE friendship
    SET status = 'accepted',
        responded_at = CURRENT_TIMESTAMP
    WHERE friendship_id = p_friendship_id
      AND addressee_user_id = p_addressee_user_id
      AND status = 'pending';

    GET DIAGNOSTICS v_rows_updated = ROW_COUNT;

    IF v_rows_updated = 0 THEN
        RAISE EXCEPTION 'Demande d''amitié introuvable ou déjà traitée';
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Fonction : Soft delete d'un utilisateur
CREATE OR REPLACE FUNCTION sp_soft_delete_user(
    p_user_id INTEGER
)
RETURNS VOID AS $$
DECLARE
    v_rows_updated INTEGER;
BEGIN
    UPDATE user_account
    SET deleted_at = CURRENT_TIMESTAMP,
        is_active = FALSE
    WHERE user_id = p_user_id
      AND deleted_at IS NULL;

    GET DIAGNOSTICS v_rows_updated = ROW_COUNT;

    IF v_rows_updated = 0 THEN
        RAISE EXCEPTION 'Utilisateur introuvable ou déjà supprimé';
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Fonction : Soft delete d'un commentaire
CREATE OR REPLACE FUNCTION sp_soft_delete_comment(
    p_comment_id INTEGER,
    p_user_id INTEGER
)
RETURNS VOID AS $$
DECLARE
    v_role user_role;
    v_rows_updated INTEGER;
BEGIN
    -- Vérifier le rôle de l'utilisateur
    SELECT role INTO v_role
    FROM user_account
    WHERE user_id = p_user_id AND deleted_at IS NULL;

    -- Supprimer si l'utilisateur est propriétaire ou administrateur
    UPDATE game_comment
    SET deleted_at = CURRENT_TIMESTAMP
    WHERE comment_id = p_comment_id
      AND (user_id = p_user_id OR v_role = 'administrator')
      AND deleted_at IS NULL;

    GET DIAGNOSTICS v_rows_updated = ROW_COUNT;

    IF v_rows_updated = 0 THEN
        RAISE EXCEPTION 'Commentaire introuvable, déjà supprimé ou non autorisé';
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Fonction : Restaurer un utilisateur supprimé
CREATE OR REPLACE FUNCTION sp_restore_user(
    p_user_id INTEGER
)
RETURNS VOID AS $$
DECLARE
    v_rows_updated INTEGER;
BEGIN
    UPDATE user_account
    SET deleted_at = NULL,
        is_active = TRUE
    WHERE user_id = p_user_id
      AND deleted_at IS NOT NULL;

    GET DIAGNOSTICS v_rows_updated = ROW_COUNT;

    IF v_rows_updated = 0 THEN
        RAISE EXCEPTION 'Utilisateur introuvable ou non supprimé';
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Fonction : Restaurer un commentaire supprimé
CREATE OR REPLACE FUNCTION sp_restore_comment(
    p_comment_id INTEGER
)
RETURNS VOID AS $$
DECLARE
    v_rows_updated INTEGER;
BEGIN
    UPDATE game_comment
    SET deleted_at = NULL
    WHERE comment_id = p_comment_id
      AND deleted_at IS NOT NULL;

    GET DIAGNOSTICS v_rows_updated = ROW_COUNT;

    IF v_rows_updated = 0 THEN
        RAISE EXCEPTION 'Commentaire introuvable ou non supprimé';
    END IF;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- TRIGGERS SUPPLÉMENTAIRES
-- ============================================

-- Trigger : Vérifier le rôle du modérateur
CREATE OR REPLACE FUNCTION trg_verify_moderator_report()
RETURNS TRIGGER AS $$
DECLARE
    v_role user_role;
BEGIN
    IF NEW.moderator_user_id IS NOT NULL THEN
        SELECT role INTO v_role
        FROM user_account
        WHERE user_id = NEW.moderator_user_id;

        IF v_role != 'administrator' THEN
            RAISE EXCEPTION 'Seul un administrateur peut modérer un signalement';
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_verify_moderator_report
    BEFORE UPDATE ON report
    FOR EACH ROW
    EXECUTE FUNCTION trg_verify_moderator_report();

-- Trigger : Mettre à jour automatiquement updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_library_updated_at
    BEFORE UPDATE ON library
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_rating_updated_at
    BEFORE UPDATE ON rating
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_game_comment_updated_at
    BEFORE UPDATE ON game_comment
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger : Automatiser responded_at pour les amitiés
CREATE OR REPLACE FUNCTION trg_auto_set_responded_at()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.status = 'pending'
       AND NEW.status IN ('accepted', 'rejected', 'blocked')
       AND NEW.responded_at IS NULL THEN
        NEW.responded_at = CURRENT_TIMESTAMP;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_friendship_auto_responded_at
    BEFORE UPDATE ON friendship
    FOR EACH ROW
    EXECUTE FUNCTION trg_auto_set_responded_at();

-- ============================================
-- COMMENTAIRES FINAUX
-- ============================================

/*
MyGameList - Base de données PostgreSQL 16+

Fonctionnalités implémentées :
- Gestion des utilisateurs avec rôles (member, administrator)
- Catalogue de jeux avec plateformes, genres et tags
- Bibliothèques personnelles avec statuts de progression
- Système de notation et de commentaires
- Gestion des relations d'amitié
- Système de signalement et de modération

Optimisations :
- Index sur les colonnes fréquemment recherchées
- Index composites pour les requêtes complexes
- Index GIN pour la recherche full-text
- Vues pour les statistiques et agrégations
- Fonctions stockées pour les opérations métier
- Triggers pour garantir l'intégrité des données

Sécurité :
- Contraintes d'intégrité référentielle
- Contraintes de domaine (CHECK)
- Validation des données via triggers
- Cascades appropriées pour les suppressions
- Soft delete pour utilisateurs et commentaires

Version : 2.0 (PostgreSQL)
Date : 2025-11-27
*/
