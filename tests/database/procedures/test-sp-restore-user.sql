-- ============================================
-- Test de la stored procedure : sp_restore_user
-- Restaurer un utilisateur supprimé (annuler soft delete)
-- ============================================

\echo '========================================'
\echo 'TEST PROCEDURE: sp_restore_user'
\echo '========================================'

BEGIN;

-- Créer données de test
INSERT INTO user_account (user_id, username, email, password, is_active) VALUES
(1, 'active_user', 'active@test.com', '$2b$10$hashedpassword', TRUE),
(2, 'deleted_user', 'deleted@test.com', '$2b$10$hashedpassword', FALSE),
(3, 'another_deleted', 'another@test.com', '$2b$10$hashedpassword', FALSE);

-- Marquer les utilisateurs 2 et 3 comme supprimés
UPDATE user_account SET deleted_at = CURRENT_TIMESTAMP - INTERVAL '10 days'
WHERE user_id IN (2, 3);

DO $$
DECLARE
    v_deleted_at TIMESTAMP;
    v_is_active BOOLEAN;
BEGIN
    -- TEST 1 : Restaurer un utilisateur supprimé
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 1 : Restaurer un utilisateur supprimé';
    
    PERFORM sp_restore_user(2);
    
    SELECT deleted_at, is_active INTO v_deleted_at, v_is_active
    FROM user_account
    WHERE user_id = 2;
    
    IF v_deleted_at IS NULL THEN
        RAISE NOTICE '[PASS] deleted_at mis à NULL';
    ELSE
        RAISE NOTICE '[FAIL] deleted_at devrait être NULL';
    END IF;
    
    IF v_is_active = TRUE THEN
        RAISE NOTICE '[PASS] is_active mis à TRUE';
    ELSE
        RAISE NOTICE '[FAIL] is_active devrait être TRUE';
    END IF;

    -- TEST 2 : Erreur si utilisateur déjà actif
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 2 : Erreur si utilisateur déjà actif';
    BEGIN
        PERFORM sp_restore_user(1);  -- Utilisateur jamais supprimé
        RAISE NOTICE '[FAIL] Devrait échouer (déjà actif)';
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE '%Utilisateur introuvable ou non supprimé%' THEN
            RAISE NOTICE '[PASS] Erreur correctement levée';
        ELSE
            RAISE NOTICE '[FAIL] Erreur inattendue: %', SQLERRM;
        END IF;
    END;

    -- TEST 3 : Erreur si utilisateur restauré deux fois
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 3 : Erreur si utilisateur déjà restauré';
    BEGIN
        PERFORM sp_restore_user(2);  -- Déjà restauré au TEST 1
        RAISE NOTICE '[FAIL] Devrait échouer (déjà restauré)';
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE '%Utilisateur introuvable ou non supprimé%' THEN
            RAISE NOTICE '[PASS] Erreur correctement levée';
        ELSE
            RAISE NOTICE '[FAIL] Erreur inattendue: %', SQLERRM;
        END IF;
    END;

    -- TEST 4 : Erreur si user_id inexistant
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 4 : Erreur si user_id inexistant';
    BEGIN
        PERFORM sp_restore_user(999);
        RAISE NOTICE '[FAIL] Devrait échouer (user_id inexistant)';
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE '%Utilisateur introuvable ou non supprimé%' THEN
            RAISE NOTICE '[PASS] Erreur correctement levée';
        ELSE
            RAISE NOTICE '[FAIL] Erreur inattendue: %', SQLERRM;
        END IF;
    END;

    -- TEST 5 : Restaurer le deuxième utilisateur supprimé
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 5 : Restaurer le deuxième utilisateur supprimé';
    
    PERFORM sp_restore_user(3);
    
    SELECT deleted_at, is_active INTO v_deleted_at, v_is_active
    FROM user_account
    WHERE user_id = 3;
    
    IF v_deleted_at IS NULL AND v_is_active = TRUE THEN
        RAISE NOTICE '[PASS] Deuxième utilisateur restauré';
    ELSE
        RAISE NOTICE '[FAIL] deleted_at: %, is_active: %', v_deleted_at, v_is_active;
    END IF;

    -- TEST 6 : Vérifier que l'utilisateur restauré apparaît dans les requêtes
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 6 : Utilisateur restauré visible dans requêtes';
    
    DECLARE
        v_active_count INTEGER;
    BEGIN
        SELECT COUNT(*) INTO v_active_count
        FROM user_account
        WHERE deleted_at IS NULL;
        
        IF v_active_count = 3 THEN
            RAISE NOTICE '[PASS] 3 utilisateurs actifs (tous restaurés)';
        ELSE
            RAISE NOTICE '[FAIL] Nombre d''utilisateurs actifs: % (attendu: 3)', v_active_count;
        END IF;
    END;

    -- TEST 7 : Cycle complet suppression/restauration
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 7 : Cycle complet suppression puis restauration';
    
    INSERT INTO user_account (user_id, username, email, password)
    VALUES (4, 'cycle_user', 'cycle@test.com', '$2b$10$hashedpassword');
    
    -- Supprimer
    PERFORM sp_soft_delete_user(4);
    
    SELECT deleted_at, is_active INTO v_deleted_at, v_is_active
    FROM user_account WHERE user_id = 4;
    
    IF v_deleted_at IS NOT NULL AND v_is_active = FALSE THEN
        RAISE NOTICE '[PASS] Utilisateur supprimé';
    ELSE
        RAISE NOTICE '[FAIL] Échec de suppression';
    END IF;
    
    -- Restaurer
    PERFORM sp_restore_user(4);
    
    SELECT deleted_at, is_active INTO v_deleted_at, v_is_active
    FROM user_account WHERE user_id = 4;
    
    IF v_deleted_at IS NULL AND v_is_active = TRUE THEN
        RAISE NOTICE '[PASS] Utilisateur restauré après suppression';
    ELSE
        RAISE NOTICE '[FAIL] Échec de restauration';
    END IF;

    -- TEST 8 : Les données liées restent intactes
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 8 : Données liées restent intactes après restauration';
    
    INSERT INTO game (game_id, title, slug) VALUES (1, 'Test Game', 'test-game');
    INSERT INTO library (user_id, game_id, status) VALUES (4, 1, 'playing');
    INSERT INTO rating (user_id, game_id, rating) VALUES (4, 1, 8.5);
    
    -- Supprimer et restaurer
    PERFORM sp_soft_delete_user(4);
    PERFORM sp_restore_user(4);
    
    DECLARE
        v_library_exists BOOLEAN;
        v_rating_exists BOOLEAN;
    BEGIN
        SELECT EXISTS(SELECT 1 FROM library WHERE user_id = 4) INTO v_library_exists;
        SELECT EXISTS(SELECT 1 FROM rating WHERE user_id = 4) INTO v_rating_exists;
        
        IF v_library_exists AND v_rating_exists THEN
            RAISE NOTICE '[PASS] Données liées préservées après restauration';
        ELSE
            RAISE NOTICE '[FAIL] Données perdues: library=%, rating=%', v_library_exists, v_rating_exists;
        END IF;
    END;

    -- TEST 9 : Multiples suppressions/restaurations
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 9 : Multiples cycles suppression/restauration';
    
    PERFORM sp_soft_delete_user(4);
    PERFORM sp_restore_user(4);
    PERFORM sp_soft_delete_user(4);
    PERFORM sp_restore_user(4);
    
    SELECT deleted_at, is_active INTO v_deleted_at, v_is_active
    FROM user_account WHERE user_id = 4;
    
    IF v_deleted_at IS NULL AND v_is_active = TRUE THEN
        RAISE NOTICE '[PASS] Multiples cycles fonctionnent correctement';
    ELSE
        RAISE NOTICE '[FAIL] État final incorrect';
    END IF;

    -- TEST 10 : Statistiques finales
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 10 : Statistiques finales';
    
    DECLARE
        v_total INTEGER;
        v_active INTEGER;
        v_deleted INTEGER;
    BEGIN
        SELECT COUNT(*) INTO v_total FROM user_account;
        SELECT COUNT(*) INTO v_active FROM user_account WHERE deleted_at IS NULL;
        SELECT COUNT(*) INTO v_deleted FROM user_account WHERE deleted_at IS NOT NULL;
        
        RAISE NOTICE '[INFO] Total utilisateurs: %', v_total;
        RAISE NOTICE '[INFO] Utilisateurs actifs: %', v_active;
        RAISE NOTICE '[INFO] Utilisateurs supprimés: %', v_deleted;
        
        IF v_active = 4 AND v_deleted = 0 THEN
            RAISE NOTICE '[PASS] Tous les utilisateurs sont actifs';
        ELSE
            RAISE NOTICE '[INFO] Actifs: %, Supprimés: %', v_active, v_deleted;
        END IF;
    END;

END;
$$;

ROLLBACK;
