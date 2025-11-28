-- ============================================
-- Tests unitaires pour la vue view_friendship_pending_requests
-- ============================================

\echo '========================================'
\echo 'TEST VUE: view_friendship_pending_requests'
\echo '========================================'

BEGIN;

-- Nettoyage
DELETE FROM friendship;
DELETE FROM user_account WHERE user_id > 0;

-- Données de test
INSERT INTO user_account (user_id, username, email, password, bio, avatar) VALUES
(1, 'alice', 'alice@test.com', '$2a$10$test', 'Alice bio', 'alice.jpg'),
(2, 'bob', 'bob@test.com', '$2a$10$test', 'Bob bio', 'bob.jpg'),
(3, 'charlie', 'charlie@test.com', '$2a$10$test', 'Charlie bio', 'charlie.jpg'),
(4, 'david', 'david@test.com', '$2a$10$test', 'David bio', 'david.jpg'),
(5, 'deleted_requester', 'req@test.com', '$2a$10$test', 'Deleted', NULL),
(6, 'deleted_addressee', 'addr@test.com', '$2a$10$test', 'Deleted', NULL);

-- Supprimer utilisateurs 5 et 6
UPDATE user_account SET deleted_at = CURRENT_TIMESTAMP WHERE user_id IN (5, 6);

-- Créer différents types de relations d'amitié
INSERT INTO friendship (requester_user_id, addressee_user_id, status, requested_at, responded_at) VALUES
-- Demandes en attente (doivent apparaître)
(1, 2, 'pending', CURRENT_TIMESTAMP - INTERVAL '2 days', NULL),
(2, 3, 'pending', CURRENT_TIMESTAMP - INTERVAL '1 day', NULL),
(3, 4, 'pending', CURRENT_TIMESTAMP - INTERVAL '3 hours', NULL),

-- Amitiés acceptées (ne doivent PAS apparaître)
(1, 3, 'accepted', CURRENT_TIMESTAMP - INTERVAL '10 days', CURRENT_TIMESTAMP - INTERVAL '9 days'),

-- Demandes rejetées (ne doivent PAS apparaître)
(1, 4, 'rejected', CURRENT_TIMESTAMP - INTERVAL '5 days', CURRENT_TIMESTAMP - INTERVAL '4 days'),

-- Utilisateur bloqué (ne doit PAS apparaître)
(2, 4, 'blocked', CURRENT_TIMESTAMP - INTERVAL '7 days', CURRENT_TIMESTAMP - INTERVAL '6 days'),

-- Demandes impliquant utilisateurs supprimés (ne doivent PAS apparaître)
(5, 1, 'pending', CURRENT_TIMESTAMP - INTERVAL '1 day', NULL),  -- requester supprimé
(2, 6, 'pending', CURRENT_TIMESTAMP - INTERVAL '1 day', NULL);  -- addressee supprimé

\echo ''
\echo '--- Test 1: Vérifier que la vue existe ---'
SELECT EXISTS (
    SELECT 1 
    FROM information_schema.views 
    WHERE table_schema = 'public' 
    AND table_name = 'view_friendship_pending_requests'
) AS "Vue view_friendship_pending_requests existe";

\echo ''
\echo '--- Test 2: Lister toutes les demandes en attente ---'
SELECT 
    friendship_id,
    requester_username,
    addressee_username,
    requested_at
FROM view_friendship_pending_requests
ORDER BY requested_at DESC;
-- Attendu: 3 demandes (alice->bob, bob->charlie, charlie->david)

\echo ''
\echo '--- Test 3: Demandes reçues par Bob (addressee) ---'
SELECT 
    friendship_id,
    requester_user_id,
    requester_username,
    requester_bio,
    requester_avatar,
    requested_at
FROM view_friendship_pending_requests
WHERE addressee_user_id = 2;
-- Attendu: 1 demande (de alice)

\echo ''
\echo '--- Test 4: Demandes envoyées par Charlie (requester) ---'
SELECT 
    friendship_id,
    addressee_user_id,
    addressee_username,
    requested_at
FROM view_friendship_pending_requests
WHERE requester_user_id = 3;
-- Attendu: 1 demande (à david)

\echo ''
\echo '--- Test 5: Vérifier le filtrage des statuts ---'
DO $$
DECLARE
    v_pending_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_pending_count FROM view_friendship_pending_requests;
    
    IF v_pending_count = 3 THEN
        RAISE NOTICE '[PASS] Seules les demandes "pending" sont visibles (3)';
    ELSE
        RAISE NOTICE '[FAIL] Nombre incorrect: % (attendu: 3)', v_pending_count;
    END IF;
    
    -- Vérifier qu'aucune amitié acceptée n'est présente
    IF NOT EXISTS (
        SELECT 1 FROM view_friendship_pending_requests 
        WHERE requester_user_id = 1 AND addressee_user_id = 3
    ) THEN
        RAISE NOTICE '[PASS] Amitiés acceptées correctement exclues';
    ELSE
        RAISE NOTICE '[FAIL] Une amitié acceptée est visible dans la vue';
    END IF;
    
    -- Vérifier qu'aucune demande rejetée n'est présente
    IF NOT EXISTS (
        SELECT 1 FROM view_friendship_pending_requests 
        WHERE requester_user_id = 1 AND addressee_user_id = 4
    ) THEN
        RAISE NOTICE '[PASS] Demandes rejetées correctement exclues';
    ELSE
        RAISE NOTICE '[FAIL] Une demande rejetée est visible dans la vue';
    END IF;
END;
$$;

\echo ''
\echo '--- Test 6: Vérifier exclusion utilisateurs supprimés ---'
DO $$
BEGIN
    -- Vérifier que deleted_requester n'apparaît pas
    IF NOT EXISTS (
        SELECT 1 FROM view_friendship_pending_requests 
        WHERE requester_user_id = 5
    ) THEN
        RAISE NOTICE '[PASS] Demandes de requester supprimé exclues';
    ELSE
        RAISE NOTICE '[FAIL] Une demande de requester supprimé est visible';
    END IF;
    
    -- Vérifier que deleted_addressee n'apparaît pas
    IF NOT EXISTS (
        SELECT 1 FROM view_friendship_pending_requests 
        WHERE addressee_user_id = 6
    ) THEN
        RAISE NOTICE '[PASS] Demandes vers addressee supprimé exclues';
    ELSE
        RAISE NOTICE '[FAIL] Une demande vers addressee supprimé est visible';
    END IF;
END;
$$;

\echo ''
\echo '--- Test 7: Vérifier la présence des informations utilisateur ---'
SELECT 
    requester_username,
    requester_avatar,
    requester_bio,
    addressee_username
FROM view_friendship_pending_requests
WHERE requester_user_id = 1;
-- Attendu: alice, alice.jpg, Alice bio, bob

\echo ''
\echo '--- Test 8: Vérifier que responded_at est NULL ---'
DO $$
DECLARE
    v_responded_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_responded_count
    FROM friendship
    WHERE friendship_id IN (
        SELECT friendship_id FROM view_friendship_pending_requests
    )
    AND responded_at IS NOT NULL;
    
    IF v_responded_count = 0 THEN
        RAISE NOTICE '[PASS] Toutes les demandes pending ont responded_at = NULL';
    ELSE
        RAISE NOTICE '[FAIL] % demandes avec responded_at non NULL', v_responded_count;
    END IF;
END;
$$;

ROLLBACK;
