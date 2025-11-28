-- ============================================
-- TESTS COMPLETS DES TRIGGERS BDD
-- MyGameList - PostgreSQL 16+
-- ============================================

-- Note: PostgreSQL ne supporte pas les variables @ comme MySQL
-- On utilise des transactions et des blocs anonymes DO

-- ============================================
-- PRÉPARATION : Créer données de test
-- ============================================

BEGIN;

-- Créer utilisateurs de test
INSERT INTO user_account (username, email, password)
VALUES
    ('test_user1', 'test1@example.com', '$2b$10$hashedpassword'),
    ('test_user2', 'test2@example.com', '$2b$10$hashedpassword'),
    ('test_admin', 'admin@example.com', '$2b$10$hashedpassword')
RETURNING user_id;

UPDATE user_account SET role = 'administrator' WHERE username = 'test_admin';

-- Créer jeu de test
INSERT INTO game (title, slug, release_date, metacritic)
VALUES ('Test Game', 'test-game', '2024-01-01', 85)
RETURNING game_id;

-- ============================================
-- SECTION 1 : TRIGGERS FRIENDSHIP
-- ============================================

DO $$
DECLARE
    v_user1_id INTEGER;
    v_user2_id INTEGER;
    v_test_passed BOOLEAN;
BEGIN
    -- Récupérer les IDs
    SELECT user_id INTO v_user1_id FROM user_account WHERE username = 'test_user1';
    SELECT user_id INTO v_user2_id FROM user_account WHERE username = 'test_user2';

    RAISE NOTICE '========================================';
    RAISE NOTICE 'SECTION 1 : TRIGGERS FRIENDSHIP';
    RAISE NOTICE '========================================';

    -- TEST 1.1 : INSERT auto-amitie (doit echouer)
    RAISE NOTICE 'TEST 1.1 : INSERT auto-amitie';
    v_test_passed := FALSE;
    BEGIN
        INSERT INTO friendship (requester_user_id, addressee_user_id, status)
        VALUES (v_user1_id, v_user1_id, 'pending');
        RAISE NOTICE '[FAIL] L''insertion aurait du echouer';
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE '%Cannot add yourself as friend%' THEN
            RAISE NOTICE '[PASS]';
            v_test_passed := TRUE;
        ELSE
            RAISE NOTICE '[FAIL] Erreur inattendue: %', SQLERRM;
        END IF;
    END;

    -- TEST 1.2 : INSERT amitie normale (doit reussir)
    RAISE NOTICE 'TEST 1.2 : INSERT amitie normale';
    BEGIN
        INSERT INTO friendship (requester_user_id, addressee_user_id, status)
        VALUES (v_user1_id, v_user2_id, 'pending');
        RAISE NOTICE '[PASS]';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '[FAIL] %', SQLERRM;
    END;

    -- TEST 1.3 : UPDATE vers auto-amitie (doit echouer)
    RAISE NOTICE 'TEST 1.3 : UPDATE vers auto-amitie';
    v_test_passed := FALSE;
    BEGIN
        UPDATE friendship
        SET addressee_user_id = requester_user_id
        WHERE requester_user_id = v_user1_id;
        RAISE NOTICE '[FAIL] L''UPDATE aurait du echouer';
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE '%Cannot add yourself as friend%' THEN
            RAISE NOTICE '[PASS]';
            v_test_passed := TRUE;
        ELSE
            RAISE NOTICE '[FAIL] Erreur inattendue: %', SQLERRM;
        END IF;
    END;

    -- Nettoyage
    DELETE FROM friendship WHERE requester_user_id = v_user1_id;
END $$;

-- ============================================
-- SECTION 2 : TRIGGERS RATING
-- ============================================

DO $$
DECLARE
    v_user1_id INTEGER;
    v_game_id INTEGER;
    v_test_passed BOOLEAN;
