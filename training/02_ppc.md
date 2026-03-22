# Module 02 — PPC Advertising

**Estimated time:** 60 minutes
**SQL skills:** Running totals, `RANK()`, `ROW_NUMBER()`, composite indexes, `EXPLAIN`, correlated subqueries
**Tables:** `campaigns`, `ad_groups`, `ads`, `ad_performance`

[← Module 01: SEO](01_seo.md) | [Back to Index](README.md) | [Next: Module 03 — Email →](03_email.md)

---

## What You Will Learn

- How PPC campaigns are structured and how that structure maps to your schema
- How to calculate the core PPC metrics: CTR, CPC, CPA, ROAS
- How to identify your best-performing ads using window functions
- How to compare bid strategies using A/B test analysis
- How to use `EXPLAIN` to ensure your PPC reporting queries are fast

---

## Engineering Lens — Before You Build Anything in This Module

> 💡 **Engineering Lens** — Profile `ad_performance` before writing any PPC queries. Check how many rows exist per ad and what date range they cover. Run `EXPLAIN` on the core metrics query — before indexes you will see `type: ALL` on `ad_performance`, meaning every row is scanned to compute campaign-level totals. The composite index `idx_adperf_ad_date (ad_id, perf_date)` was created because `ad_id` and `perf_date` appear in every PPC query's JOIN and WHERE clause. Notice also that `vw_ppc_performance` became a view (not a stored procedure) because PPC reporting queries have no parameters — the same query shape runs every time. The channel filter belongs at the consumer level, not baked into the object.

---

## 2.1 How PPC Is Structured

PPC (Pay-Per-Click) has a strict hierarchy that mirrors the schema exactly:

```
Campaign
  └── Ad Group          (a thematic grouping of ads and keywords)
        └── Ad          (the actual creative shown to the user)
              └── Ad Performance   (daily metrics: impressions, clicks, spend)
```

This hierarchy is intentional. Different bid strategies (`target_cpa`, `manual_cpc`, `maximize_conversions`) are set at the ad group level. Different creative messaging is set at the ad level. Performance is measured at all levels.

```sql
-- See the full hierarchy
SELECT
    c.campaign_name,
    c.channel,
    ag.ad_group_name,
    ag.bid_strategy,
    ag.max_cpc,
    ag.target_cpa,
    a.headline_1,
    a.ad_type,
    a.status
FROM campaigns c
JOIN ad_groups ag ON c.campaign_id = ag.campaign_id
JOIN ads       a  ON ag.ad_group_id = a.ad_group_id
ORDER BY c.campaign_name, ag.ad_group_name;
```

> 📊 **MARKETING NUGGET** — Bid strategy is one of the highest-leverage decisions in PPC management. `manual_cpc` gives you full control but requires constant adjustment. `target_cpa` lets Google's algorithm optimize for a specific cost per conversion — it learns from your conversion data. `maximize_conversions` tells Google to get as many conversions as possible within your budget. The A/B test in Module 09 proves that `target_cpa` outperformed `manual_cpc` in this dataset. Understanding *why* is the difference between a junior analyst and a senior one.

---

## 2.2 Core PPC Metrics

These four metrics define PPC performance. Memorize them.

| Metric | Formula | What it measures |
|--------|---------|-----------------|
| **CTR** | Clicks ÷ Impressions × 100 | Ad relevance — does the ad resonate with searchers? |
| **CPC** | Spend ÷ Clicks | Efficiency of traffic acquisition |
| **CPA** | Spend ÷ Conversions | Cost to acquire one customer action |
| **ROAS** | Revenue ÷ Spend | Return on every dollar spent |

