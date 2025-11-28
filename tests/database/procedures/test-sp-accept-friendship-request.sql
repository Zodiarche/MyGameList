-- ============================================
-- Test de la stored procedure : sp_accept_friendship_request
-- Accepter une demande d'amitié en attente
-- ============================================

\echo '========================================'
\echo 'TEST PROCEDURE: sp_accept_friendship_request'
\echo '========================================'

BEGIN;

-- Créer données de test
INSERT INTO user_account (user_id, username, email, password) VALUES
(1, 'alice', 'alice@test.com', '$2b$10$hashedpassword'),
(2, 'bob', 'bob@test.com', '$2b$10$hashedpassword'),
(3, 'charlie', 'charlie@test.com', '$2b$10$hashedpassword');

-- Créer des demandes d'amitié
INSERT INTO friendship (friendship_id, requester_user_id, addressee_user_id, status, requested_at) VALUES
(1, 1, 2, 'pending', CURRENT_TIMESTAMP - INTERVAL '2 days'),
(2, 1, 3, 'pending', CURRENT_TIMESTAMP - INTERVAL '1 day'),
(3, 2, 3, 'accepted', CURRENT_TIMESTAMP - INTERVAL '5 days');

DO $$
DECLARE
    v_status friendship_status;
    v_responded_at TIMESTAMP;
