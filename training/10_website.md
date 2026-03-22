# Module 10 — Website Development Essentials

**Estimated time:** 60 minutes
**SQL skills:** Funnel CTEs, correlated subqueries, optimization flags, `fn_lcp_rating()` UDF
**Tables:** `web_pages`, `web_sessions`, `web_vitals`

[← Module 09: Optimization](09_optimization.md) | [Back to Index](README.md) | [Next: Module 11 — Glossary →](11_glossary.md)

---

## What You Will Learn

- How Core Web Vitals affect both SEO rankings and conversion rates
- How to build a conversion funnel from session data using union CTEs
- How to identify pages that need CRO (Conversion Rate Optimization) attention
- How to correlate page speed scores with conversion rates
- How to use the `fn_lcp_rating()` UDF to flag underperforming pages

---

## Engineering Lens — Before You Build Anything in This Module

> 💡 **Engineering Lens** — Website data has two profiling questions that matter most. First, does every `web_session` have a valid `landing_page` that exists in `web_pages`? Run a LEFT JOIN check — orphaned sessions (no matching page record) would disappear from page-level conversion rate reports without warning. Second, does every page in `web_vitals` have continuous quarterly snapshots? Gaps in the vitals timeline break the LAG-based trend queries. The `fn_lcp_rating()` UDF was created because LCP classification appeared in the CRO priority matrix, in the vitals trend query, and in the web vitals summary view — three consumers. The funnel query in this module uses `UNION ALL` inside a CTE rather than a single complex query because each funnel stage has a genuinely different WHERE clause. `UNION ALL` of simple queries is more readable and maintainable than one query with five levels of nested subqueries doing the same work.

---

## 10.1 Core Web Vitals — What They Are and Why They Matter

Google uses three metrics — LCP, FID/INP, and CLS — as ranking signals AND as predictors of user experience quality.

```sql
SELECT
    page_url,
    vital_date,
    lcp_ms,
    fn_lcp_rating(lcp_ms)       AS lcp_rating,
    fid_ms,
    cls_score,
    mobile_score,
    desktop_score
FROM web_vitals
ORDER BY page_url, vital_date;
```

| Metric | What it measures | Good threshold |
|--------|-----------------|---------------|
| **LCP** (Largest Contentful Paint) | How fast the main content loads | < 2,500ms |
| **FID** (First Input Delay) | How quickly the page responds to interaction | < 100ms |
| **CLS** (Cumulative Layout Shift) | How much the page jumps around while loading | < 0.1 |

> 📊 **MARKETING NUGGET** — A 1-second improvement in mobile page load time increases conversion rates by an average of 27% according to Google's internal research. For a page converting 2% of 10,000 monthly visitors at a $500 average order value, that's 27 additional conversions × $500 = $13,500 more revenue per month from a single technical improvement. Page speed is not a developer problem. It is a revenue problem.

> 🎯 **CMO QUESTION** — *"Which pages should engineering prioritize for performance improvements?"* Filter for pages with `lcp_rating = 'Poor'` or `mobile_score < 50`. Cross-reference with the session data to find which of those pages have high traffic volume — the intersection of "slow" and "high-traffic" is where performance investment has the biggest revenue impact.

---

## 10.2 Core Web Vitals Improvement Trend

```sql
SELECT
    page_url,
    vital_date,
    lcp_ms,
    fn_lcp_rating(lcp_ms)           AS lcp_rating,
    mobile_score,
    LAG(mobile_score) OVER (
        PARTITION BY page_url
        ORDER BY     vital_date
    )                               AS prev_mobile_score,
    mobile_score - LAG(mobile_score) OVER (
        PARTITION BY page_url
        ORDER BY     vital_date
    )                               AS mobile_score_change
FROM web_vitals
ORDER BY page_url, vital_date;
```

Positive `mobile_score_change` means the page improved. Track this after every major site release or CDN configuration change.

---

## 10.3 The Website Conversion Funnel — Union CTE

This is the most important query in the website module. It builds a step-by-step funnel from raw session data.

```sql
WITH funnel_stages AS (
    SELECT 'Step 1: All Sessions'       AS stage, 1 AS step, COUNT(*) AS count
    FROM web_sessions

    UNION ALL

    SELECT 'Step 2: Multi-Page',         2, COUNT(*)
    FROM web_sessions WHERE pages_viewed > 1

    UNION ALL

    SELECT 'Step 3: High Intent Pages',  3, COUNT(*)
    FROM web_sessions
    WHERE landing_page IN ('/pricing', '/demo', '/trial')
       OR landing_page LIKE '%pricing%'
       OR landing_page LIKE '%demo%'

    UNION ALL

    SELECT 'Step 4: Converted',          4, SUM(converted)
    FROM web_sessions
),
funnel_with_rates AS (
    SELECT
        stage,
        step,
        count,
        LAG(count) OVER (ORDER BY step)     AS prev_step_count
    FROM funnel_stages
)
SELECT
    step,
    stage,
    count,
    prev_step_count,
    ROUND(count / NULLIF(prev_step_count, 0) * 100, 1)      AS step_retention_pct,
    ROUND(count / NULLIF(FIRST_VALUE(count) OVER (ORDER BY step), 0) * 100, 1) AS overall_funnel_pct
FROM funnel_with_rates
ORDER BY step;
```

