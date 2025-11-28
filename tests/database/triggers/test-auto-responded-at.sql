-- ============================================
-- Test du trigger : trg_auto_set_responded_at
-- Automatise responded_at lors du traitement d'amitié
-- ============================================

\echo '========================================'
\echo 'TEST TRIGGER: trg_auto_set_responded_at'
\echo '========================================'

BEGIN;

-- Créer données de test
INSERT INTO user_account (username, email, password)
VALUES 
    ('requester', 'requester@test.com', '$2b$10$hash'),
    ('addressee', 'addressee@test.com', '$2b$10$hash');

DO $$
DECLARE
    v_requester_id INTEGER;
    v_addressee_id INTEGER;
    v_friendship_id INTEGER;
    v_responded_at TIMESTAMP;
BEGIN
    SELECT user_id INTO v_requester_id FROM user_account WHERE username = 'requester';
    SELECT user_id INTO v_addressee_id FROM user_account WHERE username = 'addressee';

    -- TEST 1 : responded_at NULL à la création
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 1 : responded_at NULL à la création';
    INSERT INTO friendship (requester_user_id, addressee_user_id, status)
    VALUES (v_requester_id, v_addressee_id, 'pending')
    RETURNING friendship_id INTO v_friendship_id;
    
    SELECT responded_at INTO v_responded_at
    FROM friendship WHERE friendship_id = v_friendship_id;
    
    IF v_responded_at IS NULL THEN
        RAISE NOTICE '[PASS] responded_at NULL pour status pending';
    ELSE
        RAISE NOTICE '[FAIL] responded_at devrait être NULL';
    END IF;

    -- TEST 2 : Auto-set responded_at lors de l'acceptation
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 2 : Auto-set responded_at lors de l''acceptation';
    
    PERFORM pg_sleep(0.1);  -- Petit délai pour garantir un timestamp différent
    
    UPDATE friendship 
    SET status = 'accepted'
    WHERE friendship_id = v_friendship_id;
    
    SELECT responded_at INTO v_responded_at
    FROM friendship WHERE friendship_id = v_friendship_id;
    
    IF v_responded_at IS NOT NULL THEN
        RAISE NOTICE '[PASS] responded_at automatiquement défini';
    ELSE
        RAISE NOTICE '[FAIL] responded_at devrait être défini';
    END IF;

    -- TEST 3 : Test avec rejected
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 3 : Auto-set responded_at lors du rejet';
    
    DELETE FROM friendship WHERE friendship_id = v_friendship_id;
    
    INSERT INTO friendship (requester_user_id, addressee_user_id, status)
    VALUES (v_requester_id, v_addressee_id, 'pending')
    RETURNING friendship_id INTO v_friendship_id;
    
    UPDATE friendship 
    SET status = 'rejected'
    WHERE friendship_id = v_friendship_id;
    
    SELECT responded_at INTO v_responded_at
    FROM friendship WHERE friendship_id = v_friendship_id;
    
    IF v_responded_at IS NOT NULL THEN
        RAISE NOTICE '[PASS] responded_at défini pour rejected';
    ELSE
        RAISE NOTICE '[FAIL] responded_at devrait être défini';
    END IF;

    -- TEST 4 : Test avec blocked
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 4 : Auto-set responded_at lors du blocage';
    
    DELETE FROM friendship WHERE friendship_id = v_friendship_id;
    
    INSERT INTO friendship (requester_user_id, addressee_user_id, status)
    VALUES (v_requester_id, v_addressee_id, 'pending')
    RETURNING friendship_id INTO v_friendship_id;
    
    UPDATE friendship 
    SET status = 'blocked'
    WHERE friendship_id = v_friendship_id;
    
    SELECT responded_at INTO v_responded_at
    FROM friendship WHERE friendship_id = v_friendship_id;
    
    IF v_responded_at IS NOT NULL THEN
        RAISE NOTICE '[PASS] responded_at défini pour blocked';
    ELSE
        RAISE NOTICE '[FAIL] responded_at devrait être défini';
    END IF;

    -- TEST 5 : Ne pas écraser responded_at existant
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 5 : Ne pas écraser responded_at existant';
    
    DECLARE
        v_original_responded_at TIMESTAMP;
    BEGIN
        v_original_responded_at := v_responded_at;
        
        PERFORM pg_sleep(0.1);
        
        -- Essayer de modifier autre chose
        UPDATE friendship 
        SET reason = 'Test update'
        WHERE friendship_id = v_friendship_id;
        
        SELECT responded_at INTO v_responded_at
        FROM friendship WHERE friendship_id = v_friendship_id;
        
        IF v_responded_at = v_original_responded_at THEN
            RAISE NOTICE '[PASS] responded_at non écrasé';
        ELSE
            RAISE NOTICE '[FAIL] responded_at ne devrait pas changer';
        END IF;
    END;

    -- Nettoyage
    DELETE FROM friendship WHERE friendship_id = v_friendship_id;
END $$;

DELETE FROM user_account WHERE username IN ('requester', 'addressee');

ROLLBACK;

\echo ''
\echo '========================================'
\echo 'RÉSUMÉ : 5 tests exécutés'
\echo '========================================'
