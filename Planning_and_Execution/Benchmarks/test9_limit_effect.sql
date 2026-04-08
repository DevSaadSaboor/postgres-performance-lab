-- ============================================
-- TEST 9a: BITMAP SCAN WITHOUT LIMIT
-- Query: age = 5 (no limit)
-- Result: Bitmap Index Scan
-- ============================================
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM users WHERE age = 5;

-- Expected Output:
-- Bitmap Heap Scan on users (cost=24.21..1448.01 rows=2053 width=24)
-- (actual time=0.201..0.913 rows=2017 loops=1)
-- -> Bitmap Index Scan on idx_age (cost=0.00..23.69 rows=2053 width=0)
-- (actual time=0.111..0.111 rows=2017 loops=1)
-- Planning Time: 0.090 ms
-- Execution Time: 0.961 ms


-- ============================================
-- TEST 9b: INDEX SCAN WITH LIMIT
-- Query: age = 5 LIMIT 5
-- Result: Index Scan (stops early)
-- ============================================
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM users WHERE age = 5 LIMIT 5;

-- Expected Output:
-- Limit (cost=0.29..11.72 rows=5 width=24)
-- (actual time=0.016..0.020 rows=5 loops=1)
-- -> Index Scan using idx_age on users
-- (actual time=0.015..0.018 rows=5 loops=1)
-- Planning Time: 0.085 ms
-- Execution Time: 0.030 ms
--
-- KEY FINDING: LIMIT changes plan from Bitmap to Index Scan
-- 32x faster: 0.961ms -> 0.030ms
