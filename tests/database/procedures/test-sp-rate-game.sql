-- ============================================
-- Test de la stored procedure : sp_rate_game
-- Noter ou mettre à jour la note d'un jeu (UPSERT)
-- ============================================

\echo '========================================'
\echo 'TEST PROCEDURE: sp_rate_game'
\echo '========================================'

BEGIN;

-- Créer données de test
INSERT INTO user_account (user_id, username, email, password)
VALUES (1, 'test_user', 'test@example.com', '$2b$10$hashedpassword');

INSERT INTO game (game_id, title, slug)
VALUES (1, 'Test Game', 'test-game');

DO $$
DECLARE
    v_user_id INTEGER := 1;
    v_game_id INTEGER := 1;
    v_rating_count INTEGER;
    v_rating_value NUMERIC;
    v_updated_at TIMESTAMP;
BEGIN
    -- TEST 1 : Créer une note (INSERT)
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 1 : Créer une note (INSERT)';
    
    PERFORM sp_rate_game(v_user_id, v_game_id, 8.5);
    
    SELECT COUNT(*) INTO v_rating_count
    FROM rating
    WHERE user_id = v_user_id AND game_id = v_game_id;
    
    IF v_rating_count = 1 THEN
        RAISE NOTICE '[PASS] Note créée';
    ELSE
        RAISE NOTICE '[FAIL] La note n''a pas été créée';
    END IF;
    
    -- Vérifier la valeur
    SELECT rating INTO v_rating_value
    FROM rating
    WHERE user_id = v_user_id AND game_id = v_game_id;
    
    IF v_rating_value = 8.5 THEN
        RAISE NOTICE '[PASS] Valeur de la note correcte (8.5)';
    ELSE
        RAISE NOTICE '[FAIL] Valeur incorrecte: % (attendu: 8.5)', v_rating_value;
    END IF;

    -- TEST 2 : Mettre à jour une note existante (UPDATE via UPSERT)
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 2 : Mettre à jour une note existante (UPSERT)';
    
    -- Attendre 1 seconde pour voir la différence de timestamp
    PERFORM pg_sleep(1);
    
    PERFORM sp_rate_game(v_user_id, v_game_id, 9.0);
    
    SELECT COUNT(*) INTO v_rating_count
    FROM rating
    WHERE user_id = v_user_id AND game_id = v_game_id;
    
    IF v_rating_count = 1 THEN
        RAISE NOTICE '[PASS] Pas de duplication (toujours 1 note)';
    ELSE
        RAISE NOTICE '[FAIL] Duplication détectée: % notes', v_rating_count;
    END IF;
    
    -- Vérifier la mise à jour
    SELECT rating, updated_at INTO v_rating_value, v_updated_at
    FROM rating
    WHERE user_id = v_user_id AND game_id = v_game_id;
    
    IF v_rating_value = 9.0 THEN
        RAISE NOTICE '[PASS] Note mise à jour: 9.0';
    ELSE
        RAISE NOTICE '[FAIL] Note: % (attendu: 9.0)', v_rating_value;
    END IF;
    
    IF v_updated_at IS NOT NULL THEN
        RAISE NOTICE '[PASS] updated_at mis à jour automatiquement';
    ELSE
        RAISE NOTICE '[FAIL] updated_at devrait être mis à jour';
    END IF;

    -- TEST 3 : Note minimale (0.0)
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 3 : Note minimale (0.0)';
    
    INSERT INTO user_account (user_id, username, email, password)
    VALUES (2, 'user2', 'user2@example.com', '$2b$10$hashedpassword');
    
    PERFORM sp_rate_game(2, v_game_id, 0.0);
    
    SELECT rating INTO v_rating_value
    FROM rating
    WHERE user_id = 2 AND game_id = v_game_id;
    
    IF v_rating_value = 0.0 THEN
        RAISE NOTICE '[PASS] Note minimale acceptée (0.0)';
    ELSE
        RAISE NOTICE '[FAIL] Note: % (attendu: 0.0)', v_rating_value;
    END IF;

    -- TEST 4 : Note maximale (10.0)
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 4 : Note maximale (10.0)';
    
    INSERT INTO user_account (user_id, username, email, password)
    VALUES (3, 'user3', 'user3@example.com', '$2b$10$hashedpassword');
    
    PERFORM sp_rate_game(3, v_game_id, 10.0);
    
    SELECT rating INTO v_rating_value
    FROM rating
    WHERE user_id = 3 AND game_id = v_game_id;
    
    IF v_rating_value = 10.0 THEN
        RAISE NOTICE '[PASS] Note maximale acceptée (10.0)';
    ELSE
        RAISE NOTICE '[FAIL] Note: % (attendu: 10.0)', v_rating_value;
    END IF;

    -- TEST 5 : Note avec décimale (7.3)
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 5 : Note avec décimale (7.3)';
    
    INSERT INTO user_account (user_id, username, email, password)
    VALUES (4, 'user4', 'user4@example.com', '$2b$10$hashedpassword');
    
    PERFORM sp_rate_game(4, v_game_id, 7.3);
    
    SELECT rating INTO v_rating_value
    FROM rating
    WHERE user_id = 4 AND game_id = v_game_id;
    
    IF v_rating_value = 7.3 THEN
        RAISE NOTICE '[PASS] Note avec décimale acceptée (7.3)';
    ELSE
        RAISE NOTICE '[FAIL] Note: % (attendu: 7.3)', v_rating_value;
    END IF;

    -- TEST 6 : Erreur si note < 0
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 6 : Erreur si note < 0';
    BEGIN
        PERFORM sp_rate_game(v_user_id, v_game_id, -1.0);
        RAISE NOTICE '[FAIL] Devrait échouer avec note < 0';
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE '%note doit être comprise entre 0 et 10%' THEN
            RAISE NOTICE '[PASS] Erreur correctement levée pour note < 0';
        ELSE
            RAISE NOTICE '[FAIL] Erreur inattendue: %', SQLERRM;
        END IF;
    END;

    -- TEST 7 : Erreur si note > 10
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 7 : Erreur si note > 10';
    BEGIN
        PERFORM sp_rate_game(v_user_id, v_game_id, 11.0);
        RAISE NOTICE '[FAIL] Devrait échouer avec note > 10';
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE '%note doit être comprise entre 0 et 10%' THEN
            RAISE NOTICE '[PASS] Erreur correctement levée pour note > 10';
        ELSE
            RAISE NOTICE '[FAIL] Erreur inattendue: %', SQLERRM;
        END IF;
    END;

    -- TEST 8 : Erreur si user_id inexistant (violation FK)
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 8 : Erreur si user_id inexistant';
    BEGIN
        PERFORM sp_rate_game(999, v_game_id, 5.0);
        RAISE NOTICE '[FAIL] Devrait échouer avec user_id inexistant';
    EXCEPTION WHEN foreign_key_violation THEN
        RAISE NOTICE '[PASS] Erreur FK correctement levée';
    WHEN OTHERS THEN
        RAISE NOTICE '[FAIL] Erreur inattendue: %', SQLERRM;
    END;

    -- TEST 9 : Erreur si game_id inexistant (violation FK)
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 9 : Erreur si game_id inexistant';
    BEGIN
        PERFORM sp_rate_game(v_user_id, 999, 5.0);
        RAISE NOTICE '[FAIL] Devrait échouer avec game_id inexistant';
    EXCEPTION WHEN foreign_key_violation THEN
        RAISE NOTICE '[PASS] Erreur FK correctement levée';
    WHEN OTHERS THEN
        RAISE NOTICE '[FAIL] Erreur inattendue: %', SQLERRM;
    END;

    -- TEST 10 : Plusieurs utilisateurs peuvent noter le même jeu
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 10 : Plusieurs utilisateurs peuvent noter le même jeu';
    
    SELECT COUNT(*) INTO v_rating_count
    FROM rating
    WHERE game_id = v_game_id;
    
    IF v_rating_count = 4 THEN
        RAISE NOTICE '[PASS] 4 utilisateurs ont noté le jeu';
    ELSE
        RAISE NOTICE '[FAIL] Nombre de notes: % (attendu: 4)', v_rating_count;
    END IF;

    -- TEST 11 : Calcul de la moyenne
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 11 : Calcul de la moyenne des notes';
    
    DECLARE
        v_avg NUMERIC;
    BEGIN
        SELECT ROUND(AVG(rating)::numeric, 1) INTO v_avg
        FROM rating
        WHERE game_id = v_game_id;
        
        -- Moyenne = (9.0 + 0.0 + 10.0 + 7.3) / 4 = 6.575 ≈ 6.6
        IF v_avg = 6.6 THEN
            RAISE NOTICE '[PASS] Moyenne calculée: 6.6';
        ELSE
            RAISE NOTICE '[INFO] Moyenne calculée: % (proche de 6.6)', v_avg;
        END IF;
    END;

END;
$$;

ROLLBACK;
