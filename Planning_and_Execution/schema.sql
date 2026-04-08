-- ============================================
-- USERS TABLE (200,000 rows)
-- ============================================
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    age INT NOT NULL,
    city VARCHAR(50) NOT NULL,
    is_active BOOLEAN NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);


-- 70% lahore, 20% karachi, 10% islamabad
INSERT INTO users (age, city, is_active, created_at)
SELECT 
    (random() * 100)::int AS age,
    CASE 
        WHEN random() < 0.70 THEN 'lahore'
        WHEN random() < 0.90 THEN 'karachi'
        ELSE 'islamabad'
    END AS city,
    (random() < 0.5) AS is_active,
    NOW() - (random() * interval '365 days') AS created_at
FROM generate_series(1, 200000);

-- ============================================
-- ORDERS TABLE (500,000 rows)
-- ============================================
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users(id),
    amount INT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);


INSERT INTO orders (user_id, amount, created_at)
SELECT 
    (random() * 199999 + 1)::int AS user_id,
    (random() * 1000)::int AS amount,
    NOW() - (random() * interval '365 days') AS created_at
FROM generate_series(1, 500000);

-- Update statistics for accurate query planning
ANALYZE users;
ANALYZE orders;
