-- ============================================
-- Tests pour la vue view_user_library_stats
-- ============================================

\echo '========================================'
\echo 'TEST VUE: view_user_library_stats'
\echo '========================================'

BEGIN;

-- Créer données de test
INSERT INTO user_account (username, email, password)
VALUES ('test_user', 'test@test.com', '$2b$10$hash');

INSERT INTO game (title, slug)
VALUES 
    ('Game 1', 'game-1'),
    ('Game 2', 'game-2'),
    ('Game 3', 'game-3'),
    ('Game 4', 'game-4');

DO $$
DECLARE
    v_user_id INTEGER;
    v_game1_id INTEGER;
    v_game2_id INTEGER;
    v_game3_id INTEGER;
    v_game4_id INTEGER;
    v_total_games INTEGER;
    v_to_play INTEGER;
    v_playing INTEGER;
    v_completed INTEGER;
    v_total_play_time INTEGER;
BEGIN
    SELECT user_id INTO v_user_id FROM user_account WHERE username = 'test_user';
    SELECT game_id INTO v_game1_id FROM game WHERE slug = 'game-1';
    SELECT game_id INTO v_game2_id FROM game WHERE slug = 'game-2';
    SELECT game_id INTO v_game3_id FROM game WHERE slug = 'game-3';
    SELECT game_id INTO v_game4_id FROM game WHERE slug = 'game-4';

    -- Créer bibliothèque avec différents statuts
    INSERT INTO library (user_id, game_id, status, play_time)
    VALUES 
        (v_user_id, v_game1_id, 'to_play', 0),
        (v_user_id, v_game2_id, 'playing', 10),
        (v_user_id, v_game3_id, 'completed', 50),
        (v_user_id, v_game4_id, 'abandoned', 5);

    -- TEST 1 : Vérifier que la vue existe
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 1 : Vérifier que la vue existe';
    IF EXISTS (
        SELECT 1 FROM information_schema.views 
        WHERE table_name = 'view_user_library_stats'
    ) THEN
        RAISE NOTICE '[PASS] Vue existe';
    ELSE
        RAISE NOTICE '[FAIL] Vue n''existe pas';
    END IF;

    -- TEST 2 : Compter total des jeux
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 2 : Compter total des jeux';
    SELECT total_games INTO v_total_games
    FROM view_user_library_stats WHERE user_id = v_user_id;
    
    IF v_total_games = 4 THEN
        RAISE NOTICE '[PASS] Total games correct (4)';
    ELSE
        RAISE NOTICE '[FAIL] Total games incorrect: %', v_total_games;
    END IF;

    -- TEST 3 : Vérifier count par statut
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 3 : Vérifier count par statut';
    SELECT to_play_count, playing_count, completed_count
    INTO v_to_play, v_playing, v_completed
    FROM view_user_library_stats WHERE user_id = v_user_id;
    
    IF v_to_play = 1 AND v_playing = 1 AND v_completed = 1 THEN
        RAISE NOTICE '[PASS] Counts par statut corrects';
    ELSE
        RAISE NOTICE '[FAIL] Counts incorrects: to_play=%, playing=%, completed=%', 
            v_to_play, v_playing, v_completed;
    END IF;

    -- TEST 4 : Vérifier total play_time
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 4 : Vérifier total play_time';
    SELECT total_play_time INTO v_total_play_time
    FROM view_user_library_stats WHERE user_id = v_user_id;
    
    IF v_total_play_time = 65 THEN
        RAISE NOTICE '[PASS] Total play_time correct (65h)';
    ELSE
        RAISE NOTICE '[FAIL] Total play_time incorrect: %', v_total_play_time;
    END IF;

    -- TEST 5 : Utilisateur sans jeux retourne 0
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 5 : Utilisateur sans jeux n''apparaît pas dans la vue';
    INSERT INTO user_account (username, email, password)
    VALUES ('empty_user', 'empty@test.com', '$2b$10$hash');
    
    IF NOT EXISTS (
        SELECT 1 FROM view_user_library_stats 
        WHERE user_id = (SELECT user_id FROM user_account WHERE username = 'empty_user')
    ) THEN
        RAISE NOTICE '[PASS] User sans jeux absent de la vue';
    ELSE
        RAISE NOTICE '[FAIL] User sans jeux présent dans la vue';
    END IF;

    -- Nettoyage
    DELETE FROM library WHERE user_id = v_user_id;
END $$;

DELETE FROM game WHERE slug IN ('game-1', 'game-2', 'game-3', 'game-4');
DELETE FROM user_account WHERE username IN ('test_user', 'empty_user');

ROLLBACK;

\echo ''
\echo '========================================'
\echo 'RÉSUMÉ : 5 tests exécutés'
\echo '========================================'
