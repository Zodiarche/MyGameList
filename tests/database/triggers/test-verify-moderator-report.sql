-- ============================================
-- Test du trigger : trg_verify_moderator_report
-- Vérifie que seul un administrateur peut modérer
-- ============================================

\echo '========================================'
\echo 'TEST TRIGGER: trg_verify_moderator_report'
\echo '========================================'

BEGIN;

-- Créer données de test
INSERT INTO user_account (username, email, password)
VALUES
    ('test_member', 'member@example.com', '$2b$10$hashedpassword'),
    ('test_reporter', 'reporter@example.com', '$2b$10$hashedpassword'),
    ('test_admin', 'admin@example.com', '$2b$10$hashedpassword');

UPDATE user_account SET role = 'administrator' WHERE username = 'test_admin';

INSERT INTO game (title, slug)
VALUES ('Test Game', 'test-game');

DO $$
DECLARE
    v_member_id INTEGER;
    v_reporter_id INTEGER;
    v_admin_id INTEGER;
    v_game_id INTEGER;
    v_comment_id INTEGER;
    v_report_id INTEGER;
    v_test_passed BOOLEAN;
BEGIN
    -- Récupérer les IDs
    SELECT user_id INTO v_member_id FROM user_account WHERE username = 'test_member';
    SELECT user_id INTO v_reporter_id FROM user_account WHERE username = 'test_reporter';
    SELECT user_id INTO v_admin_id FROM user_account WHERE username = 'test_admin';
    SELECT game_id INTO v_game_id FROM game WHERE slug = 'test-game';

    -- Créer commentaire et signalement
    INSERT INTO game_comment (user_id, game_id, content)
    VALUES (v_member_id, v_game_id, 'Test comment to report')
    RETURNING comment_id INTO v_comment_id;

    INSERT INTO report (reporter_user_id, content_type, content_id, reason)
    VALUES (v_reporter_id, 'comment', v_comment_id, 'Test report')
    RETURNING report_id INTO v_report_id;

    -- TEST 1 : Membre essaye de modérer (doit échouer)
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 1 : Membre essaye de modérer (doit échouer)';
    v_test_passed := FALSE;
    BEGIN
        UPDATE report
        SET status = 'processed',
            moderator_user_id = v_member_id,
            processed_at = CURRENT_TIMESTAMP
        WHERE report_id = v_report_id;
        RAISE NOTICE '[FAIL] L''UPDATE aurait dû échouer';
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE '%administrateur%' THEN
            RAISE NOTICE '[PASS] Erreur correctement déclenchée';
            v_test_passed := TRUE;
        ELSE
            RAISE NOTICE '[FAIL] Erreur inattendue: %', SQLERRM;
        END IF;
    END;

    -- TEST 2 : Admin modère (doit réussir)
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 2 : Admin modère (doit réussir)';
    BEGIN
        UPDATE report
        SET status = 'processed',
            moderator_user_id = v_admin_id,
            processed_at = CURRENT_TIMESTAMP
        WHERE report_id = v_report_id;
        RAISE NOTICE '[PASS] Modération réussie';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '[FAIL] %', SQLERRM;
    END;

    -- TEST 3 : Update sans affecter de modérateur (doit réussir)
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 3 : Update sans moderator_user_id (doit réussir)';
    BEGIN
        UPDATE report
        SET reason = 'Updated reason'
        WHERE report_id = v_report_id;
        RAISE NOTICE '[PASS] Update réussi';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '[FAIL] %', SQLERRM;
    END;

    -- Nettoyage
    DELETE FROM report WHERE report_id = v_report_id;
    DELETE FROM game_comment WHERE comment_id = v_comment_id;
END $$;

-- Nettoyage final
DELETE FROM game WHERE slug = 'test-game';
DELETE FROM user_account WHERE username IN ('test_member', 'test_reporter', 'test_admin');

ROLLBACK;

\echo ''
\echo '========================================'
\echo 'RÉSUMÉ : 3 tests exécutés'
\echo '========================================'