> 💡 **TIP & TRICK** — `UNION ALL` in a CTE is how you build a funnel from separate aggregate queries. Each `SELECT` in the UNION represents one funnel stage. The `LAG()` in the outer query then computes the step-over-step retention rate. This is cleaner than writing one massive query with nested subqueries — each stage is independently readable and debuggable.

---

## 10.4 CRO Priority Matrix — Full Analysis Query

This query combines session performance and web vitals into a single prioritized action list:

```sql
WITH page_performance AS (
    SELECT
        landing_page,
        referrer_source,
        device_type,
        COUNT(session_id)                           AS sessions,
        SUM(converted)                              AS conversions,
        ROUND(SUM(converted) / NULLIF(COUNT(session_id), 0) * 100, 2) AS conv_rate_pct
    FROM web_sessions
    GROUP BY landing_page, referrer_source, device_type
),
vitals_latest AS (
    SELECT
        page_url,
        lcp_ms,
        mobile_score,
        fn_lcp_rating(lcp_ms)                       AS lcp_rating
    FROM web_vitals wv
    WHERE vital_date = (
        SELECT MAX(vital_date) FROM web_vitals wv2
        WHERE wv2.page_url = wv.page_url
    )
)
SELECT
    pp.landing_page,
    pp.device_type,
    pp.referrer_source,
    pp.sessions,
    pp.conv_rate_pct,
    vl.lcp_ms,
    vl.lcp_rating,
    vl.mobile_score,
    CASE
        WHEN vl.mobile_score < 50 AND pp.device_type = 'mobile'  THEN 'P1 — Fix Mobile Speed'
        WHEN pp.conv_rate_pct < 1.0                              THEN 'P2 — Low Conversion Rate'
        WHEN vl.lcp_rating IN ('Poor', 'Needs Improvement')      THEN 'P3 — Core Web Vitals'
        ELSE 'Performing'
    END                                             AS cro_priority
FROM page_performance pp
LEFT JOIN vitals_latest vl ON pp.landing_page = vl.page_url
ORDER BY pp.sessions DESC;
```

> 📊 **MARKETING NUGGET** — CRO (Conversion Rate Optimization) is one of the highest-ROI activities in marketing because it improves the efficiency of every dollar you're already spending. If you double your conversion rate, every campaign's ROAS doubles — with zero additional spend. The priority matrix above tells you where to start: P1 is a technical fix (speed), P2 is a messaging or UX fix (redesign, copy), P3 is a performance fix (images, JavaScript). Different teams, different work, different timelines.

---

## Test Yourself — Module 10

**Question 1:** Which page has improved its mobile PageSpeed score the most over the recorded period?

**Question 2:** What percentage of all sessions ended in a conversion? Break it down by device type.

**Question 3:** Which traffic source has the highest session-to-conversion rate? Which has the lowest?

**Question 4 (Challenge):** Build a query that identifies the top 5 pages by traffic volume where the LCP is still in "Needs Improvement" or "Poor" territory. These are your highest-impact performance investment targets.

---

### Answers

**Answer 1:**
```sql
SELECT
    page_url,
    MIN(mobile_score)                   AS starting_score,
    MAX(mobile_score)                   AS ending_score,
    MAX(mobile_score) - MIN(mobile_score) AS improvement
FROM web_vitals
GROUP BY page_url
ORDER BY improvement DESC
LIMIT 5;
```

**Answer 2:**
```sql
SELECT
    device_type,
    COUNT(*)                            AS total_sessions,
    SUM(converted)                      AS conversions,
    ROUND(SUM(converted) / NULLIF(COUNT(*), 0) * 100, 2) AS conv_rate_pct
FROM web_sessions
GROUP BY device_type
ORDER BY conv_rate_pct DESC;
```

**Answer 3:**
```sql
SELECT
    referrer_source,
    COUNT(*)            AS sessions,
    SUM(converted)      AS conversions,
    ROUND(SUM(converted) / NULLIF(COUNT(*), 0) * 100, 2) AS conv_rate_pct
FROM web_sessions
GROUP BY referrer_source
ORDER BY conv_rate_pct DESC;
```

**Answer 4 (Challenge):**
```sql
WITH latest_vitals AS (
    SELECT page_url, lcp_ms, fn_lcp_rating(lcp_ms) AS lcp_rating
    FROM web_vitals wv
    WHERE vital_date = (
        SELECT MAX(vital_date) FROM web_vitals wv2 WHERE wv2.page_url = wv.page_url
    )
),
page_traffic AS (
    SELECT landing_page, COUNT(*) AS sessions
    FROM web_sessions
    GROUP BY landing_page
)
SELECT
    pt.landing_page,
    pt.sessions,
    lv.lcp_ms,
    lv.lcp_rating
FROM page_traffic pt
JOIN latest_vitals lv ON pt.landing_page = lv.page_url
WHERE lv.lcp_rating IN ('Needs Improvement', 'Poor')
ORDER BY pt.sessions DESC
LIMIT 5;
```

---

[← Module 09: Optimization](09_optimization.md) | [Back to Index](README.md) | [Next: Module 11 — Glossary →](11_glossary.md)
