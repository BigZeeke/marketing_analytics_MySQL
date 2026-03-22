# Marketing Analytics SQL Portfolio

A production-grade SQL portfolio project demonstrating advanced analytics across the full digital marketing stack — built in MySQL 8.0 and designed to showcase Analytics Engineering skills for roles targeting dbt, Databricks, and Snowflake environments.

---

## Project Overview

This project models a fictional B2B marketing software company running campaigns across six channels (Email, Paid Search, Social, Organic, Display, Referral) over two full years (2023–2024). The database supports year-over-year comparison, full-funnel attribution, campaign optimization analysis, and executive-level reporting.

**25 tables | 3,000+ rows | 11 SQL files | 10 digital marketing topics**

---

## Repository Structure

```
marketing_analytics_portfolio/
│
├── sql/
│   ├── 01_schema/
│   │   └── 01_create_schema.sql       # All 25 table definitions with FK constraints
│   │
│   ├── 02_data/
│   │   ├── 02_data_core.sql           # Products, customers, campaigns, leads, orders
│   │   └── 03_data_channels.sql       # SEO, PPC, email, GTM, content, audiences, A/B tests, web, trends
│   │
│   ├── 03_views/
│   │   └── 04_views.sql               # 10 reusable views (campaign perf, email metrics, KPI dashboard, etc.)
│   │
│   ├── 04_stored_procedures/
│   │   └── 05_stored_procedures.sql   # 8 stored procedures with error handling and audit logging
│   │
│   ├── 05_functions/
│   │   └── 06_functions.sql           # 10 scalar UDFs (ROAS, lead tier, LCP rating, CLV tier, etc.)
│   │
│   ├── 06_triggers/
│   │   └── 07_triggers.sql            # 7 triggers (auto-scoring, audit trail, budget enforcement)
│   │
│   ├── 07_window_functions/
│   │   └── 08_window_functions.sql    # 10 window function queries (LAG, LEAD, RANK, NTILE, running totals)
│   │
│   ├── 08_ctes_subqueries/
│   │   └── 09_ctes_subqueries.sql     # 11 CTE and subquery analyses (attribution, A/B lift, funnel)
│   │
│   ├── 09_indexes/
│   │   └── 10_indexes.sql             # Strategic index design + EXPLAIN examples for all 25 tables
│   │
│   └── 10_analysis/
│       └── 11_analysis.sql            # 10 production analytical queries — one per marketing topic
│
└── docs/
    └── README.md                      # This file
```

---

## Run Order

Execute files in numbered order. Each file depends on the previous.

| Step | File                       | Description                                                            |
| ---- | -------------------------- | ---------------------------------------------------------------------- |
| 1    | `01_create_schema.sql`     | Creates the `marketing_analytics` schema and all 25 tables             |
| 2    | `02_data_core.sql`         | Loads products, customers, campaigns, leads, orders, payments          |
| 3    | `03_data_channels.sql`     | Loads SEO, PPC, email, GTM, content, audiences, A/B tests, web, trends |
| 4    | `04_views.sql`             | Creates 10 reporting views                                             |
| 5    | `05_stored_procedures.sql` | Creates 8 stored procedures                                            |
| 6    | `06_functions.sql`         | Creates 10 scalar UDFs                                                 |
| 7    | `07_triggers.sql`          | Creates 7 triggers                                                     |
| 8    | `08_window_functions.sql`  | Window function query examples                                         |
| 9    | `09_ctes_subqueries.sql`   | CTE and subquery examples                                              |
| 10   | `10_indexes.sql`           | Applies index strategy + runs EXPLAIN examples                         |
| 11   | `11_analysis.sql`          | Runs all 10 production analytical queries                              |

**Quick start in MySQL Workbench:** Open each file, select all (`CMD+A` / `CTRL+A`), execute (`CMD+Enter` / `CTRL+Enter`).

---

## 📚 Training Guide

New to SQL or digital marketing analytics? A complete self-paced training course
built around this project is available in the [`training/`](/training/) folder.
It covers all 10 digital marketing topics, every SQL technique used in this project,
and includes exercises, quizzes, and answers for each module.

