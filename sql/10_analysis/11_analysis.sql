-- ============================================================
-- MARKETING ANALYTICS PORTFOLIO PROJECT
-- File: 11_analysis.sql
-- Description: 10 production-grade analytical queries — one
--              per digital marketing topic. Each query ties
--              together multiple tables, SQL techniques, and
--              UDFs to answer a real business question.
-- Run Order: After all other files
-- ============================================================

USE marketing_analytics;

-- ============================================================
-- QUERY 1: SEO — Organic Search ROI Dashboard
-- Business Question: Which keywords are driving the most
-- revenue-qualified traffic and how has organic performance
-- trended YoY?
-- Techniques: CTEs, window functions, correlated subquery, UDF
-- ============================================================
WITH keyword_traffic AS (
    SELECT
        k.keyword_id,
        k.keyword,
        k.search_volume,
        k.intent_type,
        k.topic_cluster,
        r.ranking_date,
        r.position,
        r.clicks,
        r.impressions,
        ROUND(r.clicks / NULLIF(r.impressions, 0) * 100, 2) AS ctr_pct
    FROM seo_keywords k
    JOIN seo_rankings r ON k.keyword_id = r.keyword_id
),
keyword_yoy AS (
    SELECT
        keyword_id,
        keyword,
        search_volume,
        intent_type,
        topic_cluster,
        MAX(CASE WHEN ranking_date <= '2023-12-31' THEN clicks END) AS clicks_2023,
        MAX(CASE WHEN ranking_date  > '2023-12-31' THEN clicks END) AS clicks_2024,
        MIN(CASE WHEN ranking_date <= '2023-12-31' THEN position END) AS best_pos_2023,
        MIN(CASE WHEN ranking_date  > '2023-12-31' THEN position END) AS best_pos_2024
    FROM keyword_traffic
    GROUP BY keyword_id, keyword, search_volume, intent_type, topic_cluster
)
SELECT
    keyword,
    search_volume,
    intent_type,
    topic_cluster,
    best_pos_2023,
    best_pos_2024,
    fn_seo_rank_tier(best_pos_2024)                 AS current_rank_tier,
    clicks_2023,
    clicks_2024,
    ROUND(
        (clicks_2024 - clicks_2023) / NULLIF(clicks_2023, 0) * 100, 1
    )                                               AS yoy_click_growth_pct,
    RANK() OVER (ORDER BY clicks_2024 DESC)         AS click_volume_rank
FROM keyword_yoy
WHERE clicks_2024 IS NOT NULL
ORDER BY clicks_2024 DESC;

-- ============================================================
-- QUERY 2: PPC — Google Ads Performance vs Target Benchmarks
-- Business Question: Which ads are beating our target CPA of
-- $75, and which bid strategies are most efficient?
-- Techniques: CTEs, CASE, window function, UDF
-- ============================================================
WITH ad_totals AS (
    SELECT
        c.channel,
        c.campaign_name,
        ag.ad_group_name,
        ag.bid_strategy,
        a.headline_1,
        a.ad_type,
        SUM(p.impressions)      AS impressions,
        SUM(p.clicks)           AS clicks,
        SUM(p.spend)            AS spend,
        SUM(p.conversions)      AS conversions,
        SUM(p.conversion_value) AS revenue,
        ROUND(AVG(p.quality_score), 1) AS avg_qs
    FROM ad_performance p
    JOIN ads       a  ON p.ad_id        = a.ad_id
    JOIN ad_groups ag ON a.ad_group_id  = ag.ad_group_id
    JOIN campaigns c  ON ag.campaign_id = c.campaign_id
    GROUP BY c.channel, c.campaign_name, ag.ad_group_name,
             ag.bid_strategy, a.headline_1, a.ad_type
)
SELECT
    channel,
    campaign_name,
    bid_strategy,
    headline_1,
    impressions,
    clicks,
    ROUND(clicks / NULLIF(impressions, 0) * 100, 2) AS ctr_pct,
    spend,
    conversions,
    fn_calculate_roas(revenue, spend)               AS roas,
    ROUND(spend / NULLIF(conversions, 0), 2)        AS cpa,
    avg_qs,
    CASE
        WHEN spend / NULLIF(conversions, 0) < 75    THEN 'Under Target (Good)'
        WHEN spend / NULLIF(conversions, 0) < 100   THEN 'Near Target'
        ELSE 'Over Target'
    END                                             AS cpa_vs_target,
    fn_channel_perf_tier(
        fn_calculate_roas(revenue, spend)
    )                                               AS invest_decision,
    RANK() OVER (ORDER BY fn_calculate_roas(revenue, spend) DESC) AS roas_rank
