-- ============================================
-- TEST 5: FORCE INDEX (Bad Decision Demo)
-- Query: city = 'lahore' with seqscan disabled
-- Result: Bitmap Index Scan (forced, minimal gain)
-- ============================================
SET enable_seqscan = OFF;

EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM users
WHERE city = 'lahore';

SET enable_seqscan = ON;

-- Expected Output:
-- Bitmap Heap Scan on users (cost=1562.66..4645.41 rows=139660 width=24)
-- (actual time=2.625..10.825 rows=140064 loops=1)
-- -> Bitmap Index Scan on idx_city (cost=0.00..1527.75 rows=139660 width=0)
-- (actual time=2.511..2.511 rows=140064 loops=1)
-- Planning Time: 0.081 ms
-- Execution Time: 12.981 ms
--
-- KEY FINDING: Forced index is slightly faster (12.98ms vs 15.90ms)
-- But gain is minimal - planner was right to use Seq Scan