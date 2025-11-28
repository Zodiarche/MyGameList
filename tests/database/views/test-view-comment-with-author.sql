-- ============================================
-- Tests pour la vue view_comment_with_author
-- ============================================

\echo '========================================'
\echo 'TEST VUE: view_comment_with_author'
\echo '========================================'

BEGIN;

-- Créer données de test
INSERT INTO user_account (username, email, password, bio)
VALUES 
    ('author1', 'author1@test.com', '$2b$10$hash', 'Author bio'),
    ('author2_deleted', 'author2@test.com', '$2b$10$hash', 'Deleted user');

UPDATE user_account SET deleted_at = CURRENT_TIMESTAMP WHERE username = 'author2_deleted';

INSERT INTO game (title, slug)
VALUES ('Test Game 1', 'test-game-1');

DO $$
DECLARE
    v_author1_id INTEGER;
    v_author2_id INTEGER;
    v_game_id INTEGER;
    v_comment1_id INTEGER;
    v_comment2_id INTEGER;
BEGIN
    SELECT user_id INTO v_author1_id FROM user_account WHERE username = 'author1';
    SELECT user_id INTO v_author2_id FROM user_account WHERE username = 'author2_deleted';
    SELECT game_id INTO v_game_id FROM game WHERE slug = 'test-game-1';

    -- Créer commentaires
    INSERT INTO game_comment (user_id, game_id, content)
    VALUES (v_author1_id, v_game_id, 'Great game!')
    RETURNING comment_id INTO v_comment1_id;

    INSERT INTO game_comment (user_id, game_id, content)
    VALUES (v_author2_id, v_game_id, 'Comment from deleted user')
    RETURNING comment_id INTO v_comment2_id;

    -- TEST 1 : Vérifier que la vue existe
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 1 : Vérifier que la vue existe';
    IF EXISTS (
        SELECT 1 FROM information_schema.views 
        WHERE table_name = 'view_comment_with_author'
    ) THEN
        RAISE NOTICE '[PASS] Vue existe';
    ELSE
        RAISE NOTICE '[FAIL] Vue n''existe pas';
    END IF;

    -- TEST 2 : Commentaire avec author actif visible
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 2 : Commentaire avec author actif visible';
    IF EXISTS (
        SELECT 1 FROM view_comment_with_author 
        WHERE comment_id = v_comment1_id
    ) THEN
        RAISE NOTICE '[PASS] Commentaire visible';
    ELSE
        RAISE NOTICE '[FAIL] Commentaire non visible';
    END IF;

    -- TEST 3 : Commentaire d'utilisateur supprimé non visible
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 3 : Commentaire d''utilisateur supprimé non visible';
    IF NOT EXISTS (
        SELECT 1 FROM view_comment_with_author 
        WHERE comment_id = v_comment2_id
    ) THEN
        RAISE NOTICE '[PASS] Commentaire d''user supprimé caché';
    ELSE
        RAISE NOTICE '[FAIL] Commentaire d''user supprimé visible';
    END IF;

    -- TEST 4 : Vérifier les colonnes enrichies
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 4 : Vérifier les colonnes enrichies';
    DECLARE
        v_author_username TEXT;
        v_game_title TEXT;
    BEGIN
        SELECT author_username, game_title 
        INTO v_author_username, v_game_title
        FROM view_comment_with_author 
        WHERE comment_id = v_comment1_id;

        IF v_author_username = 'author1' AND v_game_title = 'Test Game 1' THEN
            RAISE NOTICE '[PASS] Colonnes enrichies correctes';
        ELSE
            RAISE NOTICE '[FAIL] Colonnes enrichies incorrectes';
        END IF;
    END;

    -- TEST 5 : Soft delete d'un commentaire
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 5 : Soft delete exclut le commentaire';
    UPDATE game_comment SET deleted_at = CURRENT_TIMESTAMP WHERE comment_id = v_comment1_id;
    
    IF NOT EXISTS (
        SELECT 1 FROM view_comment_with_author 
        WHERE comment_id = v_comment1_id
    ) THEN
        RAISE NOTICE '[PASS] Commentaire soft deleted exclu';
    ELSE
        RAISE NOTICE '[FAIL] Commentaire soft deleted visible';
    END IF;

    -- Nettoyage
    DELETE FROM game_comment WHERE comment_id IN (v_comment1_id, v_comment2_id);
END $$;

DELETE FROM game WHERE slug = 'test-game-1';
DELETE FROM user_account WHERE username IN ('author1', 'author2_deleted');

ROLLBACK;

\echo ''
\echo '========================================'
\echo 'RÉSUMÉ : 5 tests exécutés'
\echo '========================================'
