# Module 01 — SEO Fundamentals

**Estimated time:** 60 minutes
**SQL skills:** `LAG()`, `LEAD()`, `RANK()`, `NTILE()`, CTEs, correlated subqueries, `PERCENT_RANK()`
**Tables:** `seo_keywords`, `seo_rankings`, `organic_traffic`

[← Module 00B: Engineering Workflow](00b_engineering_workflow.md) | [Back to Index](README.md) | [Next: Module 02 — PPC →](02_ppc.md)

---

## What You Will Learn

- What SEO metrics actually measure and why they matter to a business
- How to track keyword ranking movement over time using `LAG()` and `LEAD()`
- How to identify the best keyword opportunities using scoring and `NTILE()`
- How to build a topic cluster authority report using a multi-step CTE chain
- How to connect organic traffic to revenue-generating pages

---

## Engineering Lens — Before You Build Anything in This Module

> 💡 **Engineering Lens** — Before writing a single SEO query, apply the Module 00B workflow to the SEO tables. Run the profiling queries first. Check NULL rates on `seo_rankings.position` and `seo_rankings.clicks`. Check the date range — do you have continuous monthly snapshots or gaps? Run `EXPLAIN` on the ranking trend query before adding `idx_seo_rankings_keyword_date`. The index exists in the project files because profiling revealed that keyword + date is the dominant filter pattern across every SEO query. If you had built the index before writing the queries, you would have been guessing. Building it after EXPLAIN is evidence-based engineering.

---

## 1.1 The SEO Tables

### seo_keywords

The foundation of all SEO analysis. Each row is a keyword the company is actively targeting.

```sql
DESCRIBE seo_keywords;

SELECT * FROM seo_keywords LIMIT 10;
```

**Key columns:**

| Column | What it means |
|--------|--------------|
| `search_volume` | How many times per month this keyword is searched nationally |
| `keyword_difficulty` | 0–100 score — how hard it is to rank on page 1. Higher = harder |
| `intent_type` | What the searcher wants: `informational`, `commercial`, `transactional`, `navigational` |
| `topic_cluster` | The content theme this keyword belongs to |
| `is_branded` | 1 if the keyword includes your company name — these behave differently |

### seo_rankings

Tracks where each keyword ranks in Google search results over time. Think of it as a monthly snapshot.

```sql
SELECT
    keyword_id,
    ranking_date,
    position,
    impressions,
    clicks,
    ctr_pct
FROM seo_rankings
ORDER BY keyword_id, ranking_date
LIMIT 20;
```

> 📊 **MARKETING NUGGET** — Position 1 in Google gets roughly 28–32% of all clicks for a given keyword. Position 2 gets about 15%. By position 10 (bottom of page 1), you're getting around 2.5%. The difference between rank 8 and rank 3 for a 10,000 search/month keyword can be hundreds of additional visitors per month — without spending a dollar more on ads. This is why SEOs obsess over moving from position 8 to position 3.

### organic_traffic

Monthly sessions and goal completions per page, sourced from Google Analytics.

```sql
SELECT * FROM organic_traffic LIMIT 10;
```

---

## 1.2 Keyword Rank Movement with LAG()

The most common SEO question is: *"Is our keyword ranking getting better or worse?"* `LAG()` answers it by giving you access to the previous row's value within a partition.

```sql
SELECT
    k.keyword,
    k.search_volume,
    r.ranking_date,
    r.position                              AS current_position,
    LAG(r.position) OVER (
        PARTITION BY r.keyword_id
        ORDER BY     r.ranking_date
    )                                       AS previous_position,
    r.position - LAG(r.position) OVER (
        PARTITION BY r.keyword_id
        ORDER BY     r.ranking_date
    )                                       AS position_change
FROM seo_rankings r
JOIN seo_keywords k ON r.keyword_id = k.keyword_id
ORDER BY k.search_volume DESC, r.ranking_date;
```

**Reading the output:**
- `position_change` of **-5** means you moved UP 5 spots (lower number = better rank)
- `position_change` of **+3** means you dropped DOWN 3 spots
- NULL in the first row is expected — there is no previous period to compare against

> 💡 **TIP & TRICK** — `PARTITION BY keyword_id` tells the window function to reset for each keyword. Without it, the LAG would compare position 8 of keyword A against position 6 of keyword B — a meaningless comparison. Always ask: *"What am I computing this window function within?"* That is your partition.

