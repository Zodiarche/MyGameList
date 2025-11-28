-- ============================================
-- Test du trigger : trg_game_metacritic_validate
-- Valide que le score Metacritic est entre 0 et 100
-- ============================================

\echo '========================================'
\echo 'TEST TRIGGER: trg_game_metacritic_validate'
\echo '========================================'

BEGIN;

DO $$
DECLARE
    v_test_game_id INTEGER;
    v_test_passed BOOLEAN;
BEGIN
    -- TEST 1 : INSERT metacritic < 0 (doit échouer)
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 1 : INSERT metacritic < 0 (doit échouer)';
    v_test_passed := FALSE;
    BEGIN
        INSERT INTO game (title, slug, metacritic)
        VALUES ('Bad Game', 'bad-game', -10);
        RAISE NOTICE '[FAIL] L''insertion aurait dû échouer';
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE '%Metacritic score must be between 0 and 100%' THEN
            RAISE NOTICE '[PASS] Erreur correctement déclenchée';
            v_test_passed := TRUE;
        ELSE
            RAISE NOTICE '[FAIL] Erreur inattendue: %', SQLERRM;
        END IF;
    END;

    -- TEST 2 : INSERT metacritic > 100 (doit échouer)
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 2 : INSERT metacritic > 100 (doit échouer)';
    v_test_passed := FALSE;
    BEGIN
        INSERT INTO game (title, slug, metacritic)
        VALUES ('Super Game', 'super-game', 150);
        RAISE NOTICE '[FAIL] L''insertion aurait dû échouer';
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE '%Metacritic score must be between 0 and 100%' THEN
            RAISE NOTICE '[PASS] Erreur correctement déclenchée';
            v_test_passed := TRUE;
        ELSE
            RAISE NOTICE '[FAIL] Erreur inattendue: %', SQLERRM;
        END IF;
    END;

    -- TEST 3 : INSERT metacritic NULL (doit réussir)
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 3 : INSERT metacritic NULL (doit réussir)';
    BEGIN
        INSERT INTO game (title, slug, metacritic)
        VALUES ('No Score Game', 'no-score-game', NULL)
        RETURNING game_id INTO v_test_game_id;
        DELETE FROM game WHERE game_id = v_test_game_id;
        RAISE NOTICE '[PASS] Insertion réussie';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '[FAIL] %', SQLERRM;
    END;

    -- TEST 4 : INSERT metacritic valides 0 et 100 (doit réussir)
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 4 : INSERT metacritic valides (0 et 100) (doit réussir)';
    BEGIN
        INSERT INTO game (title, slug, metacritic)
        VALUES
            ('Worst Game', 'worst-game', 0),
            ('Best Game', 'best-game', 100);
        DELETE FROM game WHERE slug IN ('worst-game', 'best-game');
        RAISE NOTICE '[PASS] Insertions réussies';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '[FAIL] %', SQLERRM;
    END;

    -- TEST 5 : UPDATE metacritic invalide > 100 (doit échouer)
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 5 : UPDATE metacritic > 100 (doit échouer)';
    v_test_passed := FALSE;
    BEGIN
        INSERT INTO game (title, slug, metacritic)
        VALUES ('Update Test', 'update-test', 85)
        RETURNING game_id INTO v_test_game_id;
        
        UPDATE game SET metacritic = 200 WHERE game_id = v_test_game_id;
        RAISE NOTICE '[FAIL] L''UPDATE aurait dû échouer';
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE '%Metacritic score must be between 0 and 100%' THEN
            RAISE NOTICE '[PASS] Erreur correctement déclenchée';
            v_test_passed := TRUE;
        ELSE
            RAISE NOTICE '[FAIL] Erreur inattendue: %', SQLERRM;
        END IF;
    END;
END $$;

ROLLBACK;

\echo ''
\echo '========================================'
\echo 'RÉSUMÉ : 5 tests exécutés'
\echo '========================================'
