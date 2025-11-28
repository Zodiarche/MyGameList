-- ============================================
-- Test du trigger : trg_friendship_no_self
-- Empêche un utilisateur de s'ajouter lui-même en ami
-- ============================================

\echo '========================================'
\echo 'TEST TRIGGER: trg_friendship_no_self'
\echo '========================================'

BEGIN;

-- Créer utilisateurs de test
INSERT INTO user_account (username, email, password)
VALUES
    ('test_user1', 'test1@example.com', '$2b$10$hashedpassword'),
    ('test_user2', 'test2@example.com', '$2b$10$hashedpassword');

DO $$
DECLARE
    v_user1_id INTEGER;
    v_user2_id INTEGER;
    v_test_passed BOOLEAN;
BEGIN
    -- Récupérer les IDs
    SELECT user_id INTO v_user1_id FROM user_account WHERE username = 'test_user1';
    SELECT user_id INTO v_user2_id FROM user_account WHERE username = 'test_user2';

    -- TEST 1 : INSERT auto-amitié (doit échouer)
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 1 : INSERT auto-amitié (doit échouer)';
    v_test_passed := FALSE;
    BEGIN
        INSERT INTO friendship (requester_user_id, addressee_user_id, status)
        VALUES (v_user1_id, v_user1_id, 'pending');
        RAISE NOTICE '[FAIL] L''insertion aurait dû échouer';
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE '%Cannot add yourself as friend%' THEN
            RAISE NOTICE '[PASS] Erreur correctement déclenchée';
            v_test_passed := TRUE;
        ELSE
            RAISE NOTICE '[FAIL] Erreur inattendue: %', SQLERRM;
        END IF;
    END;

    -- TEST 2 : INSERT amitié normale (doit réussir)
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 2 : INSERT amitié normale (doit réussir)';
    BEGIN
        INSERT INTO friendship (requester_user_id, addressee_user_id, status)
        VALUES (v_user1_id, v_user2_id, 'pending');
        RAISE NOTICE '[PASS] Insertion réussie';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '[FAIL] %', SQLERRM;
    END;

    -- TEST 3 : UPDATE vers auto-amitié (doit échouer)
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 3 : UPDATE vers auto-amitié (doit échouer)';
    v_test_passed := FALSE;
    BEGIN
        UPDATE friendship
        SET addressee_user_id = requester_user_id
        WHERE requester_user_id = v_user1_id;
        RAISE NOTICE '[FAIL] L''UPDATE aurait dû échouer';
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE '%Cannot add yourself as friend%' THEN
            RAISE NOTICE '[PASS] Erreur correctement déclenchée';
            v_test_passed := TRUE;
        ELSE
            RAISE NOTICE '[FAIL] Erreur inattendue: %', SQLERRM;
        END IF;
    END;

    -- Nettoyage
    DELETE FROM friendship WHERE requester_user_id = v_user1_id;
END $$;

-- Nettoyage final
DELETE FROM user_account WHERE username IN ('test_user1', 'test_user2');

ROLLBACK;

\echo ''
\echo '========================================'
\echo 'RÉSUMÉ : 3 tests exécutés'
\echo '========================================'
