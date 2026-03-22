-- ============================================================
-- MARKETING ANALYTICS PORTFOLIO PROJECT
-- File: 04_views.sql
-- Description: 10 views covering campaign performance,
--              channel summary, email metrics, SEO progress,
--              content performance, and customer segments
-- Run Order: 4 of 10
-- ============================================================

USE marketing_analytics;

-- ============================================================
-- VIEW 1: Campaign Performance Summary
-- Combines campaign spend, leads, conversions, and ROAS
-- Used in: dashboards, executive reporting
-- ============================================================
CREATE OR REPLACE VIEW vw_campaign_performance AS
SELECT
    c.campaign_id,
    c.campaign_name,
    c.channel,
    c.campaign_type,
    c.objective,
    YEAR(c.start_date)                              AS campaign_year,
    QUARTER(c.start_date)                           AS campaign_quarter,
    c.budget,
    c.spend,
    ROUND(c.spend / NULLIF(c.budget, 0) * 100, 2)  AS budget_utilization_pct,
    COUNT(l.lead_id)                                AS total_leads,
    SUM(CASE WHEN l.status = 'converted'
        THEN 1 ELSE 0 END)                          AS converted_leads,
    SUM(CASE WHEN l.status = 'qualified'
        THEN 1 ELSE 0 END)                          AS qualified_leads,
    ROUND(
        SUM(CASE WHEN l.status = 'converted' THEN 1 ELSE 0 END)
        / NULLIF(COUNT(l.lead_id), 0) * 100, 2)    AS conversion_rate_pct,
    ROUND(c.spend
        / NULLIF(COUNT(l.lead_id), 0), 2)           AS cost_per_lead,
    ROUND(c.spend
        / NULLIF(SUM(CASE WHEN l.status = 'converted'
            THEN 1 ELSE 0 END), 0), 2)              AS cost_per_conversion,
    COALESCE(SUM(l.deal_value), 0)                  AS total_pipeline,
    ROUND(
        COALESCE(SUM(l.deal_value), 0)
        / NULLIF(c.spend, 0), 2)                    AS roas,
    c.status                                        AS campaign_status
FROM campaigns c
LEFT JOIN leads l ON c.campaign_id = l.campaign_id
GROUP BY
    c.campaign_id, c.campaign_name, c.channel, c.campaign_type,
    c.objective, c.start_date, c.budget, c.spend, c.status;

-- ============================================================
-- VIEW 2: Channel YoY Performance
-- Year over year comparison by marketing channel
-- Used in: executive dashboards, budget planning
-- ============================================================
CREATE OR REPLACE VIEW vw_channel_yoy AS
SELECT
    c.channel,
    YEAR(c.start_date)                              AS campaign_year,
    COUNT(DISTINCT c.campaign_id)                   AS total_campaigns,
    SUM(c.budget)                                   AS total_budget,
    SUM(c.spend)                                    AS total_spend,
    COUNT(l.lead_id)                                AS total_leads,
    SUM(CASE WHEN l.status = 'converted'
        THEN 1 ELSE 0 END)                          AS total_conversions,
    ROUND(
        SUM(CASE WHEN l.status = 'converted' THEN 1 ELSE 0 END)
        / NULLIF(COUNT(l.lead_id), 0) * 100, 2)    AS conversion_rate_pct,
    ROUND(SUM(c.spend)
        / NULLIF(COUNT(l.lead_id), 0), 2)           AS cost_per_lead,
    COALESCE(SUM(l.deal_value), 0)                  AS total_pipeline,
    ROUND(
        COALESCE(SUM(l.deal_value), 0)
        / NULLIF(SUM(c.spend), 0), 2)               AS roas
FROM campaigns c
LEFT JOIN leads l ON c.campaign_id = l.campaign_id
GROUP BY
    c.channel,
    YEAR(c.start_date)
ORDER BY
    c.channel,
    campaign_year;

