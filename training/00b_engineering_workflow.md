# Module 00B — The Analytics Engineering Workflow

**Estimated time:** 60 minutes
**This module is the recipe. Every other module is an application of it.**

[← Module 00: Foundations](00_foundations.md) | [Back to Index](README.md) | [Next: Module 01 — SEO →](01_seo.md)

---

## Why This Module Exists

Module 00 taught you how to navigate a database. The marketing modules (01–10) teach you what each metric means and how to query it. This module teaches you the **professional discipline that connects them** — how an Analytics Engineer actually thinks about building a data system from scratch.

The order matters more than the objects. A senior engineer with no knowledge of your specific business can build a reliable analytics system on any dataset because they follow a repeatable process. That process is what this module teaches.

**The core principle:** Objects emerge from evidence. You do not decide upfront what indexes, views, procedures, and triggers to create. You discover what is needed by profiling the data, writing the queries, measuring their cost, and then building exactly what the evidence demands — nothing more.

---

## The Real Build Order

This is the workflow a professional Analytics Engineer follows on every project:

```
Step 1 — Understand the business questions (before any code)
Step 2 — Profile the raw data (understand before you transform)
Step 3 — Write raw analytical queries (validate logic first)
Step 4 — Run EXPLAIN on slow queries (measure before you optimize)
Step 5 — Create indexes (based on real query evidence)
Step 6 — Create UDFs (calculations used in 2+ places)
Step 7 — Create Triggers (automatic data integrity rules)
Step 8 — Create Views (frequently queried, parameterless logic)
Step 9 — Create Stored Procedures (parameterized or scheduled logic)
Step 10 — Validate end to end (check results, edge cases, performance)
Step 11 — Document (what each object does and why it exists)
```

Each step is covered in detail below. The one-page cheat sheet at the end of this module is the reference you will use on every future project.

---

## Step 1 — Understand the Business Questions

Before writing a single line of SQL, answer these questions by talking to the stakeholders who will consume the data:

- What decisions does this data need to support?
- What questions get asked every week in every meeting?
- What reports exist today and where do they break or take too long?
- Who consumes this — analysts, executives, operations teams?
- How fresh does the data need to be — real time, daily, weekly?
- What is the grain of the data? One row equals one what?

**Applied to this project:**

| Business question | Consumer | Frequency | Grain |
|---|---|---|---|
| Which channels deliver the best ROAS? | CMO | Weekly | One row per campaign per week |
| Are lead scores predicting conversion? | Sales ops | Daily | One row per lead |
| Which email campaigns are improving? | Email team | Per send | One row per email campaign |
| Where are website visitors dropping off? | Growth team | Weekly | One row per session |

> 📊 **MARKETING NUGGET** — At VCA this is the conversation you have with the contact center leadership before building a single notebook cell. "What do you look at every Monday morning and what takes you the longest to produce?" That answer is your build list. Every object you create should map back to a specific question on that list. If you cannot name the business question an object answers, question whether it needs to exist.

**Deliverable from Step 1:** A ranked list of business questions. Not a schema. Not a query. A list.

---

## Step 2 — Profile the Raw Data

Data profiling is the most skipped step in analytics engineering and the source of most downstream bugs. You cannot build reliable metrics on data you have not examined.

Run these profiling queries against every table you plan to use before writing any analytical logic.

### Profile 1 — Row Counts and Date Ranges

```sql
SELECT 'campaigns' AS tbl, COUNT(*) AS rows,
    MIN(start_date) AS earliest, MAX(start_date) AS latest
FROM campaigns
UNION ALL
SELECT 'leads', COUNT(*), MIN(created_at), MAX(created_at) FROM leads
UNION ALL
SELECT 'orders', COUNT(*), MIN(order_date), MAX(order_date) FROM orders
UNION ALL
SELECT 'ad_performance', COUNT(*), MIN(perf_date), MAX(perf_date) FROM ad_performance
UNION ALL
SELECT 'email_events', COUNT(*), MIN(event_at), MAX(event_at) FROM email_events
UNION ALL
SELECT 'seo_rankings', COUNT(*), MIN(ranking_date), MAX(ranking_date) FROM seo_rankings;
```