FROM ad_totals
ORDER BY roas DESC;

-- ============================================================
-- QUERY 3: EMAIL — Segment Engagement and Revenue Attribution
-- Business Question: Which audience segments and email types
-- drive the highest conversion rates and downstream revenue?
-- Techniques: CTEs, conditional aggregation, subquery
-- ============================================================
WITH email_perf AS (
    SELECT
        ec.email_campaign_id,
        ec.audience_segment,
        ec.email_type,
        ec.list_size,
        YEAR(ec.send_date)                          AS send_year,
        SUM(CASE WHEN ee.event_type = 'opened'    THEN 1 ELSE 0 END) AS opens,
        SUM(CASE WHEN ee.event_type = 'clicked'   THEN 1 ELSE 0 END) AS clicks,
        SUM(CASE WHEN ee.event_type = 'converted' THEN 1 ELSE 0 END) AS conversions
    FROM email_campaigns ec
    LEFT JOIN email_events ee ON ec.email_campaign_id = ee.email_campaign_id
    GROUP BY ec.email_campaign_id, ec.audience_segment,
             ec.email_type, ec.list_size, YEAR(ec.send_date)
),
segment_summary AS (
    SELECT
        audience_segment,
        email_type,
        send_year,
        SUM(list_size)                              AS total_sends,
        SUM(opens)                                  AS total_opens,
        SUM(clicks)                                 AS total_clicks,
        SUM(conversions)                            AS total_conversions,
        ROUND(SUM(opens) / NULLIF(SUM(list_size),0) * 100, 2)       AS open_rate_pct,
        ROUND(SUM(conversions) / NULLIF(SUM(list_size),0) * 100, 2) AS conv_rate_pct
    FROM email_perf
    GROUP BY audience_segment, email_type, send_year
)
SELECT
    audience_segment,
    email_type,
    send_year,
    total_sends,
    total_opens,
    total_conversions,
    open_rate_pct,
    conv_rate_pct,
    fn_email_health_grade(open_rate_pct)            AS email_grade,
    -- Compare to overall average (subquery)
    ROUND(
        conv_rate_pct - (
            SELECT AVG(conv_rate_pct)
            FROM   segment_summary s2
            WHERE  s2.email_type = segment_summary.email_type
        ), 2
    )                                               AS conv_rate_vs_type_avg
FROM segment_summary
ORDER BY conv_rate_pct DESC;

-- ============================================================
-- QUERY 4: GTM — Tag Coverage and Conversion Tracking Audit
-- Business Question: Which pages have full GTM tag coverage
-- and which have tracking gaps affecting attribution?
-- Techniques: LEFT JOIN, conditional aggregation, EXISTS
-- ============================================================
SELECT
    wp.page_url,
    wp.page_type,
    wp.page_title,
    wp.cta_text,
    COUNT(DISTINCT we.tag_id)                       AS distinct_tags_fired,
    COUNT(DISTINCT we.web_event_id)                 AS total_events,
    SUM(CASE WHEN we.event_name = 'page_view'    THEN 1 ELSE 0 END) AS page_views,
    SUM(CASE WHEN we.event_name = 'cta_click'    THEN 1 ELSE 0 END) AS cta_clicks,
    SUM(CASE WHEN we.event_name = 'form_submit'  THEN 1 ELSE 0 END) AS form_submits,
    SUM(CASE WHEN we.event_name = 'scroll_50'    THEN 1 ELSE 0 END) AS scroll_50_events,
    ROUND(
        SUM(CASE WHEN we.event_name = 'cta_click' THEN 1 ELSE 0 END)
        / NULLIF(SUM(CASE WHEN we.event_name = 'page_view' THEN 1 ELSE 0 END), 0)
        * 100, 2
    )                                               AS cta_click_rate_pct,
    CASE
        WHEN EXISTS (
            SELECT 1 FROM web_events we2
            WHERE we2.page_url = wp.page_url
              AND we2.event_name = 'form_submit'
        ) THEN 'Yes' ELSE 'No'
    END                                             AS has_conversion_tracking
FROM web_pages wp
LEFT JOIN web_events we ON wp.page_url = we.page_url
WHERE wp.is_active = 1
GROUP BY wp.page_url, wp.page_type, wp.page_title, wp.cta_text
ORDER BY total_events DESC;

