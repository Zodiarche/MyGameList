-- ============================================
-- Test de la stored procedure : sp_soft_delete_comment
-- Supprimer un commentaire (soft delete avec contrôle de permissions)
-- ============================================

\echo '========================================'
\echo 'TEST PROCEDURE: sp_soft_delete_comment'
\echo '========================================'

BEGIN;

-- Créer données de test
INSERT INTO user_account (user_id, username, email, password, role) VALUES
(1, 'comment_owner', 'owner@test.com', '$2b$10$hashedpassword', 'member'),
(2, 'other_user', 'other@test.com', '$2b$10$hashedpassword', 'member'),
(3, 'admin', 'admin@test.com', '$2b$10$hashedpassword', 'administrator'),
(4, 'deleted_user', 'deleted@test.com', '$2b$10$hashedpassword', 'member');

-- Marquer l'utilisateur 4 comme supprimé
UPDATE user_account SET deleted_at = CURRENT_TIMESTAMP WHERE user_id = 4;

INSERT INTO game (game_id, title, slug) VALUES (1, 'Test Game', 'test-game');

-- Créer des commentaires
INSERT INTO game_comment (comment_id, user_id, game_id, content) VALUES
(1, 1, 1, 'Comment by owner'),
(2, 1, 1, 'Another comment by owner'),
(3, 2, 1, 'Comment by other user'),
(4, 1, 1, 'Already deleted comment');

-- Marquer le commentaire 4 comme déjà supprimé
UPDATE game_comment SET deleted_at = CURRENT_TIMESTAMP - INTERVAL '5 days'
WHERE comment_id = 4;

DO $$
DECLARE
    v_deleted_at TIMESTAMP;
