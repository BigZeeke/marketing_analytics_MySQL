# Marketing Analytics SQL — Training Curriculum & Production Database

A self-paced SQL training course for marketing analysts — built from scratch on a production-grade 25-table database. 12 modules · 11 hours of structured learning · every query tied to a real CMO business question.

> Built by someone who understands both sides: the SQL that powers the analysis, and the business meeting where the results get presented.

---

## What This Is

Most SQL portfolios show that someone can write queries. This one goes further.

This is a **complete training curriculum** built on top of a production-grade marketing analytics database. Each module covers one digital marketing discipline, teaches the SQL techniques required to analyze it, and connects every query to the kind of question a CMO or senior marketing leader asks in a real meeting.

Every module includes:
- **Engineering Lens** — data profiling and EXPLAIN-driven thinking before writing a single query
- **Marketing Nuggets** — business context explaining *why* this metric matters
- **CMO Questions** — the actual executive question your query answers
- **Tips & Tricks** — SQL patterns, shortcuts, and gotchas
- **Test Yourself** — graded exercises with full worked answers

**By the end, you can build, maintain, and explain a production-grade marketing analytics system — in SQL, in a business meeting, and on a resume.**

---

## Curriculum

| Module | Topic | SQL Skills Covered | Time |
|---|---|---|---|
| 00 | Database Foundations | USE, DESCRIBE, SELECT, WHERE, JOIN | 45 min |
| 00B | Engineering Workflow ⚠️ *Do this first* | EXPLAIN, data profiling, index strategy, build order | 60 min |
| 01 | SEO Analytics | LAG(), LEAD(), RANK(), NTILE(), CTEs, correlated subqueries | 60 min |
| 02 | PPC & Paid Ads | Running totals, NTILE(), composite indexes, EXPLAIN | 60 min |
| 03 | Email Marketing | Views, conditional aggregation, moving averages | 60 min |
| 04 | GTM & Tag Management | EXISTS / NOT EXISTS, triggers, GROUP BY auditing | 45 min |
| 05 | Content Marketing | UDFs, DENSE_RANK(), above-average filtering | 60 min |
| 06 | Audience Targeting | PERCENT_RANK(), GROUP_CONCAT(), multi-CTE pipelines | 60 min |
| 07 | Marketing Analytics | Full attribution CTE chain, YoY window functions | 75 min |
| 08 | Trends & Impact | Date range joins, EXISTS, impact score aggregation | 45 min |
| 09 | Campaign Optimization | A/B lift CTEs, stored procedures, cumulative totals | 60 min |
| 10 | Website & CRO | Funnel CTEs, correlated subqueries, optimization flags | 60 min |
| 11 | Glossary | Every marketing and SQL term used in this guide | — |

**Total: ~11 hours of active learning**

---

## Questions This Course Teaches You to Answer

After completing this curriculum, you can walk into a senior marketing meeting and answer:

- *"Which channel is giving us the best return on ad spend?"*
- *"Why did organic traffic drop last quarter?"*
- *"Are our email campaigns getting better or worse over time?"*
- *"Which content pieces are actually driving pipeline, not just traffic?"*
- *"What happened to conversion rates after the Google core update?"*
- *"Which customers are at risk of churning and what did they respond to before?"*

---

## Sample: Module 01 — SEO Analytics

Here's what a module looks like in practice.

### Engineering Lens
> Before writing a single SEO query, apply the Module 00B workflow. Check NULL rates on `seo_rankings.position` and `seo_rankings.clicks`. Check the date range — do you have continuous monthly snapshots or gaps? Run EXPLAIN on the ranking trend query **before** adding the index. The index exists because profiling revealed that `keyword + date` is the dominant filter pattern across every SEO query. Building it after EXPLAIN is evidence-based engineering. Guessing is not.

### Keyword Rank Movement with LAG()
```sql
SELECT
    k.keyword,
    k.search_volume,
    r.ranking_date,
    r.position                                      AS current_position,
    LAG(r.position) OVER (
        PARTITION BY r.keyword_id
        ORDER BY     r.ranking_date
    )                                               AS previous_position,
    r.position - LAG(r.position) OVER (
        PARTITION BY r.keyword_id
        ORDER BY     r.ranking_date
    )                                               AS position_change
FROM seo_rankings r
JOIN seo_keywords k ON r.keyword_id = k.keyword_id
ORDER BY k.search_volume DESC, r.ranking_date;
```

> 💡 **TIP** — `PARTITION BY keyword_id` tells the window function to reset for each keyword. Without it, LAG would compare position 8 of keyword A against position 6 of keyword B — a meaningless comparison. Always ask: *"What am I computing this window function within?"* That is your partition.

> 📊 **MARKETING NUGGET** — Position 1 in Google gets ~28–32% of all clicks. Position 10 gets ~2.5%. The difference between rank 8 and rank 3 for a 10,000 search/month keyword can be hundreds of additional visitors per month — without spending a dollar more on ads.

> 🎯 **CMO QUESTION** — *"Which keywords improved the most last quarter?"* Filter `position_change < 0` and order by magnitude. Negative numbers mean rank improvement — the keywords your SEO investment is paying off on.

