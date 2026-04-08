-- ============================================
-- INDEX DEFINITIONS FOR QUERY PLANNER BENCHMARK
-- Apply after schema.sql
-- ============================================

-- Single column indexes for basic lookups
CREATE INDEX IF NOT EXISTS idx_users_age ON users(age);
CREATE INDEX IF NOT EXISTS idx_users_city ON users(city);
CREATE INDEX IF NOT EXISTS idx_users_created_at ON users(created_at);
CREATE INDEX IF NOT EXISTS idx_users_is_active ON users(is_active);

-- Foreign key index (critical for join performance)
CREATE INDEX IF NOT EXISTS idx_orders_user_id ON orders(user_id);

-- Verify all indexes created
SELECT 
    schemaname,
    tablename,
    indexname,
    pg_size_pretty(pg_relation_size(indexrelid)) as index_size
FROM pg_indexes 
JOIN pg_stat_user_indexes USING (indexrelname)
WHERE tablename IN ('users', 'orders')
ORDER BY tablename, indexname;