-- Test 2: Composite B-Tree Index Benchmark
-- Query: Multi-column equality filter
-- Lesson: Column order matters (most selective first)

-- =====================================================
-- BEFORE: No composite index (drop single-column first)
-- Expected: Seq Scan, ~13ms, filter on both columns
-- =====================================================

DROP INDEX IF EXISTS idx_product_id;

EXPLAIN (ANALYZE, BUFFERS, TIMING)
SELECT * FROM orders 
WHERE product_id = 5000 AND status = 'shipped';

-- Results:
--   Scan Type: Seq Scan
--   Execution Time: 12.819 ms
--   Filter: ((product_id = 5000) AND (status = 'shipped'::text))
--   Rows Removed by Filter: 99,997
--   Buffers: shared hit=3134

-- =====================================================
-- CREATE INDEX: Composite B-Tree
-- Column order: product_id (high cardinality) first, status second
-- =====================================================

CREATE INDEX idx_product_status ON orders USING btree (product_id, status);

-- =====================================================
-- AFTER: With composite index
-- Expected: Bitmap Index Scan, ~0.17ms, both columns in Index Cond
-- =====================================================

EXPLAIN (ANALYZE, BUFFERS, TIMING)
SELECT * FROM orders 
WHERE product_id = 5000 AND status = 'shipped';

-- Results:
--   Scan Type: Bitmap Index Scan
--   Execution Time: 0.170 ms
--   Index Cond: ((product_id = 5000) AND (status = 'shipped'::text))
--   Rows Removed by Filter: 0
--   Buffers: shared hit=3, read=3

-- =====================================================
-- KEY LEARNING
-- =====================================================
-- 1. No "Filter" line after = index handles ALL conditions
-- 2. Column order: equality filters first, most selective leftmost
-- 3. 75x speedup vs sequential scan
-- 4. Composite index eliminates post-filtering entirely