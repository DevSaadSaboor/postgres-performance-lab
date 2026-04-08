-- ============================================
-- TEST 6: HASH JOIN (Large Tables)
-- Query: users JOIN orders (200K + 500K rows)
-- Result: Hash Join
-- ============================================
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM users u
JOIN orders o ON u.id = o.user_id;

-- Expected Output:
-- Hash Join (cost=10000010216.42..10000026745.94 rows=500000 width=44)
-- (actual time=42.036..287.489 rows=500000 loops=1)
-- Hash Cond: (o.user_id = u.id)
-- -> Seq Scan on orders o (cost=10000000000.00..10000008185.00 rows=500000 width=20)
-- -> Hash (cost=6544.42..6544.42 rows=200000 width=24)
--    Buckets: 131072 Batches: 2 Memory Usage: 6732kB
--    -> Index Scan using users_pkey on users u
-- Planning Time: 0.354 ms
-- Execution Time: 309.298 ms
--
-- KEY FINDING: Hash Join builds hash table on smaller table (users)
-- Memory: 6.7MB, 2 batches (spills to disk slightly)
