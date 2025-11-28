-- ============================================
-- Test des triggers : updated_at auto-update
-- Vérifie que updated_at est mis à jour automatiquement
-- ============================================

\echo '========================================'
\echo 'TEST TRIGGERS: updated_at auto-update'
\echo '========================================'

BEGIN;

-- Créer données de test
INSERT INTO user_account (username, email, password)
VALUES ('test_user', 'test@example.com', '$2b$10$hashedpassword');

INSERT INTO game (title, slug)
VALUES ('Test Game', 'test-game');

INSERT INTO platform (name)
VALUES ('Test Platform');

DO $$
DECLARE
    v_user_id INTEGER;
    v_game_id INTEGER;
    v_platform_id INTEGER;
    v_library_id INTEGER;
    v_rating_id INTEGER;
    v_comment_id INTEGER;
    v_updated_at_before TIMESTAMP;
    v_updated_at_after TIMESTAMP;
BEGIN
    -- Récupérer les IDs
    SELECT user_id INTO v_user_id FROM user_account WHERE username = 'test_user';
    SELECT game_id INTO v_game_id FROM game WHERE slug = 'test-game';
    SELECT platform_id INTO v_platform_id FROM platform WHERE name = 'Test Platform';

    -- TEST 1 : Trigger library updated_at
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 1 : Trigger library updated_at';
    BEGIN
        -- Insérer dans library
        INSERT INTO library (user_id, game_id, status, owned_platform_id)
        VALUES (v_user_id, v_game_id, 'to_play', v_platform_id)
        RETURNING library_id INTO v_library_id;
        
        -- Attendre 1 seconde
        PERFORM pg_sleep(1);
        
        -- Récupérer updated_at avant update
        SELECT updated_at INTO v_updated_at_before FROM library WHERE library_id = v_library_id;
        
        -- Update
        UPDATE library SET status = 'playing' WHERE library_id = v_library_id;
        
        -- Récupérer updated_at après update
        SELECT updated_at INTO v_updated_at_after FROM library WHERE library_id = v_library_id;
        
        IF v_updated_at_after > v_updated_at_before OR (v_updated_at_before IS NULL AND v_updated_at_after IS NOT NULL) THEN
            RAISE NOTICE '[PASS] updated_at mis à jour automatiquement';
        ELSE
            RAISE NOTICE '[FAIL] updated_at non mis à jour (avant: %, après: %)', v_updated_at_before, v_updated_at_after;
        END IF;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '[FAIL] %', SQLERRM;
    END;

    -- TEST 2 : Trigger rating updated_at
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 2 : Trigger rating updated_at';
    BEGIN
        -- Insérer dans rating
        INSERT INTO rating (user_id, game_id, rating)
        VALUES (v_user_id, v_game_id, 7.5)
        RETURNING rating_id INTO v_rating_id;
        
        -- Attendre 1 seconde
        PERFORM pg_sleep(1);
        
        -- Récupérer updated_at avant update
        SELECT updated_at INTO v_updated_at_before FROM rating WHERE rating_id = v_rating_id;
        
        -- Update
        UPDATE rating SET rating = 8.5 WHERE rating_id = v_rating_id;
        
        -- Récupérer updated_at après update
        SELECT updated_at INTO v_updated_at_after FROM rating WHERE rating_id = v_rating_id;
        
        IF v_updated_at_after > v_updated_at_before OR (v_updated_at_before IS NULL AND v_updated_at_after IS NOT NULL) THEN
            RAISE NOTICE '[PASS] updated_at mis à jour automatiquement';
        ELSE
            RAISE NOTICE '[FAIL] updated_at non mis à jour (avant: %, après: %)', v_updated_at_before, v_updated_at_after;
        END IF;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '[FAIL] %', SQLERRM;
    END;

    -- TEST 3 : Trigger game_comment updated_at
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 3 : Trigger game_comment updated_at';
    BEGIN
        -- Insérer dans game_comment
        INSERT INTO game_comment (user_id, game_id, content)
        VALUES (v_user_id, v_game_id, 'Test comment')
        RETURNING comment_id INTO v_comment_id;
        
        -- Attendre 1 seconde
        PERFORM pg_sleep(1);
        
        -- Récupérer updated_at avant update
        SELECT updated_at INTO v_updated_at_before FROM game_comment WHERE comment_id = v_comment_id;
        
        -- Update
        UPDATE game_comment SET content = 'Updated comment' WHERE comment_id = v_comment_id;
        
        -- Récupérer updated_at après update
        SELECT updated_at INTO v_updated_at_after FROM game_comment WHERE comment_id = v_comment_id;
        
        IF v_updated_at_after > v_updated_at_before OR (v_updated_at_before IS NULL AND v_updated_at_after IS NOT NULL) THEN
            RAISE NOTICE '[PASS] updated_at mis à jour automatiquement';
        ELSE
            RAISE NOTICE '[FAIL] updated_at non mis à jour (avant: %, après: %)', v_updated_at_before, v_updated_at_after;
        END IF;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '[FAIL] %', SQLERRM;
    END;

    -- Nettoyage
    DELETE FROM game_comment WHERE comment_id = v_comment_id;
    DELETE FROM rating WHERE rating_id = v_rating_id;
    DELETE FROM library WHERE library_id = v_library_id;
END $$;

-- Nettoyage final
DELETE FROM platform WHERE name = 'Test Platform';
DELETE FROM game WHERE slug = 'test-game';
DELETE FROM user_account WHERE username = 'test_user';

ROLLBACK;

\echo ''
\echo '========================================'
\echo 'RÉSUMÉ : 3 tests exécutés'
\echo '========================================'