**What you are looking for:** Are date ranges complete? Are row counts what you expect? A leads table with 10 rows when you expected 10,000 means the data load failed — catch this before building 20 views on top of it.

### Profile 2 — NULL Rates on Key Columns

```sql
SELECT
    COUNT(*)                                                AS total_leads,
    SUM(CASE WHEN deal_value   IS NULL THEN 1 ELSE 0 END)  AS null_deal_value,
    SUM(CASE WHEN score        IS NULL THEN 1 ELSE 0 END)  AS null_score,
    SUM(CASE WHEN customer_id  IS NULL THEN 1 ELSE 0 END)  AS null_customer_id,
    SUM(CASE WHEN converted_at IS NULL THEN 1 ELSE 0 END)  AS null_converted_at,
    ROUND(SUM(CASE WHEN deal_value IS NULL THEN 1 ELSE 0 END)
        / COUNT(*) * 100, 1)                               AS pct_null_deal_value
FROM leads;
```

**What you are looking for:** A column with 80% NULL rate is either intentionally sparse (deal_value is only populated for converted leads) or broken (a pipeline that failed to load values). You need to know which before aggregating that column.

> ⚠️ **WATCH OUT** — `AVG(deal_value)` excludes NULLs automatically. If 70% of deal_value rows are NULL, your average is computed over only 30% of leads — the converted ones. This is actually correct behavior for deal value, but could be wrong for other columns. Always profile NULL rates before aggregating so you know exactly what denominator your averages are using.

### Profile 3 — Cardinality of Filter Columns

```sql
SELECT
    COUNT(DISTINCT channel)         AS distinct_channels,
    COUNT(DISTINCT campaign_type)   AS distinct_types,
    COUNT(DISTINCT status)          AS distinct_statuses,
    COUNT(DISTINCT YEAR(start_date)) AS distinct_years
FROM campaigns;

SELECT
    COUNT(DISTINCT lead_source)     AS distinct_sources,
    COUNT(DISTINCT status)          AS distinct_statuses
FROM leads;
```

**What you are looking for:** Cardinality tells you two things. First, whether a column is useful for GROUP BY (a column with 2 distinct values produces a 2-row summary — useful. A column with 50,000 distinct values produces a 50,000-row summary — probably not what you want). Second, whether a column is a good index candidate (high cardinality = good index candidate, low cardinality alone = poor index candidate).

### Profile 4 — Value Distribution

```sql
-- Are leads evenly distributed across statuses or heavily skewed?
SELECT
    status,
    COUNT(*)                                            AS cnt,
    ROUND(COUNT(*) / SUM(COUNT(*)) OVER () * 100, 1)   AS pct
FROM leads
GROUP BY status
ORDER BY cnt DESC;

-- Are campaigns evenly distributed across channels?
SELECT
    channel,
    COUNT(*)                                            AS campaigns,
    ROUND(COUNT(*) / SUM(COUNT(*)) OVER () * 100, 1)   AS pct
FROM campaigns
GROUP BY channel
ORDER BY campaigns DESC;
```

**What you are looking for:** Heavy skew affects your analysis. If 85% of leads come from one campaign, your channel-level averages will be dominated by that campaign's characteristics. Know the distribution before presenting averages as representative.

### Profile 5 — Duplicate Check

```sql
-- Check for duplicate leads by email within the same campaign
SELECT email, campaign_id, COUNT(*) AS occurrences
FROM leads
GROUP BY email, campaign_id
HAVING COUNT(*) > 1;

-- Check for duplicate ranking snapshots
SELECT keyword_id, ranking_date, COUNT(*) AS occurrences
FROM seo_rankings
GROUP BY keyword_id, ranking_date
HAVING COUNT(*) > 1;
```

**What you are looking for:** Duplicates inflate every count and aggregate. A lead that appears twice doubles its contribution to conversion rate. Find duplicates at this stage, not after building 15 views on top of them.