-- ============================================================
-- VIEW 3: Email Campaign Metrics
-- Open rates, click rates, conversion rates per email send
-- Used in: email performance reporting
-- ============================================================
CREATE OR REPLACE VIEW vw_email_metrics AS
SELECT
    ec.email_campaign_id,
    ec.email_name,
    ec.subject_line,
    ec.email_type,
    ec.audience_segment,
    ec.list_size,
    ec.send_date,
    YEAR(ec.send_date)                              AS send_year,
    SUM(CASE WHEN ee.event_type = 'delivered'
        THEN 1 ELSE 0 END)                          AS delivered,
    SUM(CASE WHEN ee.event_type = 'opened'
        THEN 1 ELSE 0 END)                          AS opens,
    SUM(CASE WHEN ee.event_type = 'clicked'
        THEN 1 ELSE 0 END)                          AS clicks,
    SUM(CASE WHEN ee.event_type = 'converted'
        THEN 1 ELSE 0 END)                          AS conversions,
    SUM(CASE WHEN ee.event_type = 'unsubscribed'
        THEN 1 ELSE 0 END)                          AS unsubscribes,
    SUM(CASE WHEN ee.event_type = 'bounced'
        THEN 1 ELSE 0 END)                          AS bounces,
    ROUND(
        SUM(CASE WHEN ee.event_type = 'opened' THEN 1 ELSE 0 END)
        / NULLIF(ec.list_size, 0) * 100, 2)         AS open_rate_pct,
    ROUND(
        SUM(CASE WHEN ee.event_type = 'clicked' THEN 1 ELSE 0 END)
        / NULLIF(
            SUM(CASE WHEN ee.event_type = 'opened' THEN 1 ELSE 0 END)
        , 0) * 100, 2)                              AS ctor_pct,
    ROUND(
        SUM(CASE WHEN ee.event_type = 'converted' THEN 1 ELSE 0 END)
        / NULLIF(ec.list_size, 0) * 100, 2)         AS conversion_rate_pct
FROM email_campaigns ec
LEFT JOIN email_events ee ON ec.email_campaign_id = ee.email_campaign_id
GROUP BY
    ec.email_campaign_id, ec.email_name, ec.subject_line,
    ec.email_type, ec.audience_segment, ec.list_size, ec.send_date;

-- ============================================================
-- VIEW 4: SEO Keyword Rank Tracker
-- Latest ranking position for each keyword
-- Used in: SEO reporting
-- ============================================================
CREATE OR REPLACE VIEW vw_seo_keyword_latest AS
SELECT
    k.keyword_id,
    k.keyword,
    k.search_volume,
    k.keyword_difficulty,
    k.intent_type,
    k.topic_cluster,
    k.is_branded,
    r.ranking_date                                  AS last_checked,
    r.position                                      AS current_position,
    r.impressions                                   AS monthly_impressions,
    r.clicks                                        AS monthly_clicks,
    r.ctr_pct                                       AS ctr_pct,
    CASE
        WHEN r.position = 1              THEN 'Position 1'
        WHEN r.position BETWEEN 2 AND 3  THEN 'Top 3'
        WHEN r.position BETWEEN 4 AND 10 THEN 'Page 1'
        WHEN r.position BETWEEN 11 AND 20 THEN 'Page 2'
        ELSE 'Page 3+'
    END                                             AS rank_tier
FROM seo_keywords k
LEFT JOIN seo_rankings r ON k.keyword_id = r.keyword_id
WHERE r.ranking_date = (
    SELECT MAX(r2.ranking_date)
    FROM seo_rankings r2
    WHERE r2.keyword_id = k.keyword_id
);

-- ============================================================
-- VIEW 5: Content Performance Summary
-- Latest performance stats per content piece
-- Used in: content marketing reporting
-- ============================================================
CREATE OR REPLACE VIEW vw_content_performance_summary AS
SELECT
    cp.content_id,
    cp.title,
    cp.content_type,
    cp.topic_cluster,
    cp.author,
    cp.publish_date,
    cp.status,
    cp.cta_type,
    SUM(p.page_views)                               AS total_page_views,
    SUM(p.unique_visitors)                          AS total_unique_visitors,
    ROUND(AVG(p.avg_time_sec), 0)                   AS avg_time_on_page_sec,
    ROUND(AVG(p.bounce_rate_pct), 2)                AS avg_bounce_rate_pct,
    SUM(p.social_shares)                            AS total_social_shares,
    SUM(p.backlinks_earned)                         AS total_backlinks,
    SUM(p.cta_clicks)                               AS total_cta_clicks,
    SUM(p.conversions)                              AS total_conversions,
    ROUND(
        SUM(p.conversions)
        / NULLIF(SUM(p.page_views), 0) * 100, 2)   AS content_conversion_rate_pct
