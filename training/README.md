# Marketing Analytics SQL Training Guide

> **A complete, self-paced course in SQL and digital marketing analytics — built around a real production database.**

This training guide walks you through the `marketing_analytics` portfolio database from the ground up. Each module covers one digital marketing discipline, teaches the SQL techniques needed to analyze it, and connects every query to the kind of business questions a CMO or senior marketing leader asks in real life.

By the end of this guide you will be able to build, maintain, and explain a production-grade marketing analytics system — in SQL, in a business meeting, and on a resume.

---

## How to Use This Guide

| Step | What to do |
|------|------------|
| **1** | Run the SQL project files in order (`01_create_schema.sql` through `03_data_channels.sql`) to load your database |
| **2** | Open MySQL Workbench and connect to the `marketing_analytics` schema |
| **3** | Work through each module in order — read first, then run the queries, then do the exercises |
| **4** | Use the **Tips & Tricks** boxes to pick up technique shortcuts |
| **5** | Use the **Marketing Nuggets** to understand the business context behind every query |
| **6** | Complete the **Test Yourself** quiz at the end of each module before moving on |

> 💡 **You don't have to go in order.** If you already know SEO well, jump to Module 02 (PPC). Each module is self-contained.

---

## Table of Contents

| Module | Topic | SQL Skills Covered | Est. Time |
|--------|-------|--------------------|-----------|
| [00 — Foundations](00_foundations.md) | Database design, schema navigation, running your first queries | `USE`, `DESCRIBE`, `SELECT`, `WHERE`, `JOIN` | 45 min |
| [00B — Engineering Workflow](00b_engineering_workflow.md) | **The recipe.** Data profiling, EXPLAIN-driven indexing, object decision framework, build order | `EXPLAIN`, `UNION ALL` profiling, referential integrity checks | 60 min |
| [01 — SEO](01_seo.md) | Keyword research, rank tracking, organic traffic analysis | `LAG()`, `LEAD()`, `RANK()`, CTEs, correlated subqueries | 60 min |
| [02 — PPC](02_ppc.md) | Paid search and social ads, bidding, budget management | Running totals, `NTILE()`, composite indexes, `EXPLAIN` | 60 min |
| [03 — Email Marketing](03_email.md) | Campaign funnels, open/click/convert rates, list health | Views, conditional aggregation, moving averages | 60 min |
| [04 — GTM](04_gtm.md) | Tag management, event tracking, conversion attribution | `EXISTS` / `NOT EXISTS`, triggers, `GROUP BY` auditing | 45 min |
| [05 — Content Marketing](05_content.md) | Content strategy, topic clusters, performance scoring | UDFs, `DENSE_RANK()`, above-average filtering | 60 min |
| [06 — Audience Targeting](06_audience.md) | Segmentation, multi-channel overlap, CLV tiers | `PERCENT_RANK()`, `GROUP_CONCAT()`, multi-CTE pipelines | 60 min |
| [07 — Marketing Analytics](07_analytics.md) | KPI dashboards, attribution models, executive reporting | Full attribution CTE chain, YoY window functions | 75 min |
| [08 — Trends](08_trends.md) | Algorithm updates, AI tools, impact tracking | Date range joins, `EXISTS`, impact score aggregation | 45 min |
| [09 — Campaign Optimization](09_optimization.md) | A/B testing, statistical lift, bid strategy analysis | A/B lift CTEs, stored procedures, cumulative totals | 60 min |
| [10 — Website Development](10_website.md) | CRO, web vitals, session funnel analysis | Funnel CTEs, correlated subqueries, optimization flags | 60 min |
| [11 — Glossary](11_glossary.md) | Every marketing and SQL term used in this guide | Reference — use anytime | — |

**Total estimated time: ~11 hours of active learning**

> 💡 **Module 00B is not optional.** It is the mental model that makes every other module make sense. The marketing modules teach you *what* to measure. Module 00B teaches you *how to think* about building the system that does the measuring. Do Module 00B before Module 01.

---

## What You Will Be Able to Answer

After completing this guide, you can walk into a senior marketing meeting and answer:

- *"Which channel is giving us the best return on ad spend?"*
- *"Why did organic traffic drop last quarter?"*
- *"Are our email campaigns getting better or worse over time?"*
- *"Which content pieces are actually driving pipeline, not just traffic?"*
- *"What happened to conversion rates after the Google core update?"*
- *"Which customers are at risk of churning and what did they respond to before?"*

---

## Legend

Throughout this guide you will see four types of callout boxes:

> 💡 **TIP & TRICK** — A SQL technique, shortcut, or pattern that makes the query cleaner or faster.

> 📊 **MARKETING NUGGET** — The real business context. What this query means to a CMO. What decision it supports.

> ⚠️ **WATCH OUT** — A common mistake or gotcha to avoid.

> 🎯 **CMO QUESTION** — An actual question a senior leader might ask. Your query is the answer.

---

*Built alongside the [Marketing Analytics SQL Portfolio](../docs/README.md) project.*
