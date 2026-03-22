# Module 07 — Marketing Analytics & Reporting

**Estimated time:** 75 minutes
**SQL skills:** Full attribution CTE chain, YoY window functions, conditional aggregation, stored procedures for reporting
**Tables:** All core tables, `vw_marketing_kpi_dashboard`, `vw_channel_yoy`

[← Module 06: Audiences](06_audience.md) | [Back to Index](README.md) | [Next: Module 08 — Trends →](08_trends.md)

---

## What You Will Learn

- How to build an executive KPI dashboard in SQL
- How to construct a first-touch attribution model from scratch
- How YoY comparison queries work and where they break
- How stored procedures automate recurring reports
- How to answer the hardest marketing measurement question: "What drove revenue?"

---

## Engineering Lens — Before You Build Anything in This Module

> 💡 **Engineering Lens** — The marketing analytics and reporting module is where the dependency order from Module 00B becomes most visible. `vw_marketing_kpi_dashboard` depends on `campaigns` and `leads`. `sp_yoy_channel_report` depends on `vw_channel_yoy`. `sp_campaign_health_check` depends on `campaigns`, `leads`, and calls `fn_calculate_roas()`. If you had built the stored procedures before the views and UDFs, every procedure would fail at creation time. The attribution model CTE in this module was kept as a query rather than a view deliberately — it is complex enough to need modification for different attribution windows, and a view cannot accept parameters. When a query is too complex to be a simple view but needs flexibility, a stored procedure is the right object. When it is exploratory and needs to change frequently, keeping it as a named query is the right choice.

---

## 7.1 The Marketing KPI Dashboard

The `vw_marketing_kpi_dashboard` view gives you the top-line numbers every quarter:

```sql
SELECT * FROM vw_marketing_kpi_dashboard ORDER BY reporting_year, reporting_quarter;
```

Study the output. Notice how budget utilization, lead volume, conversion rate, blended CPL, and ROAS all tell a different part of the same story.

> 🎯 **CMO QUESTION** — *"Give me a one-page summary of marketing performance this year vs last year."* This view is that one page. For each metric, calculate the YoY change:

```sql
SELECT
    reporting_year,
    reporting_quarter,
    total_spend,
    blended_roas,
    lead_conversion_rate_pct,
    blended_cpl,
    LAG(blended_roas) OVER (ORDER BY reporting_year, reporting_quarter)         AS prev_roas,
    ROUND(blended_roas - LAG(blended_roas) OVER (ORDER BY reporting_year, reporting_quarter), 2) AS roas_change,
    LAG(blended_cpl)  OVER (ORDER BY reporting_year, reporting_quarter)         AS prev_cpl,
    ROUND(blended_cpl - LAG(blended_cpl) OVER (ORDER BY reporting_year, reporting_quarter), 2)  AS cpl_change
FROM vw_marketing_kpi_dashboard
ORDER BY reporting_year, reporting_quarter;
```

> 📊 **MARKETING NUGGET** — Senior leaders care about trends, not point-in-time numbers. A ROAS of 3.2x is a good number. A ROAS of 3.2x that was 2.4x last year is a great story. A ROAS of 3.2x that was 4.1x last year is a crisis. The number without the trend is meaningless. Always present marketing KPIs with their direction of change.

---

## 7.2 First-Touch Attribution Model

Attribution is the practice of assigning credit for revenue to the marketing touchpoints that influenced it. First-touch gives 100% credit to the campaign that first generated the lead.

```sql
WITH lead_journey AS (
    SELECT
        l.lead_id,
        l.customer_id,
        l.deal_value,
        l.created_at                            AS first_touch_date,
        l.converted_at,
        c.channel                               AS first_touch_channel,
        c.campaign_name                         AS first_touch_campaign,
        c.campaign_type
    FROM leads l
    JOIN campaigns c ON l.campaign_id = c.campaign_id
    WHERE l.status    = 'converted'
      AND l.deal_value > 0
),
order_summary AS (
    SELECT customer_id,
           SUM(amount)  AS total_order_revenue,
           COUNT(*)     AS order_count
    FROM orders
    GROUP BY customer_id
),
attribution_base AS (
    SELECT
        lj.first_touch_channel,
        lj.first_touch_campaign,
        lj.deal_value                           AS pipeline_value,
        os.total_order_revenue                  AS actual_revenue,
        DATEDIFF(lj.converted_at, lj.first_touch_date) AS days_to_convert
    FROM lead_journey lj
    LEFT JOIN order_summary os ON lj.customer_id = os.customer_id
)
SELECT
    first_touch_channel,
    COUNT(*)                                    AS attributed_conversions,
    SUM(pipeline_value)                         AS total_pipeline,
    SUM(actual_revenue)                         AS total_revenue,
    ROUND(AVG(pipeline_value), 2)               AS avg_deal_size,
    ROUND(AVG(days_to_convert), 1)              AS avg_days_to_convert,
    ROUND(
        SUM(actual_revenue)
        / (SELECT SUM(actual_revenue) FROM attribution_base) * 100, 2
    )                                           AS revenue_share_pct
FROM attribution_base
GROUP BY first_touch_channel
ORDER BY total_revenue DESC;
```

