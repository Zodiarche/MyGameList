-- ============================================
-- Tests unitaires pour la vue view_report_with_details
-- ============================================

\echo '========================================'
\echo 'TEST VUE: view_report_with_details'
\echo '========================================'

BEGIN;

-- Nettoyage
DELETE FROM report;
DELETE FROM game_comment;
DELETE FROM game WHERE game_id > 0;
DELETE FROM user_account WHERE user_id > 0;

-- Données de test
INSERT INTO user_account (user_id, username, email, password, role) VALUES
(1, 'reporter1', 'reporter1@test.com', '$2a$10$test', 'member'),
(2, 'reporter2', 'reporter2@test.com', '$2a$10$test', 'member'),
(3, 'moderator', 'moderator@test.com', '$2a$10$test', 'administrator'),
(4, 'author', 'author@test.com', '$2a$10$test', 'member'),
(5, 'reported_user', 'reported@test.com', '$2a$10$test', 'member');

-- Créer un jeu et un commentaire pour les signalements
INSERT INTO game (game_id, title, slug) VALUES (1, 'Test Game', 'test-game');
INSERT INTO game_comment (comment_id, user_id, game_id, content) VALUES
(1, 4, 1, 'Inappropriate comment'),
(2, 4, 1, 'Normal comment');

-- Créer différents types de signalements
INSERT INTO report (report_id, reporter_user_id, content_type, content_id, reason, description, status, reported_at, moderator_user_id, processed_at) VALUES
-- Signalement de commentaire en attente
(1, 1, 'comment', 1, 'Contenu inapproprié', 'Ce commentaire contient du langage offensant', 'pending', CURRENT_TIMESTAMP - INTERVAL '2 days', NULL, NULL),

-- Signalement d'utilisateur traité
(2, 2, 'user', 5, 'Spam', 'Cet utilisateur envoie du spam', 'processed', CURRENT_TIMESTAMP - INTERVAL '5 days', 3, CURRENT_TIMESTAMP - INTERVAL '4 days'),

-- Signalement de commentaire rejeté
(3, 1, 'comment', 2, 'Harcèlement', 'Commentaire harcelant', 'rejected', CURRENT_TIMESTAMP - INTERVAL '7 days', 3, CURRENT_TIMESTAMP - INTERVAL '6 days'),

-- Autre signalement en attente
(4, 2, 'comment', 1, 'Violence', 'Incitation à la violence', 'pending', CURRENT_TIMESTAMP - INTERVAL '1 day', NULL, NULL);

\echo ''
\echo '--- Test 1: Vérifier que la vue existe ---'
SELECT EXISTS (
    SELECT 1 
    FROM information_schema.views 
    WHERE table_schema = 'public' 
    AND table_name = 'view_report_with_details'
) AS "Vue view_report_with_details existe";

\echo ''
\echo '--- Test 2: Lister tous les signalements avec détails ---'
SELECT 
    report_id,
    content_type,
    content_id,
    reason,
    status,
    reporter_username,
    moderator_username,
    reported_at,
    processed_at
FROM view_report_with_details
ORDER BY reported_at DESC;
-- Attendu: 4 signalements avec informations complètes

\echo ''
\echo '--- Test 3: Signalements en attente uniquement ---'
SELECT 
    report_id,
    reason,
    description,
    reporter_username,
    moderator_username
FROM view_report_with_details
WHERE status = 'pending'
ORDER BY reported_at DESC;
-- Attendu: 2 signalements (id 1 et 4), moderator_username = NULL

\echo ''
\echo '--- Test 4: Signalements traités par le modérateur ---'
SELECT 
    report_id,
    content_type,
    status,
    moderator_username,
    processed_at
FROM view_report_with_details
WHERE status IN ('processed', 'rejected')
ORDER BY processed_at DESC;
-- Attendu: 2 signalements (id 2 et 3), moderator_username = 'moderator'

\echo ''
\echo '--- Test 5: Signalements par type de contenu ---'
DO $$
DECLARE
    v_comment_count INTEGER;
    v_user_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_comment_count
    FROM view_report_with_details
    WHERE content_type = 'comment';
    
    SELECT COUNT(*) INTO v_user_count
    FROM view_report_with_details
    WHERE content_type = 'user';
    
    IF v_comment_count = 3 THEN
        RAISE NOTICE '[PASS] Nombre de signalements de commentaires correct (3)';
    ELSE
        RAISE NOTICE '[FAIL] Nombre incorrect: % (attendu: 3)', v_comment_count;
    END IF;
    
    IF v_user_count = 1 THEN
        RAISE NOTICE '[PASS] Nombre de signalements d''utilisateurs correct (1)';
    ELSE
        RAISE NOTICE '[FAIL] Nombre incorrect: % (attendu: 1)', v_user_count;
    END IF;
END;
$$;

\echo ''
\echo '--- Test 6: Vérifier les informations du reporter ---'
SELECT 
    report_id,
    reporter_username,
    reporter_email
FROM view_report_with_details
WHERE report_id = 1;
-- Attendu: reporter1, reporter1@test.com

\echo ''
\echo '--- Test 7: Vérifier les informations du moderator ---'
DO $$
DECLARE
    v_mod_username VARCHAR;
    v_mod_null_count INTEGER;
BEGIN
    -- Vérifier le nom du modérateur pour signalement traité
    SELECT moderator_username INTO v_mod_username
    FROM view_report_with_details
    WHERE report_id = 2;
    
    IF v_mod_username = 'moderator' THEN
        RAISE NOTICE '[PASS] Nom du modérateur correct';
    ELSE
        RAISE NOTICE '[FAIL] Nom du modérateur: % (attendu: moderator)', v_mod_username;
    END IF;
    
    -- Vérifier que moderator_username est NULL pour signalements pending
    SELECT COUNT(*) INTO v_mod_null_count
    FROM view_report_with_details
    WHERE status = 'pending' AND moderator_username IS NULL;
    
    IF v_mod_null_count = 2 THEN
        RAISE NOTICE '[PASS] moderator_username NULL pour signalements pending';
    ELSE
        RAISE NOTICE '[FAIL] % signalements pending avec moderator NULL (attendu: 2)', v_mod_null_count;
    END IF;
END;
$$;

\echo ''
\echo '--- Test 8: Signalements du même contenu par différents utilisateurs ---'
SELECT 
    content_id,
    content_type,
    COUNT(*) as report_count,
    STRING_AGG(reporter_username, ', ') as reporters
FROM view_report_with_details
WHERE content_id = 1 AND content_type = 'comment'
GROUP BY content_id, content_type;
-- Attendu: 2 signalements pour comment_id=1 (par reporter1 et reporter2)

\echo ''
\echo '--- Test 9: Vérifier la présence de description ---'
SELECT 
    report_id,
    reason,
    description
FROM view_report_with_details
WHERE report_id = 1;
-- Attendu: description complète visible

\echo ''
\echo '--- Test 10: Signalements par status ---'
SELECT 
    status,
    COUNT(*) as count
FROM view_report_with_details
GROUP BY status
ORDER BY status;
-- Attendu: pending=2, processed=1, rejected=1

ROLLBACK;