> 💡 **TIP & TRICK** — Save your profiling queries in a file called `00_data_profile.sql` in every project. Run it at the start of every sprint and after every data load. The output becomes your data quality baseline — when a number changes unexpectedly, you run the profile again and compare. In dbt, this is formalized as schema tests. In Databricks, it is Delta Lake data quality checks. In MySQL, it is this file.

---

## Step 3 — Write Raw Analytical Queries First

This is the most important rule in this entire guide:

**Write the analysis queries against base tables before creating any views, procedures, or indexes.**

The temptation is to jump straight to building objects. Resist it. Write the ugly, long query first. Validate that it returns correct results. Only then decide whether it deserves to become a view or a procedure.

```sql
-- Write this first — ugly but correct
SELECT
    c.channel,
    YEAR(c.start_date)                              AS yr,
    COUNT(l.lead_id)                                AS total_leads,
    SUM(CASE WHEN l.status = 'converted'
        THEN 1 ELSE 0 END)                          AS conversions,
    ROUND(
        SUM(CASE WHEN l.status = 'converted'
            THEN 1 ELSE 0 END)
        / NULLIF(COUNT(l.lead_id), 0) * 100, 2
    )                                               AS conv_rate_pct,
    SUM(c.spend)                                    AS total_spend,
    ROUND(
        COALESCE(SUM(l.deal_value), 0)
        / NULLIF(SUM(c.spend), 0), 2
    )                                               AS roas
FROM campaigns c
LEFT JOIN leads l ON c.campaign_id = l.campaign_id
GROUP BY c.channel, YEAR(c.start_date)
ORDER BY c.channel, yr;
```

Run it. Check the numbers. Then ask:

- Is this result correct based on what I know about the data?
- Does it handle NULLs correctly?
- Is it slow?
- Will I run this same query multiple times?

If the answer to the last two questions is yes, you have identified a view and a potential index candidate.

---

## Step 4 — EXPLAIN Driven Index Design

You do not create indexes based on theory. You create them based on evidence from real queries.

**The process is always the same three steps:**

### Step 4a — Run EXPLAIN before adding any indexes

```sql
EXPLAIN
SELECT c.channel, COUNT(l.lead_id) AS leads
FROM campaigns c
LEFT JOIN leads l ON c.campaign_id = l.campaign_id
WHERE c.channel = 'Paid'
  AND YEAR(c.start_date) = 2024
GROUP BY c.channel;
```

Read the output. The columns that matter most:

| Column | Red flag | Good sign |
|--------|----------|-----------|
| `type` | `ALL` = full table scan | `ref`, `range`, `eq_ref` = index used |
| `key` | `NULL` = no index used | Index name = index found and used |
| `rows` | High number = reading many unnecessary rows | Low number = targeted scan |
| `Extra` | `Using filesort`, `Using temporary` | `Using index` = covering index hit |

### Step 4b — Identify index candidates from the query

The columns that should be indexed are the ones that appear in:

```sql
WHERE column = value          -- equality filter
WHERE column BETWEEN a AND b  -- range filter
JOIN ON table.column          -- join condition (foreign keys)
GROUP BY column               -- grouping column
ORDER BY column               -- sort column (if also filtered)
```

From the query above:
- `campaigns.channel` — appears in WHERE
- `campaigns.start_date` — appears in WHERE (as YEAR() function — see warning below)
- `leads.campaign_id` — appears in JOIN ON

### Step 4c — Create the index and re-run EXPLAIN

```sql
-- Create the index
CREATE INDEX idx_campaigns_channel_start
    ON campaigns (channel, start_date);

CREATE INDEX idx_leads_campaign_id
    ON leads (campaign_id);

-- Re-run EXPLAIN and compare
EXPLAIN
SELECT c.channel, COUNT(l.lead_id) AS leads
FROM campaigns c
LEFT JOIN leads l ON c.campaign_id = l.campaign_id
WHERE c.channel = 'Paid'
  AND YEAR(c.start_date) = 2024
GROUP BY c.channel;
```

Compare `type` and `rows` before and after. The improvement is your evidence that the index is working.

