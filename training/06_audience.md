# Module 06 — Audience Targeting and Segmentation

**Estimated time:** 60 minutes
**SQL skills:** `PERCENT_RANK()`, `GROUP_CONCAT()`, multi-CTE pipelines, `HAVING` with aggregates
**Tables:** `audiences`, `audience_members`, `customers`, `orders`

[← Module 05: Content](05_content.md) | [Back to Index](README.md) | [Next: Module 07 — Analytics →](07_analytics.md)

---

## What You Will Learn

- The difference between audience types and when to use each
- How to segment customers by revenue using `PERCENT_RANK()` and `NTILE()`
- How to find customers appearing in multiple audiences
- How to calculate CLV tier using the `fn_clv_tier()` UDF
- How multi-channel exposure affects customer value

---

## Engineering Lens — Before You Build Anything in This Module

> 💡 **Engineering Lens** — Audience data has a referential integrity profiling question: are all `audience_members` linked to customers that actually exist? Run the referential integrity check from Module 00B against `audience_members.customer_id`. Any orphaned audience members — customers who appear in an audience but not in the `customers` table — would produce NULLs in every audience overlap report. Profile the `match_rate_pct` column in `audiences` too — it has intentional NULLs for platform-based audiences where match rate is not tracked. Know this before aggregating it. The `fn_clv_tier()` UDF was created specifically because CLV tiering appeared in audience analysis, customer reporting, and the KPI dashboard — three distinct consumers. It became a function so that if the business changes the tier thresholds, one edit updates all three reports simultaneously.

---

## 6.1 Audience Types

The `audiences` table defines how audiences are built across platforms:

```sql
SELECT audience_name, channel, audience_type, size_estimate, match_rate_pct
FROM audiences
ORDER BY channel, audience_type;
```

| Audience Type | What it is | Best used for |
|---|---|---|
| `remarketing` | People who visited your site | Re-engaging warm prospects |
| `lookalike` | New people similar to your best customers | Scalable prospecting |
| `interest` | Platform-defined interest categories | Top-of-funnel awareness |
| `in_market` | People actively researching your category | High-intent prospecting |
| `custom` | Your own CRM or email data uploaded to a platform | Retention, upsell, win-back |
| `demographic` | Job title, company size, industry filters | B2B LinkedIn targeting |

> 📊 **MARKETING NUGGET** — The most underutilized audience type in B2B marketing is `remarketing` on high-intent pages. Someone who visited your pricing page is 10x more likely to convert than a cold prospect. Remarketing to pricing page visitors with a specific offer — "You looked at our pricing, here's a demo" — typically converts at 3–5x the rate of cold audience campaigns at a fraction of the cost.

---

## 6.2 Customer Revenue Segmentation — PERCENT_RANK() and NTILE()

```sql
SELECT
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name)      AS customer_name,
    c.segment,
    COALESCE(SUM(o.amount), 0)                  AS total_revenue,
    COUNT(o.order_id)                            AS order_count,
    NTILE(5) OVER (
        ORDER BY COALESCE(SUM(o.amount), 0) DESC
    )                                           AS revenue_quintile,
    ROUND(
        PERCENT_RANK() OVER (
            ORDER BY COALESCE(SUM(o.amount), 0)
        ) * 100, 1
    )                                           AS revenue_percentile,
    fn_clv_tier(COALESCE(SUM(o.amount), 0))     AS clv_tier
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name, c.segment
ORDER BY total_revenue DESC;
```

> 💡 **TIP & TRICK** — `PERCENT_RANK()` tells you where a customer falls relative to all others on a 0–100 scale. `NTILE(5)` splits the population into exactly 5 equal buckets. They serve different purposes: use `PERCENT_RANK()` when you want to tell a story ("this customer is in the top 8% by revenue"), use `NTILE()` when you want to assign equal-sized tiers for operational use (sending the top 20% to sales, the next 20% to nurture, etc.).