-- ============================================================
-- QUERY 5: CONTENT — Topic Cluster Content Audit
-- Business Question: Which topic clusters have the strongest
-- content portfolios? Which clusters need more pieces?
-- Techniques: CTEs, window functions, aggregation
-- ============================================================
WITH cluster_content AS (
    SELECT
        cp.topic_cluster,
        cp.content_type,
        COUNT(cp.content_id)                        AS piece_count,
        SUM(p.page_views)                           AS total_views,
        SUM(p.conversions)                          AS total_conversions,
        SUM(p.backlinks_earned)                     AS total_backlinks,
        ROUND(AVG(p.bounce_rate_pct), 2)            AS avg_bounce_rate,
        ROUND(AVG(p.avg_time_sec), 0)               AS avg_time_sec
    FROM content_pieces cp
    JOIN content_performance p ON cp.content_id = p.content_id
    WHERE cp.status = 'published'
    GROUP BY cp.topic_cluster, cp.content_type
),
cluster_totals AS (
    SELECT
        topic_cluster,
        SUM(piece_count)                            AS total_pieces,
        SUM(total_views)                            AS cluster_views,
        SUM(total_conversions)                      AS cluster_conversions,
        SUM(total_backlinks)                        AS cluster_backlinks,
        ROUND(AVG(avg_bounce_rate), 2)              AS cluster_avg_bounce
    FROM cluster_content
    GROUP BY topic_cluster
)
SELECT
    ct.topic_cluster,
    ct.total_pieces,
    ct.cluster_views,
    ct.cluster_conversions,
    ct.cluster_backlinks,
    ct.cluster_avg_bounce,
    ROUND(ct.cluster_conversions / NULLIF(ct.cluster_views, 0) * 100, 2) AS cluster_conv_rate,
    RANK() OVER (ORDER BY ct.cluster_conversions DESC)  AS conv_rank,
    RANK() OVER (ORDER BY ct.cluster_views DESC)        AS traffic_rank,
    CASE
        WHEN ct.total_pieces < 3 THEN 'Needs Content'
        WHEN ct.total_pieces < 6 THEN 'Growing'
        ELSE 'Established'
    END                                             AS cluster_maturity
FROM cluster_totals ct
ORDER BY cluster_conversions DESC;

-- ============================================================
-- QUERY 6: AUDIENCE — Multi-Channel Audience Overlap and Value
-- Business Question: Which customer segments respond to
-- multiple channels and generate the most revenue?
-- Techniques: CTEs, conditional aggregation, subqueries
-- ============================================================
WITH customer_channels AS (
    SELECT
        l.customer_id,
        COUNT(DISTINCT c.channel)                   AS channels_touched,
        GROUP_CONCAT(DISTINCT c.channel ORDER BY c.channel SEPARATOR ', ') AS channel_mix,
        SUM(CASE WHEN c.channel = 'Email'    THEN 1 ELSE 0 END) AS email_touches,
        SUM(CASE WHEN c.channel = 'Paid'     THEN 1 ELSE 0 END) AS paid_touches,
        SUM(CASE WHEN c.channel = 'Social'   THEN 1 ELSE 0 END) AS social_touches,
        SUM(CASE WHEN c.channel = 'Organic'  THEN 1 ELSE 0 END) AS organic_touches,
        SUM(CASE WHEN c.channel = 'Referral' THEN 1 ELSE 0 END) AS referral_touches
    FROM leads l
    JOIN campaigns c ON l.campaign_id = c.campaign_id
    WHERE l.customer_id IS NOT NULL
    GROUP BY l.customer_id
),
customer_revenue AS (
    SELECT
        cu.customer_id,
        cu.segment,
        COALESCE(SUM(o.amount), 0)                  AS total_revenue,
        COUNT(o.order_id)                            AS order_count
    FROM customers cu
    LEFT JOIN orders o ON cu.customer_id = o.customer_id
    GROUP BY cu.customer_id, cu.segment
)
SELECT
    cr.segment,
    cc.channels_touched,
    cc.channel_mix,
    COUNT(cr.customer_id)                           AS customer_count,
    ROUND(AVG(cr.total_revenue), 2)                 AS avg_revenue,
    SUM(cr.total_revenue)                           AS total_revenue,
    ROUND(AVG(cr.order_count), 1)                   AS avg_orders,
    fn_clv_tier(AVG(cr.total_revenue))              AS avg_clv_tier
FROM customer_revenue cr
JOIN customer_channels cc ON cr.customer_id = cc.customer_id
GROUP BY cr.segment, cc.channels_touched, cc.channel_mix
ORDER BY avg_revenue DESC;

