-- ============================================
-- TEST 7: MERGE JOIN (With Index on Orders)
-- Query: users JOIN orders with idx_orders_user_id
-- Result: Merge Join (index changes join type)
-- ============================================
CREATE INDEX IF NOT EXISTS idx_orders_user_id ON orders(user_id);

EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM users u
JOIN orders o ON u.id = o.user_id;

-- Expected Output:
-- Merge Join (cost=2.61..37358.63 rows=500000 width=44)
-- (actual time=0.013..320.362 rows=500000 loops=1)
-- Merge Cond: (u.id = o.user_id)
-- -> Index Scan using users_pkey on users u
-- -> Index Scan using idx_orders_user_id on orders o
-- Planning Time: 1.100 ms
-- Execution Time: 329.261 ms
--
-- KEY FINDING: Index on orders enables Merge Join
-- Similar time to Hash Join (329ms vs 309ms)