> 🎯 **CMO QUESTION** — *"Which keywords improved the most last quarter?"* Filter `position_change < 0` and order by the magnitude of improvement. Negative numbers mean rank improvement — the keywords that moved up the most are the ones your SEO investment is paying off on.

---

## 1.3 LEAD() — Looking Ahead

`LEAD()` is `LAG()` in reverse — it shows you the *next* period's value. This is useful for identifying keywords that are about to drop (early warning) or are trending upward.

```sql
SELECT
    k.keyword,
    r.ranking_date,
    r.position                              AS this_period,
    LEAD(r.position) OVER (
        PARTITION BY r.keyword_id
        ORDER BY     r.ranking_date
    )                                       AS next_period,
    CASE
        WHEN LEAD(r.position) OVER (
            PARTITION BY r.keyword_id
            ORDER BY     r.ranking_date
        ) < r.position THEN 'Trending Up'
        WHEN LEAD(r.position) OVER (
            PARTITION BY r.keyword_id
            ORDER BY     r.ranking_date
        ) > r.position THEN 'Trending Down'
        ELSE 'Stable'
    END                                     AS trajectory
FROM seo_rankings r
JOIN seo_keywords k ON r.keyword_id = k.keyword_id
ORDER BY k.search_volume DESC, r.ranking_date;
```

> ⚠️ **WATCH OUT** — The last row in each partition will have NULL for `LEAD()` because there is no next period. This is not an error. Filter `WHERE LEAD(...) IS NOT NULL` if you only want rows with a valid comparison.

---

## 1.4 Rolling Average Position with Window Frames

A single month's ranking can be noisy — one Google algorithm tweak can spike a position up or down temporarily. A rolling average smooths this out and reveals the true trend.

```sql
SELECT
    k.keyword,
    r.ranking_date,
    r.position,
    ROUND(AVG(r.position) OVER (
        PARTITION BY r.keyword_id
        ORDER BY     r.ranking_date
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 1)                                   AS rolling_3period_avg
FROM seo_rankings r
JOIN seo_keywords k ON r.keyword_id = k.keyword_id
ORDER BY k.search_volume DESC, r.ranking_date;
```

**The window frame explained:**

```
ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
```

This means: *"For each row, look at the 2 rows before it and the current row — average those three values."* This is a 3-period moving average.

| Frame clause | What it includes |
|---|---|
| `ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW` | All rows from the start through now (running total / running average) |
| `ROWS BETWEEN 2 PRECEDING AND CURRENT ROW` | Previous 2 rows + current row (rolling 3-period) |
| `ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING` | Previous row, current row, next row (centered moving average) |

> 💡 **TIP & TRICK** — When you leave out the frame clause entirely, MySQL uses `RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW` as the default for aggregating window functions. This means `SUM()` over a window without a frame gives you a running total automatically. Add the frame clause explicitly whenever precision matters.

---

## 1.5 RANK() and NTILE() — Prioritizing Keywords

Not all keywords deserve equal attention. `RANK()` and `NTILE()` help you prioritize where to focus SEO effort.

### RANK() within intent type

```sql
SELECT
    keyword,
    search_volume,
    keyword_difficulty,
    intent_type,
    RANK() OVER (
        PARTITION BY intent_type
        ORDER BY     search_volume DESC
    )                                       AS volume_rank_within_intent
FROM seo_keywords
ORDER BY intent_type, volume_rank_within_intent;
```

### NTILE() for opportunity scoring

```sql
SELECT
    keyword,
    search_volume,
    keyword_difficulty,
    ROUND(search_volume / NULLIF(keyword_difficulty, 1), 1) AS opportunity_score,
    NTILE(4) OVER (
        ORDER BY search_volume / NULLIF(keyword_difficulty, 1) DESC
    )                                       AS opportunity_quartile
FROM seo_keywords
ORDER BY opportunity_score DESC;
```

**Reading NTILE(4):** The keyword lands in quartile 1 (top 25% of opportunity), 2, 3, or 4 (bottom 25%). Quartile 1 = highest search volume relative to difficulty — the sweet spot for SEO investment.

> 📊 **MARKETING NUGGET** — Opportunity score = search volume ÷ keyword difficulty. A keyword with 5,000 searches/month and a difficulty of 30 (score: 167) is a better investment than a keyword with 8,000 searches/month and a difficulty of 80 (score: 100). The first one is 67% more attainable for the same content effort. This is how SEO teams prioritize their editorial calendar.

