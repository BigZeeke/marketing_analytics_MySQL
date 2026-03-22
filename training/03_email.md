# Module 03 — Email Marketing

**Estimated time:** 60 minutes
**SQL skills:** Views, conditional aggregation, moving averages, `fn_email_health_grade()` UDF
**Tables:** `email_campaigns`, `email_events`, `customers`

[← Module 02: PPC](02_ppc.md) | [Back to Index](README.md) | [Next: Module 04 — GTM →](04_gtm.md)

---

## What You Will Learn

- The email marketing funnel and how each stage maps to event types in the database
- How to calculate open rate, CTOR, and conversion rate using conditional aggregation
- How to use a View to simplify recurring email reports
- How to detect list health problems before they hurt deliverability
- How to use the `fn_email_health_grade()` UDF for instant grading

---

## Engineering Lens — Before You Build Anything in This Module

> 💡 **Engineering Lens** — Profile `email_events` before writing email metrics. The most important profiling question here is: what event types actually exist in the data? Run `SELECT DISTINCT event_type FROM email_events` — if your profiling reveals that `delivered` events are missing, your deliverability rate calculation will be wrong before you even write it. The composite index `idx_emailevents_campaign_event (email_campaign_id, event_type)` was designed specifically because the core email funnel query always filters by both columns simultaneously. The `vw_email_metrics` view exists because this query shape runs after every single email send — always the same structure, never parameterized. The `fn_email_health_grade()` UDF exists because open rate grading appeared in the view, in reporting procedures, and in ad-hoc analyses — three places, so it became a function.

---

## 3.1 The Email Funnel

Email marketing has a defined funnel with a specific metric at each stage:

```
List Size
  → Delivered       (deliverability rate = delivered / sent)
    → Opened        (open rate = opened / delivered)
      → Clicked     (CTOR = clicked / opened)
        → Converted (conversion rate = converted / delivered)
          → Unsubscribed / Bounced  (health signals)
```

Every stage has a benchmark. If you fall below the benchmark, something is wrong at that stage specifically.

| Metric | Industry benchmark | Formula |
|--------|--------------------|---------|
| Deliverability | > 95% | delivered / sent |
| Open rate | 20–30% B2B | opened / list_size |
| CTOR | 10–20% | clicked / opened |
| Conversion rate | 1–5% | converted / list_size |
| Unsubscribe rate | < 0.5% | unsubs / list_size |

> 📊 **MARKETING NUGGET** — Low open rate = a subject line problem (or a list quality problem). Low CTOR = a content problem — people opened but the email didn't compel them to click. Low conversion rate with high CTOR = a landing page problem — they clicked but the page didn't close them. Each metric points to a different part of the funnel. This is why you measure all of them, not just "email performance."

---

## 3.2 Building the Email Funnel Query

```sql
SELECT
    ec.email_name,
    ec.subject_line,
    ec.email_type,
    ec.audience_segment,
    ec.list_size,
    DATE_FORMAT(ec.send_date, '%Y-%m-%d')                   AS send_date,
    SUM(CASE WHEN ee.event_type = 'opened'       THEN 1 ELSE 0 END) AS opens,
    SUM(CASE WHEN ee.event_type = 'clicked'      THEN 1 ELSE 0 END) AS clicks,
    SUM(CASE WHEN ee.event_type = 'converted'    THEN 1 ELSE 0 END) AS conversions,
    SUM(CASE WHEN ee.event_type = 'unsubscribed' THEN 1 ELSE 0 END) AS unsubs,
    SUM(CASE WHEN ee.event_type = 'bounced'      THEN 1 ELSE 0 END) AS bounces,
    ROUND(
        SUM(CASE WHEN ee.event_type = 'opened' THEN 1 ELSE 0 END)
        / NULLIF(ec.list_size, 0) * 100, 2
    )                                                       AS open_rate_pct,
    ROUND(
        SUM(CASE WHEN ee.event_type = 'clicked' THEN 1 ELSE 0 END)
        / NULLIF(SUM(CASE WHEN ee.event_type = 'opened' THEN 1 ELSE 0 END), 0)
        * 100, 2
    )                                                       AS ctor_pct,
    ROUND(
        SUM(CASE WHEN ee.event_type = 'converted' THEN 1 ELSE 0 END)
        / NULLIF(ec.list_size, 0) * 100, 2
    )                                                       AS conv_rate_pct
FROM email_campaigns ec
LEFT JOIN email_events ee ON ec.email_campaign_id = ee.email_campaign_id
GROUP BY ec.email_campaign_id, ec.email_name, ec.subject_line,
         ec.email_type, ec.audience_segment, ec.list_size, ec.send_date
ORDER BY ec.send_date;
```

> 💡 **TIP & TRICK** — `LEFT JOIN` is critical here. If an email was sent but no events were recorded yet, an `INNER JOIN` would drop that campaign from the results entirely. With `LEFT JOIN`, campaigns with zero events appear with NULL counts — which you then catch with `COALESCE` or `CASE WHEN`. Always use `LEFT JOIN` when you need "all campaigns, with metrics if they exist."

---

## 3.3 Using the vw_email_metrics View

The view in `04_views.sql` pre-computes all of this. Once loaded, your reporting query becomes:

