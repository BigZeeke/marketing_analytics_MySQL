# Marketing Analytics — MySQL Portfolio

A production-grade MySQL database modeling a B2B marketing software company running campaigns across six channels over two full years (2023–2024). Built to demonstrate advanced SQL engineering across the full stack — schema design, stored procedures, triggers, window functions, CTEs, index strategy, and execution plan analysis.

**25 tables · 3,000+ rows · 11 SQL files · 10 marketing analytics topics**

---

## What This Demonstrates

| Skill | Where |
|---|---|
| Schema design & normalization (1NF–3NF/BCNF) | `01_create_schema.sql` |
| FK constraints, ON DELETE/UPDATE cascade rules | `01_create_schema.sql` |
| Complex multi-table INSERTs with referential integrity | `02_data_core.sql`, `03_data_channels.sql` |
| Reporting views with aggregations and JOINs | `04_views.sql` |
| Stored procedures with error handling & audit logging | `05_stored_procedures.sql` |
| Scalar UDFs (ROAS, lead tier, CLV, LCP rating) | `06_functions.sql` |
| Triggers (auto-scoring, audit trail, budget enforcement) | `07_triggers.sql` |
| Window functions (LAG, LEAD, RANK, NTILE, running totals) | `08_window_functions.sql` |
| CTEs & subqueries (attribution, A/B lift, funnel analysis) | `09_ctes_subqueries.sql` |
| Index strategy + EXPLAIN execution plan analysis | `10_indexes.sql` |
| Production analytical queries (one per marketing topic) | `11_analysis.sql` |

---

## Repository Structure

```
marketing_analytics_MySQL/
├── sql/
│   ├── 01_schema/
│   │   └── 01_create_schema.sql        # 25 table definitions with FK constraints
│   ├── 02_data/
│   │   ├── 02_data_core.sql            # Products, customers, campaigns, leads, orders
│   │   └── 03_data_channels.sql        # SEO, PPC, email, GTM, content, audiences, A/B tests
│   ├── 03_views/
│   │   └── 04_views.sql                # 10 reporting views
│   ├── 04_stored_procedures/
│   │   └── 05_stored_procedures.sql    # 8 stored procedures with error handling
│   ├── 05_functions/
│   │   └── 06_functions.sql            # 10 scalar UDFs
│   ├── 06_triggers/
│   │   └── 07_triggers.sql             # 7 triggers
│   ├── 07_window_functions/
│   │   └── 08_window_functions.sql     # 10 window function queries
│   ├── 08_ctes_subqueries/
│   │   └── 09_ctes_subqueries.sql      # 11 CTE and subquery analyses
│   ├── 09_indexes/
│   │   └── 10_indexes.sql              # Index strategy + EXPLAIN examples
│   └── 10_analysis/
│       └── 11_analysis.sql             # 10 production analytical queries
└── README.md
```

---

## Run Order

Execute files in numbered order in MySQL Workbench. Each file depends on the previous.

| Step | File | Description |
|---|---|---|
| 1 | `01_create_schema.sql` | Creates schema and all 25 tables |
| 2 | `02_data_core.sql` | Loads products, customers, campaigns, leads, orders, payments |
| 3 | `03_data_channels.sql` | Loads SEO, PPC, email, GTM, content, audiences, A/B tests, web |
| 4 | `04_views.sql` | Creates 10 reporting views |
| 5 | `05_stored_procedures.sql` | Creates 8 stored procedures |
| 6 | `06_functions.sql` | Creates 10 scalar UDFs |
| 7 | `07_triggers.sql` | Creates 7 triggers |
| 8 | `08_window_functions.sql` | Window function query examples |
| 9 | `09_ctes_subqueries.sql` | CTE and subquery examples |
| 10 | `10_indexes.sql` | Index strategy + EXPLAIN execution plans |
| 11 | `11_analysis.sql` | 10 production analytical queries |

**Quick start in MySQL Workbench:** Open each file → `CMD+A` → `CMD+Enter`

---

## Database Schema

### Core Tables
| Table | Rows | Description |
|---|---|---|
| `products` | 20 | Software, services, training, and support SKUs |
| `customers` | 50 | Enterprise, SMB, and Consumer segments across 30+ cities |
| `campaigns` | 40 | 20 campaigns per year across 6 channels and 4 campaign types |
| `leads` | 300+ | Multi-status leads (new, qualified, converted, stale) with deal values |
| `orders` | 90 | Customer orders linked to source campaigns |
| `order_items` | 48 | Line items per order |
| `payments` | 90 | Payment records |

