# Module 05 — Content Marketing Strategy

**Estimated time:** 60 minutes
**SQL skills:** UDFs, `DENSE_RANK()`, above-average filtering, multi-CTE pipelines
**Tables:** `content_pieces`, `content_performance`

[← Module 04: GTM](04_gtm.md) | [Back to Index](README.md) | [Next: Module 06 — Audiences →](06_audience.md)

---

## What You Will Learn

- How to measure content performance beyond page views
- How to use the `fn_content_quality_score()` UDF to score content holistically
- How to identify over- and under-performing content within each type
- How to build a topic cluster content audit
- How to connect content to pipeline, not just traffic

---

## Engineering Lens — Before You Build Anything in This Module

> 💡 **Engineering Lens** — Profile `content_performance` before building content analytics. The key profiling question is: does every published content piece have performance records? Run a LEFT JOIN from `content_pieces` to `content_performance` and check for NULLs on the right side — any content piece with no performance data will silently disappear from INNER JOIN based reports. The `fn_content_quality_score()` UDF was created because the four-signal quality calculation appeared in the content views, in the cluster audit CTE, and in ranking queries — three places. The moment a calculation appears in a third place, it becomes a function. Before that point, repeating it inline is acceptable. After that point, a function is the only maintainable choice — one formula change updates every query that calls it simultaneously.

---

## 5.1 Why Page Views Alone Are Misleading

A blog post with 50,000 page views and a 90% bounce rate is less valuable than one with 5,000 page views, a 35% bounce rate, a 3-minute average time on page, and a 4% conversion rate.

The `content_performance` table captures all the signals you need to make this distinction:

```sql
DESCRIBE content_performance;
```

| Column | What it measures |
|--------|-----------------|
| `page_views` | Raw traffic |
| `unique_visitors` | Distinct people (not return visits) |
| `avg_time_sec` | Engagement depth — are people reading? |
| `bounce_rate_pct` | Did they leave immediately? |
| `social_shares` | Did they find it valuable enough to share? |
| `backlinks_earned` | Did other sites link to it? (SEO signal) |
| `cta_clicks` | Did it move people toward a conversion? |
| `conversions` | Did it actually convert? |

> 📊 **MARKETING NUGGET** — Content ROI is one of the hardest things to measure in marketing. Most companies measure content by traffic volume and feel good when the numbers go up. But a CMO asking *"What did our content investment return this year?"* needs to see conversions, pipeline influence, and cost per lead — not page views. This module builds the measurement framework that answers that question precisely.

---

## 5.2 The Content Quality Score UDF

The `fn_content_quality_score()` function combines four engagement signals into a single 0–100 score:

```sql
-- See the score formula components
SELECT
    cp.title,
    cp.content_type,
    SUM(p.page_views)                           AS total_views,
    ROUND(AVG(p.avg_time_sec), 0)               AS avg_time_sec,
    ROUND(AVG(p.bounce_rate_pct), 1)            AS avg_bounce_rate,
    SUM(p.social_shares)                        AS total_shares,
    SUM(p.conversions)                          AS total_conversions,
    fn_content_quality_score(
        SUM(p.page_views),
        AVG(p.avg_time_sec),
        AVG(p.bounce_rate_pct),
        SUM(p.social_shares)
    )                                           AS quality_score
FROM content_pieces cp
JOIN content_performance p ON cp.content_id = p.content_id
WHERE cp.status = 'published'
GROUP BY cp.content_id, cp.title, cp.content_type
ORDER BY quality_score DESC;
```

**Score breakdown:**
- 0–40 points from average time on page (engagement depth)
- 0–30 points from bounce rate (relevance)
- 0–20 points from social shares (perceived value)
- 0–10 points from page view volume

> 💡 **TIP & TRICK** — UDFs (User-Defined Functions) are callable inside any SQL expression — in `SELECT`, `WHERE`, `ORDER BY`, `HAVING`, and inside CTEs. This means you can filter by quality score: `WHERE fn_content_quality_score(...) >= 70`, or sort by it, or use it as a CTE output that a subsequent query operates on. UDFs turn complex multi-signal calculations into a single readable function call.

---

## 5.3 DENSE_RANK() — Top Content Within Each Type

```sql
SELECT
    cp.content_type,
    cp.title,
    cp.topic_cluster,
    SUM(p.page_views)                       AS total_views,
    SUM(p.conversions)                      AS total_conversions,
    ROUND(SUM(p.conversions)
        / NULLIF(SUM(p.page_views), 0) * 100, 2) AS conv_rate_pct,
    DENSE_RANK() OVER (
        PARTITION BY cp.content_type
        ORDER BY SUM(p.conversions) DESC
    )                                       AS conversion_rank_in_type
FROM content_pieces cp
JOIN content_performance p ON cp.content_id = p.content_id
GROUP BY cp.content_id, cp.content_type, cp.title, cp.topic_cluster
ORDER BY cp.content_type, conversion_rank_in_type;
```

This tells you: *"Within blog posts, which post drives the most conversions? Within whitepapers, which one? Within case studies?"* Each content type competes within its own category.

> 🎯 **CMO QUESTION** — *"Which content pieces should we promote more aggressively?"* The rank-1 piece in each category is your "hero content" for that type. It has proven conversion performance. Double down on distributing it — add it to email nurture sequences, link to it from your highest-traffic pages, run paid promotion behind it. Your best content often just needs more distribution.

---

## 5.4 Topic Cluster Content Audit — CTE Pipeline

