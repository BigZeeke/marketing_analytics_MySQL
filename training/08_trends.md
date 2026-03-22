# Module 08 — Current Trends & Best Practices

**Estimated time:** 45 minutes
**SQL skills:** Date range joins, `EXISTS`, impact score aggregation, running averages
**Tables:** `industry_trends`, `algorithm_updates`, `campaigns`

[← Module 07: Analytics](07_analytics.md) | [Back to Index](README.md) | [Next: Module 09 — Optimization →](09_optimization.md)

---

## Engineering Lens — Before You Build Anything in This Module

> 💡 **Engineering Lens** — Trends data has an important profiling question: check for NULLs in `algorithm_updates.our_impact_score`. This column is intentionally NULL for updates not yet evaluated — including them in averages skews results. Profiling reveals this immediately and tells you to always filter `WHERE our_impact_score IS NOT NULL` in any aggregation. Notice that no views or procedures were created for trends analysis in this project. Why? Because trends queries are run irregularly, change shape frequently, and are typically one-off analyses — exactly the scenario where named ad-hoc queries are the right tool and objects would be over-engineering. Resist the temptation to turn every query into an object. Objects are a commitment. Queries are flexible.

---

## What You Will Learn

- How to track and score the impact of industry changes on your marketing
- How to use date range joins to correlate external events with campaign performance
- How algorithm updates affect campaign data — and how to detect it in SQL
- How to build a trends monitoring framework

---

## 8.1 The Trends Tables

```sql
SELECT trend_name, category, impact_level, date_identified, our_adoption
FROM industry_trends
ORDER BY date_identified;

SELECT platform, update_name, update_date, our_impact_score, action_taken
FROM algorithm_updates
ORDER BY update_date;
```

The `our_impact_score` column in `algorithm_updates` uses a -5 to +5 scale:
- **+3 to +5** — Major positive impact (traffic surge, CPL drop)
- **+1 to +2** — Minor positive
- **0** — Neutral or not yet measured
- **-1 to -2** — Minor negative
- **-3 to -5** — Major negative (traffic crash, CPL spike)

> 📊 **MARKETING NUGGET** — Google's March 2024 Core Update is recorded in this dataset with a score of +3. The action taken was: *"Traffic up 24% in 45 days."* This happened because the site had been consistently publishing high-quality, original content — exactly what the update rewarded. Algorithm updates are not random. Sites with strong fundamentals consistently gain during core updates. The update didn't change the site; it changed how Google valued what was already there.

---

## 8.2 Running Average Impact Score by Platform

```sql
SELECT
    platform,
    update_name,
    update_date,
    our_impact_score,
    ROUND(AVG(our_impact_score) OVER (
        PARTITION BY platform
        ORDER BY     update_date
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 2)                                   AS rolling_3update_avg,
    SUM(our_impact_score) OVER (
        PARTITION BY platform
        ORDER BY     update_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    )                                       AS cumulative_impact
FROM algorithm_updates
WHERE our_impact_score IS NOT NULL
ORDER BY platform, update_date;
```

A rising `cumulative_impact` means the platform's updates have been net-positive for your marketing over time. A declining trend means the platform is becoming less favorable — which should influence budget allocation.

---

## 8.3 Campaigns Running During High-Impact Updates

```sql
SELECT
    c.campaign_name,
    c.channel,
    c.start_date,
    c.end_date,
    c.spend,
    (
        SELECT COUNT(*) FROM algorithm_updates au
        WHERE au.our_impact_score >= 2
          AND au.update_date BETWEEN c.start_date AND COALESCE(c.end_date, CURDATE())
    )                                       AS positive_updates_during_run,
    (
        SELECT au.update_name FROM algorithm_updates au
        WHERE au.our_impact_score >= 2
          AND au.update_date BETWEEN c.start_date AND COALESCE(c.end_date, CURDATE())
        ORDER BY au.our_impact_score DESC
        LIMIT 1
    )                                       AS biggest_positive_update
FROM campaigns c
WHERE EXISTS (
    SELECT 1 FROM algorithm_updates au
    WHERE au.our_impact_score >= 2
      AND au.update_date BETWEEN c.start_date AND COALESCE(c.end_date, CURDATE())
)
ORDER BY c.start_date;
```

> 🎯 **CMO QUESTION** — *"Why did Q3 2023 organic campaigns outperform our forecast?"* This query shows that the August 2023 Core Update (impact score: +3) ran concurrent with your Q3 organic campaigns. The algorithm update boosted your organic rankings mid-campaign — a tailwind that inflated performance beyond what your baseline would predict. Understanding this prevents you from over-crediting campaign creative when external factors were the real driver.

---

## Test Yourself — Module 08

**Question 1:** How many trends have we "adopted" vs are still "evaluating" or "planned"?

**Question 2:** Which platform has the highest cumulative impact score across all its algorithm updates?

**Question 3:** Write a query showing the average impact score of Google Search updates vs Meta updates. Which platform has been more favorable?

---

### Answers

**Answer 1:**
```sql
SELECT our_adoption, COUNT(*) AS trend_count
FROM industry_trends
GROUP BY our_adoption
ORDER BY trend_count DESC;
```

**Answer 2:**
```sql
SELECT platform, SUM(our_impact_score) AS cumulative_impact
FROM algorithm_updates
WHERE our_impact_score IS NOT NULL
GROUP BY platform
ORDER BY cumulative_impact DESC;
```

**Answer 3:**
```sql
SELECT
    platform,
    ROUND(AVG(our_impact_score), 2) AS avg_impact,
    COUNT(*) AS update_count
FROM algorithm_updates
WHERE platform IN ('Google Search', 'Meta')
  AND our_impact_score IS NOT NULL
GROUP BY platform;
```

---

[← Module 07: Analytics](07_analytics.md) | [Back to Index](README.md) | [Next: Module 09 — Optimization →](09_optimization.md)

---
