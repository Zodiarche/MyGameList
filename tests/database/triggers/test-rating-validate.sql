-- ============================================
-- Test du trigger : trg_rating_validate
-- Valide que les notes sont comprises entre 0 et 10
-- ============================================

\echo '========================================'
\echo 'TEST TRIGGER: trg_rating_validate'
\echo '========================================'

BEGIN;

-- Créer données de test
INSERT INTO user_account (username, email, password)
VALUES ('test_user', 'test@example.com', '$2b$10$hashedpassword');

INSERT INTO game (title, slug, release_date)
VALUES ('Test Game', 'test-game', '2024-01-01');

DO $$
DECLARE
    v_user_id INTEGER;
    v_game_id INTEGER;
    v_test_passed BOOLEAN;
BEGIN
    -- Récupérer les IDs
    SELECT user_id INTO v_user_id FROM user_account WHERE username = 'test_user';
    SELECT game_id INTO v_game_id FROM game WHERE slug = 'test-game';

    -- TEST 1 : INSERT note < 0 (doit échouer)
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 1 : INSERT note < 0 (doit échouer)';
    v_test_passed := FALSE;
    BEGIN
        INSERT INTO rating (user_id, game_id, rating)
        VALUES (v_user_id, v_game_id, -1.5);
        RAISE NOTICE '[FAIL] L''insertion aurait dû échouer';
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE '%Rating must be between 0 and 10%' THEN
            RAISE NOTICE '[PASS] Erreur correctement déclenchée';
            v_test_passed := TRUE;
        ELSE
            RAISE NOTICE '[FAIL] Erreur inattendue: %', SQLERRM;
        END IF;
    END;

    -- TEST 2 : INSERT note > 10 (doit échouer)
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 2 : INSERT note > 10 (doit échouer)';
    v_test_passed := FALSE;
    BEGIN
        INSERT INTO rating (user_id, game_id, rating)
        VALUES (v_user_id, v_game_id, 15.0);
        RAISE NOTICE '[FAIL] L''insertion aurait dû échouer';
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE '%Rating must be between 0 and 10%' THEN
            RAISE NOTICE '[PASS] Erreur correctement déclenchée';
            v_test_passed := TRUE;
        ELSE
            RAISE NOTICE '[FAIL] Erreur inattendue: %', SQLERRM;
        END IF;
    END;

    -- TEST 3 : INSERT note valide 0.0 (doit réussir)
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 3 : INSERT note valide 0.0 (doit réussir)';
    BEGIN
        INSERT INTO rating (user_id, game_id, rating)
        VALUES (v_user_id, v_game_id, 0.0);
        RAISE NOTICE '[PASS] Insertion réussie';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '[FAIL] %', SQLERRM;
    END;

    -- TEST 4 : UPDATE note valide 10.0 (doit réussir)
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 4 : UPDATE note valide 10.0 (doit réussir)';
    BEGIN
        UPDATE rating SET rating = 10.0
        WHERE user_id = v_user_id AND game_id = v_game_id;
        RAISE NOTICE '[PASS] Update réussi';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '[FAIL] %', SQLERRM;
    END;

    -- TEST 5 : UPDATE note invalide > 10 (doit échouer)
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 5 : UPDATE note > 10 (doit échouer)';
    v_test_passed := FALSE;
    BEGIN
        UPDATE rating SET rating = 11.0
        WHERE user_id = v_user_id AND game_id = v_game_id;
        RAISE NOTICE '[FAIL] L''UPDATE aurait dû échouer';
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE '%Rating must be between 0 and 10%' THEN
            RAISE NOTICE '[PASS] Erreur correctement déclenchée';
            v_test_passed := TRUE;
        ELSE
            RAISE NOTICE '[FAIL] Erreur inattendue: %', SQLERRM;
        END IF;
    END;

    -- Nettoyage
    DELETE FROM rating WHERE user_id = v_user_id;
END $$;

-- Nettoyage final
DELETE FROM game WHERE slug = 'test-game';
DELETE FROM user_account WHERE username = 'test_user';

ROLLBACK;

\echo ''
\echo '========================================'
\echo 'RÉSUMÉ : 5 tests exécutés'
\echo '========================================'
