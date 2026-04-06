-- Test 1: Single-Column B-Tree Index Benchmark
-- Query: Equality lookup on high-cardinality column

-- =====================================================
-- BEFORE: No index on product_id
-- Expected: Seq Scan, ~17ms, 99,989 rows removed by filter
-- =====================================================

EXPLAIN (ANALYZE, BUFFERS, TIMING)
SELECT * FROM orders WHERE product_id = 5000;

-- Results:
--   Scan Type: Seq Scan
--   Execution Time: 16.906 ms
--   Rows Removed by Filter: 99,989
--   Buffers: shared hit=3134

-- =====================================================
-- CREATE INDEX: Single-column B-Tree
-- =====================================================

CREATE INDEX idx_product_id ON orders USING btree (product_id);

-- =====================================================
-- AFTER: With B-Tree index
-- Expected: Bitmap Index Scan, ~0.09ms, 190x speedup
-- =====================================================

EXPLAIN (ANALYZE, BUFFERS, TIMING)
SELECT * FROM orders WHERE product_id = 5000;

-- Results:
--   Scan Type: Bitmap Index Scan
--   Execution Time: 0.089 ms
--   Rows Removed by Filter: 0 (index finds exact rows)
--   Buffers: shared hit=11, read=2

-- =====================================================
-- KEY LEARNING
-- =====================================================
-- Low selectivity (0.01%) + high cardinality (10k products) = 
-- massive index benefit. Bitmap scan batches row fetches for efficiency.