### Channel Tables
| Table | Rows | Description |
|---|---|---|
| `seo_keywords` | 40 | Keyword research with intent, difficulty, and topic cluster |
| `seo_rankings` | 32 | Monthly position snapshots showing rank improvement 2023→2024 |
| `organic_traffic` | 32 | Monthly sessions by page |
| `ad_groups` | 14 | PPC ad group configuration and bid strategies |
| `ads` | 13 | RSA ad copy with headlines and descriptions |
| `ad_performance` | 20 | Monthly impressions, clicks, spend, conversion value |
| `email_campaigns` | 20 | Email sends with subject lines, segments, list sizes |
| `email_events` | 55 | Individual open, click, convert, unsubscribe events |
| `gtm_tags` | 20 | GA4, Google Ads, Meta Pixel, LinkedIn tag configurations |
| `web_events` | 33 | Web events fired by GTM tags |
| `content_pieces` | 30 | Blog posts, whitepapers, case studies, landing pages |
| `content_performance` | 19 | Monthly engagement and conversion metrics |
| `audiences` | 15 | Audience definitions across Google, Meta, LinkedIn, Email |
| `audience_members` | 19 | Customer-to-audience assignments |
| `ab_tests` | 12 | A/B test configurations across 6 test types |
| `ab_variants` | 24 | Variant results with impressions, conversions, revenue |
| `web_sessions` | 25 | Session-level web analytics |

---

## Key SQL Techniques

### Window Functions (`08_window_functions.sql`)
```sql
-- Month-over-month revenue growth with LAG
SELECT
    DATE_FORMAT(order_date, '%Y-%m')                        AS month,
    SUM(amount)                                             AS revenue,
    LAG(SUM(amount)) OVER (ORDER BY DATE_FORMAT(order_date, '%Y-%m')) AS prev_month,
    ROUND(
        (SUM(amount) - LAG(SUM(amount)) OVER (ORDER BY DATE_FORMAT(order_date, '%Y-%m')))
        / LAG(SUM(amount)) OVER (ORDER BY DATE_FORMAT(order_date, '%Y-%m')) * 100, 2
    )                                                       AS mom_growth_pct
FROM orders
GROUP BY DATE_FORMAT(order_date, '%Y-%m')
ORDER BY month;
```

### CTEs & Attribution (`09_ctes_subqueries.sql`)
```sql
-- First-touch attribution: revenue by first lead source
WITH first_touch AS (
    SELECT
        customer_id,
        lead_source,
        ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY created_at) AS rn
    FROM leads
    WHERE status = 'converted'
)
SELECT
    ft.lead_source,
    COUNT(*)            AS converted_customers,
    SUM(o.amount)       AS attributed_revenue
FROM first_touch ft
JOIN orders o ON ft.customer_id = o.customer_id
WHERE ft.rn = 1
GROUP BY ft.lead_source
ORDER BY attributed_revenue DESC;
```

### Index Strategy + EXPLAIN (`10_indexes.sql`)
```sql
-- Covering index for hot campaign + status reporting query
CREATE INDEX idx_leads_campaign_status
    ON leads (campaign_id, status, deal_value);

-- Verify with EXPLAIN
EXPLAIN SELECT campaign_id, status, SUM(deal_value)
FROM leads
WHERE campaign_id = 2 AND status = 'converted'
GROUP BY campaign_id, status;
```

### ROAS Scalar UDF (`06_functions.sql`)
```sql
CREATE FUNCTION calculate_roas(p_campaign_id INT)
RETURNS DECIMAL(10,2) DETERMINISTIC
BEGIN
    DECLARE v_spend     DECIMAL(10,2);
    DECLARE v_revenue   DECIMAL(10,2);
    SELECT spend INTO v_spend FROM campaigns WHERE campaign_id = p_campaign_id;
    SELECT COALESCE(SUM(deal_value), 0) INTO v_revenue
    FROM leads WHERE campaign_id = p_campaign_id AND status = 'converted';
    IF v_spend = 0 THEN RETURN 0; END IF;
    RETURN ROUND(v_revenue / v_spend, 2);
END;
```

---

## Related Projects

This schema is the foundation for the **[Marketing Analytics Assistant](https://github.com/BigZeeke/marketing_analytics_assistant)** — a live NL-to-SQL chat app that queries a migrated version of this schema on Databricks.

**[→ Try the Live Demo](https://marketing-analytics-assistant.streamlit.app)**

---

## Prerequisites

- MySQL 8.0+ (window functions require 8.0)
- MySQL Workbench (recommended) or any MySQL client
- ~5 minutes to run all 11 files in order

## Author

Steve Lopez · [LinkedIn](https://linkedin.com/in/stevelopezenterprise) · [GitHub](https://github.com/BigZeeke)
