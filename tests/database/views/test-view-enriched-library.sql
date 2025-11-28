-- ============================================
-- Tests unitaires pour la vue view_enriched_library
-- ============================================

\echo '========================================'
\echo 'TEST VUE: view_enriched_library'
\echo '========================================'

BEGIN;

-- Nettoyage
DELETE FROM rating;
DELETE FROM library;
DELETE FROM game WHERE game_id > 0;
DELETE FROM platform WHERE platform_id > 0;
DELETE FROM user_account WHERE user_id > 0;

-- Données de test
INSERT INTO user_account (user_id, username, email, password) VALUES
(1, 'player1', 'player1@test.com', '$2a$10$test'),
(2, 'player2', 'player2@test.com', '$2a$10$test'),
(3, 'deleted_user', 'deleted@test.com', '$2a$10$test');

UPDATE user_account SET deleted_at = CURRENT_TIMESTAMP WHERE user_id = 3;

INSERT INTO platform (platform_id, name) VALUES
(1, 'PC'),
(2, 'PlayStation 5'),
(3, 'Xbox Series X');

INSERT INTO game (game_id, title, slug, cover_image) VALUES
(1, 'Epic Game', 'epic-game', 'http://example.com/epic.jpg'),
(2, 'Great Game', 'great-game', 'http://example.com/great.jpg'),
(3, 'Good Game', 'good-game', 'http://example.com/good.jpg');

-- Bibliothèques des utilisateurs
INSERT INTO library (library_id, user_id, game_id, status, play_time, owned_platform_id, added_at) VALUES
(1, 1, 1, 'completed', 50, 1, CURRENT_TIMESTAMP - INTERVAL '30 days'),
(2, 1, 2, 'playing', 20, 2, CURRENT_TIMESTAMP - INTERVAL '10 days'),
(3, 1, 3, 'to_play', 0, 1, CURRENT_TIMESTAMP - INTERVAL '5 days'),
(4, 2, 1, 'completed', 45, 3, CURRENT_TIMESTAMP - INTERVAL '20 days'),
(5, 2, 2, 'abandoned', 5, 2, CURRENT_TIMESTAMP - INTERVAL '15 days'),
(6, 3, 1, 'completed', 100, 1, CURRENT_TIMESTAMP - INTERVAL '40 days');  -- Utilisateur supprimé

-- Notes des utilisateurs
INSERT INTO rating (user_id, game_id, rating) VALUES
(1, 1, 9.5),  -- Ma note pour Epic Game
(1, 2, 8.0),  -- Ma note pour Great Game
(2, 1, 9.0),  -- Note de player2 pour Epic Game
(2, 2, 7.5),  -- Note de player2 pour Great Game
(3, 1, 10.0); -- Note d'utilisateur supprimé (ne doit pas compter dans la moyenne)

\echo ''
\echo '--- Test 1: Vérifier que la vue existe ---'
SELECT EXISTS (
    SELECT 1 
    FROM information_schema.views 
    WHERE table_schema = 'public' 
    AND table_name = 'view_enriched_library'
) AS "Vue view_enriched_library existe";

\echo ''
\echo '--- Test 2: Bibliothèque complète de player1 ---'
SELECT 
    library_id,
    game_id,
    title,
    status,
    play_time,
    platform,
    my_rating,
    community_average_rating
FROM view_enriched_library
WHERE user_id = 1
ORDER BY added_at DESC;
-- Attendu: 3 jeux avec toutes les informations enrichies

\echo ''
\echo '--- Test 3: Vérifier les notes personnelles et moyennes communauté ---'
DO $$
DECLARE
    v_my_rating NUMERIC;
    v_community_avg NUMERIC;
BEGIN
    -- Epic Game dans bibliothèque de player1
    SELECT my_rating, community_average_rating INTO v_my_rating, v_community_avg
    FROM view_enriched_library
    WHERE user_id = 1 AND game_id = 1;
    
    IF v_my_rating = 9.5 THEN
        RAISE NOTICE '[PASS] my_rating correct (9.5)';
    ELSE
        RAISE NOTICE '[FAIL] my_rating incorrect: % (attendu: 9.5)', v_my_rating;
    END IF;
    
    -- Moyenne communauté = (9.5 + 9.0) / 2 = 9.2 (user3 exclu car supprimé)
    IF v_community_avg = 9.2 THEN
        RAISE NOTICE '[PASS] community_average_rating correct (9.2, user3 exclu)';
    ELSE
        RAISE NOTICE '[FAIL] community_average_rating: % (attendu: 9.2)', v_community_avg;
    END IF;