BEGIN
    -- Récupérer les IDs
    SELECT user_id INTO v_user1_id FROM user_account WHERE username = 'test_user1';
    SELECT game_id INTO v_game_id FROM game WHERE slug = 'test-game';

    RAISE NOTICE '========================================';
    RAISE NOTICE 'SECTION 2 : TRIGGERS RATING';
    RAISE NOTICE '========================================';

    -- TEST 2.1 : INSERT note < 0 (doit echouer)
    RAISE NOTICE 'TEST 2.1 : INSERT note < 0';
    v_test_passed := FALSE;
    BEGIN
        INSERT INTO rating (user_id, game_id, rating)
        VALUES (v_user1_id, v_game_id, -1.5);
        RAISE NOTICE '[FAIL] L''insertion aurait du echouer';
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE '%Rating must be between 0 and 10%' THEN
            RAISE NOTICE '[PASS]';
            v_test_passed := TRUE;
        ELSE
            RAISE NOTICE '[FAIL] Erreur inattendue: %', SQLERRM;
        END IF;
    END;

    -- TEST 2.2 : INSERT note > 10 (doit echouer)
    RAISE NOTICE 'TEST 2.2 : INSERT note > 10';
    v_test_passed := FALSE;
    BEGIN
        INSERT INTO rating (user_id, game_id, rating)
        VALUES (v_user1_id, v_game_id, 15.0);
        RAISE NOTICE '[FAIL] L''insertion aurait du echouer';
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE '%Rating must be between 0 and 10%' THEN
            RAISE NOTICE '[PASS]';
            v_test_passed := TRUE;
        ELSE
            RAISE NOTICE '[FAIL] Erreur inattendue: %', SQLERRM;
        END IF;
    END;

    -- TEST 2.3 : INSERT note valide 0.0 (doit reussir)
    RAISE NOTICE 'TEST 2.3 : INSERT note valide 0.0';
    BEGIN
        INSERT INTO rating (user_id, game_id, rating)
        VALUES (v_user1_id, v_game_id, 0.0);
        RAISE NOTICE '[PASS]';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '[FAIL] %', SQLERRM;
    END;

    -- TEST 2.4 : UPDATE note valide 10.0 (doit reussir)
    RAISE NOTICE 'TEST 2.4 : UPDATE note valide 10.0';
    BEGIN
        UPDATE rating SET rating = 10.0
        WHERE user_id = v_user1_id AND game_id = v_game_id;
        RAISE NOTICE '[PASS]';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '[FAIL] %', SQLERRM;
    END;

    -- TEST 2.5 : UPDATE note invalide > 10 (doit echouer)
    RAISE NOTICE 'TEST 2.5 : UPDATE note > 10';
    v_test_passed := FALSE;
    BEGIN
        UPDATE rating SET rating = 11.0
        WHERE user_id = v_user1_id AND game_id = v_game_id;
        RAISE NOTICE '[FAIL] L''UPDATE aurait du echouer';
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE '%Rating must be between 0 and 10%' THEN
            RAISE NOTICE '[PASS]';
            v_test_passed := TRUE;
        ELSE
            RAISE NOTICE '[FAIL] Erreur inattendue: %', SQLERRM;
        END IF;
    END;

    -- Nettoyage
    DELETE FROM rating WHERE user_id = v_user1_id;
END $$;

-- ============================================
-- SECTION 3 : TRIGGERS METACRITIC
-- ============================================

DO $$
DECLARE
    v_test_game_id INTEGER;
    v_test_passed BOOLEAN;
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE 'SECTION 3 : TRIGGERS METACRITIC';
    RAISE NOTICE '========================================';

    -- TEST 3.1 : INSERT metacritic < 0 (doit echouer)
    RAISE NOTICE 'TEST 3.1 : INSERT metacritic < 0';
    v_test_passed := FALSE;
    BEGIN
        INSERT INTO game (title, slug, metacritic)
        VALUES ('Bad Game', 'bad-game', -10);
        RAISE NOTICE '[FAIL] L''insertion aurait du echouer';
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE '%Metacritic score must be between 0 and 100%' THEN
            RAISE NOTICE '[PASS]';
            v_test_passed := TRUE;
        ELSE
            RAISE NOTICE '[FAIL] Erreur inattendue: %', SQLERRM;
        END IF;
    END;

    -- TEST 3.2 : INSERT metacritic > 100 (doit echouer)
    RAISE NOTICE 'TEST 3.2 : INSERT metacritic > 100';
    v_test_passed := FALSE;
    BEGIN
        INSERT INTO game (title, slug, metacritic)
        VALUES ('Super Game', 'super-game', 150);
        RAISE NOTICE '[FAIL] L''insertion aurait du echouer';
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE '%Metacritic score must be between 0 and 100%' THEN
            RAISE NOTICE '[PASS]';
            v_test_passed := TRUE;
        ELSE
            RAISE NOTICE '[FAIL] Erreur inattendue: %', SQLERRM;
        END IF;
    END;

    -- TEST 3.3 : INSERT metacritic NULL (doit reussir)
    RAISE NOTICE 'TEST 3.3 : INSERT metacritic NULL';
    BEGIN
        INSERT INTO game (title, slug, metacritic)
        VALUES ('No Score Game', 'no-score-game', NULL)
        RETURNING game_id INTO v_test_game_id;
        DELETE FROM game WHERE game_id = v_test_game_id;
        RAISE NOTICE '[PASS]';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '[FAIL] %', SQLERRM;
    END;

    -- TEST 3.4 : INSERT metacritic valides 0 et 100 (doit reussir)
    RAISE NOTICE 'TEST 3.4 : INSERT metacritic valides (0 et 100)';
    BEGIN
        INSERT INTO game (title, slug, metacritic)
        VALUES
            ('Worst Game', 'worst-game', 0),
            ('Best Game', 'best-game', 100);
        DELETE FROM game WHERE slug IN ('worst-game', 'best-game');
        RAISE NOTICE '[PASS]';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '[FAIL] %', SQLERRM;
    END;

    -- TEST 3.5 : UPDATE metacritic invalide > 100 (doit echouer)
    RAISE NOTICE 'TEST 3.5 : UPDATE metacritic > 100';
    v_test_passed := FALSE;
    BEGIN
        SELECT game_id INTO v_test_game_id FROM game WHERE slug = 'test-game';
        UPDATE game SET metacritic = 200 WHERE game_id = v_test_game_id;
        RAISE NOTICE '[FAIL] L''UPDATE aurait du echouer';
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE '%Metacritic score must be between 0 and 100%' THEN
            RAISE NOTICE '[PASS]';
            v_test_passed := TRUE;
        ELSE
            RAISE NOTICE '[FAIL] Erreur inattendue: %', SQLERRM;
        END IF;
    END;
