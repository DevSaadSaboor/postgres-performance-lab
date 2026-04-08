-- ============================================
-- TEST 2: BITMAP INDEX SCAN (With Index)
-- Query: created_at > NOW() - interval '30 days'
-- Index: idx_created_at
-- Result: Bitmap Index Scan
-- ============================================
CREATE INDEX IF NOT EXISTS idx_created_at ON users(created_at);

EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM users
WHERE created_at > NOW() - interval '30 days';

-- Expected Output:
-- Bitmap Heap Scan on users (cost=313.05..1940.50 rows=16597 width=24)
-- (actual time=1.524..3.651 rows=16193 loops=1)
-- -> Bitmap Index Scan on idx_created_at (cost=0.00..308.90 rows=16597 width=0)
-- (actual time=1.417..1.417 rows=16193 loops=1)
-- Planning Time: 0.985 ms
-- Execution Time: 3.915 ms
--
-- KEY FINDING: 8.8x faster than Seq Scan (34.6ms -> 3.9ms)
-- Bitmap batches index lookups for efficiency