> ⚠️ **WATCH OUT — The Function Trap** — `WHERE YEAR(start_date) = 2024` is non-sargable. Wrapping a column in a function breaks index usage because MySQL cannot use the index to find `YEAR(start_date) = 2024` — it has to compute `YEAR()` for every row first. Always rewrite function-wrapped filters as range conditions:
> ```sql
> -- Non-sargable (index not used)
> WHERE YEAR(start_date) = 2024
>
> -- Sargable (index used)
> WHERE start_date BETWEEN '2024-01-01' AND '2024-12-31'
> ```
> This single habit change can make queries 10–100x faster on large tables.

**The index decision framework:**

| Scenario | Index strategy |
|----------|---------------|
| Foreign key column | Always index — every FK needs an index |
| Column in WHERE equality filter | Single column index |
| Two columns always filtered together | Composite index, most selective first |
| Query only reads indexed columns | Covering index — add all SELECT columns |
| Long VARCHAR in WHERE | Prefix index `(column(100))` |
| Low cardinality column alone | Not worth it — combine with high cardinality column |
| Column only in SELECT, never in WHERE/JOIN | Do not index |

> 💡 **TIP & TRICK** — Indexes have a write cost. Every INSERT, UPDATE, and DELETE must also update every index on that table. In analytics workloads that are read-heavy this is rarely a problem. In transactional systems with high insert volume, too many indexes slow down writes. Know your workload before indexing everything. The rule of thumb: index for your most frequent and most expensive read queries, then check write performance.

---

## Step 5 — The Object Decision Framework

After validating your raw queries, apply this decision tree to every query to determine what object, if any, it should become:

```
Is this calculation used in multiple queries or objects?
    YES → Create a UDF (User-Defined Function)
    NO  → Inline the calculation

Does this query need to run automatically when data changes?
    YES → Create a Trigger
    NO  → Continue

Does this query run repeatedly with no parameters?
    YES → Create a View
    NO  → Continue

Does this query take parameters (date range, channel, campaign ID)?
    YES → Create a Stored Procedure
    NO  → Save as a named query in your query library

Is this a one-time analysis?
    YES → Keep it as an ad-hoc query, do not create an object
```

**Applied to this project:**

| Query | Decision | Reason |
|-------|----------|--------|
| ROAS calculation | UDF `fn_calculate_roas()` | Used in 6 views and procedures |
| Lead scoring on insert | Trigger `trg_leads_score_on_insert` | Must run automatically, not manually called |
| Campaign performance summary | View `vw_campaign_performance` | Run daily, same shape, no parameters |
| YoY channel report | Stored Procedure `sp_yoy_channel_report` | Takes a channel parameter |
| Lead quality by campaign | Stored Procedure `sp_lead_quality_summary` | Takes a campaign_id parameter |
| One-time data profile | Ad-hoc query | Run once, no reuse value |

> 📊 **MARKETING NUGGET** — The discipline of asking "should this be an object?" before creating it is what separates a maintainable analytics system from a pile of queries nobody understands. Every object you create is a commitment — someone has to maintain it, document it, and update it when the business logic changes. Create objects deliberately, not habitually.

---

## Step 6 — The Dependency Order

Objects depend on each other. Build them in dependency order or you will hit errors when one object tries to call another that does not exist yet.

```
Raw tables
    ↓
Indexes        (tables must exist before you can index them)
    ↓
UDFs           (no dependencies — pure functions)
    ↓
Triggers       (depend on tables, may call UDFs)
    ↓
Views          (depend on tables and UDFs)
    ↓
Stored Procedures  (depend on tables, views, and UDFs)
    ↓
Analytical queries  (depend on everything above)
```

**The test:** Before creating any object, ask "what does this object depend on?" Every dependency must already exist. If it does not, build the dependency first.

---

## Step 7 — Validation

Before calling any object production-ready, validate it against three types of tests:

### Correctness Tests

```sql
-- Does the view return the right number of rows?
SELECT COUNT(*) FROM vw_campaign_performance;
-- Should equal the number of campaigns in the base table
SELECT COUNT(*) FROM campaigns;

-- Does the ROAS calculation match manual calculation?
SELECT
    campaign_id,
    fn_calculate_roas(
        (SELECT SUM(deal_value) FROM leads l WHERE l.campaign_id = c.campaign_id),
        c.spend
    ) AS fn_roas,
    -- Manual calculation for comparison
    ROUND(
        (SELECT COALESCE(SUM(deal_value), 0) FROM leads l WHERE l.campaign_id = c.campaign_id)
        / NULLIF(c.spend, 0), 2
    ) AS manual_roas
FROM campaigns c
WHERE spend > 0
LIMIT 10;
-- Both columns should match exactly
```

