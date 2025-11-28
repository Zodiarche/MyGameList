-- ============================================
-- Tests unitaires pour la vue view_friends
-- ============================================

-- Contexte de test
\echo '========================================'
\echo 'TEST VUE: view_friends'
\echo '========================================'

-- Nettoyage
DELETE FROM friendship;
DELETE FROM user_account WHERE user_id > 0;

-- Données de test
INSERT INTO user_account (user_id, username, email, password, bio, is_active) VALUES
(1, 'alice', 'alice@test.com', '$2a$10$test', 'Alice profile', TRUE),
(2, 'bob', 'bob@test.com', '$2a$10$test', 'Bob profile', TRUE),
(3, 'charlie', 'charlie@test.com', '$2a$10$test', 'Charlie profile', TRUE),
(4, 'deleted_user', 'deleted@test.com', '$2a$10$test', 'Deleted', FALSE);

-- Mise à jour de la colonne deleted_at pour simuler une suppression
UPDATE user_account SET deleted_at = CURRENT_TIMESTAMP WHERE user_id = 4;

-- Créer des relations d'amitié
INSERT INTO friendship (requester_user_id, addressee_user_id, status, requested_at, responded_at) VALUES
(1, 2, 'accepted', CURRENT_TIMESTAMP - INTERVAL '10 days', CURRENT_TIMESTAMP - INTERVAL '9 days'),
(1, 3, 'accepted', CURRENT_TIMESTAMP - INTERVAL '5 days', CURRENT_TIMESTAMP - INTERVAL '4 days'),
(2, 3, 'accepted', CURRENT_TIMESTAMP - INTERVAL '3 days', CURRENT_TIMESTAMP - INTERVAL '2 days'),
(1, 4, 'accepted', CURRENT_TIMESTAMP - INTERVAL '20 days', CURRENT_TIMESTAMP - INTERVAL '19 days'),
(3, 1, 'pending', CURRENT_TIMESTAMP, NULL);

\echo ''
\echo '--- Test 1: Vérifier que la vue existe ---'
SELECT EXISTS (
    SELECT 1 
    FROM information_schema.views 
    WHERE table_schema = 'public' 
    AND table_name = 'view_friends'
) AS "Vue view_friends existe";

\echo ''
\echo '--- Test 2: Récupérer les amis de Alice (user_id = 1) ---'
SELECT 
    user_id,
    friend_id,
    friend_username,
    friend_bio,
    friendship_date
FROM view_friends
WHERE user_id = 1
ORDER BY friendship_date DESC;
-- Résultat attendu : 2 amis (Bob et Charlie), pas deleted_user

\echo ''
\echo '--- Test 3: Compter les amis de chaque utilisateur ---'
SELECT 
    user_id,
    COUNT(*) as friend_count
FROM view_friends
GROUP BY user_id
ORDER BY user_id;
-- Résultat attendu :
-- user_id 1 : 2 amis
-- user_id 2 : 2 amis
-- user_id 3 : 2 amis

\echo ''
\echo '--- Test 4: Vérifier que les utilisateurs supprimés sont exclus ---'
SELECT 
    COUNT(*) as deleted_users_in_view
FROM view_friends
WHERE friend_id = 4;
-- Résultat attendu : 0 (aucun utilisateur supprimé ne doit apparaître)

\echo ''
\echo '--- Test 5: Vérifier que seules les amitiés acceptées apparaissent ---'
SELECT 
    COUNT(*) as pending_friendships
FROM view_friends vf
JOIN friendship f ON 
    (vf.user_id = f.requester_user_id AND vf.friend_id = f.addressee_user_id)
    OR (vf.user_id = f.addressee_user_id AND vf.friend_id = f.requester_user_id)
WHERE f.status != 'accepted';
-- Résultat attendu : 0 (aucune amitié en attente ne doit apparaître)

\echo ''
\echo '--- Test 6: Vérifier la bidirectionnalité (Alice voit Bob, Bob voit Alice) ---'
SELECT 
    'Alice -> Bob' as relation,
    EXISTS(SELECT 1 FROM view_friends WHERE user_id = 1 AND friend_id = 2) as exists_1_2,
    'Bob -> Alice' as relation_inverse,
    EXISTS(SELECT 1 FROM view_friends WHERE user_id = 2 AND friend_id = 1) as exists_2_1;
-- Résultat attendu : TRUE pour les deux

\echo ''
\echo '--- Test 7: Test de performance - Utilisation des index ---'
EXPLAIN (ANALYZE, BUFFERS) 
SELECT * FROM view_friends WHERE user_id = 1;
-- Vérifier que les index sont utilisés (idx_requester, idx_addressee)

\echo ''
\echo '========================================'
\echo 'Tests terminés !'
\echo '========================================'
\echo 'Résumé attendu :'
\echo '- 3 utilisateurs actifs avec des amitiés'
\echo '- Utilisateurs supprimés exclus'
\echo '- Amitiés en attente exclues'
\echo '- Relations bidirectionnelles correctes'
\echo '========================================'
\echo 'RÉSUMÉ : 7 tests exécutés'
\echo '========================================'