> 🎯 **CMO QUESTION** — *"Where should we focus our content team's time to get the most organic traffic growth?"* Quartile 1 keywords — high volume, lower difficulty. Your answer is a filtered list of those keywords with their current positions, showing the gap between where you rank now and where you could rank with targeted content.

---

## 1.6 Multi-Step CTE: Topic Cluster Authority Report

This is the most powerful SEO query in the project. It builds in four steps.

```sql
WITH keyword_latest_rank AS (
    -- Step 1: Most recent position for each keyword
    SELECT
        r.keyword_id,
        r.position,
        r.impressions,
        r.clicks
    FROM seo_rankings r
    WHERE r.ranking_date = (
        SELECT MAX(r2.ranking_date)
        FROM   seo_rankings r2
        WHERE  r2.keyword_id = r.keyword_id    -- correlated subquery
    )
),
cluster_metrics AS (
    -- Step 2: Aggregate to topic cluster level
    SELECT
        k.topic_cluster,
        COUNT(k.keyword_id)                                 AS keyword_count,
        AVG(k.search_volume)                                AS avg_search_volume,
        AVG(lr.position)                                    AS avg_position,
        SUM(lr.clicks)                                      AS total_monthly_clicks,
        COUNT(CASE WHEN lr.position <= 10 THEN 1 END)       AS keywords_on_page_1
    FROM seo_keywords k
    JOIN keyword_latest_rank lr ON k.keyword_id = lr.keyword_id
    GROUP BY k.topic_cluster
),
cluster_scored AS (
    -- Step 3: Calculate authority score
    SELECT
        topic_cluster,
        keyword_count,
        avg_search_volume,
        ROUND(avg_position, 1)                              AS avg_position,
        total_monthly_clicks,
        keywords_on_page_1,
        ROUND(
            (keywords_on_page_1 / NULLIF(keyword_count, 0)) * 40
            + LEAST(total_monthly_clicks / 100, 40)
            + GREATEST(30 - avg_position, 0)
        , 1)                                                AS authority_score
    FROM cluster_metrics
)
-- Step 4: Final ranking
SELECT
    topic_cluster,
    keyword_count,
    ROUND(avg_search_volume, 0)                             AS avg_monthly_searches,
    avg_position,
    total_monthly_clicks,
    keywords_on_page_1,
    authority_score,
    RANK() OVER (ORDER BY authority_score DESC)             AS cluster_rank
FROM cluster_scored
ORDER BY authority_score DESC;
```

> 💡 **TIP & TRICK** — CTEs are not just a style preference. They make complex queries **debuggable**. When this query returns a surprising result, you can run each CTE individually by adding `SELECT * FROM keyword_latest_rank` to troubleshoot step by step. With a monolithic nested subquery, you cannot do this. CTEs are the SQL equivalent of breaking a function into testable components.

> 📊 **MARKETING NUGGET** — Topic cluster authority is the concept behind modern SEO strategy. Google rewards sites that demonstrate deep expertise on a topic — not just one strong article, but a constellation of related content all linking to a central "pillar page." A cluster with 8 keywords on page 1 and 2,000+ monthly clicks is a content moat that takes competitors months to replicate. This query tells you where yours are.

---

## 1.7 Connecting SEO to Revenue

Traffic is vanity. Revenue is sanity. This query connects organic sessions to goal completions on the most valuable pages.

```sql
SELECT
    t.page_url,
    t.traffic_date,
    t.sessions,
    t.new_users,
    t.bounce_rate_pct,
    t.avg_session_sec,
    t.goal_completions,
    ROUND(t.goal_completions / NULLIF(t.sessions, 0) * 100, 2) AS organic_conv_rate_pct,
    SUM(t.sessions) OVER (
        PARTITION BY t.page_url
        ORDER BY     t.traffic_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    )                                       AS cumulative_sessions
FROM organic_traffic t
ORDER BY t.page_url, t.traffic_date;
```

> 🎯 **CMO QUESTION** — *"Is our SEO investment actually generating revenue, or just traffic?"* `goal_completions` represents conversions on organic pages — demo requests, downloads, or purchases driven purely by unpaid search. Dividing by sessions gives you the organic conversion rate. Compare this to your paid conversion rate from Module 02. If organic converts at 3% and paid converts at 2.5%, organic has a higher quality score — and you should be investing more in content.

---

## Test Yourself — Module 01

**Question 1:** Which keyword improved its ranking position the most between its earliest and latest recorded date? Show the keyword, the start position, the end position, and the total improvement.