### Edge Case Tests

```sql
-- Does it handle zero spend without dividing by zero?
SELECT fn_calculate_roas(50000, 0);   -- should return NULL, not error

-- Does it handle NULL deal values?
SELECT fn_calculate_roas(NULL, 5000); -- should return NULL

-- Does the lead scoring trigger handle a lead with no deal value?
INSERT INTO leads (campaign_id, email, first_name, last_name, lead_source, status)
VALUES (22, 'edge.test@example.com', 'Edge', 'Test', 'Organic', 'new');
-- deal_value is omitted — trigger should still assign a score
SELECT lead_id, score FROM leads WHERE email = 'edge.test@example.com';
```

### Performance Tests

```sql
-- Time the view query before and after indexes
SET profiling = 1;
SELECT * FROM vw_campaign_performance;
SHOW PROFILES;
-- Compare duration before and after index creation
```

---

## Step 8 — Documentation

Every object you create should have a comment block that answers:

- What does this object do?
- What business question does it answer?
- What tables does it depend on?
- Who uses it and how often?
- When was it last changed and why?

```sql
-- ============================================================
-- VIEW: vw_campaign_performance
-- Purpose: Summarizes spend, leads, conversions, and ROAS
--          per campaign for use in weekly performance reports
-- Business question: Which campaigns are delivering best ROAS?
-- Depends on: campaigns, leads
-- Consumers: Marketing dashboard, sp_yoy_channel_report
-- Refresh: Real-time (view, not materialized)
-- Last updated: 2024-01-15 — added budget_utilization_pct
-- ============================================================
CREATE OR REPLACE VIEW vw_campaign_performance AS
...
```

> 💡 **TIP & TRICK** — In dbt, this documentation lives in `.yml` files alongside your models and is rendered automatically into a browsable data catalog. In Databricks, it lives in Unity Catalog column descriptions. In MySQL, it lives in comment blocks. The tool changes — the discipline does not. Always document the "why" not just the "what." Anyone can read the SQL and understand what it does. Only the author knows why it was built that way.

---

## The One-Page Cheat Sheet

Print this. Pin it next to your monitor. Use it on every project.

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
ANALYTICS ENGINEERING BUILD RECIPE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

BEFORE YOU WRITE CODE
□ What business questions need to be answered?
□ What is the grain of each table?
□ Who consumes this and how often?
□ How fresh does the data need to be?

DATA PROFILING (run on every table)
□ Row counts and date ranges
□ NULL rates on key columns
□ Cardinality of filter columns
□ Distribution of categorical values
□ Duplicate check on natural keys

WRITE RAW QUERIES FIRST
□ Write the ugliest version that works
□ Validate results against known numbers
□ Check NULL handling explicitly
□ Time the query

EXPLAIN BEFORE INDEXING
□ Run EXPLAIN on every slow query
□ Look for type: ALL (full scan = no index)
□ Look for key: NULL (no index used)
□ Rewrite function-wrapped filters as ranges
□ Create indexes based on evidence
□ Re-run EXPLAIN to confirm improvement

OBJECT DECISION FRAMEWORK
□ Calculation used in 2+ places → UDF
□ Must run automatically on data change → Trigger
□ Frequently queried, no parameters → View
□ Parameterized or scheduled → Stored Procedure
□ One-time analysis → Ad-hoc query only

BUILD ORDER (always)
□ 1. Raw tables
□ 2. Indexes
□ 3. UDFs
□ 4. Triggers
□ 5. Views
□ 6. Stored Procedures
□ 7. Validate (correctness + edge cases + performance)
□ 8. Document

VALIDATION CHECKLIST
□ Row counts match expectations
□ Results match manual calculations
□ Zero and NULL inputs handled
□ EXPLAIN shows index usage
□ Performance acceptable at scale
□ Edge cases tested
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## How This Applies to Every Module That Follows

