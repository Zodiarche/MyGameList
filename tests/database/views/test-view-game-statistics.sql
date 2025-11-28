-- ============================================
-- Tests unitaires pour la vue view_game_statistics
-- ============================================

\echo '========================================'
\echo 'TEST VUE: view_game_statistics'
\echo '========================================'

BEGIN;

-- Nettoyage
DELETE FROM rating;
DELETE FROM game_comment;
DELETE FROM library;
DELETE FROM game WHERE game_id > 0;
DELETE FROM user_account WHERE user_id > 0;

-- Données de test
INSERT INTO user_account (user_id, username, email, password) VALUES
(1, 'user1', 'user1@test.com', '$2a$10$test'),
(2, 'user2', 'user2@test.com', '$2a$10$test'),
(3, 'user3', 'user3@test.com', '$2a$10$test'),
(4, 'deleted_user', 'deleted@test.com', '$2a$10$test');

UPDATE user_account SET deleted_at = CURRENT_TIMESTAMP WHERE user_id = 4;

INSERT INTO game (game_id, title, slug) VALUES
(1, 'Game One', 'game-one'),
(2, 'Game Two', 'game-two'),
(3, 'Game Three', 'game-three');

-- Ajouter des notes
INSERT INTO rating (user_id, game_id, rating) VALUES
(1, 1, 8.5),
(2, 1, 9.0),
(3, 1, 7.5),
(4, 1, 10.0),  -- Note d'un utilisateur supprimé (ne doit pas compter)
(1, 2, 6.0),
(2, 2, 7.0);

-- Ajouter des commentaires
INSERT INTO game_comment (user_id, game_id, content) VALUES
(1, 1, 'Great game!'),
(2, 1, 'Love it'),
(3, 1, 'Not bad'),
(4, 1, 'Amazing'),  -- Commentaire d'un utilisateur supprimé
(1, 2, 'Good game');

-- Supprimer un commentaire (soft delete)
UPDATE game_comment SET deleted_at = CURRENT_TIMESTAMP 
WHERE user_id = 1 AND game_id = 1;

-- Ajouter à la bibliothèque
INSERT INTO library (user_id, game_id, status) VALUES
(1, 1, 'completed'),
(2, 1, 'playing'),
(3, 1, 'to_play'),
(4, 1, 'completed'),  -- Bibliothèque d'un utilisateur supprimé
(1, 2, 'playing');

\echo ''
\echo '--- Test 1: Vérifier que la vue existe ---'
SELECT EXISTS (
    SELECT 1 
    FROM information_schema.views 
    WHERE table_schema = 'public' 
    AND table_name = 'view_game_statistics'
) AS "Vue view_game_statistics existe";

\echo ''
\echo '--- Test 2: Statistiques pour Game One (jeu populaire) ---'
SELECT 
    game_id,
    title,
    rating_count,
    average_rating,
    comment_count,
    owner_count
FROM view_game_statistics
WHERE game_id = 1;
-- Attendu: rating_count=3 (pas user4), average_rating=8.3, comment_count=2 (pas deleted), owner_count=3

\echo ''
\echo '--- Test 3: Statistiques pour Game Two ---'
SELECT 
    game_id,
    title,
    rating_count,
    average_rating,
    comment_count,
    owner_count
FROM view_game_statistics
WHERE game_id = 2;
-- Attendu: rating_count=2, average_rating=6.5, comment_count=1, owner_count=1

\echo ''
\echo '--- Test 4: Jeu sans statistiques (Game Three) ---'
SELECT 
    game_id,
    title,
    rating_count,
    average_rating,
    comment_count,
    owner_count
FROM view_game_statistics
WHERE game_id = 3;
-- Attendu: rating_count=0, average_rating=NULL, comment_count=0, owner_count=0

\echo ''
\echo '--- Test 5: Vérifier que les utilisateurs supprimés sont exclus ---'
DO $$
DECLARE
    v_rating_count INTEGER;
    v_comment_count INTEGER;
    v_owner_count INTEGER;
BEGIN
    SELECT rating_count, comment_count, owner_count
    INTO v_rating_count, v_comment_count, v_owner_count
    FROM view_game_statistics
    WHERE game_id = 1;
    
    IF v_rating_count = 3 THEN
        RAISE NOTICE '[PASS] rating_count correct (3, user4 exclu)';
    ELSE
        RAISE NOTICE '[FAIL] rating_count incorrect: % (attendu: 3)', v_rating_count;
    END IF;
    
    IF v_comment_count = 2 THEN
        RAISE NOTICE '[PASS] comment_count correct (2, deleted et user4 exclus)';
    ELSE
        RAISE NOTICE '[FAIL] comment_count incorrect: % (attendu: 2)', v_comment_count;
    END IF;
    
    IF v_owner_count = 3 THEN
        RAISE NOTICE '[PASS] owner_count correct (3, user4 exclu)';
    ELSE
        RAISE NOTICE '[FAIL] owner_count incorrect: % (attendu: 3)', v_owner_count;
    END IF;
END;
$$;

\echo ''
\echo '--- Test 6: Tous les jeux sont présents dans la vue ---'
SELECT COUNT(*) as total_games FROM view_game_statistics;
-- Attendu: 3 (tous les jeux, même sans statistiques)

ROLLBACK;
