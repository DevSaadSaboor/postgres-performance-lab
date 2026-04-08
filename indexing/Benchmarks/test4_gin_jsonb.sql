-- Test 4: GIN Index for JSONB Benchmark
-- Query: JSONB containment operator (@>)
-- Lesson: GIN indexes complex types where B-Tree cannot help

-- =====================================================
-- BEFORE: No index on metadata
-- Expected: Seq Scan, ~35ms, parsing JSONB for every row
-- =====================================================

EXPLAIN (ANALYZE, BUFFERS, TIMING)
SELECT * FROM orders WHERE metadata @> '{"region": "US"}';

-- Results:
--   Scan Type: Seq Scan
--   Execution Time: 34.919 ms
--   Filter: (metadata @> '{"region": "US"}'::jsonb)
--   Rows Removed by Filter: 83,477
--   Rows Returned: 16,523 (17% selectivity)
--   Buffers: shared hit=3134

-- =====================================================
-- CREATE INDEX: GIN for JSONB
-- B-Tree cannot index JSONB containment - GIN is required
-- =====================================================

CREATE INDEX idx_metadata ON orders USING gin (metadata);

-- =====================================================
-- AFTER: With GIN index
-- Expected: Bitmap Index Scan, ~16ms (2.1x speedup)
-- =====================================================

EXPLAIN (ANALYZE, BUFFERS, TIMING)
SELECT * FROM orders WHERE metadata @> '{"region": "US"}';

-- Results:
--   Scan Type: Bitmap Index Scan
--   Execution Time: 16.261 ms
--   Index Cond: (metadata @> '{"region": "US"}'::jsonb)
--   Rows Removed by Filter: 0
--   Buffers: shared hit=3158, read=34

-- =====================================================
-- KEY LEARNING
-- =====================================================
-- 1. GIN = Generalized Inverted Index for complex data types
-- 2. B-Tree cannot help with JSONB operators (@>, <@, ?, ?|, ?&)
-- 3. 2.1x speedup despite 17% selectivity (better than B-Tree range)
-- 4. GIN stores keys from JSONB, not the whole value
-- 5. Trade-off: GIN indexes are larger and slower to update than B-Tree