FROM content_pieces cp
LEFT JOIN content_performance p ON cp.content_id = p.content_id
GROUP BY
    cp.content_id, cp.title, cp.content_type, cp.topic_cluster,
    cp.author, cp.publish_date, cp.status, cp.cta_type;

-- ============================================================
-- VIEW 6: Customer Segment Summary
-- Revenue, order frequency, and engagement by segment
-- Used in: audience targeting, CRM analysis
-- ============================================================
CREATE OR REPLACE VIEW vw_customer_segment_summary AS
SELECT
    c.segment,
    COUNT(DISTINCT c.customer_id)                   AS total_customers,
    ROUND(AVG(c.points), 0)                         AS avg_loyalty_points,
    ROUND(AVG(c.balance), 2)                        AS avg_balance,
    COUNT(DISTINCT o.order_id)                      AS total_orders,
    ROUND(SUM(o.amount), 2)                         AS total_revenue,
    ROUND(AVG(o.amount), 2)                         AS avg_order_value,
    ROUND(
        COUNT(DISTINCT o.order_id)
        / NULLIF(COUNT(DISTINCT c.customer_id), 0)
    , 2)                                            AS orders_per_customer,
    ROUND(
        SUM(o.amount)
        / NULLIF(COUNT(DISTINCT c.customer_id), 0)
    , 2)                                            AS revenue_per_customer
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.segment
ORDER BY total_revenue DESC;

-- ============================================================
-- VIEW 7: PPC Ad Performance Summary
-- Click-through rates, conversion rates, quality scores
-- Used in: PPC reporting and optimization
-- ============================================================
CREATE OR REPLACE VIEW vw_ppc_performance AS
SELECT
    c.campaign_name,
    c.channel,
    ag.ad_group_name,
    ag.bid_strategy,
    a.headline_1,
    a.ad_type,
    YEAR(p.perf_date)                               AS perf_year,
    SUM(p.impressions)                              AS total_impressions,
    SUM(p.clicks)                                   AS total_clicks,
    SUM(p.spend)                                    AS total_spend,
    SUM(p.conversions)                              AS total_conversions,
    SUM(p.conversion_value)                         AS total_conversion_value,
    ROUND(
        SUM(p.clicks)
        / NULLIF(SUM(p.impressions), 0) * 100, 2)  AS ctr_pct,
    ROUND(
        SUM(p.spend)
        / NULLIF(SUM(p.clicks), 0), 2)             AS avg_cpc,
    ROUND(
        SUM(p.conversions)
        / NULLIF(SUM(p.clicks), 0) * 100, 2)       AS conversion_rate_pct,
    ROUND(
        SUM(p.spend)
        / NULLIF(SUM(p.conversions), 0), 2)        AS cost_per_conversion,
    ROUND(
        SUM(p.conversion_value)
        / NULLIF(SUM(p.spend), 0), 2)              AS roas,
    ROUND(AVG(p.quality_score), 1)                  AS avg_quality_score
FROM ad_performance p
JOIN ads a ON p.ad_id = a.ad_id
JOIN ad_groups ag ON a.ad_group_id = ag.ad_group_id
JOIN campaigns c ON ag.campaign_id = c.campaign_id
GROUP BY
    c.campaign_name, c.channel, ag.ad_group_name,
    ag.bid_strategy, a.headline_1, a.ad_type, YEAR(p.perf_date)
ORDER BY total_spend DESC;