-- ============================================================
-- QUERY 7: MARKETING ANALYTICS — Executive KPI Report (YoY)
-- Business Question: How did key marketing KPIs change YoY
-- across all channels? What drove the growth?
-- Techniques: CTEs, conditional aggregation, LAG window function
-- ============================================================
WITH yearly_kpis AS (
    SELECT
        YEAR(c.start_date)                          AS yr,
        c.channel,
        SUM(c.budget)                               AS total_budget,
        SUM(c.spend)                                AS total_spend,
        COUNT(DISTINCT c.campaign_id)               AS campaigns_run,
        COUNT(DISTINCT l.lead_id)                   AS total_leads,
        COUNT(DISTINCT CASE WHEN l.status = 'converted' THEN l.lead_id END) AS conversions,
        COALESCE(SUM(l.deal_value), 0)              AS total_pipeline
    FROM campaigns c
    LEFT JOIN leads l ON c.campaign_id = l.campaign_id
    GROUP BY YEAR(c.start_date), c.channel
)
SELECT
    channel,
    yr,
    total_budget,
    total_spend,
    total_leads,
    conversions,
    total_pipeline,
    ROUND(conversions / NULLIF(total_leads, 0) * 100, 2)  AS conv_rate_pct,
    ROUND(total_spend / NULLIF(total_leads, 0), 2)         AS cpl,
    fn_calculate_roas(total_pipeline, total_spend)         AS roas,
    fn_channel_perf_tier(
        fn_calculate_roas(total_pipeline, total_spend)
    )                                               AS perf_tier,
    -- YoY comparisons via LAG
    ROUND(
        (total_leads - LAG(total_leads) OVER (PARTITION BY channel ORDER BY yr))
        / NULLIF(LAG(total_leads) OVER (PARTITION BY channel ORDER BY yr), 0) * 100, 1
    )                                               AS yoy_lead_growth_pct,
    ROUND(
        (total_pipeline - LAG(total_pipeline) OVER (PARTITION BY channel ORDER BY yr))
        / NULLIF(LAG(total_pipeline) OVER (PARTITION BY channel ORDER BY yr), 0) * 100, 1
    )                                               AS yoy_pipeline_growth_pct
FROM yearly_kpis
ORDER BY channel, yr;

-- ============================================================
-- QUERY 8: TRENDS — Campaign Performance During Algorithm Updates
-- Business Question: Did major search algorithm updates
-- materially impact campaign performance?
-- Techniques: CTEs, date range joins, conditional aggregation
-- ============================================================
WITH update_windows AS (
    SELECT
        update_id,
        platform,
        update_name,
        update_date,
        update_type,
        our_impact_score,
        DATE_SUB(update_date, INTERVAL 30 DAY)  AS window_start,
        DATE_ADD(update_date, INTERVAL 30 DAY)  AS window_end
    FROM algorithm_updates
    WHERE our_impact_score IS NOT NULL
),
campaign_performance_by_period AS (
    SELECT
        uw.update_name,
        uw.platform,
        uw.update_date,
        uw.our_impact_score,
        -- Campaigns active DURING the update window
        COUNT(DISTINCT CASE
            WHEN c.start_date <= uw.window_end
             AND COALESCE(c.end_date, CURDATE()) >= uw.window_start
            THEN c.campaign_id END)               AS active_campaigns,
        SUM(CASE
            WHEN c.start_date <= uw.window_end
             AND COALESCE(c.end_date, CURDATE()) >= uw.window_start
            THEN c.spend ELSE 0 END)              AS spend_in_window,
        COUNT(DISTINCT CASE
            WHEN c.start_date <= uw.window_end
             AND COALESCE(c.end_date, CURDATE()) >= uw.window_start
             AND l.status = 'converted'
            THEN l.lead_id END)                   AS conversions_in_window
    FROM update_windows uw
    LEFT JOIN campaigns c ON c.channel IN ('Organic', 'Paid')   -- channels affected by search updates
    LEFT JOIN leads     l ON l.campaign_id = c.campaign_id
    GROUP BY uw.update_id, uw.update_name, uw.platform,
             uw.update_date, uw.our_impact_score
)
SELECT
    update_name,
    platform,
    update_date,
    our_impact_score,
    CASE
        WHEN our_impact_score >= 2  THEN 'Positive'
        WHEN our_impact_score <= -1 THEN 'Negative'
        ELSE 'Neutral'
    END                                           AS impact_direction,
    active_campaigns,
    spend_in_window,
    conversions_in_window,
    ROUND(spend_in_window / NULLIF(conversions_in_window, 0), 2) AS cpa_in_window
FROM campaign_performance_by_period
ORDER BY update_date;