```sql
SELECT
    c.campaign_name,
    c.channel,
    ag.bid_strategy,
    SUM(p.impressions)                              AS impressions,
    SUM(p.clicks)                                   AS clicks,
    SUM(p.spend)                                    AS spend,
    SUM(p.conversions)                              AS conversions,
    SUM(p.conversion_value)                         AS revenue,
    ROUND(SUM(p.clicks)
        / NULLIF(SUM(p.impressions), 0) * 100, 2)  AS ctr_pct,
    ROUND(SUM(p.spend)
        / NULLIF(SUM(p.clicks), 0), 2)             AS avg_cpc,
    ROUND(SUM(p.spend)
        / NULLIF(SUM(p.conversions), 0), 2)        AS cpa,
    ROUND(SUM(p.conversion_value)
        / NULLIF(SUM(p.spend), 0), 2)              AS roas
FROM ad_performance p
JOIN ads       a  ON p.ad_id        = a.ad_id
JOIN ad_groups ag ON a.ad_group_id  = ag.ad_group_id
JOIN campaigns c  ON ag.campaign_id = c.campaign_id
GROUP BY c.campaign_name, c.channel, ag.bid_strategy
ORDER BY roas DESC;
```

> 🎯 **CMO QUESTION** — *"Are we getting a good return on our paid media spend?"* ROAS of 2.0 means every dollar spent returned two dollars in pipeline. ROAS of 4.0 means four dollars back. Most B2B marketing leaders target ROAS of 3–5x depending on margins. Below 1.5x is a warning sign — you are spending more than you are getting back.

---

## 2.3 Running Totals — Cumulative Spend and Revenue

The CFO wants to know: *"How is our cumulative PPC spend tracking against cumulative revenue this year?"* This requires a running total.

```sql
SELECT
    a.headline_1                            AS ad_name,
    p.perf_date,
    p.spend,
    p.conversion_value,
    SUM(p.spend) OVER (
        PARTITION BY p.ad_id
        ORDER BY     p.perf_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    )                                       AS cumulative_spend,
    SUM(p.conversion_value) OVER (
        PARTITION BY p.ad_id
        ORDER BY     p.perf_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    )                                       AS cumulative_revenue,
    ROUND(
        SUM(p.conversion_value) OVER (
            PARTITION BY p.ad_id
            ORDER BY     p.perf_date
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) / NULLIF(
            SUM(p.spend) OVER (
                PARTITION BY p.ad_id
                ORDER BY     p.perf_date
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            ), 0)
    , 2)                                    AS running_roas
FROM ad_performance p
JOIN ads a ON p.ad_id = a.ad_id
ORDER BY p.ad_id, p.perf_date;
```

> 💡 **TIP & TRICK** — Notice that `running_roas` is computed by dividing two window functions. You can nest window functions in arithmetic expressions — you cannot nest them inside each other. If a query requires the output of one window function as input to another window function, wrap the first in a CTE and then apply the second in the outer query.

---

## 2.4 Ad Ranking Within a Campaign — RANK() vs ROW_NUMBER()

These two functions look similar but behave differently when values are tied.

```sql
SELECT
    c.campaign_name,
    a.headline_1,
    SUM(p.conversion_value)                 AS total_revenue,
    ROUND(SUM(p.conversion_value)
        / NULLIF(SUM(p.spend), 0), 2)       AS roas,
    -- RANK() leaves gaps after ties: 1, 1, 3
    RANK() OVER (
        PARTITION BY c.campaign_id
        ORDER BY SUM(p.conversion_value) / NULLIF(SUM(p.spend), 0) DESC
    )                                       AS roas_rank,
    -- DENSE_RANK() has no gaps after ties: 1, 1, 2
    DENSE_RANK() OVER (
        PARTITION BY c.campaign_id
        ORDER BY SUM(p.conversion_value) / NULLIF(SUM(p.spend), 0) DESC
    )                                       AS roas_dense_rank,
    -- ROW_NUMBER() always unique: 1, 2, 3
    ROW_NUMBER() OVER (
        PARTITION BY c.campaign_id
        ORDER BY SUM(p.conversion_value) / NULLIF(SUM(p.spend), 0) DESC
    )                                       AS roas_row_num
FROM ad_performance p
JOIN ads       a  ON p.ad_id        = a.ad_id
JOIN ad_groups ag ON a.ad_group_id  = ag.ad_group_id
JOIN campaigns c  ON ag.campaign_id = c.campaign_id
GROUP BY c.campaign_id, c.campaign_name, a.ad_id, a.headline_1
ORDER BY c.campaign_name, roas_rank;
```

