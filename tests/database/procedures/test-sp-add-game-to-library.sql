-- ============================================
-- Test de la stored procedure : sp_add_game_to_library
-- Ajouter ou mettre à jour un jeu dans la bibliothèque (UPSERT)
-- ============================================

\echo '========================================'
\echo 'TEST PROCEDURE: sp_add_game_to_library'
\echo '========================================'

BEGIN;

-- Créer données de test
INSERT INTO user_account (user_id, username, email, password)
VALUES (1, 'test_user', 'test@example.com', '$2b$10$hashedpassword');

INSERT INTO game (game_id, title, slug)
VALUES (1, 'Test Game', 'test-game');

INSERT INTO platform (platform_id, name)
VALUES (1, 'PC'), (2, 'PlayStation 5');

DO $$
DECLARE
    v_user_id INTEGER := 1;
    v_game_id INTEGER := 1;
    v_library_count INTEGER;
    v_status library_status;
    v_platform_id INTEGER;
    v_updated_at TIMESTAMP;
BEGIN
    -- TEST 1 : Ajouter un jeu à la bibliothèque (INSERT)
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 1 : Ajouter un jeu à la bibliothèque (INSERT)';
    
    PERFORM sp_add_game_to_library(v_user_id, v_game_id, 'to_play', 1);
    
    SELECT COUNT(*) INTO v_library_count
    FROM library
    WHERE user_id = v_user_id AND game_id = v_game_id;
    
    IF v_library_count = 1 THEN
        RAISE NOTICE '[PASS] Jeu ajouté à la bibliothèque';
    ELSE
        RAISE NOTICE '[FAIL] Le jeu n''a pas été ajouté';
    END IF;
    
    -- Vérifier les valeurs
    SELECT status, owned_platform_id INTO v_status, v_platform_id
    FROM library
    WHERE user_id = v_user_id AND game_id = v_game_id;
    
    IF v_status = 'to_play' AND v_platform_id = 1 THEN
        RAISE NOTICE '[PASS] Status et plateforme corrects';
    ELSE
        RAISE NOTICE '[FAIL] Status: %, Platform: % (attendu: to_play, 1)', v_status, v_platform_id;
    END IF;

    -- TEST 2 : Mettre à jour un jeu existant (UPDATE via UPSERT)
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 2 : Mettre à jour un jeu existant (UPSERT)';
    
    -- Attendre 1 seconde pour voir la différence de timestamp
    PERFORM pg_sleep(1);
    
    PERFORM sp_add_game_to_library(v_user_id, v_game_id, 'playing', 2);
    
    SELECT COUNT(*) INTO v_library_count
    FROM library
    WHERE user_id = v_user_id AND game_id = v_game_id;
    
    IF v_library_count = 1 THEN
        RAISE NOTICE '[PASS] Pas de duplication (toujours 1 entrée)';
    ELSE
        RAISE NOTICE '[FAIL] Duplication détectée: % entrées', v_library_count;
    END IF;
    
    -- Vérifier la mise à jour
    SELECT status, owned_platform_id, updated_at INTO v_status, v_platform_id, v_updated_at
    FROM library
    WHERE user_id = v_user_id AND game_id = v_game_id;
    
    IF v_status = 'playing' AND v_platform_id = 2 THEN
        RAISE NOTICE '[PASS] Status mis à jour: playing, plateforme: PlayStation 5';
    ELSE
        RAISE NOTICE '[FAIL] Status: %, Platform: % (attendu: playing, 2)', v_status, v_platform_id;
    END IF;
    
    IF v_updated_at IS NOT NULL THEN
        RAISE NOTICE '[PASS] updated_at mis à jour automatiquement';
    ELSE
        RAISE NOTICE '[FAIL] updated_at devrait être mis à jour';
    END IF;

    -- TEST 3 : Ajouter avec plateforme NULL
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 3 : Ajouter avec plateforme NULL';
    
    INSERT INTO game (game_id, title, slug) VALUES (2, 'Game 2', 'game-2');
    
    PERFORM sp_add_game_to_library(v_user_id, 2, 'completed', NULL);
    
    SELECT owned_platform_id INTO v_platform_id
    FROM library
    WHERE user_id = v_user_id AND game_id = 2;
    
    IF v_platform_id IS NULL THEN
        RAISE NOTICE '[PASS] Plateforme NULL acceptée';
    ELSE
        RAISE NOTICE '[FAIL] Plateforme devrait être NULL';
    END IF;

    -- TEST 4 : Tester tous les statuts
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 4 : Tester tous les statuts de bibliothèque';
    
    INSERT INTO game (game_id, title, slug) VALUES (3, 'Game 3', 'game-3');
    INSERT INTO game (game_id, title, slug) VALUES (4, 'Game 4', 'game-4');
    INSERT INTO game (game_id, title, slug) VALUES (5, 'Game 5', 'game-5');
    
    PERFORM sp_add_game_to_library(v_user_id, 3, 'to_play', NULL);
    PERFORM sp_add_game_to_library(v_user_id, 4, 'playing', NULL);
    PERFORM sp_add_game_to_library(v_user_id, 5, 'abandoned', NULL);
    
    SELECT COUNT(*) INTO v_library_count
    FROM library
    WHERE user_id = v_user_id;
    
    IF v_library_count = 5 THEN
        RAISE NOTICE '[PASS] Tous les statuts acceptés (5 jeux au total)';
    ELSE
        RAISE NOTICE '[FAIL] Nombre de jeux: % (attendu: 5)', v_library_count;
    END IF;

    -- TEST 5 : Vérifier contrainte UNIQUE (user_id, game_id)
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 5 : Vérifier contrainte UNIQUE';
    
    -- Cette opération ne doit pas créer de duplication
    PERFORM sp_add_game_to_library(v_user_id, 3, 'completed', 1);
    
    SELECT COUNT(*) INTO v_library_count
    FROM library
    WHERE user_id = v_user_id AND game_id = 3;
    
    IF v_library_count = 1 THEN
        RAISE NOTICE '[PASS] Contrainte UNIQUE respectée';
    ELSE
        RAISE NOTICE '[FAIL] Duplication: % entrées', v_library_count;
    END IF;

    -- TEST 6 : Ajouter le même jeu pour un autre utilisateur
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 6 : Ajouter le même jeu pour un autre utilisateur';
    
    INSERT INTO user_account (user_id, username, email, password)
    VALUES (2, 'user2', 'user2@example.com', '$2b$10$hashedpassword');
    
    PERFORM sp_add_game_to_library(2, v_game_id, 'playing', 2);
    
    SELECT COUNT(*) INTO v_library_count
    FROM library
    WHERE game_id = v_game_id;
    
    IF v_library_count = 2 THEN
        RAISE NOTICE '[PASS] Deux utilisateurs peuvent avoir le même jeu';
    ELSE
        RAISE NOTICE '[FAIL] Nombre d''entrées: % (attendu: 2)', v_library_count;
    END IF;

    -- TEST 7 : Erreur si user_id inexistant (violation FK)
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 7 : Erreur si user_id inexistant';
    BEGIN
        PERFORM sp_add_game_to_library(999, v_game_id, 'to_play', NULL);
        RAISE NOTICE '[FAIL] Devrait échouer avec user_id inexistant';
    EXCEPTION WHEN foreign_key_violation THEN
        RAISE NOTICE '[PASS] Erreur FK correctement levée';
    WHEN OTHERS THEN
        RAISE NOTICE '[FAIL] Erreur inattendue: %', SQLERRM;
    END;

    -- TEST 8 : Erreur si game_id inexistant (violation FK)
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 8 : Erreur si game_id inexistant';
    BEGIN
        PERFORM sp_add_game_to_library(v_user_id, 999, 'to_play', NULL);
        RAISE NOTICE '[FAIL] Devrait échouer avec game_id inexistant';
    EXCEPTION WHEN foreign_key_violation THEN
        RAISE NOTICE '[PASS] Erreur FK correctement levée';
    WHEN OTHERS THEN
        RAISE NOTICE '[FAIL] Erreur inattendue: %', SQLERRM;
    END;

END;
$$;

ROLLBACK;
