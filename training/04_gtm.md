# Module 04 — Google Tag Manager (GTM)

**Estimated time:** 45 minutes
**SQL skills:** `EXISTS` / `NOT EXISTS`, triggers, `GROUP BY` auditing, conditional aggregation
**Tables:** `gtm_tags`, `web_events`, `web_pages`

[← Module 03: Email](03_email.md) | [Back to Index](README.md) | [Next: Module 05 — Content →](05_content.md)

---

## What You Will Learn

- What GTM does and why it matters to analytics accuracy
- How to audit tag coverage across your site using SQL
- How `EXISTS` and `NOT EXISTS` find tracking gaps
- How SQL triggers mirror the logic of GTM triggers
- How to calculate CTA click rates by page and traffic source

---

## Engineering Lens — Before You Build Anything in This Module

> 💡 **Engineering Lens** — GTM data has a specific profiling question that differs from other channels: are all active tags actually firing? Profile `gtm_tags` vs `web_events` with a LEFT JOIN — any active tag with zero web events is a tracking gap, not a data quality problem, but you need to know it exists before building coverage reports on top of it. The `trg_leads_score_on_insert` trigger was created because lead scoring needed to happen automatically on every INSERT — not manually called, not in a procedure a human has to remember to run. The decision to make it a trigger rather than a procedure was made by asking: "Can this ever be skipped?" If the answer is no, it belongs in a trigger. If it can sometimes be skipped or run differently, it belongs in a procedure.

---

## 4.1 What GTM Does

Google Tag Manager is a container that sits on your website and fires tracking scripts (called "tags") based on user actions (called "triggers"). Without GTM, you need an engineer to add tracking code every time marketing wants to measure something new. With GTM, marketing can deploy tracking in minutes.

The `gtm_tags` table models 20 different tags you would find on a real marketing site:

```sql
SELECT tag_name, tag_type, trigger_type, trigger_detail, is_active
FROM gtm_tags
ORDER BY tag_type, tag_name;
```

**The most important tags:**
- **GA4 Event tags** — Send behavioral data to Google Analytics 4
- **Google Ads Conversion tags** — Tell Google which clicks resulted in conversions
- **Meta Pixel tags** — Power Facebook/Instagram remarketing audiences
- **LinkedIn tags** — Enable LinkedIn matched audiences and conversion tracking

> 📊 **MARKETING NUGGET** — Conversion tracking is the foundation of every PPC optimization decision. If your Google Ads conversion tag misfires — fires twice, or never fires — your CPA data is wrong. Your bid strategy is optimizing toward phantom conversions or ignoring real ones. Bad tracking = bad bidding = wasted budget. A GTM audit query is not a technical exercise; it is a budget protection exercise.

---

## 4.2 Tag Coverage Audit

Which pages have full conversion tracking coverage, and which have gaps?

```sql
SELECT
    wp.page_url,
    wp.page_type,
    wp.cta_text,
    COUNT(DISTINCT we.tag_id)                           AS tags_fired,
    SUM(CASE WHEN we.event_name = 'page_view'   THEN 1 ELSE 0 END) AS page_views,
    SUM(CASE WHEN we.event_name = 'cta_click'   THEN 1 ELSE 0 END) AS cta_clicks,
    SUM(CASE WHEN we.event_name = 'form_submit' THEN 1 ELSE 0 END) AS form_submits,
    CASE
        WHEN EXISTS (
            SELECT 1 FROM web_events we2
            WHERE we2.page_url  = wp.page_url
              AND we2.event_name = 'form_submit'
        ) THEN 'Yes' ELSE 'No'
    END                                                 AS has_conversion_tracking,
    ROUND(
        SUM(CASE WHEN we.event_name = 'cta_click' THEN 1 ELSE 0 END)
        / NULLIF(SUM(CASE WHEN we.event_name = 'page_view' THEN 1 ELSE 0 END), 0)
        * 100, 2
    )                                                   AS cta_click_rate_pct
FROM web_pages wp
LEFT JOIN web_events we ON wp.page_url = we.page_url
WHERE wp.is_active = 1
GROUP BY wp.page_url, wp.page_type, wp.cta_text
ORDER BY page_views DESC;
```

> 💡 **TIP & TRICK** — `EXISTS` is faster than `COUNT() > 0` for existence checks. MySQL stops scanning as soon as it finds one matching row. `COUNT() > 0` scans every matching row and then compares. For large event tables, this difference is measurable. Always use `EXISTS` when the question is "does at least one row match?" not "how many rows match?"

---

## 4.3 Tags That Fire But Never Convert — NOT EXISTS

These are tracking coverage gaps — tags firing on pages or for events that have no associated conversion event downstream.

