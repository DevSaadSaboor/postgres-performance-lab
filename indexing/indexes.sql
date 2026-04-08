-- PostgreSQL Index Performance Lab - Index Creation
-- Run these one by one, testing between each

-- =====================================================
-- BASELINE: Verify only primary key exists
-- =====================================================
SELECT indexname, indexdef 
FROM pg_indexes 
WHERE tablename = 'orders';

-- Expected: Only orders_pkey

-- =====================================================
-- TEST 1: Single-Column B-Tree Index
-- =====================================================
-- Query: SELECT * FROM orders WHERE product_id = 5000;
-- Expected: Bitmap Index Scan, ~0.09ms (190x speedup)

CREATE INDEX idx_product_id ON orders USING btree (product_id);

-- Verify
EXPLAIN (ANALYZE, BUFFERS, TIMING)
SELECT * FROM orders WHERE product_id = 5000;

-- =====================================================
-- TEST 2: Composite B-Tree Index (replace Test 1 index)
-- =====================================================
-- Query: SELECT * FROM orders WHERE product_id = 5000 AND status = 'shipped';
-- Expected: Bitmap Index Scan on both columns, ~0.17ms (75x speedup)

DROP INDEX IF EXISTS idx_product_id;

CREATE INDEX idx_product_status ON orders USING btree (product_id, status);

-- Verify
EXPLAIN (ANALYZE, BUFFERS, TIMING)
SELECT * FROM orders 
WHERE product_id = 5000 AND status = 'shipped';

-- =====================================================
-- TEST 3: Range-Optimized B-Tree Index
-- =====================================================
-- Query: SELECT * FROM orders WHERE created_at > '2026-01-01';
-- Expected: Bitmap Index Scan, ~18ms (1.04x speedup - marginal due to 26% selectivity)

CREATE INDEX idx_created_at ON orders USING btree (created_at);

-- Verify
EXPLAIN (ANALYZE, BUFFERS, TIMING)
SELECT * FROM orders WHERE created_at > '2026-01-01';

-- =====================================================
-- TEST 4: GIN Index for JSONB
-- =====================================================
-- Query: SELECT * FROM orders WHERE metadata @> '{"region": "US"}';
-- Expected: Bitmap Index Scan using GIN, ~16ms (2.1x speedup)

CREATE INDEX idx_metadata ON orders USING gin (metadata);

-- Verify
EXPLAIN (ANALYZE, BUFFERS, TIMING)
SELECT * FROM orders WHERE metadata @> '{"region": "US"}';

-- =====================================================
-- TEST 5: GIN Index for Arrays
-- =====================================================
-- Query: SELECT * FROM orders WHERE tags @> ARRAY['sale'];
-- Expected: Bitmap Index Scan, ~24ms (1.7x - planner was right to hesitate at 83% selectivity!)

CREATE INDEX idx_tags_gin ON orders USING gin (tags);

-- Verify
EXPLAIN (ANALYZE, BUFFERS, TIMING)
SELECT * FROM orders WHERE tags @> ARRAY['sale'];

-- =====================================================
-- FINAL: List all indexes created with sizes
-- =====================================================
SELECT 
    indexname, 
    indexdef,
    pg_size_pretty(pg_relation_size(indexrelid)) as size
FROM pg_indexes 
JOIN pg_stat_user_indexes USING (indexrelname)
WHERE tablename = 'orders'
ORDER BY pg_relation_size(indexrelid) DESC;