-- ============================================
-- MPD - Modèle Physique de Données
-- MyGameList - Réseau Social de Collection de Jeux Vidéo
-- SGBD : MySQL 8.0+
-- ============================================

-- ============================================
-- Configuration de la base de données
-- ============================================

DROP DATABASE IF EXISTS mygamelist;
CREATE DATABASE mygamelist CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE mygamelist;

-- ============================================
-- Table: USER_ACCOUNT
-- ============================================

CREATE TABLE user_account (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL COMMENT 'Bcrypt hash of password',
    avatar VARCHAR(255) DEFAULT NULL COMMENT 'Avatar URL',
    bio TEXT DEFAULT NULL,
    registration_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    role ENUM('member', 'administrator') NOT NULL DEFAULT 'member',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    INDEX idx_username (username),
    INDEX idx_email (email),
    INDEX idx_role (role),
    INDEX idx_is_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Table des utilisateurs';

-- ============================================
-- Table: GAME
-- ============================================

CREATE TABLE game (
    game_id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    release_date DATE DEFAULT NULL,
    metacritic INT DEFAULT NULL COMMENT 'Score Metacritic (0-100)',
    website VARCHAR(255) DEFAULT NULL COMMENT 'Site web officiel du jeu',
    cover_image VARCHAR(255) DEFAULT NULL COMMENT 'URL de l''image de couverture',

    INDEX idx_title (title),
    INDEX idx_release_date (release_date),
    INDEX idx_metacritic (metacritic),

    CONSTRAINT chk_metacritic_range
        CHECK (metacritic IS NULL OR (metacritic >= 0 AND metacritic <= 100))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Table des jeux vidéo';

-- ============================================
-- Table: PLATFORM
-- ============================================

CREATE TABLE platform (
    platform_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,

    INDEX idx_name_platform (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Table des plateformes de jeu';

-- ============================================
-- Table: GENRE
-- ============================================

CREATE TABLE genre (
    genre_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,

    INDEX idx_name_genre (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Table des genres de jeux';

-- ============================================
-- Table: TAG
-- ============================================

CREATE TABLE tag (
    tag_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,

    INDEX idx_name_tag (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Table des tags de jeux';

-- ============================================
-- Table: DEVELOPER
-- ============================================

CREATE TABLE developer (
    developer_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,

    INDEX idx_name_developer (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Table des développeurs de jeux';

-- ============================================
-- Table: STORE
-- ============================================

CREATE TABLE store (
    store_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    url VARCHAR(255) DEFAULT NULL COMMENT 'URL du magasin',

    INDEX idx_name_store (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Table des magasins de jeux';

-- ============================================
-- Table: PUBLISHER
-- ============================================

CREATE TABLE publisher (
    publisher_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,

    INDEX idx_name_publisher (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Table des éditeurs de jeux';

-- ============================================
-- Table: LIBRARY
-- ============================================

CREATE TABLE library (
    library_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    game_id INT NOT NULL,
    status ENUM('to_play', 'playing', 'completed', 'abandoned') NOT NULL DEFAULT 'to_play',
    added_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
    play_time INT DEFAULT 0 COMMENT 'Temps de jeu en heures',
    owned_platform_id INT DEFAULT NULL COMMENT 'Plateforme sur laquelle l''utilisateur possède le jeu',

    INDEX idx_user (user_id),
    INDEX idx_game (game_id),
    INDEX idx_status (status),
    UNIQUE INDEX idx_user_game (user_id, game_id),

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
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Table des bibliothèques personnelles';

-- ============================================
-- Table: RATING
-- ============================================

CREATE TABLE rating (
    rating_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    game_id INT NOT NULL,
    rating DECIMAL(3,1) NOT NULL COMMENT 'Note entre 0.0 et 10.0',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,

    INDEX idx_game_rating (game_id),
    INDEX idx_rating_value (rating),
    UNIQUE INDEX idx_user_game_rating (user_id, game_id),

    CONSTRAINT fk_rating_user
        FOREIGN KEY (user_id) REFERENCES user_account(user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_rating_game
        FOREIGN KEY (game_id) REFERENCES game(game_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT chk_rating_value
        CHECK (rating >= 0 AND rating <= 10)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Table des notes attribuées aux jeux';

-- ============================================
-- Table: GAME_COMMENT
-- ============================================

CREATE TABLE game_comment (
    comment_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    game_id INT NOT NULL,
    content TEXT NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,

    INDEX idx_user_game_comment (user_id),
    INDEX idx_game_game_comment (game_id),
    INDEX idx_created_at (created_at DESC),
    FULLTEXT idx_fulltext_content (content),

    CONSTRAINT fk_game_comment_user
        FOREIGN KEY (user_id) REFERENCES user_account(user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_game_comment_game
        FOREIGN KEY (game_id) REFERENCES game(game_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Table des commentaires sur les jeux';

-- ============================================
-- Table: FRIENDSHIP
-- ============================================

CREATE TABLE friendship (
    friendship_id INT AUTO_INCREMENT PRIMARY KEY,
    requester_user_id INT NOT NULL,
    addressee_user_id INT NOT NULL,
    status ENUM('pending', 'accepted', 'rejected', 'blocked') NOT NULL DEFAULT 'pending',
    requested_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    responded_at DATETIME DEFAULT NULL,

    INDEX idx_requester (requester_user_id),
    INDEX idx_addressee (addressee_user_id),
    INDEX idx_status (status),
    UNIQUE INDEX idx_friendship_unique (requester_user_id, addressee_user_id),

    CONSTRAINT fk_friendship_requester
        FOREIGN KEY (requester_user_id) REFERENCES user_account(user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_friendship_addressee
        FOREIGN KEY (addressee_user_id) REFERENCES user_account(user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT chk_friendship_different_users
        CHECK (requester_user_id != addressee_user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Table des relations d''amitié';

-- ============================================
-- Table: REPORT
-- ============================================

CREATE TABLE report (
    report_id INT AUTO_INCREMENT PRIMARY KEY,
    reporter_user_id INT NOT NULL,
    content_type ENUM('comment', 'user') NOT NULL,
    content_id INT NOT NULL COMMENT 'ID du commentaire ou de l''utilisateur signalé',
    reason VARCHAR(255) NOT NULL,
    description TEXT DEFAULT NULL,
    reported_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status ENUM('pending', 'processed', 'rejected') NOT NULL DEFAULT 'pending',
    processed_at DATETIME DEFAULT NULL,
    moderator_user_id INT DEFAULT NULL COMMENT 'Administrateur ayant traité le signalement',

    INDEX idx_reporter (reporter_user_id),
    INDEX idx_content_type (content_type, content_id),
    INDEX idx_status_report (status),
    INDEX idx_moderator (moderator_user_id),
    INDEX idx_reported_at (reported_at DESC),

    CONSTRAINT fk_report_reporter
        FOREIGN KEY (reporter_user_id) REFERENCES user_account(user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_report_moderator
        FOREIGN KEY (moderator_user_id) REFERENCES user_account(user_id)
        ON DELETE SET NULL
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Table des signalements de contenu';

-- ============================================
-- Table: GAME_PLATFORM (Association)
-- ============================================

CREATE TABLE game_platform (
    game_id INT NOT NULL,
    platform_id INT NOT NULL,
    platform_release_date DATE DEFAULT NULL COMMENT 'Date de sortie spécifique à cette plateforme',

    PRIMARY KEY (game_id, platform_id),
    INDEX idx_platform_game (platform_id),

    CONSTRAINT fk_game_platform_game
        FOREIGN KEY (game_id) REFERENCES game(game_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_game_platform_platform
        FOREIGN KEY (platform_id) REFERENCES platform(platform_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Association Jeux-Plateformes';

-- ============================================
-- Table: GAME_GENRE (Association)
-- ============================================

CREATE TABLE game_genre (
    game_id INT NOT NULL,
    genre_id INT NOT NULL,

    PRIMARY KEY (game_id, genre_id),
    INDEX idx_genre_game (genre_id),

    CONSTRAINT fk_game_genre_game
        FOREIGN KEY (game_id) REFERENCES game(game_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_game_genre_genre
        FOREIGN KEY (genre_id) REFERENCES genre(genre_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Association Jeux-Genres';

-- ============================================
-- Table: GAME_TAG (Association)
-- ============================================

CREATE TABLE game_tag (
    game_id INT NOT NULL,
    tag_id INT NOT NULL,

    PRIMARY KEY (game_id, tag_id),
    INDEX idx_tag_game (tag_id),

    CONSTRAINT fk_game_tag_game
        FOREIGN KEY (game_id) REFERENCES game(game_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_game_tag_tag
        FOREIGN KEY (tag_id) REFERENCES tag(tag_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Association Jeux-Tags';

-- ============================================
-- Table: GAME_DEVELOPER (Association)
-- ============================================

CREATE TABLE game_developer (
    game_id INT NOT NULL,
    developer_id INT NOT NULL,

    PRIMARY KEY (game_id, developer_id),
    INDEX idx_developer_game (developer_id),

    CONSTRAINT fk_game_developer_game
        FOREIGN KEY (game_id) REFERENCES game(game_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_game_developer_developer
        FOREIGN KEY (developer_id) REFERENCES developer(developer_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Association Jeux-Développeurs';

-- ============================================
-- Table: GAME_STORE (Association)
-- ============================================

CREATE TABLE game_store (
    game_id INT NOT NULL,
    store_id INT NOT NULL,

    PRIMARY KEY (game_id, store_id),
    INDEX idx_store_game (store_id),

    CONSTRAINT fk_game_store_game
        FOREIGN KEY (game_id) REFERENCES game(game_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_game_store_store
        FOREIGN KEY (store_id) REFERENCES store(store_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Association Jeux-Magasins';

-- ============================================
-- Table: GAME_PUBLISHER (Association)
-- ============================================

CREATE TABLE game_publisher (
    game_id INT NOT NULL,
    publisher_id INT NOT NULL,

    PRIMARY KEY (game_id, publisher_id),
    INDEX idx_publisher_game (publisher_id),

    CONSTRAINT fk_game_publisher_game
        FOREIGN KEY (game_id) REFERENCES game(game_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_game_publisher_publisher
        FOREIGN KEY (publisher_id) REFERENCES publisher(publisher_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Association Jeux-Éditeurs';

-- ============================================
-- VUES UTILES
-- ============================================

-- Vue : Statistiques des jeux
CREATE OR REPLACE VIEW view_game_statistics AS
SELECT
    g.game_id,
    g.title,
    COUNT(DISTINCT r.user_id) AS rating_count,
    ROUND(AVG(r.rating), 1) AS average_rating,
    COUNT(DISTINCT gc.comment_id) AS comment_count,
    COUNT(DISTINCT l.user_id) AS owner_count
FROM game g
LEFT JOIN rating r ON g.game_id = r.game_id
LEFT JOIN game_comment gc ON g.game_id = gc.game_id
LEFT JOIN library l ON g.game_id = l.game_id
GROUP BY g.game_id, g.title;

-- Vue : Classement des jeux
CREATE OR REPLACE VIEW view_game_ranking AS
SELECT
    g.game_id,
    g.title,
    g.cover_image,
    ROUND(AVG(r.rating), 1) AS average_rating,
    COUNT(r.rating_id) AS rating_count
FROM game g
INNER JOIN rating r ON g.game_id = r.game_id
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
    f.responded_at AS friendship_date
FROM friendship f
INNER JOIN user_account u ON f.addressee_user_id = u.user_id
WHERE f.status = 'accepted'
UNION
SELECT
    f.addressee_user_id AS user_id,
    f.requester_user_id AS friend_id,
    u.username AS friend_username,
    u.avatar AS friend_avatar,
    f.responded_at AS friendship_date
FROM friendship f
INNER JOIN user_account u ON f.requester_user_id = u.user_id
WHERE f.status = 'accepted';

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
    ROUND(AVG(r2.rating), 1) AS community_average_rating
FROM library l
INNER JOIN game g ON l.game_id = g.game_id
LEFT JOIN platform p ON l.owned_platform_id = p.platform_id
LEFT JOIN rating r ON l.user_id = r.user_id AND l.game_id = r.game_id
LEFT JOIN rating r2 ON l.game_id = r2.game_id
GROUP BY l.library_id, l.user_id, l.game_id, g.title, g.cover_image,
         l.status, l.added_at, l.play_time, p.name, r.rating;

-- ============================================
-- PROCÉDURES STOCKÉES
-- ============================================

-- Procédure : Ajouter un jeu à la bibliothèque
DELIMITER //
CREATE PROCEDURE sp_add_game_to_library(
    IN p_user_id INT,
    IN p_game_id INT,
    IN p_status VARCHAR(20),
    IN p_platform_id INT
)
BEGIN
    INSERT INTO library (user_id, game_id, status, owned_platform_id)
    VALUES (p_user_id, p_game_id, p_status, p_platform_id)
    ON DUPLICATE KEY UPDATE
        status = p_status,
        owned_platform_id = p_platform_id,
        updated_at = CURRENT_TIMESTAMP;
END //
DELIMITER ;

-- Procédure : Noter un jeu
DELIMITER //
CREATE PROCEDURE sp_rate_game(
    IN p_user_id INT,
    IN p_game_id INT,
    IN p_rating DECIMAL(3,1)
)
BEGIN
    IF p_rating < 0 OR p_rating > 10 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La note doit être comprise entre 0 et 10';
    END IF;

    INSERT INTO rating (user_id, game_id, rating)
    VALUES (p_user_id, p_game_id, p_rating)
    ON DUPLICATE KEY UPDATE
        rating = p_rating,
        updated_at = CURRENT_TIMESTAMP;
END //
DELIMITER ;

-- Procédure : Accepter une demande d'amitié
DELIMITER //
CREATE PROCEDURE sp_accept_friendship_request(
    IN p_friendship_id INT,
    IN p_addressee_user_id INT
)
BEGIN
    UPDATE friendship
    SET status = 'accepted',
        responded_at = CURRENT_TIMESTAMP
    WHERE friendship_id = p_friendship_id
      AND addressee_user_id = p_addressee_user_id
      AND status = 'pending';

    IF ROW_COUNT() = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Demande d''amitié introuvable ou déjà traitée';
    END IF;
END //
DELIMITER ;

-- ============================================
-- TRIGGERS
-- ============================================

-- Trigger : Vérifier le rôle du modérateur
DELIMITER //
CREATE TRIGGER trg_verify_moderator_report
BEFORE UPDATE ON report
FOR EACH ROW
BEGIN
    DECLARE v_role VARCHAR(20);

    IF NEW.moderator_user_id IS NOT NULL THEN
        SELECT role INTO v_role
        FROM user_account
        WHERE user_id = NEW.moderator_user_id;

        IF v_role != 'administrator' THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Seul un administrateur peut modérer un signalement';
        END IF;
    END IF;
END //
DELIMITER ;

-- Trigger : Mettre à jour la date de modification de la bibliothèque
DELIMITER //
CREATE TRIGGER trg_library_updated_at
BEFORE UPDATE ON library
FOR EACH ROW
BEGIN
    SET NEW.updated_at = CURRENT_TIMESTAMP;
END //
DELIMITER ;

-- ============================================
-- INDEX ADDITIONNELS POUR OPTIMISATION
-- ============================================

-- Index composite pour les requêtes de bibliothèque par statut
CREATE INDEX idx_library_user_status ON library(user_id, status);

-- Index pour les commentaires récents
CREATE INDEX idx_game_comment_game_date ON game_comment(game_id, created_at DESC);


CREATE INDEX idx_friendship_requester_status ON friendship(requester_user_id, status);
CREATE INDEX idx_friendship_addressee_status ON friendship(addressee_user_id, status);

-- ============================================
-- COMMENTAIRES FINAUX
-- ============================================

/*
Ce script crée la structure complète de la base de données MyGameList.

Fonctionnalités implémentées :
- Gestion des utilisateurs avec rôles (membre, administrateur)
- Catalogue de jeux avec plateformes, genres et tags
- Bibliothèques personnelles avec statuts de progression
- Système de notation et de commentaires
- Gestion des relations d'amitié
- Système de signalement et de modération

Optimisations :
- Index sur les colonnes fréquemment recherchées
- Index composites pour les requêtes complexes
- Index FULLTEXT pour la recherche textuelle
- Vues matérialisées pour les statistiques
- Procédures stockées pour les opérations métier
- Triggers pour garantir l'intégrité des données

Sécurité :
- Contraintes d'intégrité référentielle
- Contraintes de domaine (CHECK)
- Validation des données via triggers
- Cascades appropriées pour les suppressions

Version : 1.0
Date : 2025-11-27
*/