| Function | Tie behavior | Use when |
|---|---|---|
| `RANK()` | 1, 1, 3 (skips 2) | You want to show that two ads are genuinely tied |
| `DENSE_RANK()` | 1, 1, 2 (no skip) | You want contiguous ranks |
| `ROW_NUMBER()` | 1, 2, 3 (always unique) | You want exactly one row per rank, even on ties |

> 📊 **MARKETING NUGGET** — Ranking ads within a campaign is how paid search managers identify their "hero" ads — the ones driving 80% of conversions. Once identified, hero ads get protected status: never pause them, never change the headline without an A/B test running. The supporting ads are tested and iterated. This is the 80/20 principle applied to creative strategy.

---

## 2.5 Bid Strategy Performance — Correlated Subquery

This query compares each ad's CPA against the average CPA for its channel — without joining to a separate aggregation.

```sql
SELECT
    c.channel,
    a.headline_1,
    ag.bid_strategy,
    ROUND(SUM(p.spend) / NULLIF(SUM(p.conversions), 0), 2) AS this_ad_cpa,
    (
        SELECT ROUND(SUM(p2.spend) / NULLIF(SUM(p2.conversions), 0), 2)
        FROM   ad_performance p2
        JOIN   ads       a2  ON p2.ad_id        = a2.ad_id
        JOIN   ad_groups ag2 ON a2.ad_group_id  = ag2.ad_group_id
        JOIN   campaigns c2  ON ag2.campaign_id = c2.campaign_id
        WHERE  c2.channel = c.channel
    )                                           AS channel_avg_cpa,
    CASE
        WHEN SUM(p.spend) / NULLIF(SUM(p.conversions), 0) <
             (SELECT SUM(p2.spend) / NULLIF(SUM(p2.conversions), 0)
              FROM ad_performance p2
              JOIN ads a2 ON p2.ad_id = a2.ad_id
              JOIN ad_groups ag2 ON a2.ad_group_id = ag2.ad_group_id
              JOIN campaigns c2 ON ag2.campaign_id = c2.campaign_id
              WHERE c2.channel = c.channel)
        THEN 'Below Average (Efficient)'
        ELSE 'Above Average'
    END                                         AS efficiency_vs_channel
FROM ad_performance p
JOIN ads       a  ON p.ad_id        = a.ad_id
JOIN ad_groups ag ON a.ad_group_id  = ag.ad_group_id
JOIN campaigns c  ON ag.campaign_id = c.campaign_id
GROUP BY c.channel, a.ad_id, a.headline_1, ag.bid_strategy
ORDER BY this_ad_cpa;
```

> 💡 **TIP & TRICK** — Correlated subqueries execute once per row of the outer query. On large tables they can be slow. If you notice this query taking a long time, rewrite it as a CTE: compute the channel averages once, then JOIN to them. The CTE version runs the subquery once per channel, not once per ad — far more efficient at scale.

---

## 2.6 Using EXPLAIN to Optimize PPC Queries

PPC reporting is often run daily — sometimes on tables with millions of rows in production. Index awareness matters.

```sql
-- Run this BEFORE the indexes in 10_indexes.sql
EXPLAIN
SELECT c.channel, SUM(p.spend), SUM(p.conversions)
FROM ad_performance p
JOIN ads       a  ON p.ad_id        = a.ad_id
JOIN ad_groups ag ON a.ad_group_id  = ag.ad_group_id
JOIN campaigns c  ON ag.campaign_id = c.campaign_id
WHERE c.channel = 'Paid'
  AND p.perf_date BETWEEN '2024-01-01' AND '2024-12-31'
GROUP BY c.channel;
```

**Before indexes:** You will see `type: ALL` on `ad_performance` — a full table scan. Every row in the table is read even though we only want 2024 data.

**After indexes (from `10_indexes.sql`):** You will see `type: range` and `key: idx_adperf_ad_date` — MySQL uses the composite index to scan only the 2024 rows. On a million-row table, this is the difference between a 3-second query and a 50ms query.

> 📊 **MARKETING NUGGET** — In real marketing data warehouses, `ad_performance` tables can have tens of millions of rows — Google Ads alone can generate thousands of daily performance rows across a large account. Unindexed queries on these tables don't just run slowly; they consume database resources that affect every other analyst running queries at the same time. Index design is a shared responsibility, not just a DBA concern.