**Question 2:** Write a query that returns only keywords currently ranked on page 1 (position 1–10) with a search volume above 3,000. How many are there?

**Question 3:** What is the total monthly click volume across all keywords in the `Marketing Automation` topic cluster as of the most recent ranking date?

**Question 4:** Which page in the `organic_traffic` table has the highest goal completion rate (goal completions / sessions)? What does this tell you about that page?

**Question 5 (Challenge):** Write a query that flags keywords where the current position is worse (higher number) than the 3-period rolling average — indicating the keyword is declining. What would you do with this list?

---

### Answers

**Answer 1:**
```sql
WITH first_last AS (
    SELECT
        keyword_id,
        MIN(ranking_date)   AS first_date,
        MAX(ranking_date)   AS last_date
    FROM seo_rankings
    GROUP BY keyword_id
),
positions AS (
    SELECT
        fl.keyword_id,
        r1.position                             AS start_position,
        r2.position                             AS end_position,
        r1.position - r2.position               AS improvement   -- positive = got better
    FROM first_last fl
    JOIN seo_rankings r1
        ON  r1.keyword_id   = fl.keyword_id
        AND r1.ranking_date = fl.first_date
    JOIN seo_rankings r2
        ON  r2.keyword_id   = fl.keyword_id
        AND r2.ranking_date = fl.last_date
)
SELECT
    k.keyword,
    p.start_position,
    p.end_position,
    p.improvement
FROM positions p
JOIN seo_keywords k ON p.keyword_id = k.keyword_id
ORDER BY p.improvement DESC
LIMIT 5;
```

**Answer 2:**
```sql
SELECT
    k.keyword,
    k.search_volume,
    r.position,
    r.ranking_date
FROM seo_rankings r
JOIN seo_keywords k ON r.keyword_id = k.keyword_id
WHERE r.ranking_date = (
    SELECT MAX(r2.ranking_date)
    FROM seo_rankings r2
    WHERE r2.keyword_id = r.keyword_id
)
  AND r.position  BETWEEN 1 AND 10
  AND k.search_volume > 3000
ORDER BY k.search_volume DESC;
```

**Answer 3:**
```sql
SELECT SUM(r.clicks) AS total_monthly_clicks
FROM seo_rankings r
JOIN seo_keywords k ON r.keyword_id = k.keyword_id
WHERE k.topic_cluster = 'Marketing Automation'
  AND r.ranking_date  = (
      SELECT MAX(r2.ranking_date)
      FROM seo_rankings r2
      WHERE r2.keyword_id = r.keyword_id
  );
```

**Answer 4:**
```sql
SELECT
    page_url,
    SUM(sessions)                                           AS total_sessions,
    SUM(goal_completions)                                   AS total_goals,
    ROUND(SUM(goal_completions)/NULLIF(SUM(sessions),0)*100,2) AS goal_rate_pct
FROM organic_traffic
GROUP BY page_url
ORDER BY goal_rate_pct DESC
LIMIT 5;
```
The `/pricing` page will likely rank highest — users who land on a pricing page via organic search are self-qualified buyers. High goal rate on a pricing page means your SEO is attracting purchase-intent traffic, not just informational browsers.

**Answer 5 (Challenge):**
```sql
WITH rolling AS (
    SELECT
        keyword_id,
        ranking_date,
        position,
        ROUND(AVG(position) OVER (
            PARTITION BY keyword_id
            ORDER BY     ranking_date
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ), 1) AS rolling_avg
    FROM seo_rankings
)
SELECT
    k.keyword,
    r.ranking_date,
    r.position              AS current_position,
    r.rolling_avg           AS rolling_3period_avg,
    ROUND(r.position - r.rolling_avg, 1) AS deviation
FROM rolling r
JOIN seo_keywords k ON r.keyword_id = k.keyword_id
WHERE r.position > r.rolling_avg     -- current position is worse than trend
  AND r.ranking_date = (
      SELECT MAX(r2.ranking_date)
      FROM seo_rankings r2
      WHERE r2.keyword_id = r.keyword_id
  )
ORDER BY deviation DESC;
```
These keywords need attention — their rankings are deteriorating. Actions include refreshing the content, improving page speed, or building internal links to the page.

---

[← Module 00B: Engineering Workflow](00b_engineering_workflow.md) | [Back to Index](README.md) | [Next: Module 02 — PPC →](02_ppc.md)
