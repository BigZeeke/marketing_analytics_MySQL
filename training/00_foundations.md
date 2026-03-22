# Module 00 — Foundations

**Estimated time:** 45 minutes
**Prerequisites:** MySQL Workbench installed, database loaded from `01_create_schema.sql` through `03_data_channels.sql`

[← Back to Index](README.md) | [Next: Module 00B — Engineering Workflow →](00b_engineering_workflow.md)

---

## What You Will Learn

- How the 25-table schema is organized and why it was designed that way
- How to navigate an unfamiliar database like a professional
- The five core tables every marketing analytics query touches
- How to read and interpret query execution plans
- The mental model for connecting SQL to business outcomes

---

## 0.1 The Schema at a Glance

The `marketing_analytics` database models a B2B software company running paid, organic, email, social, display, and referral campaigns across two full years. Before writing a single query, understand how the tables relate to each other.

**The Core Spine**

Every meaningful business transaction flows through this chain:

```
campaigns → leads → customers → orders → payments
```

A campaign attracts leads. Some leads convert to customers. Customers place orders. Orders generate payments. Every revenue metric in the business traces back through these five tables.

**The Channel Layer**

Surrounding the core spine are channel-specific tables that capture how each traffic source works:

| Channel | Tables |
|---------|--------|
| SEO | `seo_keywords`, `seo_rankings`, `organic_traffic` |
| PPC | `ad_groups`, `ads`, `ad_performance` |
| Email | `email_campaigns`, `email_events` |
| GTM / Web | `gtm_tags`, `web_events`, `web_sessions`, `web_pages`, `web_vitals` |
| Content | `content_pieces`, `content_performance` |
| Audiences | `audiences`, `audience_members` |
| Testing | `ab_tests`, `ab_variants` |
| Trends | `industry_trends`, `algorithm_updates` |

**The Operations Layer**

Two tables record what happened behind the scenes:

| Table | Purpose |
|-------|---------|
| `pipeline_error_log` | Populated by stored procedures when something fails |
| `campaign_audit_log` | Populated by triggers when campaigns change status |

---

## 0.2 Navigating an Unfamiliar Database

The first thing any analyst does when connecting to a new database is orient themselves. Here are the three commands that tell you everything you need to know in under two minutes.

**Step 1: List all tables**

```sql
USE marketing_analytics;

SHOW TABLES;
```

**Step 2: Inspect a table's structure**

```sql
DESCRIBE campaigns;
```

This shows every column, its data type, whether it can be null, and whether it has a key. Run this on every table you work with until you have memorized the schema.

**Step 3: Preview a sample of data**

```sql
SELECT * FROM campaigns LIMIT 5;
SELECT * FROM leads     LIMIT 5;
SELECT * FROM customers LIMIT 5;
```

> 💡 **TIP & TRICK** — Never run `SELECT *` on a large table without a `LIMIT`. In production databases with millions of rows, an unguarded `SELECT *` can lock up your connection and your colleagues'. Build the habit of always adding `LIMIT 10` when exploring.

---

## 0.3 Understanding the Five Core Tables

Before writing analytical queries, internalize what each core table contains and what its key columns mean.

### campaigns

```sql
SELECT
    campaign_id,
    campaign_name,
    channel,
    campaign_type,
    budget,
    spend,
    status,
    start_date,
    end_date
FROM campaigns
ORDER BY start_date;
```

**What to notice:** Every campaign has a `channel` (the traffic source) and a `campaign_type` (what it was designed to do). `budget` is what was planned. `spend` is what was actually used. The gap between them tells you whether the campaign was pacing correctly.

### leads

```sql
SELECT
    lead_id,
    campaign_id,
    email,
    lead_source,
    status,
    deal_value,
    score,
    created_at,
    converted_at
FROM leads
ORDER BY created_at
LIMIT 20;
```

**What to notice:** `status` has four values: `new`, `qualified`, `converted`, `stale`. `deal_value` is only populated for converted leads — it represents the revenue attributed to that lead. `score` is a 0–99 numeric quality indicator.

### customers