---

## Test Yourself — Module 02

**Question 1:** Which single ad has the highest ROAS across the entire dataset? What is the bid strategy for that ad's ad group?

**Question 2:** Calculate the month-over-month change in total spend for Paid channel campaigns. Which month had the biggest spend increase?

**Question 3:** Write a query that returns only ads where the CPA is below $70. How many qualify?

**Question 4:** What is the average quality score for ads using `target_cpa` bidding vs `manual_cpc`? What does this suggest?

**Question 5 (Challenge):** Using a CTE, identify the top-performing ad in each campaign (by ROAS). Return one row per campaign showing campaign name, top ad headline, and its ROAS.

---

### Answers

**Answer 1:**
```sql
SELECT
    a.headline_1,
    ag.bid_strategy,
    ROUND(SUM(p.conversion_value) / NULLIF(SUM(p.spend), 0), 2) AS roas
FROM ad_performance p
JOIN ads       a  ON p.ad_id       = a.ad_id
JOIN ad_groups ag ON a.ad_group_id = ag.ad_group_id
GROUP BY a.ad_id, a.headline_1, ag.bid_strategy
ORDER BY roas DESC
LIMIT 1;
```

**Answer 2:**
```sql
SELECT
    DATE_FORMAT(perf_date, '%Y-%m') AS month,
    SUM(spend)                      AS monthly_spend,
    LAG(SUM(spend)) OVER (ORDER BY DATE_FORMAT(perf_date, '%Y-%m')) AS prev_month_spend,
    SUM(spend) - LAG(SUM(spend)) OVER (ORDER BY DATE_FORMAT(perf_date, '%Y-%m')) AS mom_change
FROM ad_performance
GROUP BY DATE_FORMAT(perf_date, '%Y-%m')
ORDER BY month;
```

**Answer 3:**
```sql
SELECT
    a.headline_1,
    ag.bid_strategy,
    ROUND(SUM(p.spend) / NULLIF(SUM(p.conversions), 0), 2) AS cpa
FROM ad_performance p
JOIN ads       a  ON p.ad_id       = a.ad_id
JOIN ad_groups ag ON a.ad_group_id = ag.ad_group_id
GROUP BY a.ad_id, a.headline_1, ag.bid_strategy
HAVING cpa < 70
ORDER BY cpa;
```

**Answer 4:**
```sql
SELECT
    ag.bid_strategy,
    ROUND(AVG(p.quality_score), 2) AS avg_quality_score,
    COUNT(DISTINCT a.ad_id)        AS ad_count
FROM ad_performance p
JOIN ads       a  ON p.ad_id       = a.ad_id
JOIN ad_groups ag ON a.ad_group_id = ag.ad_group_id
WHERE p.quality_score IS NOT NULL
GROUP BY ag.bid_strategy
ORDER BY avg_quality_score DESC;
```
Higher quality score on `target_cpa` ads suggests Google rewards ads that have conversion data to optimize against — the algorithm learns which users convert and shows the ad more selectively, improving relevance scores.

**Answer 5 (Challenge):**
```sql
WITH ad_roas AS (
    SELECT
        c.campaign_id,
        c.campaign_name,
        a.ad_id,
        a.headline_1,
        ROUND(SUM(p.conversion_value) / NULLIF(SUM(p.spend), 0), 2) AS roas
    FROM ad_performance p
    JOIN ads       a  ON p.ad_id        = a.ad_id
    JOIN ad_groups ag ON a.ad_group_id  = ag.ad_group_id
    JOIN campaigns c  ON ag.campaign_id = c.campaign_id
    GROUP BY c.campaign_id, c.campaign_name, a.ad_id, a.headline_1
),
ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY campaign_id ORDER BY roas DESC) AS rn
    FROM ad_roas
)
SELECT campaign_name, headline_1 AS top_ad, roas AS top_ad_roas
FROM ranked
WHERE rn = 1
ORDER BY roas DESC;
```

---

[← Module 01: SEO](01_seo.md) | [Back to Index](README.md) | [Next: Module 03 — Email →](03_email.md)