BEGIN
    -- TEST 1 : Le propriétaire peut supprimer son commentaire
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 1 : Le propriétaire peut supprimer son commentaire';
    
    PERFORM sp_soft_delete_comment(1, 1);
    
    SELECT deleted_at INTO v_deleted_at
    FROM game_comment
    WHERE comment_id = 1;
    
    IF v_deleted_at IS NOT NULL THEN
        RAISE NOTICE '[PASS] Commentaire supprimé par le propriétaire';
    ELSE
        RAISE NOTICE '[FAIL] deleted_at devrait être défini';
    END IF;

    -- TEST 2 : Un autre utilisateur ne peut PAS supprimer le commentaire
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 2 : Un autre utilisateur ne peut PAS supprimer';
    BEGIN
        PERFORM sp_soft_delete_comment(2, 2);  -- user2 essaie de supprimer comment_id 2 (de user1)
        RAISE NOTICE '[FAIL] Devrait échouer (pas le propriétaire)';
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE '%Commentaire introuvable, déjà supprimé ou non autorisé%' THEN
            RAISE NOTICE '[PASS] Erreur de permission correctement levée';
        ELSE
            RAISE NOTICE '[FAIL] Erreur inattendue: %', SQLERRM;
        END IF;
    END;

    -- TEST 3 : Un administrateur PEUT supprimer n'importe quel commentaire
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 3 : Un administrateur peut supprimer n''importe quel commentaire';
    
    PERFORM sp_soft_delete_comment(2, 3);  -- admin supprime comment_id 2
    
    SELECT deleted_at INTO v_deleted_at
    FROM game_comment
    WHERE comment_id = 2;
    
    IF v_deleted_at IS NOT NULL THEN
        RAISE NOTICE '[PASS] Administrateur peut supprimer n''importe quel commentaire';
    ELSE
        RAISE NOTICE '[FAIL] deleted_at devrait être défini';
    END IF;

    -- TEST 4 : Erreur si commentaire déjà supprimé
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 4 : Erreur si commentaire déjà supprimé';
    BEGIN
        PERFORM sp_soft_delete_comment(1, 1);  -- Déjà supprimé au TEST 1
        RAISE NOTICE '[FAIL] Devrait échouer (déjà supprimé)';
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE '%Commentaire introuvable, déjà supprimé ou non autorisé%' THEN
            RAISE NOTICE '[PASS] Erreur correctement levée';
        ELSE
            RAISE NOTICE '[FAIL] Erreur inattendue: %', SQLERRM;
        END IF;
    END;

    -- TEST 5 : Erreur si comment_id inexistant
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 5 : Erreur si comment_id inexistant';
    BEGIN
        PERFORM sp_soft_delete_comment(999, 1);
        RAISE NOTICE '[FAIL] Devrait échouer (comment_id inexistant)';
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE '%Commentaire introuvable, déjà supprimé ou non autorisé%' THEN
            RAISE NOTICE '[PASS] Erreur correctement levée';
        ELSE
            RAISE NOTICE '[FAIL] Erreur inattendue: %', SQLERRM;
        END IF;
    END;

    -- TEST 6 : Le propriétaire peut supprimer son propre commentaire
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 6 : Le propriétaire supprime son propre commentaire';
    
    PERFORM sp_soft_delete_comment(3, 2);  -- user2 supprime son propre commentaire
    
    SELECT deleted_at INTO v_deleted_at
    FROM game_comment
    WHERE comment_id = 3;
    
    IF v_deleted_at IS NOT NULL THEN
        RAISE NOTICE '[PASS] Propriétaire a supprimé son commentaire';
    ELSE
        RAISE NOTICE '[FAIL] deleted_at devrait être défini';
    END IF;

    -- TEST 7 : Utilisateur supprimé ne peut pas supprimer
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 7 : Utilisateur supprimé ne peut pas supprimer';
    
    -- Créer un commentaire pour user4 (avant suppression fictive)
    INSERT INTO game_comment (comment_id, user_id, game_id, content)
    VALUES (5, 2, 1, 'Comment à supprimer');
    
    BEGIN
        PERFORM sp_soft_delete_comment(5, 4);  -- user4 est supprimé
        RAISE NOTICE '[FAIL] Utilisateur supprimé ne devrait pas pouvoir supprimer';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '[PASS] Utilisateur supprimé correctement rejeté';
    END;

    -- TEST 8 : Admin peut supprimer même si l'auteur est supprimé
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 8 : Admin peut supprimer commentaire d''utilisateur supprimé';
    
    -- Note: La procédure vérifie que l'utilisateur qui supprime n'est pas deleted,
    -- pas l'auteur du commentaire
    PERFORM sp_soft_delete_comment(5, 3);  -- admin supprime
    
    SELECT deleted_at INTO v_deleted_at
    FROM game_comment
    WHERE comment_id = 5;
    
    IF v_deleted_at IS NOT NULL THEN
        RAISE NOTICE '[PASS] Admin peut supprimer commentaire';
    ELSE
        RAISE NOTICE '[FAIL] deleted_at devrait être défini';
    END IF;

    -- TEST 9 : Vérifier que deleted_at est proche de CURRENT_TIMESTAMP
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 9 : Vérifier timestamp deleted_at';
    
    DECLARE
        v_time_diff INTERVAL;
    BEGIN
        SELECT CURRENT_TIMESTAMP - deleted_at INTO v_time_diff
        FROM game_comment
        WHERE comment_id = 1;
        
        IF v_time_diff < INTERVAL '5 seconds' THEN
            RAISE NOTICE '[PASS] deleted_at correctement défini (< 5s)';
        ELSE
            RAISE NOTICE '[FAIL] deleted_at trop ancien: %', v_time_diff;
        END IF;
    END;

    -- TEST 10 : Commentaire pré-supprimé ne peut pas être re-supprimé
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 10 : Commentaire pré-supprimé ne peut être re-supprimé';
    BEGIN
        PERFORM sp_soft_delete_comment(4, 1);  -- Déjà supprimé
        RAISE NOTICE '[FAIL] Devrait échouer (pré-supprimé)';
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE '%Commentaire introuvable, déjà supprimé ou non autorisé%' THEN
            RAISE NOTICE '[PASS] Commentaire pré-supprimé correctement rejeté';
        ELSE
            RAISE NOTICE '[FAIL] Erreur inattendue: %', SQLERRM;
        END IF;
    END;

    -- TEST 11 : Statistiques finales
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 11 : Statistiques finales';
    
    DECLARE
        v_total INTEGER;
        v_active INTEGER;
        v_deleted INTEGER;
    BEGIN
        SELECT COUNT(*) INTO v_total FROM game_comment;
        SELECT COUNT(*) INTO v_active FROM game_comment WHERE deleted_at IS NULL;
        SELECT COUNT(*) INTO v_deleted FROM game_comment WHERE deleted_at IS NOT NULL;
        
        RAISE NOTICE '[INFO] Total commentaires: %', v_total;
        RAISE NOTICE '[INFO] Commentaires actifs: %', v_active;
        RAISE NOTICE '[INFO] Commentaires supprimés: %', v_deleted;
        
        IF v_deleted = 5 THEN
            RAISE NOTICE '[PASS] 5 commentaires supprimés';
        ELSE
            RAISE NOTICE '[FAIL] Nombre de supprimés: % (attendu: 5)', v_deleted;
        END IF;
    END;

    -- TEST 12 : Vérifier les permissions par rôle
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 12 : Récapitulatif permissions';
    RAISE NOTICE '[INFO] - Membre peut supprimer ses propres commentaires';
    RAISE NOTICE '[INFO] - Membre ne peut PAS supprimer commentaires d''autres';
    RAISE NOTICE '[INFO] - Admin peut supprimer N''IMPORTE QUEL commentaire';
    RAISE NOTICE '[INFO] - Utilisateurs supprimés ne peuvent rien supprimer';

END;
$$;

ROLLBACK;
