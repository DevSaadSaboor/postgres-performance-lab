-- Test 3: Range Query B-Tree Benchmark
-- Query: Range scan on timestamp
-- Lesson: Medium selectivity (26%) = marginal improvement

-- =====================================================
-- BEFORE: No index on created_at
-- Expected: Seq Scan, ~19ms, 26% of rows returned
-- =====================================================

EXPLAIN (ANALYZE, BUFFERS, TIMING)
SELECT * FROM orders WHERE created_at > '2026-01-01';

-- Results:
--   Scan Type: Seq Scan
--   Execution Time: 18.956 ms
--   Filter: (created_at > '2026-01-01 00:00:00'::timestamp)
--   Rows Removed by Filter: 73,856
--   Rows Returned: 26,144 (26% selectivity)
--   Buffers: shared hit=3134

-- =====================================================
-- CREATE INDEX: Range-optimized B-Tree
-- =====================================================

CREATE INDEX idx_created_at ON orders USING btree (created_at);

-- =====================================================
-- AFTER: With B-Tree index
-- Expected: Bitmap Index Scan, ~18ms (minimal improvement)
-- =====================================================

EXPLAIN (ANALYZE, BUFFERS, TIMING)
SELECT * FROM orders WHERE created_at > '2026-01-01';

-- Results:
--   Scan Type: Bitmap Index Scan
--   Execution Time: 18.244 ms
--   Index Cond: (created_at > '2026-01-01 00:00:00'::timestamp)
--   Rows Returned: 26,144
--   Buffers: shared hit=3134, read=74

-- =====================================================
-- KEY LEARNING
-- =====================================================
-- 1. Only 1.04x speedup (19ms -> 18ms)
-- 2. 26% selectivity = touching most heap pages anyway
-- 3. Index adds overhead: 74 index blocks read + bitmap construction
-- 4. At >20% selectivity, sequential scan often wins
-- 5. B-Tree helps most with: equality, low selectivity, or ORDER BY