```sql
-- Instead of the 40-line query above, just use the view
SELECT
    email_name,
    email_type,
    audience_segment,
    list_size,
    open_rate_pct,
    ctor_pct,
    conv_rate_pct,
    fn_email_health_grade(open_rate_pct)    AS email_grade,
    send_year
FROM vw_email_metrics
ORDER BY send_date;
```

> 💡 **TIP & TRICK** — Views are reusable query abstractions. They do not store data — they store the query definition. Every time you `SELECT` from a view, MySQL runs the underlying query. Use views for complex metrics you query repeatedly. The benefit: when the calculation changes (say, you decide to measure open rate against delivered instead of list_size), you update the view once, and every query that uses it automatically gets the new logic.

> 🎯 **CMO QUESTION** — *"How is our email program performing compared to last year?"* Filter `send_year` in the view and compare open rates, CTOR, and conversion rates. Year-over-year improvement in these metrics signals that your segmentation, subject line testing, and content quality are improving. Decline signals list fatigue or deliverability problems.

---

## 3.4 Email Health Grade UDF

The `fn_email_health_grade()` function assigns a letter grade based on open rate:

```sql
SELECT
    email_name,
    open_rate_pct,
    fn_email_health_grade(open_rate_pct) AS grade
FROM vw_email_metrics
ORDER BY open_rate_pct DESC;
```

| Grade | Open Rate | Interpretation |
|-------|-----------|---------------|
| A | ≥ 35% | Excellent — highly engaged list and strong subject lines |
| B | 25–34% | Good — above industry average |
| C | 18–24% | Average — room for improvement in subject lines or segmentation |
| D | 10–17% | Below average — list health or relevance issue |
| F | < 10% | Critical — investigate deliverability and list quality immediately |

---

## 3.5 Moving Average — Is Email Getting Better Over Time?

```sql
WITH email_monthly AS (
    SELECT
        email_type,
        send_date,
        email_name,
        list_size,
        open_rate_pct
    FROM vw_email_metrics
    WHERE open_rate_pct IS NOT NULL
)
SELECT
    email_type,
    send_date,
    email_name,
    open_rate_pct,
    ROUND(AVG(open_rate_pct) OVER (
        PARTITION BY email_type
        ORDER BY     send_date
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 2)                                       AS rolling_3send_avg
FROM email_monthly
ORDER BY email_type, send_date;
```

If `rolling_3send_avg` is trending upward over time, your email program is improving. If it's flat or declining, there's a problem worth investigating.

---

## Test Yourself — Module 03

**Question 1:** Which email campaign had the highest CTOR (click-to-open rate)? What type of email was it?

**Question 2:** What is the average open rate for promotional emails vs nurture emails? Which performs better?

**Question 3:** Write a query that returns all email campaigns where the unsubscribe count is greater than zero. What should you do with this information?

**Question 4:** How many email events of each type exist in the database? (opened, clicked, converted, unsubscribed, bounced)

**Question 5 (Challenge):** Write a query that compares each email campaign's open rate to the average open rate for that email type, and flags campaigns that are more than 5 percentage points below the type average.

---

### Answers

**Answer 1:**
```sql
SELECT email_name, email_type, ctor_pct
FROM vw_email_metrics
WHERE ctor_pct IS NOT NULL
ORDER BY ctor_pct DESC
LIMIT 5;
```

**Answer 2:**
```sql
SELECT email_type, ROUND(AVG(open_rate_pct), 2) AS avg_open_rate
FROM vw_email_metrics
GROUP BY email_type
ORDER BY avg_open_rate DESC;
```

**Answer 3:**
```sql
SELECT
    ec.email_name,
    ec.audience_segment,
    ec.list_size,
    SUM(CASE WHEN ee.event_type = 'unsubscribed' THEN 1 ELSE 0 END) AS unsubs,
    ROUND(SUM(CASE WHEN ee.event_type = 'unsubscribed' THEN 1 ELSE 0 END)
        / NULLIF(ec.list_size, 0) * 100, 3) AS unsub_rate_pct
FROM email_campaigns ec
JOIN email_events ee ON ec.email_campaign_id = ee.email_campaign_id
GROUP BY ec.email_campaign_id, ec.email_name, ec.audience_segment, ec.list_size
HAVING unsubs > 0
ORDER BY unsub_rate_pct DESC;
```
High unsub rates signal the content was irrelevant to that segment, the send frequency was too high, or the audience expectation wasn't set correctly during signup. Investigate the top offenders first.

**Answer 4:**
```sql
SELECT event_type, COUNT(*) AS event_count
FROM email_events
GROUP BY event_type
ORDER BY event_count DESC;
```

**Answer 5 (Challenge):**
```sql
WITH type_avg AS (
    SELECT email_type, AVG(open_rate_pct) AS avg_open_rate
    FROM vw_email_metrics
    GROUP BY email_type
)
SELECT
    m.email_name,
    m.email_type,
    m.open_rate_pct,
    ROUND(ta.avg_open_rate, 2)          AS type_avg,
    ROUND(m.open_rate_pct - ta.avg_open_rate, 2) AS gap
FROM vw_email_metrics m
JOIN type_avg ta ON m.email_type = ta.email_type
WHERE m.open_rate_pct < ta.avg_open_rate - 5
ORDER BY gap;
```

---

[← Module 02: PPC](02_ppc.md) | [Back to Index](README.md) | [Next: Module 04 — GTM →](04_gtm.md)