BEGIN
    -- TEST 1 : Accepter une demande d'amitié valide
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 1 : Accepter une demande d''amitié valide';
    
    PERFORM sp_accept_friendship_request(1, 2);
    
    SELECT status, responded_at INTO v_status, v_responded_at
    FROM friendship
    WHERE friendship_id = 1;
    
    IF v_status = 'accepted' THEN
        RAISE NOTICE '[PASS] Status mis à jour: accepted';
    ELSE
        RAISE NOTICE '[FAIL] Status: % (attendu: accepted)', v_status;
    END IF;
    
    IF v_responded_at IS NOT NULL THEN
        RAISE NOTICE '[PASS] responded_at mis à jour automatiquement';
    ELSE
        RAISE NOTICE '[FAIL] responded_at devrait être défini';
    END IF;

    -- TEST 2 : Accepter une autre demande
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 2 : Accepter une autre demande (charlie accepte alice)';
    
    PERFORM sp_accept_friendship_request(2, 3);
    
    SELECT status INTO v_status
    FROM friendship
    WHERE friendship_id = 2;
    
    IF v_status = 'accepted' THEN
        RAISE NOTICE '[PASS] Deuxième demande acceptée';
    ELSE
        RAISE NOTICE '[FAIL] Status: % (attendu: accepted)', v_status;
    END IF;

    -- TEST 3 : Erreur si demande déjà acceptée
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 3 : Erreur si demande déjà acceptée';
    BEGIN
        PERFORM sp_accept_friendship_request(1, 2);
        RAISE NOTICE '[FAIL] Devrait échouer (demande déjà traitée)';
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE '%Demande d''amitié introuvable ou déjà traitée%' THEN
            RAISE NOTICE '[PASS] Erreur correctement levée';
        ELSE
            RAISE NOTICE '[FAIL] Erreur inattendue: %', SQLERRM;
        END IF;
    END;

    -- TEST 4 : Erreur si friendship_id inexistant
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 4 : Erreur si friendship_id inexistant';
    BEGIN
        PERFORM sp_accept_friendship_request(999, 2);
        RAISE NOTICE '[FAIL] Devrait échouer (friendship_id inexistant)';
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE '%Demande d''amitié introuvable ou déjà traitée%' THEN
            RAISE NOTICE '[PASS] Erreur correctement levée';
        ELSE
            RAISE NOTICE '[FAIL] Erreur inattendue: %', SQLERRM;
        END IF;
    END;

    -- TEST 5 : Erreur si addressee_user_id incorrect
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 5 : Erreur si addressee_user_id incorrect';
    
    -- Créer une nouvelle demande
    INSERT INTO friendship (friendship_id, requester_user_id, addressee_user_id, status, requested_at)
    VALUES (4, 3, 1, 'pending', CURRENT_TIMESTAMP);
    
    BEGIN
        -- Essayer d'accepter avec le mauvais addressee
        PERFORM sp_accept_friendship_request(4, 2);  -- Devrait être 1
        RAISE NOTICE '[FAIL] Devrait échouer (mauvais addressee)';
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE '%Demande d''amitié introuvable ou déjà traitée%' THEN
            RAISE NOTICE '[PASS] Erreur correctement levée (protection)';
        ELSE
            RAISE NOTICE '[FAIL] Erreur inattendue: %', SQLERRM;
        END IF;
    END;

    -- TEST 6 : Le bon addressee peut accepter
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 6 : Le bon addressee peut accepter';
    
    PERFORM sp_accept_friendship_request(4, 1);
    
    SELECT status INTO v_status
    FROM friendship
    WHERE friendship_id = 4;
    
    IF v_status = 'accepted' THEN
        RAISE NOTICE '[PASS] Demande acceptée par le bon addressee';
    ELSE
        RAISE NOTICE '[FAIL] Status: % (attendu: accepted)', v_status;
    END IF;

    -- TEST 7 : Seules les demandes 'pending' peuvent être acceptées
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 7 : Seules les demandes pending peuvent être acceptées';
    
    -- friendship_id 3 est déjà 'accepted'
    BEGIN
        PERFORM sp_accept_friendship_request(3, 3);
        RAISE NOTICE '[FAIL] Devrait échouer (status != pending)';
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE '%Demande d''amitié introuvable ou déjà traitée%' THEN
            RAISE NOTICE '[PASS] Demande non-pending rejetée';
        ELSE
            RAISE NOTICE '[FAIL] Erreur inattendue: %', SQLERRM;
        END IF;
    END;

    -- TEST 8 : Vérifier que responded_at est proche de CURRENT_TIMESTAMP
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 8 : Vérifier timestamp responded_at';
    
    DECLARE
        v_time_diff INTERVAL;
    BEGIN
        SELECT CURRENT_TIMESTAMP - responded_at INTO v_time_diff
        FROM friendship
        WHERE friendship_id = 1;
        
        IF v_time_diff < INTERVAL '5 seconds' THEN
            RAISE NOTICE '[PASS] responded_at correctement défini (< 5s)';
        ELSE
            RAISE NOTICE '[FAIL] responded_at trop ancien: %', v_time_diff;
        END IF;
    END;

    -- TEST 9 : Créer demande, rejeter, puis tenter d'accepter
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 9 : Demande rejetée ne peut pas être acceptée';
    
    INSERT INTO friendship (friendship_id, requester_user_id, addressee_user_id, status, requested_at)
    VALUES (5, 2, 1, 'pending', CURRENT_TIMESTAMP);
    
    -- Simuler un rejet manuel
    UPDATE friendship SET status = 'rejected', responded_at = CURRENT_TIMESTAMP
    WHERE friendship_id = 5;
    
    BEGIN
        PERFORM sp_accept_friendship_request(5, 1);
        RAISE NOTICE '[FAIL] Demande rejetée ne devrait pas être acceptée';
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE '%Demande d''amitié introuvable ou déjà traitée%' THEN
            RAISE NOTICE '[PASS] Demande rejetée correctement refusée';
        ELSE
            RAISE NOTICE '[FAIL] Erreur inattendue: %', SQLERRM;
        END IF;
    END;

    -- TEST 10 : Statistiques finales
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 10 : Statistiques finales';
    
    DECLARE
        v_accepted_count INTEGER;
        v_pending_count INTEGER;
    BEGIN
        SELECT COUNT(*) INTO v_accepted_count FROM friendship WHERE status = 'accepted';
        SELECT COUNT(*) INTO v_pending_count FROM friendship WHERE status = 'pending';
        
        RAISE NOTICE '[INFO] Amitiés acceptées: %', v_accepted_count;
        RAISE NOTICE '[INFO] Demandes en attente: %', v_pending_count;
        
        IF v_accepted_count = 4 THEN
            RAISE NOTICE '[PASS] Nombre d''amitiés acceptées correct';
        ELSE
            RAISE NOTICE '[FAIL] Nombre incorrect: % (attendu: 4)', v_accepted_count;
        END IF;
    END;

END;
$$;

ROLLBACK;
