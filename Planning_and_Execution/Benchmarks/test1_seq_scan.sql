-- TEST 1: SEQUENTIAL SCAN (No Index)
-- Query: created_at > NOW() - interval '30 days'
-- Result: Seq Scan
-- ============================================
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM users
WHERE created_at > NOW() - interval '30 days';

-- Expected Output:
-- Seq Scan on users (cost=0.00..4837.00 rows=16598 width=24)
-- (actual time=0.009..34.313 rows=16194 loops=1)
-- Filter: (created_at > (now() - '30 days'::interval))
-- Rows Removed by Filter: 183806
-- Planning Time: 0.117 ms
-- Execution Time: 34.597 ms
--
-- KEY FINDING: No index, reads all 200K rows, filters 183K