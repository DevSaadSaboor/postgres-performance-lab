-- ============================================
-- TEST 8: NESTED LOOP (Small Filtered Join)
-- Query: JOIN with u.id < 100 (small outer table)
-- Result: Nested Loop (super fast)
-- ============================================
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM users u
JOIN orders o ON u.id = o.user_id
WHERE u.id < 100;

-- Expected Output:
-- Nested Loop (cost=0.84..1729.36 rows=272 width=44)
-- (actual time=0.010..0.346 rows=256 loops=1)
-- -> Index Scan using users_pkey on users u
--    Index Cond: (id < 100)
--    (actual time=0.004..0.017 rows=99 loops=1)
-- -> Index Scan using idx_orders_user_id on orders o
--    Index Cond: (user_id = u.id)
--    (actual time=0.002..0.003 rows=3 loops=99)
-- Planning Time: 0.182 ms
-- Execution Time: 0.382 ms
--
-- KEY FINDING: Small outer (99 rows) + indexed inner = 0.382ms!
-- 800x faster than full Hash Join (309ms)