```sql
SELECT
    customer_id,
    CONCAT(first_name, ' ', last_name) AS name,
    email,
    segment,
    city,
    state,
    points,
    balance
FROM customers
ORDER BY balance DESC;
```

**What to notice:** `segment` is your audience tier: `Enterprise`, `SMB`, or `Consumer`. Enterprise customers have the highest balances. This column drives most audience segmentation queries.

### orders and payments

```sql
-- Orders show what was purchased and when
SELECT o.order_id, o.customer_id, o.order_date, o.amount, o.status
FROM orders o
ORDER BY o.order_date
LIMIT 10;

-- Payments confirm money actually moved
SELECT p.payment_id, p.customer_id, p.order_id, p.amount, p.paid_at
FROM payments p
ORDER BY p.paid_at
LIMIT 10;
```

**What to notice:** Orders and payments have a one-to-one relationship in this schema — every order generates exactly one payment. In real systems these often diverge (installment plans, refunds, chargebacks), which is why they are separate tables.

---

## 0.4 Your First Analytical Query

Now connect the tables. This query is the foundation of almost every marketing performance report:

```sql
SELECT
    c.channel,
    c.campaign_type,
    COUNT(DISTINCT c.campaign_id)                           AS campaigns,
    SUM(c.spend)                                            AS total_spend,
    COUNT(l.lead_id)                                        AS total_leads,
    SUM(CASE WHEN l.status = 'converted' THEN 1 ELSE 0 END) AS conversions,
    ROUND(
        SUM(CASE WHEN l.status = 'converted' THEN 1 ELSE 0 END)
        / NULLIF(COUNT(l.lead_id), 0) * 100, 2
    )                                                       AS conversion_rate_pct,
    ROUND(
        SUM(c.spend)
        / NULLIF(COUNT(l.lead_id), 0), 2
    )                                                       AS cost_per_lead
FROM campaigns c
LEFT JOIN leads l ON c.campaign_id = l.campaign_id
GROUP BY c.channel, c.campaign_type
ORDER BY total_spend DESC;
```

Run this. Study the results before reading on.

> 📊 **MARKETING NUGGET** — This is the query a CMO looks at every Monday morning. It answers: *"Where did we spend money, how many leads did we generate, and which channels are converting them?"* Cost per lead (CPL) tells you the efficiency of each channel. A channel with high spend but low leads has a CPL problem. A channel with high leads but low conversion rate has a quality problem. These are very different problems with very different solutions.

> 🎯 **CMO QUESTION** — *"Which of our channels gives us the best quality leads?"* Quality here means conversion rate, not volume. A channel that sends 100 leads with a 30% conversion rate is more valuable than one sending 500 leads at 5%.

---

## 0.5 NULL Handling — The Silent Killer

One of the most common sources of wrong answers in SQL is mishandled NULLs. In this schema, NULLs appear frequently and intentionally:

- `leads.customer_id` is NULL when a lead hasn't been matched to a customer yet
- `leads.deal_value` is NULL for unconverted leads
- `leads.converted_at` is NULL for leads that haven't converted
- `campaigns.end_date` is NULL for campaigns still running

**The most important NULL rule:** Any arithmetic involving NULL returns NULL.

```sql
-- This returns NULL, not 0
SELECT NULL + 100;

-- COALESCE replaces NULL with a fallback value
SELECT COALESCE(NULL, 0) + 100;  -- returns 100

-- NULLIF prevents divide-by-zero by converting 0 to NULL
SELECT 100 / NULLIF(0, 0);       -- returns NULL instead of error
```

> ⚠️ **WATCH OUT** — `COUNT(column)` excludes NULLs. `COUNT(*)` includes them. These return different numbers and both can be correct depending on what you're measuring. `COUNT(l.lead_id)` counts leads that exist. `COUNT(l.converted_at)` counts only leads with a conversion timestamp. Always be explicit about which you want.

```sql
-- Demonstrating the difference on your data
SELECT
    COUNT(*)                AS total_rows,
    COUNT(lead_id)          AS leads_with_id,
    COUNT(converted_at)     AS leads_converted,
    COUNT(deal_value)       AS leads_with_deal_value
FROM leads;
```

