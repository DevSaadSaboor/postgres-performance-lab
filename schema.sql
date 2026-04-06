-- PostgreSQL Index Performance Lab - Schema Setup
-- Run this first to create table and insert 100,000 rows

-- Clean slate
DROP TABLE IF EXISTS orders CASCADE;

-- Create table with diverse data types for index testing
CREATE TABLE orders (
    id BIGSERIAL PRIMARY KEY,
    customer_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    category_id INTEGER NOT NULL,
    status VARCHAR(20) NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP,
    metadata JSONB,                -- For GIN index testing
    tags TEXT[],                   -- For GIN array index testing
    search_vector TSVECTOR         -- For full-text search (future extension)
);

-- Insert 100,000 realistic rows with skewed distributions
INSERT INTO orders (
    customer_id, 
    product_id, 
    category_id, 
    status, 
    amount, 
    created_at, 
    updated_at, 
    metadata, 
    tags, 
    search_vector
)
SELECT 
    (random() * 50000)::INTEGER + 1,                    -- 50,000 customers
    (random() * 10000)::INTEGER + 1,                    -- 10,000 products (high cardinality)
    (random() * 100)::INTEGER + 1,                      -- 100 categories
    (ARRAY['pending','processing','shipped','delivered','cancelled'])[1 + (random() * 4)::INTEGER],
    (random() * 1000 + 10)::DECIMAL(10,2),              -- $10 to $1010
    NOW() - (random() * INTERVAL '365 days'),           -- Last year
    NOW() - (random() * INTERVAL '30 days'),            -- Last month
    jsonb_build_object(
        'region', (ARRAY['US','EU','APAC','LATAM'])[1 + (random() * 3)::INTEGER],
        'device', (ARRAY['mobile','desktop','tablet'])[1 + (random() * 2)::INTEGER],
        'campaign_id', (random() * 1000)::INTEGER
    ),
    CASE (random() * 3)::INTEGER
        WHEN 0 THEN ARRAY['electronics']
        WHEN 1 THEN ARRAY['electronics', 'sale']
        ELSE ARRAY['electronics', 'sale', 'new']
    END,
    to_tsvector('english', 'order customer ' || (random() * 50000)::INTEGER)
FROM generate_series(1, 100000);

-- Verify data loaded
SELECT 
    COUNT(*) as total_rows,
    COUNT(DISTINCT product_id) as product_cardinality,
    COUNT(DISTINCT status) as status_cardinality,
    MIN(created_at) as earliest_order,
    MAX(created_at) as latest_order
FROM orders;

-- Check data distribution (key for understanding selectivity)
SELECT 
    status, 
    COUNT(*) as cnt, 
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1) as pct
FROM orders 
GROUP BY status 
ORDER BY cnt DESC;

-- Check JSONB region distribution
SELECT 
    metadata->>'region' as region,
    COUNT(*) as cnt,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1) as pct
FROM orders
GROUP BY metadata->>'region'
ORDER BY cnt DESC;

-- Check array tag distribution
SELECT 
    CASE 
        WHEN tags @> ARRAY['sale'] THEN 'has_sale'
        ELSE 'no_sale'
    END as has_sale_tag,
    COUNT(*) as cnt,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1) as pct
FROM orders
GROUP BY tags @> ARRAY['sale']
ORDER BY cnt DESC;  