```sql
SELECT
    t.tag_name,
    t.tag_type,
    t.trigger_type,
    COUNT(we.web_event_id)          AS total_fires
FROM gtm_tags t
JOIN web_events we ON t.tag_id = we.tag_id
WHERE t.is_active = 1
  AND NOT EXISTS (
      SELECT 1
      FROM   web_events we2
      WHERE  we2.tag_id     = t.tag_id
        AND  we2.event_name IN ('form_submit', 'purchase')
  )
GROUP BY t.tag_id, t.tag_name, t.tag_type, t.trigger_type
ORDER BY total_fires DESC;
```

> 🎯 **CMO QUESTION** — *"Can we trust our conversion numbers?"* This query surfaces tags that are technically firing but never recording a conversion. If your Google Ads Conversion tag appears here, you have a tracking problem — and every optimization decision made from that data is suspect. This is the kind of query that uncovers six-figure attribution errors.

---

## 4.4 SQL Triggers — The GTM of the Database

Just as GTM triggers fire tags when user actions occur, SQL triggers fire code when database events occur. The parallel is exact:

| GTM Concept | SQL Concept |
|-------------|-------------|
| Container | Database |
| Tag | Trigger action (INSERT / UPDATE / DELETE logic) |
| Trigger (rule) | `BEFORE INSERT`, `AFTER UPDATE`, etc. |
| Preview mode | Testing the trigger with sample data |

Review the triggers created in `07_triggers.sql`:

```sql
-- This trigger fires every time a new lead is inserted
-- It auto-assigns a score based on source and deal value
-- BEFORE INSERT means it modifies the data before it's saved

-- The GTM equivalent: "When a form is submitted (trigger),
-- fire the lead scoring tag (action)"
```

```sql
-- Test that the auto-scoring trigger works
INSERT INTO leads
    (campaign_id, email, first_name, last_name, lead_source, status, deal_value)
VALUES
    (22, 'gtm.test@example.com', 'GTM', 'Test', 'Referral', 'new', 45000.00);

-- Check what score was auto-assigned
SELECT lead_id, lead_source, deal_value, score,
       fn_lead_score_tier(score) AS tier
FROM leads
WHERE email = 'gtm.test@example.com';
```

> 💡 **TIP & TRICK** — The `BEFORE INSERT` trigger in this project sets a lead score automatically, so callers don't have to calculate it. This is the database equivalent of a calculated field — business logic enforced at the data layer, not the application layer. If the scoring formula changes, you update one trigger, and every future lead gets the new formula automatically.

---

## Test Yourself — Module 04

**Question 1:** How many distinct event types are recorded in `web_events`? List them.

**Question 2:** Which tag fired the most total times? What type of tag is it?

**Question 3:** Write a query showing the CTA click rate for each page type (homepage, landing_page, product, blog). Which page type has the highest CTA engagement?

**Question 4:** Which traffic source drives the most `form_submit` events?

---

### Answers

**Answer 1:**
```sql
SELECT DISTINCT event_name, COUNT(*) AS occurrences
FROM web_events
GROUP BY event_name
ORDER BY occurrences DESC;
```

**Answer 2:**
```sql
SELECT t.tag_name, t.tag_type, COUNT(we.web_event_id) AS fires
FROM gtm_tags t
JOIN web_events we ON t.tag_id = we.tag_id
GROUP BY t.tag_id, t.tag_name, t.tag_type
ORDER BY fires DESC
LIMIT 1;
```

**Answer 3:**
```sql
SELECT
    wp.page_type,
    SUM(CASE WHEN we.event_name = 'cta_click'  THEN 1 ELSE 0 END) AS cta_clicks,
    SUM(CASE WHEN we.event_name = 'page_view'  THEN 1 ELSE 0 END) AS page_views,
    ROUND(SUM(CASE WHEN we.event_name = 'cta_click' THEN 1 ELSE 0 END)
        / NULLIF(SUM(CASE WHEN we.event_name = 'page_view' THEN 1 ELSE 0 END), 0)
        * 100, 2) AS cta_click_rate_pct
FROM web_pages wp
LEFT JOIN web_events we ON wp.page_url = we.page_url
GROUP BY wp.page_type
ORDER BY cta_click_rate_pct DESC;
```

**Answer 4:**
```sql
SELECT traffic_source, COUNT(*) AS form_submits
FROM web_events
WHERE event_name = 'form_submit'
GROUP BY traffic_source
ORDER BY form_submits DESC;
```

---

[← Module 03: Email](03_email.md) | [Back to Index](README.md) | [Next: Module 05 — Content →](05_content.md)
