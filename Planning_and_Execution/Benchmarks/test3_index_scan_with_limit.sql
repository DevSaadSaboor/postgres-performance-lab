-- ============================================
-- TEST 3: INDEX SCAN WITH LIMIT
-- Query: age = 5 LIMIT 5
-- Result: Seq Scan with Limit (fast due to small result)
-- ============================================
CREATE INDEX IF NOT EXISTS idx_age ON users(age);

EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM users
WHERE age = 5
LIMIT 5;

-- Expected Output:
-- Limit (cost=0.00..9.34 rows=5 width=24)
-- (actual time=0.008..0.040 rows=5 loops=1)
-- -> Seq Scan on users (cost=0.00..3837.00 rows=2053 width=24)
-- (actual time=0.007..0.038 rows=5 loops=1)
-- Filter: (age = 5)
-- Rows Removed by Filter: 825
-- Planning Time: 0.857 ms
-- Execution Time: 0.047 ms
--
-- KEY FINDING: LIMIT stops early, very fast (0.047ms)
