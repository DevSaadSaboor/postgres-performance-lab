# PostgreSQL Index Performance Lab

Systematic benchmark of five index types on 100,000 rows. Demonstrates when indexes help, when they hurt, and why query planners make cost-based decisions.

> **Junior-level differentiator:** Most candidates know `CREATE INDEX`. This repo proves you understand *when* to use each type and *why* the planner ignores them.

---

## Table of Contents

- [Schema](#schema)
- [Dataset](#dataset)
- [Results Summary](#results-summary)
- [Key Learnings](#key-learnings)
- [Index Definitions](#index-definitions)
- [Screenshots](#screenshots)
- [Useful Commands](#useful-commands)
- [Environment](#environment)

---

## Schema

```sql
CREATE TABLE orders (
    id           BIGSERIAL PRIMARY KEY,
    customer_id  INTEGER     NOT NULL,
    product_id   INTEGER     NOT NULL,
    category_id  INTEGER     NOT NULL,
    status       VARCHAR(20) NOT NULL,
    amount       DECIMAL(10,2) NOT NULL,
    created_at   TIMESTAMP   NOT NULL,
    updated_at   TIMESTAMP,
    metadata     JSONB,
    tags         TEXT[],
    search_vector TSVECTOR
);
```

---

## Dataset

100,000 rows with realistic distributions:

| Dimension    | Cardinality |
|--------------|-------------|
| Customers    | 50,000      |
| Products     | 10,000      |
| Categories   | 100         |
| Statuses     | 5           |
| Regions      | 4           |

---

## Results Summary

| Test | Query Pattern | Selectivity | Before | After | Speedup | Index Type |
|------|--------------|-------------|--------|-------|---------|------------|
| 1 | `product_id = 5000` | 0.01% | 16.906 ms | 0.089 ms | **190×** | B-Tree |
| 2 | `product_id = 5000 AND status = 'shipped'` | 0.003% | 12.819 ms | 0.170 ms | **75×** | Composite B-Tree |
| 3 | `created_at > '2026-01-01'` | 26% | 18.956 ms | 18.244 ms | **1.04×** | B-Tree |
| 4 | `metadata @> '{"region": "US"}'` | 17% | 34.919 ms | 16.261 ms | **2.1×** | GIN (JSONB) |
| 5 | `tags @> ARRAY['sale']` | 83% | 41.230 ms | 24.500 ms | **1.7×** | GIN (Array) |

---

## Key Learnings

### ✅ Indexes Dominate When

- **Selectivity is low (< 1%)** — Tests 1 and 2 show 75–190× speedups.
- **Column cardinality is high** — `product_id` (10k unique values) outperforms `status` (5 unique values).
- **Composite indexes cover multi-column filters** — eliminates post-filter heap fetches entirely.

### ⚠️ Indexes Are Marginal When

- **Selectivity is medium (10–30%)** — Test 3 yielded only a 4% improvement.
- **Row distribution is scattered** — even with an index, the planner still touches most heap pages (3,134 buffers in Test 3).

### ❌ Indexes Can Hurt When

- **Selectivity is very high (> 50%)** — Test 5 shows the planner correctly hesitated before using the index.
- **Traversal overhead exceeds benefit** — index lookup + heap fetches can cost more than a straight sequential scan.

### 🎯 Critical Insight

> *"Test 3 surprised me: 26% selectivity meant the B-Tree index only improved performance by 4%. The query planner was right — at medium-high selectivity, sequential scan is often faster. I learned to measure with `EXPLAIN (ANALYZE, BUFFERS)`, not assume indexes are always better."*

---

## Index Definitions

```sql
-- Test 1: Single-column B-Tree (equality lookup)
CREATE INDEX idx_product_id ON orders USING btree (product_id);

-- Test 2: Composite B-Tree (most selective column first)
CREATE INDEX idx_product_status ON orders USING btree (product_id, status);

-- Test 3: Range-optimised B-Tree
CREATE INDEX idx_created_at ON orders USING btree (created_at);

-- Test 4: GIN for JSONB containment operators (@>, <@)
CREATE INDEX idx_metadata ON orders USING gin (metadata);

-- Test 5: GIN for array operators (@>, &&)
CREATE INDEX idx_tags_gin ON orders USING gin (tags);
```

---

## Screenshots

Full `EXPLAIN (ANALYZE, BUFFERS, TIMING)` outputs are in `results/screenshots/`.

| Test | Before | After |
|------|--------|-------|
| 1 — B-Tree Equality | `results/screenshots/test1_before.png` | `results/screenshots/test1_after.png` |
| 2 — Composite B-Tree | `results/screenshots/test2_before.png` | `results/screenshots/test2_after.png` |
| 3 — Range B-Tree | `results/screenshots/test3_before.png` | `results/screenshots/test3_after.png` |
| 4 — GIN JSONB | `results/screenshots/test4_before.png` | `results/screenshots/test4_after.png` |
| 5 — GIN Array | `results/screenshots/test5_before.png` | `results/screenshots/test5_after.png` |

**All indexes created:** `results/screenshots/index_list_final.png`

---

## Useful Commands

**Analyse a query:**

```sql
EXPLAIN (ANALYZE, BUFFERS, TIMING)
SELECT * FROM orders WHERE ...;
```

**List existing indexes:**

```sql
SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'orders';
```

**Force index usage (testing only):**

```sql
SET enable_seqscan = off;
EXPLAIN (ANALYZE, BUFFERS) SELECT ...;
SET enable_seqscan = on;
```

---

## Environment

| Component | Version / Tool |
|-----------|---------------|
| Database  | PostgreSQL 16  |
| Client    | DBeaver        |
| Benchmark date | April 2026 |