### Multi-Step CTE: Topic Cluster Authority Report
```sql
WITH keyword_latest_rank AS (
    SELECT keyword_id, position, impressions, clicks
    FROM seo_rankings r
    WHERE ranking_date = (
        SELECT MAX(r2.ranking_date) FROM seo_rankings r2
        WHERE r2.keyword_id = r.keyword_id
    )
),
cluster_metrics AS (
    SELECT
        k.topic_cluster,
        COUNT(k.keyword_id)                             AS keyword_count,
        AVG(k.search_volume)                            AS avg_search_volume,
        AVG(lr.position)                                AS avg_position,
        SUM(lr.clicks)                                  AS total_monthly_clicks,
        COUNT(CASE WHEN lr.position <= 10 THEN 1 END)   AS keywords_on_page_1
    FROM seo_keywords k
    JOIN keyword_latest_rank lr ON k.keyword_id = lr.keyword_id
    GROUP BY k.topic_cluster
),
cluster_scored AS (
    SELECT *,
        ROUND(
            (keywords_on_page_1 / NULLIF(keyword_count, 0)) * 40
            + LEAST(total_monthly_clicks / 100, 40)
            + GREATEST(30 - avg_position, 0)
        , 1) AS authority_score
    FROM cluster_metrics
)
SELECT *, RANK() OVER (ORDER BY authority_score DESC) AS cluster_rank
FROM cluster_scored
ORDER BY authority_score DESC;
```

> 📊 **MARKETING NUGGET** — Topic cluster authority is the concept behind modern SEO strategy. Google rewards sites that demonstrate deep expertise on a topic — a constellation of related content linking to a central pillar page. A cluster with 8 keywords on page 1 and 2,000+ monthly clicks is a content moat that takes competitors months to replicate.

### Test Yourself — Module 01 (Sample)
> **Question 5 (Challenge):** Write a query that flags keywords where the current position is worse than the 3-period rolling average — indicating the keyword is declining. What would you do with this list?

Full answers with worked SQL included in the training guide.

---

## SQL Engineering Demonstrated

| Skill | Where |
|---|---|
| Schema design & normalization (1NF–3NF/BCNF) | `01_create_schema.sql` |
| FK constraints, ON DELETE/UPDATE cascade rules | `01_create_schema.sql` |
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
│   │   └── 01_create_schema.sql
│   ├── 02_data/
│   │   ├── 02_data_core.sql
│   │   └── 03_data_channels.sql
│   ├── 03_views/
│   │   └── 04_views.sql
│   ├── 04_stored_procedures/
│   │   └── 05_stored_procedures.sql
│   ├── 05_functions/
│   │   └── 06_functions.sql
│   ├── 06_triggers/
│   │   └── 07_triggers.sql
│   ├── 07_window_functions/
│   │   └── 08_window_functions.sql
│   ├── 08_ctes_subqueries/
│   │   └── 09_ctes_subqueries.sql
│   ├── 09_indexes/
│   │   └── 10_indexes.sql
│   └── 10_analysis/
│       └── 11_analysis.sql
├── training/
│   ├── 00_foundations.md
│   ├── 00B_engineering_workflow.md
│   ├── 01_seo.md
│   ├── 02_ppc.md
│   ├── 03_email.md
│   ├── 04_gtm.md
│   ├── 05_content.md
│   ├── 06_audiences.md
│   ├── 07_analytics.md
│   ├── 08_trends.md
│   ├── 09_campaign_optimization.md
│   ├── 10_website_cro.md
│   └── 11_glossary.md
└── README.md
```

---

## Run Order

| Step | File | Description |
|---|---|---|
| 1 | `01_create_schema.sql` | Creates schema and all 25 tables |
| 2 | `02_data_core.sql` | Loads products, customers, campaigns, leads, orders |
| 3 | `03_data_channels.sql` | Loads SEO, PPC, email, GTM, content, audiences, A/B tests |
| 4 | `04_views.sql` | Creates 10 reporting views |
| 5 | `05_stored_procedures.sql` | Creates 8 stored procedures |
| 6 | `06_functions.sql` | Creates 10 scalar UDFs |
| 7 | `07_triggers.sql` | Creates 7 triggers |
| 8 | `08_window_functions.sql` | Window function examples |
| 9 | `09_ctes_subqueries.sql` | CTE and subquery examples |
| 10 | `10_indexes.sql` | Index strategy + EXPLAIN |
| 11 | `11_analysis.sql` | 10 production analytical queries |

**Quick start:** MySQL Workbench → open file → `CMD+A` → `CMD+Enter`

---

## Prerequisites

- MySQL 8.0+ (window functions require 8.0)
- MySQL Workbench or any MySQL client
- ~5 minutes to run all 11 files in order

---

## Related Project

This schema is the foundation for the **[Marketing Analytics Assistant](https://github.com/BigZeeke/marketing_analytics_assistant)** — a live NL-to-SQL chat app that queries a migrated version of this schema on Databricks.

**[→ Try the Live Demo](https://marketing-analytics-assistant.streamlit.app)**

---

## Author

Steve Lopez · [LinkedIn](https://linkedin.com/in/stevelopezenterprise) · [GitHub](https://github.com/BigZeeke)