END;
$$;

\echo ''
\echo '--- Test 4: Jeu sans note personnelle mais avec moyenne communauté ---'
SELECT 
    game_id,
    title,
    my_rating,
    community_average_rating
FROM view_enriched_library
WHERE user_id = 1 AND game_id = 3;
-- Attendu: my_rating = NULL, community_average_rating = NULL (aucune note)

\echo ''
\echo '--- Test 5: Vérifier les informations de plateforme ---'
SELECT 
    game_id,
    title,
    platform
FROM view_enriched_library
WHERE user_id = 1
ORDER BY game_id;
-- Attendu: Epic Game (PC), Great Game (PlayStation 5), Good Game (PC)

\echo ''
\echo '--- Test 6: Vérifier les différents statuts ---'
DO $$
DECLARE
    v_completed INTEGER;
    v_playing INTEGER;
    v_to_play INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_completed FROM view_enriched_library WHERE user_id = 1 AND status = 'completed';
    SELECT COUNT(*) INTO v_playing FROM view_enriched_library WHERE user_id = 1 AND status = 'playing';
    SELECT COUNT(*) INTO v_to_play FROM view_enriched_library WHERE user_id = 1 AND status = 'to_play';
    
    IF v_completed = 1 AND v_playing = 1 AND v_to_play = 1 THEN
        RAISE NOTICE '[PASS] Tous les statuts présents (completed=1, playing=1, to_play=1)';
    ELSE
        RAISE NOTICE '[FAIL] Statuts incorrects: completed=%, playing=%, to_play=%', v_completed, v_playing, v_to_play;
    END IF;
END;
$$;

\echo ''
\echo '--- Test 7: Temps de jeu (play_time) ---'
SELECT 
    game_id,
    title,
    status,
    play_time
FROM view_enriched_library
WHERE user_id = 1
ORDER BY play_time DESC;
-- Attendu: Epic Game (50h), Great Game (20h), Good Game (0h)

\echo ''
\echo '--- Test 8: Vérifier exclusion utilisateur supprimé ---'
DO $$
DECLARE
    v_count INTEGER;
BEGIN
    -- Vérifier que la bibliothèque de user3 n'apparaît pas
    SELECT COUNT(*) INTO v_count FROM view_enriched_library WHERE user_id = 3;
    
    IF v_count = 0 THEN
        RAISE NOTICE '[PASS] Bibliothèque d''utilisateur supprimé exclue';
    ELSE
        RAISE NOTICE '[FAIL] % entrées pour utilisateur supprimé (attendu: 0)', v_count;
    END IF;
END;
$$;

\echo ''
\echo '--- Test 9: Vérifier cover_image présente ---'
SELECT 
    game_id,
    title,
    cover_image
FROM view_enriched_library
WHERE user_id = 1;
-- Attendu: Toutes les cover_image présentes

\echo ''
\echo '--- Test 10: Bibliothèque de player2 (avec jeu abandonné) ---'
SELECT 
    game_id,
    title,
    status,
    play_time,
    my_rating
FROM view_enriched_library
WHERE user_id = 2
ORDER BY added_at DESC;
-- Attendu: 2 jeux (Epic Game completed, Great Game abandoned)

\echo ''
\echo '--- Test 11: Jeu dans plusieurs bibliothèques ---'
SELECT 
    user_id,
    game_id,
    title,
    status,
    my_rating
FROM view_enriched_library
WHERE game_id = 1
ORDER BY user_id;
-- Attendu: 2 entrées (player1 et player2), pas user3

\echo ''
\echo '--- Test 12: Vérifier la moyenne communauté pour Great Game ---'
DO $$
DECLARE
    v_avg NUMERIC;
BEGIN
    SELECT community_average_rating INTO v_avg
    FROM view_enriched_library
    WHERE user_id = 1 AND game_id = 2;
    
    -- Moyenne = (8.0 + 7.5) / 2 = 7.8 (arrondi à 1 décimale)
    IF v_avg = 7.8 THEN
        RAISE NOTICE '[PASS] community_average_rating correct pour Great Game (7.8)';
    ELSE
        RAISE NOTICE '[FAIL] community_average_rating: % (attendu: 7.8)', v_avg;
    END IF;
END;
$$;

ROLLBACK;
