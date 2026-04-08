-- ============================================
-- TEST 4: PLANNER IGNORES INDEX (High Selectivity)
-- Query: city = 'lahore' (~70% of rows)
-- Result: Seq Scan (planner correctly ignores index)
-- ============================================
CREATE INDEX IF NOT EXISTS idx_city ON users(city);

EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM users
WHERE city = 'lahore';

-- Expected Output:
-- Seq Scan on users (cost=0.00..3837.00 rows=139660 width=24)
-- (actual time=0.007..13.815 rows=140064 loops=1)
-- Filter: (city = 'lahore'::text)
-- Rows Removed by Filter: 59936
-- Planning Time: 0.880 ms
-- Execution Time: 15.902 ms
--
-- KEY FINDING: 70% rows match, Seq Scan faster than index+table lookup
-- Planner is smart - avoids index for high selectivity

