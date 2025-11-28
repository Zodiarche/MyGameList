-- ============================================
-- Tests unitaires pour la vue view_game_ranking
-- ============================================

\echo '========================================'
\echo 'TEST VUE: view_game_ranking'
\echo '========================================'

BEGIN;

-- Nettoyage
DELETE FROM rating;
DELETE FROM game WHERE game_id > 0;
DELETE FROM user_account WHERE user_id > 0;

-- Données de test
INSERT INTO user_account (user_id, username, email, password) VALUES
(1, 'user1', 'user1@test.com', '$2a$10$test'),
(2, 'user2', 'user2@test.com', '$2a$10$test'),
(3, 'user3', 'user3@test.com', '$2a$10$test'),
(4, 'user4', 'user4@test.com', '$2a$10$test'),
(5, 'user5', 'user5@test.com', '$2a$10$test'),
(6, 'deleted_user', 'deleted@test.com', '$2a$10$test');

UPDATE user_account SET deleted_at = CURRENT_TIMESTAMP WHERE user_id = 6;

INSERT INTO game (game_id, title, slug, cover_image) VALUES
(1, 'Top Game', 'top-game', 'http://example.com/top.jpg'),
(2, 'Good Game', 'good-game', 'http://example.com/good.jpg'),
(3, 'Average Game', 'average-game', 'http://example.com/avg.jpg'),
(4, 'Unpopular Game', 'unpopular-game', 'http://example.com/unpop.jpg');

-- Top Game : 5 notes, moyenne 9.0
INSERT INTO rating (user_id, game_id, rating) VALUES
(1, 1, 9.0),
(2, 1, 9.5),
(3, 1, 8.5),
(4, 1, 9.0),
(5, 1, 9.0),
(6, 1, 10.0);  -- Note d'un utilisateur supprimé (ne doit pas compter)

-- Good Game : 5 notes, moyenne 7.5
INSERT INTO rating (user_id, game_id, rating) VALUES
(1, 2, 7.0),
(2, 2, 8.0),
(3, 2, 7.5),
(4, 2, 7.5),
(5, 2, 7.5);

-- Average Game : 6 notes, moyenne 6.0
INSERT INTO rating (user_id, game_id, rating) VALUES
(1, 3, 6.0),
(2, 3, 6.5),
(3, 3, 5.5),
(4, 3, 6.0),
(5, 3, 6.0),
(6, 3, 6.0);

-- Unpopular Game : seulement 3 notes (ne doit PAS apparaître dans le classement)
INSERT INTO rating (user_id, game_id, rating) VALUES
(1, 4, 10.0),
(2, 4, 10.0),
(3, 4, 10.0);

\echo ''
\echo '--- Test 1: Vérifier que la vue existe ---'
SELECT EXISTS (
    SELECT 1 
    FROM information_schema.views 
    WHERE table_schema = 'public' 
    AND table_name = 'view_game_ranking'
) AS "Vue view_game_ranking existe";

\echo ''
\echo '--- Test 2: Classement complet (ordre décroissant) ---'
SELECT 
    game_id,
    title,
    average_rating,
    rating_count
FROM view_game_ranking
ORDER BY average_rating DESC, rating_count DESC;
-- Attendu: 3 jeux (Top Game, Good Game, Average Game), pas Unpopular Game

\echo ''
\echo '--- Test 3: Vérifier le seuil minimum (>= 5 notes) ---'
DO $$
DECLARE
    v_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_count FROM view_game_ranking;
    
    IF v_count = 3 THEN
        RAISE NOTICE '[PASS] Seuil de 5 notes respecté (3 jeux qualifiés)';
    ELSE
        RAISE NOTICE '[FAIL] Nombre de jeux incorrect: % (attendu: 3)', v_count;
    END IF;
    
    -- Vérifier qu'Unpopular Game n'est pas présent
    IF NOT EXISTS (SELECT 1 FROM view_game_ranking WHERE game_id = 4) THEN
        RAISE NOTICE '[PASS] Unpopular Game (3 notes) correctement exclu';
    ELSE
        RAISE NOTICE '[FAIL] Unpopular Game ne devrait pas être dans le classement';
    END IF;
END;
$$;

\echo ''
\echo '--- Test 4: Vérifier l''ordre du classement ---'
DO $$
DECLARE
    v_first_game_id INTEGER;
    v_first_avg NUMERIC;
    v_last_game_id INTEGER;
    v_last_avg NUMERIC;
BEGIN
    -- Premier jeu (meilleure note)
    SELECT game_id, average_rating INTO v_first_game_id, v_first_avg
    FROM view_game_ranking
    ORDER BY average_rating DESC, rating_count DESC
    LIMIT 1;
    
    -- Dernier jeu (moins bonne note)
    SELECT game_id, average_rating INTO v_last_game_id, v_last_avg
    FROM view_game_ranking
    ORDER BY average_rating ASC, rating_count ASC
    LIMIT 1;
    
    IF v_first_game_id = 1 AND v_first_avg = 9.0 THEN
        RAISE NOTICE '[PASS] Top Game en première position (avg: 9.0)';
    ELSE
        RAISE NOTICE '[FAIL] Premier jeu incorrect: % (avg: %)', v_first_game_id, v_first_avg;
    END IF;
    
    IF v_last_game_id = 3 AND v_last_avg = 6.0 THEN
        RAISE NOTICE '[PASS] Average Game en dernière position (avg: 6.0)';
    ELSE
        RAISE NOTICE '[FAIL] Dernier jeu incorrect: % (avg: %)', v_last_game_id, v_last_avg;
    END IF;
END;
$$;

\echo ''
\echo '--- Test 5: Vérifier exclusion utilisateurs supprimés ---'
DO $$
DECLARE
    v_top_game_count INTEGER;
    v_top_game_avg NUMERIC;
BEGIN
    SELECT rating_count, average_rating INTO v_top_game_count, v_top_game_avg
    FROM view_game_ranking
    WHERE game_id = 1;
    
    IF v_top_game_count = 5 THEN
        RAISE NOTICE '[PASS] rating_count correct (5, user6 exclu)';
    ELSE
        RAISE NOTICE '[FAIL] rating_count incorrect: % (attendu: 5)', v_top_game_count;
    END IF;
    
    IF v_top_game_avg = 9.0 THEN
        RAISE NOTICE '[PASS] average_rating correct (9.0, sans note de user6)';
    ELSE
        RAISE NOTICE '[FAIL] average_rating incorrect: % (attendu: 9.0)', v_top_game_avg;
    END IF;
END;
$$;

\echo ''
\echo '--- Test 6: Vérifier présence de cover_image ---'
SELECT COUNT(*) as games_with_cover
FROM view_game_ranking
WHERE cover_image IS NOT NULL;
-- Attendu: 3 (tous les jeux du classement ont une cover)

ROLLBACK;
