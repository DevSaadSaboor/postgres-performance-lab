-- ============================================
-- TEST 10: RANGE QUERY
-- Query: age BETWEEN 20 AND 40
-- Result: Bitmap Index Scan
-- ============================================
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM users WHERE age BETWEEN 20 AND 40;

-- Expected Output:
-- Bitmap Heap Scan on users (cost=594.80..2579.36 rows=43171 width=24)
-- (actual time=1.336..5.774 rows=42153 loops=1)
-- Recheck Cond: ((age >= 20) AND (age <= 40))
-- -> Bitmap Index Scan on idx_age (cost=0.00..584.00 rows=43171 width=0)
-- (actual time=1.224..1.224 rows=42153 loops=1)
-- Index Cond: ((age >= 20) AND (age <= 40))
-- Planning Time: 0.224 ms
-- Execution Time: 6.453 ms
--
-- KEY FINDING: Range query uses Bitmap Index Scan
-- ~21% of rows (42K), 6.5ms execution