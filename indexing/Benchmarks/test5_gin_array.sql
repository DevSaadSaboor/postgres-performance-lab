-- Test 5: GIN Index for Array Benchmark
-- Query: Array containment operator (@>)
-- Lesson: Very high selectivity (83%) = planner ignores index

-- =====================================================
-- BEFORE: No index on tags
-- Expected: Seq Scan, ~41ms, 83% of rows returned
-- =====================================================

EXPLAIN (ANALYZE, BUFFERS, TIMING)
SELECT * FROM orders WHERE tags @> ARRAY['sale'];

-- Results:
--   Scan Type: Seq Scan
--   Execution Time: 41.230 ms
--   Filter: (tags @> '{sale}'::text[])
--   Rows Removed by Filter: 16,742
--   Rows Returned: 83,258 (83% selectivity!)
--   Buffers: shared hit=3134

-- =====================================================
-- CREATE INDEX: GIN for Arrays
-- =====================================================

CREATE INDEX idx_tags_gin ON orders USING gin (tags);

-- =====================================================
-- AFTER: With GIN index (planner still chooses it, but marginal)
-- Expected: Bitmap Index Scan, ~24ms (1.7x - barely worth it)
-- =====================================================

EXPLAIN (ANALYZE, BUFFERS, TIMING)
SELECT * FROM orders WHERE tags @> ARRAY['sale'];

-- Results:
--   Scan Type: Bitmap Index Scan
--   Execution Time: 24.500 ms
--   Index Cond: (tags @> '{sale}'::text[])
--   Rows Returned: 83,258
--   Buffers: shared hit=3149, read=15

-- =====================================================
-- BONUS: Force index to compare overhead (optional)
-- =====================================================

SET enable_seqscan = off;

EXPLAIN (ANALYZE, BUFFERS, TIMING)
SELECT * FROM orders WHERE tags @> ARRAY['sale'];

-- With forced index: likely SLOWER than sequential scan due to overhead

SET enable_seqscan = on;

-- =====================================================
-- KEY LEARNING
-- =====================================================
-- 1. 83% selectivity = returning most of the table
-- 2. Index overhead (bitmap construction + random I/O) > sequential read
-- 3. PostgreSQL planner is cost-based, not rule-based
-- 4. At >50% selectivity, trust Seq Scan over forced indexing
-- 5. GIN helps arrays most with: low selectivity, exact matches, exclusion