Every marketing module (01–10) in this guide includes an **Engineering Lens** callout that applies this workflow to that specific domain. The pattern is always the same:

1. Profile the domain-specific tables first
2. Write the raw analytical query
3. Run EXPLAIN to identify index candidates
4. Identify which queries deserve to become views or procedures
5. Build the objects
6. Validate and document

By Module 10 you will have followed this workflow ten times across ten different domains. That repetition is what builds the habit — and the habit is what makes you an Analytics Engineer rather than someone who writes SQL queries.

---

## Test Yourself — Module 00B

**Question 1:** Run the five profiling queries against the `marketing_analytics` database. What is the NULL rate on `leads.deal_value`? Is this expected or a data quality problem?

**Question 2:** Run EXPLAIN on this query before any indexes are created. What does `type` show for the `leads` table? What does this tell you?
```sql
SELECT campaign_id, COUNT(*) FROM leads WHERE status = 'converted' GROUP BY campaign_id;
```

**Question 3:** After running `10_indexes.sql`, run the same EXPLAIN again. What changed? What is the performance improvement?

**Question 4:** Apply the object decision framework to these four queries and state what each should become:
- A query that calculates email open rate — used in 5 different reports
- A query that runs every time a new order is inserted to update a customer's total spend
- A query that returns campaign performance filtered by channel and year
- A one-time query you ran to investigate a specific data anomaly last Tuesday

**Question 5 (Challenge):** Write a profiling query that checks referential integrity — are there any leads with a `campaign_id` that does not exist in the `campaigns` table? Why would this matter for your attribution analysis?

---

### Answers

**Answer 1:**
```sql
SELECT
    COUNT(*)                                                AS total_leads,
    SUM(CASE WHEN deal_value IS NULL THEN 1 ELSE 0 END)    AS null_deal_value,
    ROUND(SUM(CASE WHEN deal_value IS NULL THEN 1 ELSE 0 END)
        / COUNT(*) * 100, 1)                               AS pct_null_deal_value
FROM leads;
```
A high NULL rate on `deal_value` is expected and correct — deal value is only populated when a lead converts. Unconverted leads have no deal value yet. This is intentional sparse data, not a pipeline failure. However if you see 0% NULL rate, that would be the data quality problem — it would mean unconverted leads have been assigned deal values incorrectly.

**Answer 2:**
```sql
EXPLAIN
SELECT campaign_id, COUNT(*) FROM leads WHERE status = 'converted' GROUP BY campaign_id;
```
Before indexes: `type: ALL` on leads — MySQL reads every row in the table to find converted leads. On 300 rows this is fast. On 3 million rows this would be very slow.

**Answer 3:**
After `idx_leads_campaign_status` is created: `type: ref`, `key: idx_leads_campaign_status`, `rows` drops significantly. MySQL now scans only the rows matching `status = 'converted'` via the index, skipping all others.

**Answer 4:**
- Email open rate calculation used in 5 reports → **UDF** (`fn_open_rate()`)
- Runs on every new order insert → **Trigger** (`trg_orders_update_customer_spend`)
- Campaign performance filtered by channel and year → **Stored Procedure** (takes parameters)
- One-time anomaly investigation → **Ad-hoc query** — do not create an object

**Answer 5 (Challenge):**
```sql
-- Referential integrity check
SELECT l.lead_id, l.campaign_id, l.email
FROM leads l
WHERE NOT EXISTS (
    SELECT 1 FROM campaigns c
    WHERE c.campaign_id = l.campaign_id
);
```
If this returns rows, those leads cannot be attributed to any campaign — they are orphaned records. In an attribution model, they would either be silently excluded (if you use INNER JOIN) or return NULLs for all campaign fields (if you use LEFT JOIN). Either way, your channel attribution percentages would be wrong. This is exactly the kind of referential integrity problem that profiling catches before it corrupts downstream analysis.

---

[← Module 00: Foundations](00_foundations.md) | [Back to Index](README.md) | [Next: Module 01 — SEO →](01_seo.md)