> 🎯 **CMO QUESTION** — *"Who are our most valuable customers and what do they have in common?"* Filter `clv_tier = 'Platinum'` or `revenue_quintile = 1`. Look at their segment, industry, city, and which campaigns acquired them. The pattern you find is your ideal customer profile (ICP) — and your ICP should be the center of every targeting decision you make.

---

## 6.3 Multi-Channel Audience Overlap

```sql
SELECT
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name)      AS customer_name,
    c.segment,
    COUNT(DISTINCT am.audience_id)              AS audience_count,
    GROUP_CONCAT(
        DISTINCT a.audience_name
        ORDER BY a.audience_id
        SEPARATOR ' | '
    )                                           AS audiences
FROM customers c
JOIN audience_members am ON c.customer_id = am.customer_id
JOIN audiences         a  ON am.audience_id = a.audience_id
GROUP BY c.customer_id, c.first_name, c.last_name, c.segment
HAVING COUNT(DISTINCT am.audience_id) >= 2
ORDER BY audience_count DESC;
```

> 💡 **TIP & TRICK** — `GROUP_CONCAT()` is MySQL's way of collapsing multiple rows into a single comma-separated (or custom-separated) string within a `GROUP BY`. It's the equivalent of Python's `', '.join(list)`. Very useful for building audience membership labels, tag lists, or feature flags in reports. In Snowflake and BigQuery, the equivalent is `LISTAGG()` and `STRING_AGG()` respectively.

---

## Test Yourself — Module 06

**Question 1:** How many customers are in each CLV tier? What percentage of total revenue does each tier represent?

**Question 2:** Which audience has the highest size estimate? Which has the highest match rate?

**Question 3:** Write a query showing average total revenue for customers in each segment (Enterprise, SMB, Consumer). How large is the gap between Enterprise and Consumer?

**Question 4 (Challenge):** Identify Enterprise customers who have NOT been added to any audience yet. These are audience gaps — high-value customers not being targeted by any campaign.

---

### Answers

**Answer 1:**
```sql
WITH customer_clv AS (
    SELECT
        c.customer_id,
        fn_clv_tier(COALESCE(SUM(o.amount), 0)) AS clv_tier,
        COALESCE(SUM(o.amount), 0)              AS total_revenue
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id
)
SELECT
    clv_tier,
    COUNT(*)                                AS customer_count,
    SUM(total_revenue)                      AS tier_revenue,
    ROUND(SUM(total_revenue)
        / (SELECT SUM(amount) FROM orders) * 100, 1) AS revenue_share_pct
FROM customer_clv
GROUP BY clv_tier
ORDER BY tier_revenue DESC;
```

**Answer 2:**
```sql
SELECT audience_name, channel, size_estimate, match_rate_pct
FROM audiences
ORDER BY size_estimate DESC
LIMIT 5;

SELECT audience_name, channel, match_rate_pct
FROM audiences
WHERE match_rate_pct IS NOT NULL
ORDER BY match_rate_pct DESC;
```

**Answer 3:**
```sql
SELECT
    c.segment,
    COUNT(DISTINCT c.customer_id)   AS customer_count,
    ROUND(AVG(o_totals.rev), 2)     AS avg_revenue_per_customer
FROM customers c
JOIN (
    SELECT customer_id, SUM(amount) AS rev
    FROM orders GROUP BY customer_id
) o_totals ON c.customer_id = o_totals.customer_id
GROUP BY c.segment
ORDER BY avg_revenue_per_customer DESC;
```

**Answer 4 (Challenge):**
```sql
SELECT
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    c.segment,
    c.email
FROM customers c
WHERE c.segment = 'Enterprise'
  AND NOT EXISTS (
      SELECT 1 FROM audience_members am
      WHERE am.customer_id = c.customer_id
  )
ORDER BY c.customer_id;
```

---

[← Module 05: Content](05_content.md) | [Back to Index](README.md) | [Next: Module 07 — Analytics →](07_analytics.md)
