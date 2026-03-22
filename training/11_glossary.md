# Module 11 — Glossary

**Reference module — use anytime**

[← Module 10: Website](10_website.md) | [Back to Index](README.md)

This glossary covers every marketing term and every SQL term used across the training modules. Use it as a quick reference when a term is unfamiliar or when you want to verify your understanding before explaining it to a stakeholder.

---

## Marketing Terms

### A

**Attribution Model** — A rule or set of rules that assigns revenue credit to the marketing touchpoints that influenced a conversion. Common models: first-touch, last-touch, linear, time-decay, data-driven.

**Average Order Value (AOV)** — Total revenue divided by number of orders. `SUM(amount) / COUNT(order_id)`.

### B

**Bounce Rate** — The percentage of sessions where a visitor viewed only one page and left. High bounce rate on a landing page usually signals a mismatch between ad promise and page content.

**Budget Pacing** — How evenly campaign spend is distributed across the campaign period. A campaign that spends 90% of its budget in the first 10 days is over-pacing; one that spends 30% with 3 days remaining is under-pacing.

### C

**CLV (Customer Lifetime Value)** — The total revenue a customer is expected to generate over their entire relationship with the company. In this project, modeled as total historical order revenue, segmented into tiers by the `fn_clv_tier()` UDF.

**CLS (Cumulative Layout Shift)** — A Core Web Vitals metric measuring visual stability. Good: < 0.1. Measures how much page elements shift during load.

**Content Gap** — A topic cluster that has keyword search demand (people are searching for it) but no published content addressing it. High-priority editorial investment opportunity.

**Conversion Rate** — The percentage of visitors or leads who complete a desired action (purchase, form submit, demo request). Formula varies by funnel stage.

**CPA (Cost Per Acquisition)** — Total spend divided by number of conversions. Also called Cost Per Conversion. `SUM(spend) / SUM(conversions)`.

**CPL (Cost Per Lead)** — Total spend divided by number of leads generated. `SUM(spend) / COUNT(lead_id)`.

**CPC (Cost Per Click)** — Total spend divided by number of clicks. `SUM(spend) / SUM(clicks)`.

**CTOR (Click-to-Open Rate)** — Email clicks divided by email opens. Measures the quality of email content, not subject lines. `clicks / opens * 100`.

**CTR (Click-Through Rate)** — Clicks divided by impressions. Measures ad relevance and creative effectiveness.

**CRO (Conversion Rate Optimization)** — The practice of improving a website or landing page to increase the percentage of visitors who take a desired action, without increasing traffic.

### D

**Deliverability** — The percentage of sent emails that actually reach the recipient's inbox. Affected by list quality, sender reputation, and email content.

### F

**FCP (First Contentful Paint)** — How quickly the browser renders the first piece of content (text, image). A user experience signal.

**FID (First Input Delay)** — A Core Web Vitals metric measuring interactivity. Good: < 100ms.

**First-Touch Attribution** — An attribution model that gives 100% of conversion credit to the first marketing touchpoint a prospect encountered.

### G

**GTM (Google Tag Manager)** — A tag management system that allows marketers to deploy and manage tracking scripts on a website without engineering involvement.

### I

**ICP (Ideal Customer Profile)** — A description of the company or individual most likely to buy your product, become a long-term customer, and refer others. Defined by analyzing your best existing customers.

**Intent Type (keyword)** — The purpose behind a search query. Informational (learning), navigational (finding a site), commercial (researching options), transactional (ready to buy).

### K

**Keyword Difficulty** — A 0–100 score estimating how hard it is to rank on page 1 for a given keyword. Higher score = more competitive.

### L

**LCP (Largest Contentful Paint)** — A Core Web Vitals metric measuring how quickly the largest visible element on a page loads. Good: < 2,500ms.

**Last-Touch Attribution** — An attribution model that gives 100% of conversion credit to the final marketing touchpoint before conversion.

**Lead Score** — A numeric value assigned to a lead based on demographic data and behavioral signals, used to prioritize sales follow-up.

**Linear Attribution** — An attribution model that gives equal credit to every touchpoint in the conversion path.

### M

**MQL (Marketing Qualified Lead)** — A lead that has met a defined score or behavior threshold, indicating sales-readiness. In this project, approximated by leads with `status = 'qualified'`.

### O

**Open Rate** — The percentage of delivered emails that were opened. `opens / list_size * 100`. Industry benchmark: 20–30% for B2B.

**Organic Traffic** — Website visitors who arrived via unpaid search results (SEO), as opposed to paid ads or direct visits.