> ⚠️ **WATCH OUT** — First-touch attribution overstates the value of awareness channels (like organic content and social) and understates the value of closing channels (like email nurture and retargeting). A prospect might first discover you through a blog post (organic), then see a LinkedIn ad, then open a nurture email, then request a demo. First-touch gives 100% credit to organic. Last-touch gives 100% credit to the email. Linear gives equal credit to all four. There is no "correct" model — the right model depends on what decision you are trying to make.

> 🎯 **CMO QUESTION** — *"Which channel deserves more budget next quarter?"* First-touch attribution tells you which channels are best at introducing new prospects to the brand — top-of-funnel efficiency. If you're trying to grow awareness, invest in the top first-touch channels. If you're trying to accelerate close rates, invest in the channels appearing most often as last-touch.

---

## 7.3 YoY Channel Performance Report via Stored Procedure

The `sp_yoy_channel_report` procedure wraps the YoY channel query into a callable unit:

```sql
-- Run the full YoY report for all channels
CALL sp_yoy_channel_report(NULL);

-- Run it for a specific channel
CALL sp_yoy_channel_report('Email');
CALL sp_yoy_channel_report('Paid');
CALL sp_yoy_channel_report('Social');
```

This is how analytics gets operationalized. Instead of a 60-line query that lives in someone's notebook, it's a named, callable procedure that anyone on the team can run. The result: consistent methodology, no copy-paste errors, and a single source of truth.

> 💡 **TIP & TRICK** — Stored procedures accept `NULL` as a wildcard in this project. The `WHERE (p_channel IS NULL OR channel = p_channel)` pattern inside the procedure means a NULL input returns all channels. This pattern avoids writing separate procedures for "all channels" vs "one channel" — one procedure handles both with a single parameter check.

---

## 7.4 Campaign Health Check Procedure

Before the weekly team meeting, run a health check on all active campaigns:

```sql
-- Check health of specific campaigns
CALL sp_campaign_health_check(22);
CALL sp_campaign_health_check(30);
CALL sp_campaign_health_check(34);
```

The procedure classifies each campaign as Healthy, On Track, At Risk, or Critical — and gives you the specific recommended action. This is the kind of automation that turns a 2-hour manual reporting process into a 10-second query.

> 📊 **MARKETING NUGGET** — In real marketing operations, campaign health checks run automatically every morning before the team arrives. Campaigns flagged "Critical" trigger a Slack alert. Campaigns flagged "Healthy" get an automated budget increase recommendation. This is the foundation of what marketing ops teams call "always-on optimization" — and SQL stored procedures are one of the core building blocks.

---

## Test Yourself — Module 07

**Question 1:** Which quarter in the dataset had the highest blended ROAS? What channel drove the most conversions that quarter?

**Question 2:** Using the attribution model, which channel has the shortest average days-to-convert? What does this mean strategically?

**Question 3:** Run `sp_campaign_health_check` on campaign IDs 1, 14, and 34. Which is healthiest? Which needs attention?

**Question 4:** Write a query showing the YoY change in conversion rate by channel (2023 vs 2024). Which channel improved the most?

---

### Answers

**Answer 1:**
```sql
SELECT reporting_year, reporting_quarter, blended_roas, total_spend
FROM vw_marketing_kpi_dashboard
ORDER BY blended_roas DESC
LIMIT 1;

-- Then find top channel in that quarter
SELECT c.channel, COUNT(CASE WHEN l.status='converted' THEN 1 END) AS conversions
FROM campaigns c JOIN leads l ON c.campaign_id = l.campaign_id
WHERE YEAR(c.start_date) = 2024 AND QUARTER(c.start_date) = 4  -- adjust to match
GROUP BY c.channel ORDER BY conversions DESC;
```

**Answer 2:**
```sql
-- Run the attribution CTE from section 7.2 and look at avg_days_to_convert
-- Referral channels typically show shortest days-to-convert because referred
-- prospects arrive pre-qualified with trust already established.
-- Strategically, this means referral programs have high velocity —
-- they close faster — which helps with quarterly revenue targets.
```

**Answer 3:**
```sql
CALL sp_campaign_health_check(1);
CALL sp_campaign_health_check(14);
CALL sp_campaign_health_check(34);
```
Campaigns with higher ROAS and conversion rate will be classified as Healthy. Closed campaigns with lower historical metrics will be At Risk or On Track depending on final numbers.

**Answer 4:**
```sql
SELECT
    channel,
    MAX(CASE WHEN campaign_year = 2023 THEN conversion_rate_pct END) AS conv_rate_2023,
    MAX(CASE WHEN campaign_year = 2024 THEN conversion_rate_pct END) AS conv_rate_2024,
    MAX(CASE WHEN campaign_year = 2024 THEN conversion_rate_pct END) -
    MAX(CASE WHEN campaign_year = 2023 THEN conversion_rate_pct END)  AS yoy_change
FROM vw_channel_yoy
GROUP BY channel
ORDER BY yoy_change DESC;
```

---

[← Module 06: Audiences](06_audience.md) | [Back to Index](README.md) | [Next: Module 08 — Trends →](08_trends.md)