---

## 0.6 Reading an Execution Plan

Before you write complex queries, understand how MySQL executes them. `EXPLAIN` shows you the plan without running the query.

```sql
EXPLAIN
SELECT c.channel, COUNT(l.lead_id) AS leads
FROM campaigns c
LEFT JOIN leads l ON c.campaign_id = l.campaign_id
GROUP BY c.channel;
```

**The columns that matter most:**

| Column | What it tells you |
|--------|------------------|
| `type` | How the table is being accessed. `ALL` = full scan (slow). `ref` or `eq_ref` = index used (fast) |
| `key` | Which index is being used. NULL means no index — potential problem |
| `rows` | Estimated rows MySQL will examine. Lower is better |
| `Extra` | `Using filesort` or `Using temporary` = query needs optimization |

> 💡 **TIP & TRICK** — After the indexes file (`10_indexes.sql`) is loaded, re-run the same `EXPLAIN`. Compare the `type` and `key` columns. You will see `ALL` become `ref`, and `rows` drop dramatically. This is what indexing does — it eliminates the work MySQL has to do.

---

## 0.7 The Mental Model: SQL as a Business Translation Layer

The most important concept in this entire guide is not a SQL function. It is a mindset.

**SQL is not about tables and rows. It is about translating business questions into precise measurements.**

Every query you write should start with a business question, not a table name. The workflow is:

```
Business question
    → Identify the metric (conversion rate, ROAS, CPL, open rate)
    → Identify which tables hold the raw inputs
    → Write the JOIN to connect them
    → Write the aggregation to compute the metric
    → Add WHERE / GROUP BY to slice it correctly
    → Interpret the number in business terms
```

This workflow applies whether you are writing a simple `COUNT(*)` or a 200-line CTE chain with window functions.

> 📊 **MARKETING NUGGET** — Every metric has a denominator problem. Conversion rate is conversions divided by *something* — but what? Total leads? Qualified leads? List size? Page visitors? The denominator changes the number completely, and different stakeholders will argue about which is "correct." Your job as an analyst is to be explicit about what denominator you used and why. Always name your metrics precisely: not "conversion rate" but "lead-to-close conversion rate" or "email open-to-click rate."

---

## Test Yourself — Module 00

Answer these questions using queries against your database. Answers follow.

**Question 1:** How many total leads exist in the database, broken down by status?

**Question 2:** What is the average deal value for converted leads only?

**Question 3:** Which customer has the highest total order revenue? What segment are they in?

**Question 4:** How many campaigns ran in 2023 vs 2024? Did budget increase year over year?

**Question 5:** Write a query that returns only leads where `deal_value` is NULL. What does this tell you about those leads?

---

### Answers

**Answer 1:**
```sql
SELECT status, COUNT(*) AS lead_count
FROM leads
GROUP BY status
ORDER BY lead_count DESC;
```

**Answer 2:**
```sql
SELECT ROUND(AVG(deal_value), 2) AS avg_deal_value
FROM leads
WHERE status = 'converted'
  AND deal_value IS NOT NULL;
```

**Answer 3:**
```sql
SELECT
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    c.segment,
    SUM(o.amount)                           AS total_revenue
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name, c.segment
ORDER BY total_revenue DESC
LIMIT 1;
```

**Answer 4:**
```sql
SELECT
    YEAR(start_date)          AS campaign_year,
    COUNT(*)                  AS campaign_count,
    SUM(budget)               AS total_budget,
    SUM(spend)                AS total_spend
FROM campaigns
GROUP BY YEAR(start_date)
ORDER BY campaign_year;
```

**Answer 5:**
```sql
SELECT lead_id, email, status, lead_source, created_at
FROM leads
WHERE deal_value IS NULL
ORDER BY created_at;
```
Leads with NULL deal value are unconverted — they entered the pipeline but never closed. Counting these tells you how much unrealized pipeline you have sitting in the system.

---

[← Back to Index](README.md) | [Next: Module 00B — Engineering Workflow →](00b_engineering_workflow.md)