**Opportunity Score (SEO)** — A custom metric calculated as `search_volume / keyword_difficulty`. Higher score = high search demand relative to competition. Used to prioritize SEO effort.

### P

**Pipeline** — The total deal value of leads or opportunities currently in the sales process. In this project, `SUM(deal_value)` across active or converted leads.

**Page 1** — Positions 1–10 in Google search results. The vast majority of clicks go to page 1. Moving a keyword from page 2 (positions 11–20) to page 1 typically generates 5–10x more traffic.

### Q

**Quality Score (Google Ads)** — A 1–10 rating Google assigns to each keyword based on expected CTR, ad relevance, and landing page experience. Higher quality scores reduce CPC.

### R

**ROAS (Return on Ad Spend)** — Revenue attributed to advertising divided by advertising spend. `SUM(revenue) / SUM(spend)`. A ROAS of 4.0 means every dollar spent returned four dollars.

**Remarketing** — Showing ads to people who have previously visited your website or interacted with your brand. Higher conversion rates than cold audiences because the prospect is already familiar with you.

**ROI (Return on Investment)** — Profit minus cost, divided by cost. Broader than ROAS — ROAS measures gross revenue, ROI accounts for margins and costs.

### S

**Sender Reputation** — An email provider's score of your sending domain, based on bounce rates, spam reports, and engagement. Poor reputation leads to deliverability problems.

**Session** — A single visit to a website. Starts when a user arrives and ends after 30 minutes of inactivity (default GA4 definition).

**SQL (Sales Qualified Lead)** — A lead that sales has accepted and is actively working. Distinct from MQL.

### T

**TTFB (Time to First Byte)** — How quickly the server sends the first byte of data to the browser. A technical performance metric. Good: < 800ms.

**Topic Cluster** — A group of related content pieces organized around a central "pillar page." A content strategy framework that builds topical authority for SEO.

### U

**UTM Parameters** — Tags appended to URLs to track the source, medium, and campaign of traffic in analytics tools. Example: `?utm_source=linkedin&utm_medium=cpc&utm_campaign=q1-2024`.

### W

**Win-Back Campaign** — A targeted campaign aimed at re-engaging customers who have churned or gone inactive. Usually includes an incentive offer.

---

## SQL Terms

### A

**Aggregate Function** — A function that computes a single result from multiple rows. Examples: `SUM()`, `COUNT()`, `AVG()`, `MAX()`, `MIN()`.

**Alias** — A temporary name assigned to a column or table using `AS`. Makes queries more readable. Example: `SUM(spend) AS total_spend`.

### C

**Cardinality** — The number of distinct values in a column. High cardinality (many distinct values, like email addresses) = good index candidate. Low cardinality (few distinct values, like status flags) = poor index candidate.

**CASE WHEN** — SQL's conditional logic operator. Returns different values based on conditions. Used for classification, bucketing, and conditional aggregation.

**Composite Index** — An index on two or more columns. MySQL uses it when the query filters or sorts by the leading column(s) in the index definition.

**Correlated Subquery** — A subquery that references a column from the outer query. Executes once per row of the outer query. Useful for row-level comparisons but can be slow on large tables.

**CTE (Common Table Expression)** — A named temporary result set defined with `WITH`. Makes complex queries readable and debuggable by breaking them into named steps.

**Covering Index** — An index that contains all the columns a query needs, so MySQL can answer the query directly from the index without reading the table. Fastest possible query execution.

### D

**DENSE_RANK()** — A window function that assigns ranks without gaps. Tied values receive the same rank, and the next rank is the consecutive integer. Example: 1, 1, 2, 3.

**DESCRIBE** — A MySQL command that shows the column definitions, data types, and constraints of a table.

### E

**EXPLAIN** — A MySQL command that shows the execution plan for a query — which indexes are used, how many rows are scanned, and how joins are executed. Use it to diagnose slow queries.

**EXISTS** — A predicate that returns TRUE if a subquery returns at least one row. Stops scanning as soon as one match is found — faster than `COUNT() > 0`.

### F

**FIRST_VALUE()** — A window function that returns the first value in a window partition, ordered by the `ORDER BY` clause.

**Foreign Key (FK)** — A column in one table that references the primary key of another table, enforcing referential integrity.

**Full Table Scan** — When MySQL reads every row in a table to find matching rows, because no suitable index exists. Appears as `type: ALL` in `EXPLAIN` output. Slow on large tables.

### G

**GROUP BY** — Aggregates rows with the same values in specified columns into summary rows. Every non-aggregate column in `SELECT` must appear in `GROUP BY`.

