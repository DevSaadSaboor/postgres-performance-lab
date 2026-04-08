# PostgreSQL Query Planner & Optimisation Benchmark

A real-world demonstration of PostgreSQL query planning strategies using large-scale datasets (700K+ total rows), covering index selection, join strategies, and planner behaviour under varying conditions.

---

## Dataset

| Table    | Rows    | Size  |
|----------|---------|-------|
| `users`  | 200,000 | ~24MB |
| `orders` | 500,000 | ~20MB |

**Data Distribution**

| Column      | Distribution                              |
|-------------|-------------------------------------------|
| `city`      | 70% Lahore · 20% Karachi · 10% Islamabad |
| `is_active` | 50% `true` · 50% `false`                 |
| `age`       | Random integer, 0–100                    |

---

## Quick Start

```bash
# 1. Create schema and seed data
psql -d your_database -f schema.sql

# 2. Create indexes
psql -d your_database -f indexes.sql

# 3. Run benchmarks
psql -d your_database -f benchmark.sql
```

> All test queries are executed with `EXPLAIN (ANALYZE, BUFFERS)` to capture actual execution time and buffer usage.

---

## Benchmark Results

### 1 · Sequential Scan vs Index Scan

| Test | Query Pattern | Plan | Execution Time | Key Insight |
|------|---------------|------|----------------|-------------|
| 1 | `created_at > NOW() - 30 days` (no index) | Seq Scan | 34.597 ms | Baseline — full table read |
| 2 | Same query with index | Bitmap Index Scan | 3.915 ms | **8.8× faster** |

---

### 2 · When the Planner Ignores an Index

| Test | Condition | Selectivity | Plan | Time |
|------|-----------|-------------|------|------|
| 4 | `city = 'lahore'` | ~70% (140K rows) | Seq Scan | 15.902 ms |
| 5 | Same, index forced | ~70% | Bitmap Index Scan | 12.981 ms |

> **Insight:** The planner correctly prefers a sequential scan for high-selectivity predicates. Forcing the index yields only a marginal gain (~2.9 ms) and adds overhead.

---

### 3 · LIMIT Optimisation

| Test | Query | Plan | Execution Time |
|------|-------|------|----------------|
| 9a | `age = 5` | Bitmap Index Scan | 0.961 ms |
| 9b | `age = 5 LIMIT 5` | Index Scan | 0.030 ms |

> **32× faster with `LIMIT`** — the planner switches strategy and performs early stopping as soon as enough rows are found.

---

### 4 · Join Strategies

| Test | Tables | Filter | Join Type | Execution Time |
|------|--------|--------|-----------|----------------|
| 6 | `users` + `orders` | None | Hash Join | 309.298 ms |
| 7 | `users` + `orders` | None | Merge Join | 329.261 ms |
| 8 | `users` + `orders` | `u.id < 100` | Nested Loop | 0.382 ms |

> **~800× improvement** when the outer table is small (99 rows vs 200K). Nested loop with an indexed inner table becomes optimal.

---

### 5 · Range Queries

| Test | Query | Rows Returned | Plan | Time |
|------|-------|---------------|------|------|
| 10 | `age BETWEEN 20 AND 40` | ~42K (21%) | Bitmap Index Scan | 6.453 ms |

---

## Key Findings

### Index Selectivity Rules

| Selectivity | Example | Optimal Plan |
|-------------|---------|--------------|
| < 5% | `email = 'specific@example.com'` | Index Scan |
| 5–20% | `created_at > NOW() - 30 days` | Bitmap Index Scan |
| 20–50% | `age BETWEEN 20 AND 40` | Bitmap Index Scan |
| > 50% | `city = 'lahore'` (70%) | Seq Scan |

### Join Selection

| Outer Table Size | Optimal Join Type | Typical Scenario |
|------------------|-------------------|-----------------|
| Large (100K+) | Hash Join / Merge Join | Full table join |
| Small (< 1,000) | Nested Loop | Filtered join with indexed inner table |

### Critical Optimisation Principles

1. **`LIMIT` changes plans** — enables early stopping; the planner may switch from Bitmap to Index Scan entirely.
2. **Statistics matter** — run `ANALYZE` after bulk inserts so the planner has accurate row estimates.
3. **Type safety** — passing `'25'` (text) instead of `25` (integer) prevents index usage due to implicit casting.
4. **Covering indexes** — including all `SELECT` columns in the index avoids heap lookups and reduces I/O.

---

## Repository Structure

| File | Description |
|------|-------------|
| `schema.sql` | Table definitions and data seeding (200K users · 500K orders) |
| `indexes.sql` | Index definitions used across all test cases |
| `benchmark.sql` | All 10 test queries with inline result documentation |

---

## Environment

| Requirement | Detail |
|-------------|--------|
| PostgreSQL | 14+ (tested on 15) |
| Memory | 4 GB+ recommended (required for hash joins on full dataset) |
| Disk | SSD recommended for consistent and fair benchmark comparisons |

---

## Concepts Covered

- Sequential Scan
- Index Scan
- Bitmap Index Scan
- Hash Join
- Merge Join
- Nested Loop Join
- `LIMIT` early-stopping optimisation
- Planner statistics and `ANALYZE`
- Index selectivity thresholds
- Join order optimisation

---

*Dataset: 700K total rows across two tables · All queries analysed with `EXPLAIN (ANALYZE, BUFFERS)` · Created: 2026-04-08*