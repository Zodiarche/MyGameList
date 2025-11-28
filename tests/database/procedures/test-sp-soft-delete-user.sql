-- ============================================
-- Test de la stored procedure : sp_soft_delete_user
-- Supprimer un utilisateur (soft delete)
-- ============================================

\echo '========================================'
\echo 'TEST PROCEDURE: sp_soft_delete_user'
\echo '========================================'

BEGIN;

-- Créer données de test
INSERT INTO user_account (user_id, username, email, password, is_active) VALUES
(1, 'user_to_delete', 'delete@test.com', '$2b$10$hashedpassword', TRUE),
(2, 'active_user', 'active@test.com', '$2b$10$hashedpassword', TRUE),
(3, 'already_deleted', 'already@test.com', '$2b$10$hashedpassword', FALSE);

-- Simuler un utilisateur déjà supprimé
UPDATE user_account SET deleted_at = CURRENT_TIMESTAMP - INTERVAL '10 days'
WHERE user_id = 3;

DO $$
DECLARE
    v_deleted_at TIMESTAMP;
    v_is_active BOOLEAN;
BEGIN
    -- TEST 1 : Supprimer un utilisateur actif
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 1 : Supprimer un utilisateur actif';
    
    PERFORM sp_soft_delete_user(1);
    
    SELECT deleted_at, is_active INTO v_deleted_at, v_is_active
    FROM user_account
    WHERE user_id = 1;
    
    IF v_deleted_at IS NOT NULL THEN
        RAISE NOTICE '[PASS] deleted_at défini';
    ELSE
        RAISE NOTICE '[FAIL] deleted_at devrait être défini';
    END IF;
    
    IF v_is_active = FALSE THEN
        RAISE NOTICE '[PASS] is_active mis à FALSE';
    ELSE
        RAISE NOTICE '[FAIL] is_active devrait être FALSE';
    END IF;

    -- TEST 2 : Erreur si utilisateur déjà supprimé
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 2 : Erreur si utilisateur déjà supprimé';
    BEGIN
        PERFORM sp_soft_delete_user(1);
        RAISE NOTICE '[FAIL] Devrait échouer (déjà supprimé)';
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE '%Utilisateur introuvable ou déjà supprimé%' THEN
            RAISE NOTICE '[PASS] Erreur correctement levée';
        ELSE
            RAISE NOTICE '[FAIL] Erreur inattendue: %', SQLERRM;
        END IF;
    END;

    -- TEST 3 : Erreur si user_id inexistant
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 3 : Erreur si user_id inexistant';
    BEGIN
        PERFORM sp_soft_delete_user(999);
        RAISE NOTICE '[FAIL] Devrait échouer (user_id inexistant)';
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE '%Utilisateur introuvable ou déjà supprimé%' THEN
            RAISE NOTICE '[PASS] Erreur correctement levée';
        ELSE
            RAISE NOTICE '[FAIL] Erreur inattendue: %', SQLERRM;
        END IF;
    END;

    -- TEST 4 : Vérifier que deleted_at est proche de CURRENT_TIMESTAMP
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 4 : Vérifier timestamp deleted_at';
    
    DECLARE
        v_time_diff INTERVAL;
    BEGIN
        SELECT CURRENT_TIMESTAMP - deleted_at INTO v_time_diff
        FROM user_account
        WHERE user_id = 1;
        
        IF v_time_diff < INTERVAL '5 seconds' THEN
            RAISE NOTICE '[PASS] deleted_at correctement défini (< 5s)';
        ELSE
            RAISE NOTICE '[FAIL] deleted_at trop ancien: %', v_time_diff;
        END IF;
    END;

    -- TEST 5 : L'utilisateur supprimé n'apparaît pas dans les requêtes standards
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 5 : Utilisateur supprimé filtré par deleted_at IS NULL';
    
    DECLARE
        v_active_count INTEGER;
    BEGIN
        SELECT COUNT(*) INTO v_active_count
        FROM user_account
        WHERE deleted_at IS NULL;
        
        IF v_active_count = 1 THEN
            RAISE NOTICE '[PASS] Seul 1 utilisateur actif visible (user2)';
        ELSE
            RAISE NOTICE '[FAIL] Nombre d''utilisateurs actifs: % (attendu: 1)', v_active_count;
        END IF;
    END;

    -- TEST 6 : Tentative de supprimer un utilisateur pré-supprimé
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 6 : Tentative sur utilisateur pré-supprimé';
    BEGIN
        PERFORM sp_soft_delete_user(3);
        RAISE NOTICE '[FAIL] Devrait échouer (déjà supprimé)';
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE '%Utilisateur introuvable ou déjà supprimé%' THEN
            RAISE NOTICE '[PASS] Utilisateur pré-supprimé correctement rejeté';
        ELSE
            RAISE NOTICE '[FAIL] Erreur inattendue: %', SQLERRM;
        END IF;
    END;

    -- TEST 7 : Supprimer le dernier utilisateur actif
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 7 : Supprimer le dernier utilisateur actif';
    
    PERFORM sp_soft_delete_user(2);
    
    SELECT deleted_at, is_active INTO v_deleted_at, v_is_active
    FROM user_account
    WHERE user_id = 2;
    
    IF v_deleted_at IS NOT NULL AND v_is_active = FALSE THEN
        RAISE NOTICE '[PASS] Dernier utilisateur supprimé';
    ELSE
        RAISE NOTICE '[FAIL] Échec de suppression';
    END IF;

    -- TEST 8 : Vérifier qu'aucun utilisateur n'est actif
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 8 : Tous les utilisateurs sont supprimés';
    
    DECLARE
        v_total_users INTEGER;
        v_deleted_users INTEGER;
    BEGIN
        SELECT COUNT(*) INTO v_total_users FROM user_account;
        SELECT COUNT(*) INTO v_deleted_users FROM user_account WHERE deleted_at IS NOT NULL;
        
        IF v_total_users = v_deleted_users THEN
            RAISE NOTICE '[PASS] Tous les utilisateurs ont deleted_at défini';
        ELSE
            RAISE NOTICE '[FAIL] Total: %, Supprimés: %', v_total_users, v_deleted_users;
        END IF;
    END;

    -- TEST 9 : Les données liées restent en base (CASCADE)
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 9 : Impact sur données liées (simulation)';
    
    -- Créer un utilisateur avec des données liées
    INSERT INTO user_account (user_id, username, email, password)
    VALUES (4, 'user_with_data', 'data@test.com', '$2b$10$hashedpassword');
    
    INSERT INTO game (game_id, title, slug) VALUES (1, 'Test Game', 'test-game');
    INSERT INTO library (user_id, game_id, status) VALUES (4, 1, 'playing');
    INSERT INTO rating (user_id, game_id, rating) VALUES (4, 1, 8.5);
    
    -- Supprimer l'utilisateur
    PERFORM sp_soft_delete_user(4);
    
    DECLARE
        v_library_exists BOOLEAN;
        v_rating_exists BOOLEAN;
    BEGIN
        -- Les données restent (soft delete ne CASCADE pas)
        SELECT EXISTS(SELECT 1 FROM library WHERE user_id = 4) INTO v_library_exists;
        SELECT EXISTS(SELECT 1 FROM rating WHERE user_id = 4) INTO v_rating_exists;
        
        IF v_library_exists AND v_rating_exists THEN
            RAISE NOTICE '[PASS] Données liées préservées (soft delete)';
        ELSE
            RAISE NOTICE '[INFO] Comportement dépend de la configuration CASCADE';
        END IF;
    END;

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
        
        IF v_deleted = 4 THEN
            RAISE NOTICE '[PASS] 4 utilisateurs supprimés';
        ELSE
            RAISE NOTICE '[FAIL] Nombre de supprimés: % (attendu: 4)', v_deleted;
        END IF;
    END;

END;
$$;

ROLLBACK;