**~10 hours of structured learning | 11 modules | 60+ term glossary**

---

## Database Schema

The ../training/ path works because your README.md lives inside docs/ — you need to go up one level to reach training/. If you move the README to the repo root instead, the path becomes just training/.Want to be notified when Claude responds?Notify Sonnet 4.6Claude is AI and can make mistakes. Please double-check responses.Marketing analytics training · ZIPMarketing analytics trainingZIP

## Database Schema

### Core Tables

| Table         | Rows | Description                                                            |
| ------------- | ---- | ---------------------------------------------------------------------- |
| `products`    | 20   | Software, services, training, and support SKUs                         |
| `customers`   | 50   | Enterprise, SMB, and Consumer segments across 30+ cities               |
| `campaigns`   | 40   | 20 campaigns per year across 6 channels and 4 campaign types           |
| `leads`       | 300+ | Multi-status leads (new, qualified, converted, stale) with deal values |
| `orders`      | 90   | Customer orders linked to source campaigns                             |
| `order_items` | 48   | Line items per order                                                   |
| `payments`    | 90   | Payment records                                                        |

### Channel Tables

| Table                 | Rows | Description                                                       |
| --------------------- | ---- | ----------------------------------------------------------------- |
| `seo_keywords`        | 40   | Keyword research data with intent, difficulty, and topic cluster  |
| `seo_rankings`        | 40   | Monthly ranking snapshots showing position improvement 2023→2024  |
| `organic_traffic`     | 32   | Monthly organic sessions by page                                  |
| `ad_groups`           | 14   | PPC ad group configuration and bid strategies                     |
| `ads`                 | 13   | RSA ad copy with headlines and descriptions                       |
| `ad_performance`      | 20   | Monthly impressions, clicks, spend, and conversion value          |
| `email_campaigns`     | 20   | Email sends with subject lines, segments, and list sizes          |
| `email_events`        | 55   | Individual open, click, convert, and unsubscribe events           |
| `gtm_tags`            | 20   | Tag configurations (GA4, Google Ads, Meta Pixel, LinkedIn)        |
| `web_events`          | 33   | Web events fired by GTM tags                                      |
| `content_pieces`      | 30   | Blog posts, whitepapers, case studies, and landing pages          |
| `content_performance` | 19   | Monthly content engagement and conversion metrics                 |
| `audiences`           | 15   | Audience definitions across Google, Meta, LinkedIn, and Email     |
| `audience_members`    | 19   | Customer-to-audience assignments                                  |
| `ab_tests`            | 12   | A/B test configurations across 6 test types                       |
| `ab_variants`         | 24   | Control vs variant results with sample sizes and revenue          |
| `web_pages`           | 22   | Page inventory with type, CTA, and publish date                   |
| `web_sessions`        | 28   | Session-level data with source, device, and conversion flag       |
| `web_vitals`          | 22   | Core Web Vitals (LCP, FID, CLS) and PageSpeed scores by page/date |
| `industry_trends`     | 20   | Trend tracking (AI, privacy, content formats, platform features)  |
| `algorithm_updates`   | 15   | Platform algorithm changes with impact scoring                    |
| `pipeline_error_log`  | —    | Procedure error log (populated at runtime)                        |
| `campaign_audit_log`  | —    | Campaign lifecycle audit trail (populated by triggers)            |

---

## SQL Skills Demonstrated

### Advanced Query Techniques

- **Window Functions** — `RANK()`, `DENSE_RANK()`, `ROW_NUMBER()`, `NTILE()`, `PERCENT_RANK()`, `LAG()`, `LEAD()`, `FIRST_VALUE()`, running totals, moving averages, cumulative distributions
- **CTEs** — Multi-step CTE chains, recursive-style union CTEs, CTE-to-window-function pipelines
- **Subqueries** — Correlated subqueries, scalar subqueries, `EXISTS` / `NOT EXISTS`, subqueries in `SELECT`, `WHERE`, and `FROM` clauses

### Object Design

