-- ============================================
-- Tests pour les nouvelles vues
-- ============================================

\echo '========================================'
\echo 'TESTS : Vues supplémentaires'
\echo '========================================'

BEGIN;

-- Créer données de test
INSERT INTO user_account (username, email, password)
VALUES 
    ('user1', 'user1@test.com', '$2b$10$hash'),
    ('user2', 'user2@test.com', '$2b$10$hash'),
    ('admin', 'admin@test.com', '$2b$10$hash');

UPDATE user_account SET role = 'administrator' WHERE username = 'admin';

INSERT INTO game (title, slug)
VALUES ('Test Game', 'test-game');

DO $$
DECLARE
    v_user1_id INTEGER;
    v_user2_id INTEGER;
    v_admin_id INTEGER;
    v_game_id INTEGER;
    v_comment_id INTEGER;
    v_friendship_id INTEGER;
    v_report_id INTEGER;
BEGIN
    SELECT user_id INTO v_user1_id FROM user_account WHERE username = 'user1';
    SELECT user_id INTO v_user2_id FROM user_account WHERE username = 'user2';
    SELECT user_id INTO v_admin_id FROM user_account WHERE username = 'admin';
    SELECT game_id INTO v_game_id FROM game WHERE slug = 'test-game';

    -- TEST view_friendship_pending_requests
    RAISE NOTICE '';
    RAISE NOTICE '--- TEST view_friendship_pending_requests ---';
    
    INSERT INTO friendship (requester_user_id, addressee_user_id, status)
    VALUES (v_user1_id, v_user2_id, 'pending')
    RETURNING friendship_id INTO v_friendship_id;
    
    IF EXISTS (
        SELECT 1 FROM view_friendship_pending_requests 
        WHERE friendship_id = v_friendship_id
        AND addressee_user_id = v_user2_id
    ) THEN
        RAISE NOTICE '[PASS] Demande pending visible dans la vue';
    ELSE
        RAISE NOTICE '[FAIL] Demande pending non visible';
    END IF;

    -- Accepter et vérifier disparition
    UPDATE friendship SET status = 'accepted' WHERE friendship_id = v_friendship_id;
    
    IF NOT EXISTS (
        SELECT 1 FROM view_friendship_pending_requests 
        WHERE friendship_id = v_friendship_id
    ) THEN
        RAISE NOTICE '[PASS] Demande acceptée disparaît de la vue';
    ELSE
        RAISE NOTICE '[FAIL] Demande acceptée toujours visible';
    END IF;

    -- TEST view_report_with_details
    RAISE NOTICE '';
    RAISE NOTICE '--- TEST view_report_with_details ---';
    
    INSERT INTO game_comment (user_id, game_id, content)
    VALUES (v_user1_id, v_game_id, 'Test comment')
    RETURNING comment_id INTO v_comment_id;

    INSERT INTO report (reporter_user_id, content_type, content_id, reason)
    VALUES (v_user2_id, 'comment', v_comment_id, 'Test reason')
    RETURNING report_id INTO v_report_id;
    
    IF EXISTS (
        SELECT 1 FROM view_report_with_details 
        WHERE report_id = v_report_id
        AND reporter_username = 'user2'
        AND moderator_username IS NULL
    ) THEN
        RAISE NOTICE '[PASS] Report visible avec détails reporter';
    ELSE
        RAISE NOTICE '[FAIL] Report non visible ou détails incorrects';
    END IF;

    -- Traiter report et vérifier modérateur
    UPDATE report 
    SET status = 'processed', 
        moderator_user_id = v_admin_id,
        processed_at = CURRENT_TIMESTAMP
    WHERE report_id = v_report_id;
    
    IF EXISTS (
        SELECT 1 FROM view_report_with_details 
        WHERE report_id = v_report_id
        AND moderator_username = 'admin'
    ) THEN
        RAISE NOTICE '[PASS] Moderator visible après traitement';
    ELSE
        RAISE NOTICE '[FAIL] Moderator non visible';
    END IF;

    -- Nettoyage
    DELETE FROM report WHERE report_id = v_report_id;
    DELETE FROM game_comment WHERE comment_id = v_comment_id;
    DELETE FROM friendship WHERE friendship_id = v_friendship_id;
END $$;

DELETE FROM game WHERE slug = 'test-game';
DELETE FROM user_account WHERE username IN ('user1', 'user2', 'admin');

ROLLBACK;

\echo ''
\echo '========================================'
\echo 'RÉSUMÉ : Tests vues supplémentaires OK'
\echo '========================================'