END $$;

-- ============================================
-- SECTION 4 : TRIGGER MODERATOR VERIFICATION
-- ============================================

DO $$
DECLARE
    v_user1_id INTEGER;
    v_user2_id INTEGER;
    v_admin_id INTEGER;
    v_game_id INTEGER;
    v_comment_id INTEGER;
    v_report_id INTEGER;
    v_test_passed BOOLEAN;
BEGIN
    -- Récupérer les IDs
    SELECT user_id INTO v_user1_id FROM user_account WHERE username = 'test_user1';
    SELECT user_id INTO v_user2_id FROM user_account WHERE username = 'test_user2';
    SELECT user_id INTO v_admin_id FROM user_account WHERE username = 'test_admin';
    SELECT game_id INTO v_game_id FROM game WHERE slug = 'test-game';

    RAISE NOTICE '========================================';
    RAISE NOTICE 'SECTION 4 : TRIGGER MODERATOR';
    RAISE NOTICE '========================================';

    -- Creer commentaire et signalement
    INSERT INTO game_comment (user_id, game_id, content)
    VALUES (v_user1_id, v_game_id, 'Test comment to report')
    RETURNING comment_id INTO v_comment_id;

    INSERT INTO report (reporter_user_id, content_type, content_id, reason)
    VALUES (v_user2_id, 'comment', v_comment_id, 'Test report')
    RETURNING report_id INTO v_report_id;

    -- TEST 4.1 : Membre essaye de moderer (doit echouer)
    RAISE NOTICE 'TEST 4.1 : Membre essaye de moderer';
    v_test_passed := FALSE;
    BEGIN
        UPDATE report
        SET status = 'processed',
            moderator_user_id = v_user1_id,
            processed_at = CURRENT_TIMESTAMP
        WHERE report_id = v_report_id;
        RAISE NOTICE '[FAIL] L''UPDATE aurait du echouer';
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE '%administrateur%' THEN
            RAISE NOTICE '[PASS]';
            v_test_passed := TRUE;
        ELSE
            RAISE NOTICE '[FAIL] Erreur inattendue: %', SQLERRM;
        END IF;
    END;

    -- TEST 4.2 : Admin modere (doit reussir)
    RAISE NOTICE 'TEST 4.2 : Admin modere';
    BEGIN
        UPDATE report
        SET status = 'processed',
            moderator_user_id = v_admin_id,
            processed_at = CURRENT_TIMESTAMP
        WHERE report_id = v_report_id;
        RAISE NOTICE '[PASS]';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '[FAIL] %', SQLERRM;
    END;

    -- Nettoyage
    DELETE FROM report WHERE report_id = v_report_id;
    DELETE FROM game_comment WHERE comment_id = v_comment_id;
END $$;

-- ============================================
-- NETTOYAGE FINAL
-- ============================================

DELETE FROM game WHERE slug = 'test-game';
DELETE FROM user_account WHERE username IN ('test_user1', 'test_user2', 'test_admin');

COMMIT;

-- ============================================
-- RESUME DES TESTS
-- ============================================

DO $$
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE 'RESUME DES TESTS';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'TOUS LES TESTS EXECUTES';
    RAISE NOTICE '14 tests - Verifiez les PASS/FAIL ci-dessus';
    RAISE NOTICE '';
    RAISE NOTICE 'Note: PostgreSQL utilise RAISE NOTICE pour afficher les resultats.';
    RAISE NOTICE 'Tous les messages [PASS] indiquent un succes.';
    RAISE NOTICE 'Tous les messages [FAIL] indiquent un echec.';
END $$;