- **Views** — 10 reusable reporting views with business logic encapsulated
- **Stored Procedures** — `IN`/`OUT` parameters, `DECLARE`, `IF/ELSEIF/ELSE`, `CURSOR` + `LOOP`, `EXIT HANDLER FOR SQLEXCEPTION`, `GET DIAGNOSTICS`, `ROLLBACK`, `SIGNAL SQLSTATE`, transaction management
- **Functions** — 10 deterministic scalar UDFs used across queries and views
- **Triggers** — `BEFORE INSERT`, `BEFORE UPDATE`, `AFTER UPDATE`, `BEFORE DELETE`; business rule enforcement and audit logging

### Performance Engineering

- **Index Strategy** — Single-column, composite, covering, and prefix indexes across all 25 tables
- **Query Optimization** — `EXPLAIN` examples showing index usage vs full table scan
- **Anti-patterns avoided** — Functions on indexed columns in `WHERE`, leading wildcards, non-sargable predicates

---

## Digital Marketing Topics Covered

| #   | Topic                   | Tables Used                                       | Key Queries                                                                           |
| --- | ----------------------- | ------------------------------------------------- | ------------------------------------------------------------------------------------- |
| 1   | SEO Fundamentals        | `seo_keywords`, `seo_rankings`, `organic_traffic` | Rank movement (LAG), topic cluster authority (CTE chain), opportunity scoring (NTILE) |
| 2   | PPC Advertising         | `ad_groups`, `ads`, `ad_performance`              | Running ROAS, ad rank within campaign, CPL vs channel average                         |
| 3   | Email Marketing         | `email_campaigns`, `email_events`                 | Full funnel rates (open→click→convert), segment engagement, 3-send moving average     |
| 4   | Google Tag Manager      | `gtm_tags`, `web_events`                          | Tag coverage audit, conversion tracking gaps (NOT EXISTS), CTA click rates            |
| 5   | Content Marketing       | `content_pieces`, `content_performance`           | Cluster content audit, quality scoring (UDF), above-average converter identification  |
| 6   | Audience Targeting      | `audiences`, `audience_members`                   | Multi-channel customer overlap, CLV by segment, revenue percentile (PERCENT_RANK)     |
| 7   | Marketing Analytics     | All core + channel tables                         | YoY KPI dashboard, first-touch attribution model, executive reporting                 |
| 8   | Trends & Best Practices | `industry_trends`, `algorithm_updates`            | Impact score running averages, campaigns running during updates                       |
| 9   | Campaign Optimization   | `ab_tests`, `ab_variants`                         | Statistical lift calculation, cumulative test revenue impact, bid strategy comparison |
| 10  | Website Development     | `web_pages`, `web_sessions`, `web_vitals`         | Conversion funnel drop-off, Core Web Vitals grading (UDF), CRO priority flags         |

---

## Key Business Questions Answered

- Which channels deliver the best ROAS year over year?
- Which keywords are gaining ranking positions and driving qualified clicks?
- Which email segments have above-average conversion rates?
- Which A/B tests delivered the highest revenue lift?
- Which website pages have tracking gaps or poor Core Web Vitals?
- Which customers appear in multiple audiences and generate the most revenue?
- How did algorithm updates affect campaign performance?
- What is the first-touch attribution breakdown by channel?

---

## Technical Environment

- **Database:** MySQL 8.0+
- **IDE:** MySQL Workbench 8.0
- **Compatibility note:** Window functions (`ROW_NUMBER`, `LAG`, etc.) require MySQL 8.0. The `QUALIFY` clause is not available in MySQL — equivalent logic is implemented with subqueries or CTEs.

### Transferable to:

- **Databricks / Spark SQL** — CTEs, window functions, and most DML translate directly
- **Snowflake** — All syntax transfers with minor dialect adjustments (`QUALIFY` can be used natively)
- **dbt** — Views and CTEs map directly to dbt models; UDFs can be wrapped in macros

---

## Author

**Steve Lopez**  
Data Analyst → Analytics Engineer  
Digital marketing analytics | Azure / Databricks | dbt | SQL

---

## License

MIT — free to use, adapt, and build on.