-- ============================================================
-- QUERY 9: CAMPAIGN OPTIMIZATION — A/B Test ROI Summary
-- Business Question: What has been the cumulative revenue
-- impact of all winning A/B tests combined?
-- Techniques: CTEs, conditional aggregation, running totals
-- ============================================================
WITH test_results AS (
    SELECT
        t.test_id,
        t.test_name,
        t.test_type,
        t.start_date,
        t.end_date,
        t.winner_variant,
        t.confidence_pct,
        -- Control metrics
        MAX(CASE WHEN v.variant_name = 'control'
            THEN ROUND(v.conversions / NULLIF(v.sample_size,0) * 100, 2) END) AS control_conv_pct,
        MAX(CASE WHEN v.variant_name = 'control'
            THEN v.revenue END)                     AS control_revenue,
        -- Winner metrics
        MAX(CASE WHEN v.variant_name = t.winner_variant AND v.variant_name != 'control'
            THEN ROUND(v.conversions / NULLIF(v.sample_size,0) * 100, 2) END) AS winner_conv_pct,
        MAX(CASE WHEN v.variant_name = t.winner_variant AND v.variant_name != 'control'
            THEN v.revenue END)                     AS winner_revenue
    FROM ab_tests t
    JOIN ab_variants v ON t.test_id = v.test_id
    WHERE t.status = 'completed'
      AND t.winner_variant != 'control'
    GROUP BY t.test_id, t.test_name, t.test_type,
             t.start_date, t.end_date, t.winner_variant, t.confidence_pct
),
test_lift AS (
    SELECT
        *,
        ROUND(winner_revenue - control_revenue, 2)  AS revenue_lift,
        ROUND(
            (winner_conv_pct - control_conv_pct)
            / NULLIF(control_conv_pct, 0) * 100, 1
        )                                           AS conv_rate_lift_pct
    FROM test_results
)
SELECT
    test_id,
    test_name,
    test_type,
    start_date,
    confidence_pct,
    control_conv_pct,
    winner_conv_pct,
    conv_rate_lift_pct,
    control_revenue,
    winner_revenue,
    revenue_lift,
    SUM(revenue_lift) OVER (
        ORDER BY start_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    )                                               AS cumulative_test_revenue_lift
FROM test_lift
ORDER BY start_date;

-- ============================================================
-- QUERY 10: WEBSITE — Full Funnel CRO Report
-- Business Question: Where are visitors dropping off, which
-- pages need optimization, and which traffic sources convert best?
-- Techniques: CTEs, window functions, LEFT JOIN, subquery
-- ============================================================
WITH page_performance AS (
    SELECT
        ws.landing_page,
        ws.referrer_source,
        ws.device_type,
        YEAR(ws.session_start)                      AS session_year,
        COUNT(ws.session_id)                        AS sessions,
        ROUND(AVG(ws.pages_viewed), 2)              AS avg_pages,
        SUM(ws.converted)                           AS conversions,
        ROUND(
            SUM(ws.converted) / NULLIF(COUNT(ws.session_id), 0) * 100, 2
        )                                           AS conv_rate_pct,
        ROUND(
            SUM(ws.conversion_value), 2
        )                                           AS total_value
    FROM web_sessions ws
    GROUP BY ws.landing_page, ws.referrer_source, ws.device_type, YEAR(ws.session_start)
),
page_vitals_latest AS (
    SELECT
        page_url,
        lcp_ms,
        mobile_score,
        desktop_score,
        fn_lcp_rating(lcp_ms)                       AS lcp_rating
    FROM web_vitals wv
    WHERE vital_date = (
        SELECT MAX(vital_date) FROM web_vitals wv2
        WHERE wv2.page_url = wv.page_url             -- correlated subquery
    )
)
SELECT
    pp.landing_page,
    pp.referrer_source,
    pp.device_type,
    pp.session_year,
    pp.sessions,
    pp.avg_pages,
    pp.conversions,
    pp.conv_rate_pct,
    pp.total_value,
    pvl.lcp_ms,
    pvl.lcp_rating,
    pvl.mobile_score,
    pvl.desktop_score,
    RANK() OVER (
        PARTITION BY pp.session_year
        ORDER BY pp.conv_rate_pct DESC
    )                                               AS conv_rate_rank,
    CASE
        WHEN pvl.mobile_score < 50 AND pp.device_type = 'mobile'
        THEN 'CRO Priority: Poor Mobile Speed'
        WHEN pp.conv_rate_pct < 1.0
        THEN 'CRO Priority: Low Conversion Rate'
        WHEN pvl.lcp_rating = 'Poor'
        THEN 'CRO Priority: Core Web Vitals'
        ELSE 'Performing'
    END                                             AS optimization_flag
FROM page_performance pp
LEFT JOIN page_vitals_latest pvl ON pp.landing_page = pvl.page_url
ORDER BY pp.conv_rate_pct DESC;

SELECT 'All analysis queries completed' AS status;