```sql
WITH cluster_content AS (
    SELECT
        cp.topic_cluster,
        cp.content_type,
        COUNT(cp.content_id)                    AS piece_count,
        SUM(p.page_views)                       AS total_views,
        SUM(p.conversions)                      AS total_conversions,
        SUM(p.backlinks_earned)                 AS total_backlinks
    FROM content_pieces cp
    JOIN content_performance p ON cp.content_id = p.content_id
    WHERE cp.status = 'published'
    GROUP BY cp.topic_cluster, cp.content_type
),
cluster_totals AS (
    SELECT
        topic_cluster,
        SUM(piece_count)                        AS total_pieces,
        SUM(total_views)                        AS cluster_views,
        SUM(total_conversions)                  AS cluster_conversions,
        SUM(total_backlinks)                    AS cluster_backlinks
    FROM cluster_content
    GROUP BY topic_cluster
)
SELECT
    topic_cluster,
    total_pieces,
    cluster_views,
    cluster_conversions,
    cluster_backlinks,
    ROUND(cluster_conversions / NULLIF(cluster_views, 0) * 100, 2) AS cluster_conv_rate,
    CASE
        WHEN total_pieces < 3 THEN 'Needs Content — invest here'
        WHEN total_pieces < 6 THEN 'Growing — add 2-3 more pieces'
        ELSE 'Established — optimize existing content'
    END                                         AS cluster_strategy
FROM cluster_totals
ORDER BY cluster_conversions DESC;
```

> 📊 **MARKETING NUGGET** — This query directly informs editorial calendar planning. Clusters labeled "Needs Content" have demand (search volume from Module 01) but no supply (few articles). That's the highest ROI content investment. Clusters labeled "Established" need optimization — updating existing posts, improving CTAs, building internal links — rather than net-new content. Different problem, different solution, different team assignment.

---

## Test Yourself — Module 05

**Question 1:** Which author has published the most content pieces? Which author's content drives the most total conversions?

**Question 2:** What is the overall average content conversion rate (conversions / page_views) across all published content?

**Question 3:** Write a query that finds content pieces with above-average conversion rates within their topic cluster. How many qualify?

**Question 4:** Which content type has the highest average quality score (using the UDF)?

**Question 5 (Challenge):** Build a "content gap" query — find topic clusters that have keyword search volume (from `seo_keywords`) but fewer than 3 published content pieces. These are your highest-priority content investments.

---

### Answers

**Answer 1:**
```sql
SELECT author,
       COUNT(*)            AS pieces_published,
       SUM(p.conversions)  AS total_conversions
FROM content_pieces cp
JOIN content_performance p ON cp.content_id = p.content_id
WHERE cp.status = 'published'
GROUP BY cp.author
ORDER BY total_conversions DESC;
```

**Answer 2:**
```sql
SELECT ROUND(SUM(p.conversions) / NULLIF(SUM(p.page_views), 0) * 100, 3)
    AS overall_conv_rate_pct
FROM content_pieces cp
JOIN content_performance p ON cp.content_id = p.content_id
WHERE cp.status = 'published';
```

**Answer 3:**
```sql
WITH cluster_avg AS (
    SELECT
        cp.topic_cluster,
        AVG(p.conversions / NULLIF(p.page_views, 0) * 100) AS avg_conv_rate
    FROM content_pieces cp
    JOIN content_performance p ON cp.content_id = p.content_id
    WHERE cp.status = 'published'
    GROUP BY cp.topic_cluster
)
SELECT
    cp.title,
    cp.topic_cluster,
    ROUND(SUM(p.conversions) / NULLIF(SUM(p.page_views), 0) * 100, 2) AS conv_rate,
    ROUND(ca.avg_conv_rate, 2)                                         AS cluster_avg
FROM content_pieces cp
JOIN content_performance p  ON cp.content_id    = p.content_id
JOIN cluster_avg ca         ON cp.topic_cluster = ca.topic_cluster
WHERE cp.status = 'published'
GROUP BY cp.content_id, cp.title, cp.topic_cluster, ca.avg_conv_rate
HAVING conv_rate > ca.avg_conv_rate
ORDER BY conv_rate DESC;
```

**Answer 4:**
```sql
SELECT
    cp.content_type,
    ROUND(AVG(fn_content_quality_score(
        p.page_views, p.avg_time_sec, p.bounce_rate_pct, p.social_shares
    )), 1) AS avg_quality_score,
    COUNT(DISTINCT cp.content_id) AS pieces
FROM content_pieces cp
JOIN content_performance p ON cp.content_id = p.content_id
WHERE cp.status = 'published'
GROUP BY cp.content_type
ORDER BY avg_quality_score DESC;
```

**Answer 5 (Challenge):**
```sql
WITH keyword_clusters AS (
    SELECT topic_cluster, SUM(search_volume) AS total_volume, COUNT(*) AS keyword_count
    FROM seo_keywords
    WHERE topic_cluster IS NOT NULL
    GROUP BY topic_cluster
),
content_counts AS (
    SELECT topic_cluster, COUNT(*) AS piece_count
    FROM content_pieces
    WHERE status = 'published' AND topic_cluster IS NOT NULL
    GROUP BY topic_cluster
)
SELECT
    kc.topic_cluster,
    kc.total_volume AS monthly_search_volume,
    kc.keyword_count,
    COALESCE(cc.piece_count, 0) AS published_pieces,
    'Content Gap — High Priority' AS recommendation
FROM keyword_clusters kc
LEFT JOIN content_counts cc ON kc.topic_cluster = cc.topic_cluster
WHERE COALESCE(cc.piece_count, 0) < 3
ORDER BY kc.total_volume DESC;
```

---

[← Module 04: GTM](04_gtm.md) | [Back to Index](README.md) | [Next: Module 06 — Audiences →](06_audience.md)