**GROUP_CONCAT()** — A MySQL aggregate function that concatenates values from multiple rows into a single string with a configurable separator.

### H

**HAVING** — A filter applied after `GROUP BY`, used to filter aggregate results. Equivalent to `WHERE` but for grouped data. Example: `HAVING COUNT(*) > 5`.

### I

**Index** — A data structure that improves query performance by allowing MySQL to find rows without scanning the entire table.

**INNER JOIN** — Returns only rows where a match exists in both tables. Excludes rows with no matching record.

### L

**LAG()** — A window function that accesses a value from a previous row in the same partition and order. Used for period-over-period comparisons.

**LEAD()** — A window function that accesses a value from a following row. Used to look ahead in a time series.

**LEFT JOIN** — Returns all rows from the left table, and matching rows from the right table. Non-matching rows in the right table appear as NULL.

### N

**NOT EXISTS** — The negation of `EXISTS`. Returns rows where no matching row exists in the subquery. Used to find gaps (e.g., pages with no conversion events).

**NTILE(n)** — A window function that divides rows into n equal-sized buckets and assigns each row a bucket number. Used for percentile bucketing.

**NULL** — The absence of a value. Not zero, not empty string — the absence of any value. NULLs propagate through arithmetic: `NULL + 5 = NULL`.

**NULLIF(a, b)** — Returns NULL if a equals b; otherwise returns a. Used to prevent division-by-zero: `SUM(spend) / NULLIF(COUNT(*), 0)`.

### O

**ORDER BY** — Sorts the result set by one or more columns. Can be ASC (ascending, default) or DESC (descending).

### P

**Partition** — In window functions, the column(s) by which rows are grouped before applying the window calculation. Defined with `PARTITION BY`. Like `GROUP BY` for window functions — but without collapsing rows.

**PERCENT_RANK()** — A window function that returns a value's rank as a percentage of the total rows in the partition. Returns 0 for the lowest value, 1 for the highest.

**Primary Key (PK)** — A column (or set of columns) that uniquely identifies each row in a table. MySQL automatically creates an index on the primary key.

### R

**RANK()** — A window function that assigns ranks with gaps after ties. Example: 1, 1, 3, 4 (position 2 is skipped after a tie).

**ROW_NUMBER()** — A window function that assigns a unique sequential integer to each row within a partition, regardless of ties.

### S

**Sargable** — A query predicate that can be satisfied by an index seek. Functions applied to indexed columns in WHERE clauses are typically non-sargable (break index usage). Example: `WHERE YEAR(created_at) = 2024` is non-sargable; `WHERE created_at BETWEEN '2024-01-01' AND '2024-12-31'` is sargable.

**Stored Procedure** — A named, compiled set of SQL statements stored in the database and executed with `CALL`. Accepts parameters, supports conditional logic, loops, error handling, and transactions.

**Subquery** — A query nested inside another query. Can appear in `SELECT`, `FROM`, or `WHERE` clauses. Correlated subqueries reference the outer query; non-correlated subqueries are independent.

### T

**Transaction** — A unit of work that either fully succeeds (`COMMIT`) or fully fails (`ROLLBACK`). Ensures data consistency when multiple related changes must succeed or fail together.

**Trigger** — A database object that automatically executes a defined action when a specified event occurs on a table (`BEFORE INSERT`, `AFTER UPDATE`, `BEFORE DELETE`, etc.).

### U

**UDF (User-Defined Function)** — A custom scalar function created with `CREATE FUNCTION`. Returns a single value and can be called inside any SQL expression.

**UNION ALL** — Combines the result sets of two or more `SELECT` statements into a single result. `UNION ALL` includes duplicates; `UNION` removes them. Use `UNION ALL` unless deduplication is required — it's faster.

### V

**View** — A saved query stored as a named virtual table. Does not store data itself — queries the underlying tables at runtime. Used to encapsulate complex business logic and simplify reporting queries.

### W

**WHERE** — Filters rows before aggregation. Applied before `GROUP BY` and `HAVING`.

**Window Function** — A function that computes a value for each row based on a "window" of related rows, without collapsing them into a single row (unlike aggregate functions). Defined with `OVER (PARTITION BY ... ORDER BY ...)`.

**Window Frame** — The subset of rows within a window partition used for a specific calculation. Defined with `ROWS BETWEEN` or `RANGE BETWEEN`. Example: `ROWS BETWEEN 2 PRECEDING AND CURRENT ROW` = 3-period rolling window.

---

*End of Glossary*

[← Module 10: Website](10_website.md) | [Back to Index](README.md)