-- ============================================================
-- VIEW 8: Website Conversion Funnel
-- Session to conversion rates by traffic source
-- Used in: website analytics, CRO reporting
-- ============================================================
CREATE OR REPLACE VIEW vw_web_conversion_funnel AS
SELECT
    COALESCE(referrer_source, 'unknown')            AS traffic_source,
    COALESCE(referrer_medium, 'unknown')            AS traffic_medium,
    YEAR(session_start)                             AS session_year,
    COUNT(session_id)                               AS total_sessions,
    SUM(pages_viewed)                               AS total_page_views,
    ROUND(AVG(pages_viewed), 2)                     AS avg_pages_per_session,
    SUM(converted)                                  AS total_conversions,
    ROUND(
        SUM(converted)
        / NULLIF(COUNT(session_id), 0) * 100, 2)   AS session_conversion_rate_pct,
    ROUND(
        SUM(conversion_value)
        / NULLIF(SUM(converted), 0), 2)             AS avg_conversion_value,
    ROUND(
        SUM(conversion_value), 2)                   AS total_conversion_value
FROM web_sessions
GROUP BY
    COALESCE(referrer_source, 'unknown'),
    COALESCE(referrer_medium, 'unknown'),
    YEAR(session_start)
ORDER BY total_sessions DESC;

-- ============================================================
-- VIEW 9: A/B Test Results Summary
-- Win rates, lift percentages, statistical confidence
-- Used in: optimization reporting, experimentation tracking
-- ============================================================
CREATE OR REPLACE VIEW vw_ab_test_results AS
SELECT
    t.test_id,
    t.test_name,
    t.test_type,
    t.hypothesis,
    t.primary_metric,
    t.start_date,
    t.end_date,
    t.status,
    t.winner_variant,
    t.confidence_pct,
    v.variant_name,
    v.sample_size,
    v.impressions,
    v.clicks,
    v.conversions,
    v.revenue,
    ROUND(
        v.clicks
        / NULLIF(v.impressions, 0) * 100, 2)        AS click_rate_pct,
    ROUND(
        v.conversions
        / NULLIF(v.sample_size, 0) * 100, 2)        AS conversion_rate_pct,
    ROUND(
        v.revenue
        / NULLIF(v.conversions, 0), 2)              AS revenue_per_conversion,
    CASE WHEN t.winner_variant = v.variant_name
        THEN 'Winner' ELSE 'Loser' END              AS variant_result
FROM ab_tests t
JOIN ab_variants v ON t.test_id = v.test_id
ORDER BY t.test_id, v.variant_name;

-- ============================================================
-- VIEW 10: Marketing KPI Dashboard
-- Top-level marketing KPIs for executive reporting
-- Used in: CMO dashboard, board reporting
-- ============================================================
CREATE OR REPLACE VIEW vw_marketing_kpi_dashboard AS
SELECT
    YEAR(c.start_date)                              AS reporting_year,
    QUARTER(c.start_date)                           AS reporting_quarter,
    SUM(c.budget)                                   AS total_budget,
    SUM(c.spend)                                    AS total_spend,
    ROUND(
        SUM(c.spend) / NULLIF(SUM(c.budget), 0)
        * 100, 2)                                   AS budget_utilization_pct,
    COUNT(DISTINCT l.lead_id)                       AS total_leads,
    COUNT(DISTINCT CASE WHEN l.status = 'qualified'
        THEN l.lead_id END)                         AS qualified_leads,
    COUNT(DISTINCT CASE WHEN l.status = 'converted'
        THEN l.lead_id END)                         AS converted_leads,
    ROUND(
        COUNT(DISTINCT CASE WHEN l.status = 'converted'
            THEN l.lead_id END)
        / NULLIF(COUNT(DISTINCT l.lead_id), 0)
        * 100, 2)                                   AS lead_conversion_rate_pct,
    ROUND(
        SUM(c.spend)
        / NULLIF(COUNT(DISTINCT l.lead_id), 0), 2) AS blended_cpl,
    COALESCE(SUM(l.deal_value), 0)                  AS total_pipeline,
    ROUND(
        COALESCE(SUM(l.deal_value), 0)
        / NULLIF(SUM(c.spend), 0), 2)               AS blended_roas,
    COUNT(DISTINCT c.campaign_id)                   AS active_campaigns
FROM campaigns c
LEFT JOIN leads l ON c.campaign_id = l.campaign_id
GROUP BY
    YEAR(c.start_date),
    QUARTER(c.start_date)
ORDER BY
    reporting_year,
    reporting_quarter;

SELECT 'Views created successfully' AS status;
SELECT table_name AS view_name
FROM information_schema.views
WHERE table_schema = 'marketing_analytics'
ORDER BY table_name;
