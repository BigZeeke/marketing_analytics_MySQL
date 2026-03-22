-- ============================================================
-- MARKETING ANALYTICS PORTFOLIO PROJECT
-- File: 08_window_functions.sql
-- Description: Window function queries covering all 10 digital
--              marketing topics. Demonstrates RANK, DENSE_RANK,
--              ROW_NUMBER, LAG, LEAD, NTILE, running totals,
--              moving averages, and cumulative distributions.
-- Run Order: 8 of 10
-- ============================================================

USE marketing_analytics;

-- ============================================================
-- 1. SEO: Keyword Rank Movement (LAG/LEAD)
-- Tracks position change between earliest and latest ranking
-- for each keyword, showing MoM momentum
-- ============================================================
SELECT
    k.keyword,
    k.search_volume,
    k.intent_type,
    k.topic_cluster,
    r.ranking_date,
    r.position                          AS current_position,
    LAG(r.position)  OVER (
        PARTITION BY r.keyword_id
        ORDER BY     r.ranking_date
    )                                   AS prev_position,
    r.position - LAG(r.position) OVER (
        PARTITION BY r.keyword_id
        ORDER BY     r.ranking_date
    )                                   AS position_change,        -- negative = improvement
    LEAD(r.position) OVER (
        PARTITION BY r.keyword_id
        ORDER BY     r.ranking_date
    )                                   AS next_period_position,
    r.clicks,
    SUM(r.clicks) OVER (
        PARTITION BY r.keyword_id
        ORDER BY     r.ranking_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    )                                   AS cumulative_clicks,
    ROUND(AVG(r.position) OVER (
        PARTITION BY r.keyword_id
        ORDER BY     r.ranking_date
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 1)                               AS rolling_3period_avg_position
FROM seo_rankings r
JOIN seo_keywords k ON r.keyword_id = k.keyword_id
ORDER BY k.search_volume DESC, r.ranking_date;

-- ============================================================
-- 2. SEO: Rank and Prioritize Keywords by Opportunity
-- RANK() within each intent type by search volume
-- NTILE to bucket keywords into effort tiers
-- ============================================================
SELECT
    k.keyword,
    k.search_volume,
    k.keyword_difficulty,
    k.intent_type,
    k.topic_cluster,
    r.position                              AS latest_position,
    RANK() OVER (
        PARTITION BY k.intent_type
        ORDER BY     k.search_volume DESC
    )                                       AS volume_rank_in_intent,
    DENSE_RANK() OVER (
        ORDER BY k.search_volume DESC
    )                                       AS overall_volume_rank,
    NTILE(4) OVER (
        ORDER BY
            (k.search_volume / NULLIF(k.keyword_difficulty, 1)) DESC
    )                                       AS opportunity_quartile,   -- 1 = best opportunity
    ROUND(
        k.search_volume / NULLIF(k.keyword_difficulty, 1), 1
    )                                       AS opportunity_score
FROM seo_keywords k
LEFT JOIN seo_rankings r
    ON  k.keyword_id   = r.keyword_id
    AND r.ranking_date = (
        SELECT MAX(r2.ranking_date)
        FROM   seo_rankings r2
        WHERE  r2.keyword_id = k.keyword_id
    )
ORDER BY opportunity_score DESC;

-- ============================================================
-- 3. PPC: Running Spend and ROAS Over Time (Running Total)
-- Shows cumulative spend and conversion value by ad
-- ============================================================
SELECT
    a.headline_1                            AS ad_headline,
    ag.bid_strategy,
    p.perf_date,
    p.impressions,
    p.clicks,
    p.spend,
    p.conversions,
    p.conversion_value,
    SUM(p.spend) OVER (
        PARTITION BY p.ad_id
        ORDER BY     p.perf_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    )                                       AS cumulative_spend,
    SUM(p.conversion_value) OVER (
        PARTITION BY p.ad_id
        ORDER BY     p.perf_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    )                                       AS cumulative_revenue,
    ROUND(
        SUM(p.conversion_value) OVER (
            PARTITION BY p.ad_id
            ORDER BY     p.perf_date
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        )
        / NULLIF(
            SUM(p.spend) OVER (
                PARTITION BY p.ad_id
                ORDER BY     p.perf_date
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            ), 0)
    , 2)                                    AS running_roas,
    ROUND(AVG(p.spend) OVER (
        PARTITION BY p.ad_id
        ORDER BY     p.perf_date
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 2)                                   AS rolling_3mo_avg_spend
FROM ad_performance p
JOIN ads       a  ON p.ad_id       = a.ad_id
JOIN ad_groups ag ON a.ad_group_id = ag.ad_group_id
ORDER BY p.ad_id, p.perf_date;

-- ============================================================
-- 4. PPC: Ad Rank Within Campaign by ROAS (RANK + ROW_NUMBER)
-- Identifies top-performing ads within each campaign
-- ============================================================
SELECT
    c.campaign_name,
    c.channel,
    a.headline_1,
    ag.bid_strategy,
    SUM(p.impressions)                      AS total_impressions,
    SUM(p.spend)                            AS total_spend,
    SUM(p.conversions)                      AS total_conversions,
    SUM(p.conversion_value)                 AS total_revenue,
    ROUND(
        SUM(p.conversion_value)
        / NULLIF(SUM(p.spend), 0), 2
    )                                       AS roas,
    RANK() OVER (
        PARTITION BY c.campaign_id
        ORDER BY
            SUM(p.conversion_value)
            / NULLIF(SUM(p.spend), 0) DESC
    )                                       AS roas_rank_in_campaign,
    ROW_NUMBER() OVER (
        ORDER BY
            SUM(p.conversion_value)
            / NULLIF(SUM(p.spend), 0) DESC
    )                                       AS overall_roas_rank
FROM ad_performance p
JOIN ads       a  ON p.ad_id       = a.ad_id
JOIN ad_groups ag ON a.ad_group_id = ag.ad_group_id
JOIN campaigns c  ON ag.campaign_id = c.campaign_id
GROUP BY c.campaign_id, c.campaign_name, c.channel, a.ad_id, a.headline_1, ag.bid_strategy
ORDER BY roas DESC;

-- ============================================================
-- 5. EMAIL: Open Rate Trend with Moving Average
-- 3-send rolling average open rate by email type
-- ============================================================
SELECT
    ec.email_type,
    ec.send_date,
    ec.email_name,
    ec.list_size,
    COUNT(CASE WHEN ee.event_type = 'opened' THEN 1 END)   AS opens,
    ROUND(
        COUNT(CASE WHEN ee.event_type = 'opened' THEN 1 END)
        / NULLIF(ec.list_size, 0) * 100, 2
    )                                       AS open_rate_pct,
    ROUND(AVG(
        COUNT(CASE WHEN ee.event_type = 'opened' THEN 1 END)
        / NULLIF(ec.list_size, 0) * 100
    ) OVER (
        PARTITION BY ec.email_type
        ORDER BY     ec.send_date
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 2)                                   AS rolling_3send_avg_open_pct,
    LAG(
        COUNT(CASE WHEN ee.event_type = 'opened' THEN 1 END)
        / NULLIF(ec.list_size, 0) * 100
    , 1) OVER (
        PARTITION BY ec.email_type
        ORDER BY     ec.send_date
    )                                       AS prev_send_open_pct
FROM email_campaigns ec
LEFT JOIN email_events ee ON ec.email_campaign_id = ee.email_campaign_id
GROUP BY ec.email_campaign_id, ec.email_type, ec.send_date, ec.email_name, ec.list_size
ORDER BY ec.email_type, ec.send_date;

-- ============================================================
-- 6. CONTENT: Rank Top Content by Conversions (DENSE_RANK)
-- Identifies best-converting content within each content type
-- ============================================================
SELECT
    cp.content_type,
    cp.title,
    cp.topic_cluster,
    cp.author,
    cp.publish_date,
    SUM(p.page_views)                       AS total_views,
    SUM(p.conversions)                      AS total_conversions,
    SUM(p.social_shares)                    AS total_shares,
    fn_content_quality_score(
        SUM(p.page_views),
        AVG(p.avg_time_sec),
        AVG(p.bounce_rate_pct),
        SUM(p.social_shares)
    )                                       AS quality_score,
    DENSE_RANK() OVER (
        PARTITION BY cp.content_type
        ORDER BY SUM(p.conversions) DESC
    )                                       AS conversion_rank_in_type,
    DENSE_RANK() OVER (
        ORDER BY SUM(p.page_views) DESC
    )                                       AS overall_traffic_rank,
    NTILE(4) OVER (
        ORDER BY SUM(p.conversions) DESC
    )                                       AS conversion_quartile    -- 1 = top 25%
FROM content_pieces cp
JOIN content_performance p ON cp.content_id = p.content_id
GROUP BY cp.content_id, cp.content_type, cp.title, cp.topic_cluster,
         cp.author, cp.publish_date
ORDER BY total_conversions DESC;

-- ============================================================
-- 7. AUDIENCE: Customer Spend Percentile and Tier (NTILE + PERCENT_RANK)
-- Ranks customers by total revenue into CLV segments
-- ============================================================
SELECT
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name)  AS customer_name,
    c.segment,
    c.city,
    c.state,
    COALESCE(SUM(o.amount), 0)              AS total_revenue,
    COUNT(o.order_id)                        AS order_count,
    RANK() OVER (
        ORDER BY SUM(o.amount) DESC
    )                                       AS revenue_rank,
    NTILE(5) OVER (
        ORDER BY SUM(o.amount) DESC
    )                                       AS revenue_quintile,       -- 1 = top 20%
    ROUND(
        PERCENT_RANK() OVER (
            ORDER BY SUM(o.amount)
        ) * 100, 1
    )                                       AS revenue_percentile,
    fn_clv_tier(COALESCE(SUM(o.amount),0))  AS clv_tier
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name, c.segment, c.city, c.state
ORDER BY total_revenue DESC;

-- ============================================================
-- 8. CAMPAIGN OPTIMIZATION: Quarter-over-Quarter Lead Volume Change
-- Uses LAG to show QoQ growth in lead generation by channel
-- ============================================================
WITH quarterly_leads AS (
    SELECT
        c.channel,
        YEAR(c.start_date)          AS yr,
        QUARTER(c.start_date)       AS qtr,
        COUNT(l.lead_id)            AS total_leads,
        SUM(CASE WHEN l.status = 'converted' THEN 1 ELSE 0 END) AS converted
    FROM campaigns c
    LEFT JOIN leads l ON c.campaign_id = l.campaign_id
    GROUP BY c.channel, YEAR(c.start_date), QUARTER(c.start_date)
)
SELECT
    channel,
    yr,
    qtr,
    total_leads,
    converted,
    ROUND(converted / NULLIF(total_leads, 0) * 100, 2) AS conv_rate_pct,
    LAG(total_leads) OVER (
        PARTITION BY channel
        ORDER BY yr, qtr
    )                                       AS prev_qtr_leads,
    ROUND(
        (total_leads - LAG(total_leads) OVER (
            PARTITION BY channel
            ORDER BY yr, qtr
        ))
        / NULLIF(LAG(total_leads) OVER (
            PARTITION BY channel
            ORDER BY yr, qtr
        ), 0) * 100
    , 1)                                    AS qoq_lead_growth_pct,
    SUM(total_leads) OVER (
        PARTITION BY channel
        ORDER BY yr, qtr
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    )                                       AS cumulative_leads_by_channel
FROM quarterly_leads
ORDER BY channel, yr, qtr;

-- ============================================================
-- 9. WEBSITE: Session Conversion Rate Trend with LEAD()
-- Shows future period conversion rate to identify momentum
-- ============================================================
SELECT
    referrer_source,
    YEAR(session_start)                     AS session_year,
    MONTH(session_start)                    AS session_month,
    COUNT(session_id)                       AS total_sessions,
    SUM(converted)                          AS conversions,
    ROUND(
        SUM(converted)
        / NULLIF(COUNT(session_id), 0) * 100, 2
    )                                       AS conv_rate_pct,
    LEAD(
        ROUND(
            SUM(converted)
            / NULLIF(COUNT(session_id), 0) * 100, 2
        ), 1
    ) OVER (
        PARTITION BY referrer_source
        ORDER BY YEAR(session_start), MONTH(session_start)
    )                                       AS next_period_conv_rate_pct,
    SUM(SUM(converted)) OVER (
        PARTITION BY referrer_source
        ORDER BY YEAR(session_start), MONTH(session_start)
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    )                                       AS cumulative_conversions
FROM web_sessions
GROUP BY referrer_source, YEAR(session_start), MONTH(session_start)
ORDER BY referrer_source, session_year, session_month;

-- ============================================================
-- 10. TRENDS: Algorithm Update Impact Score Running Average
-- Tracks cumulative impact of algorithm changes over time
-- ============================================================
SELECT
    platform,
    update_name,
    update_date,
    update_type,
    our_impact_score,
    ROUND(AVG(our_impact_score) OVER (
        PARTITION BY platform
        ORDER BY     update_date
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 2)                                   AS rolling_3update_avg_impact,
    SUM(our_impact_score) OVER (
        PARTITION BY platform
        ORDER BY     update_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    )                                       AS cumulative_impact_by_platform,
    RANK() OVER (
        PARTITION BY platform
        ORDER BY our_impact_score DESC
    )                                       AS impact_rank_by_platform,
    LAG(our_impact_score) OVER (
        PARTITION BY platform
        ORDER BY     update_date
    )                                       AS prev_update_impact
FROM algorithm_updates
WHERE our_impact_score IS NOT NULL
ORDER BY platform, update_date;

SELECT 'Window function queries completed' AS status;
