-- ============================================================
-- MARKETING ANALYTICS PORTFOLIO PROJECT
-- File: 09_ctes_subqueries.sql
-- Description: Complex analytical queries using CTEs and
--              subqueries across all 10 marketing topics.
--              Demonstrates multi-step logic, correlated
--              subqueries, recursive CTEs, and EXISTS patterns.
-- Run Order: 9 of 10
-- ============================================================

USE marketing_analytics;

-- ============================================================
-- 1. SEO: Topic Cluster Authority Score
-- CTE chain: gather rankings → aggregate by cluster →
--            score → rank clusters by authority
-- ============================================================
WITH keyword_latest_rank AS (
    -- Step 1: get most recent position for each keyword
    SELECT
        r.keyword_id,
        r.position,
        r.impressions,
        r.clicks
    FROM seo_rankings r
    WHERE r.ranking_date = (
        SELECT MAX(r2.ranking_date)
        FROM   seo_rankings r2
        WHERE  r2.keyword_id = r.keyword_id        -- correlated subquery
    )
),
cluster_metrics AS (
    -- Step 2: aggregate to topic cluster level
    SELECT
        k.topic_cluster,
        COUNT(k.keyword_id)                         AS keyword_count,
        AVG(k.search_volume)                        AS avg_search_volume,
        AVG(lr.position)                            AS avg_position,
        SUM(lr.clicks)                              AS total_monthly_clicks,
        SUM(lr.impressions)                         AS total_monthly_impressions,
        COUNT(CASE WHEN lr.position <= 10 THEN 1 END) AS keywords_on_page_1
    FROM seo_keywords k
    JOIN keyword_latest_rank lr ON k.keyword_id = lr.keyword_id
    GROUP BY k.topic_cluster
),
cluster_scored AS (
    -- Step 3: compute authority score
    SELECT
        topic_cluster,
        keyword_count,
        avg_search_volume,
        ROUND(avg_position, 1)                      AS avg_position,
        total_monthly_clicks,
        keywords_on_page_1,
        ROUND(
            (keywords_on_page_1 / NULLIF(keyword_count,0)) * 40   -- % on page 1
            + LEAST(total_monthly_clicks / 100, 40)               -- click volume
            + GREATEST(30 - avg_position, 0)                      -- rank quality
        , 1)                                        AS authority_score
    FROM cluster_metrics
)
-- Step 4: final ranking
SELECT
    topic_cluster,
    keyword_count,
    ROUND(avg_search_volume, 0)                     AS avg_monthly_searches,
    avg_position,
    total_monthly_clicks,
    keywords_on_page_1,
    authority_score,
    RANK() OVER (ORDER BY authority_score DESC)     AS cluster_rank
FROM cluster_scored
ORDER BY authority_score DESC;

-- ============================================================
-- 2. SEO: Pages That Rank for Multiple Keywords (Subquery)
-- Finds pages appearing in rankings for 3+ keywords —
-- signals strong topical relevance
-- ============================================================
SELECT
    page_url,
    keyword_count,
    avg_position,
    total_monthly_clicks
FROM (
    SELECT
        r.page_url,
        COUNT(DISTINCT r.keyword_id)                AS keyword_count,
        ROUND(AVG(r.position), 1)                   AS avg_position,
        SUM(r.clicks)                               AS total_monthly_clicks
    FROM seo_rankings r
    WHERE r.ranking_date = (
        SELECT MAX(r2.ranking_date)                 -- correlated: latest date per keyword
        FROM   seo_rankings r2
        WHERE  r2.keyword_id = r.keyword_id
    )
    GROUP BY r.page_url
) ranked_pages
WHERE keyword_count >= 3
ORDER BY total_monthly_clicks DESC;

-- ============================================================
-- 3. PPC: Cost Efficiency vs Channel Average (Correlated Subquery)
-- For each ad, compare its CPL against the channel average CPL
-- to identify which ads beat the benchmark
-- ============================================================
SELECT
    c.channel,
    a.headline_1                                    AS ad_headline,
    ag.bid_strategy,
    SUM(p.spend)                                    AS total_spend,
    SUM(p.conversions)                              AS total_conversions,
    ROUND(
        SUM(p.spend) / NULLIF(SUM(p.conversions), 0), 2
    )                                               AS this_ad_cpa,
    -- Correlated subquery: avg CPA for this channel
    (
        SELECT ROUND(
            SUM(p2.spend) / NULLIF(SUM(p2.conversions), 0), 2
        )
        FROM ad_performance p2
        JOIN ads       a2  ON p2.ad_id       = a2.ad_id
        JOIN ad_groups ag2 ON a2.ad_group_id = ag2.ad_group_id
        JOIN campaigns c2  ON ag2.campaign_id = c2.campaign_id
        WHERE c2.channel = c.channel
    )                                               AS channel_avg_cpa,
    CASE
        WHEN SUM(p.spend) / NULLIF(SUM(p.conversions), 0)
             < (
                SELECT SUM(p2.spend) / NULLIF(SUM(p2.conversions), 0)
                FROM ad_performance p2
                JOIN ads       a2  ON p2.ad_id       = a2.ad_id
                JOIN ad_groups ag2 ON a2.ad_group_id = ag2.ad_group_id
                JOIN campaigns c2  ON ag2.campaign_id = c2.campaign_id
                WHERE c2.channel = c.channel
               )
        THEN 'Below Average (Good)' ELSE 'Above Average'
    END                                             AS cpa_vs_channel
FROM ad_performance p
JOIN ads       a  ON p.ad_id        = a.ad_id
JOIN ad_groups ag ON a.ad_group_id  = ag.ad_group_id
JOIN campaigns c  ON ag.campaign_id = c.campaign_id
GROUP BY c.channel, a.ad_id, a.headline_1, ag.bid_strategy
ORDER BY this_ad_cpa;

-- ============================================================
-- 4. EMAIL: Full Funnel Email Performance
-- CTE builds the funnel stages; subquery calculates list-level rates
-- ============================================================
WITH email_funnel AS (
    SELECT
        ec.email_campaign_id,
        ec.email_name,
        ec.email_type,
        ec.audience_segment,
        ec.list_size,
        ec.send_date,
        SUM(CASE WHEN ee.event_type = 'opened'       THEN 1 ELSE 0 END) AS opens,
        SUM(CASE WHEN ee.event_type = 'clicked'      THEN 1 ELSE 0 END) AS clicks,
        SUM(CASE WHEN ee.event_type = 'converted'    THEN 1 ELSE 0 END) AS conversions,
        SUM(CASE WHEN ee.event_type = 'unsubscribed' THEN 1 ELSE 0 END) AS unsubs,
        SUM(CASE WHEN ee.event_type = 'bounced'      THEN 1 ELSE 0 END) AS bounces
    FROM email_campaigns ec
    LEFT JOIN email_events ee ON ec.email_campaign_id = ee.email_campaign_id
    GROUP BY ec.email_campaign_id, ec.email_name, ec.email_type,
             ec.audience_segment, ec.list_size, ec.send_date
),
email_rates AS (
    SELECT
        *,
        ROUND(opens       / NULLIF(list_size, 0) * 100, 2) AS open_rate_pct,
        ROUND(clicks      / NULLIF(opens, 0)     * 100, 2) AS ctor_pct,
        ROUND(conversions / NULLIF(list_size, 0) * 100, 2) AS conv_rate_pct,
        ROUND(unsubs      / NULLIF(list_size, 0) * 100, 2) AS unsub_rate_pct,
        fn_email_health_grade(
            ROUND(opens / NULLIF(list_size, 0) * 100, 2)
        )                                                   AS email_grade
    FROM email_funnel
)
SELECT
    er.*,
    -- Subquery: how does this email's open rate compare to type average?
    ROUND(
        er.open_rate_pct - (
            SELECT AVG(ef2.opens / NULLIF(ef2.list_size, 0) * 100)
            FROM   email_funnel ef2
            WHERE  ef2.email_type = er.email_type
        )
    , 2)                                                    AS open_rate_vs_type_avg
FROM email_rates er
ORDER BY open_rate_pct DESC;

-- ============================================================
-- 5. GTM: Tags That Fired But Had No Downstream Conversion
-- Uses EXISTS / NOT EXISTS to find tracking gaps
-- ============================================================
SELECT
    t.tag_id,
    t.tag_name,
    t.tag_type,
    t.trigger_type,
    COUNT(we.web_event_id)                          AS total_fires,
    SUM(CASE WHEN we.event_name = 'form_submit' THEN 1 ELSE 0 END) AS form_submits
FROM gtm_tags t
JOIN web_events we ON t.tag_id = we.tag_id
WHERE t.is_active = 1
  -- Find tags that have fires but no associated conversion event
  AND NOT EXISTS (
      SELECT 1
      FROM   web_events we2
      WHERE  we2.tag_id     = t.tag_id
        AND  we2.event_name IN ('form_submit', 'purchase')
  )
GROUP BY t.tag_id, t.tag_name, t.tag_type, t.trigger_type
ORDER BY total_fires DESC;

-- ============================================================
-- 6. CONTENT: Content Pieces Above Their Type's Average Conversion Rate
-- Multi-step CTE: compute → average → filter above average
-- ============================================================
WITH content_stats AS (
    SELECT
        cp.content_id,
        cp.title,
        cp.content_type,
        cp.topic_cluster,
        cp.author,
        cp.publish_date,
        SUM(p.page_views)                           AS total_views,
        SUM(p.conversions)                          AS total_conversions,
        ROUND(
            SUM(p.conversions)
            / NULLIF(SUM(p.page_views), 0) * 100, 2
        )                                           AS conv_rate_pct
    FROM content_pieces cp
    JOIN content_performance p ON cp.content_id = p.content_id
    GROUP BY cp.content_id, cp.title, cp.content_type,
             cp.topic_cluster, cp.author, cp.publish_date
),
type_averages AS (
    SELECT
        content_type,
        ROUND(AVG(conv_rate_pct), 2)                AS avg_conv_rate
    FROM content_stats
    GROUP BY content_type
)
SELECT
    cs.content_type,
    cs.title,
    cs.author,
    cs.publish_date,
    cs.total_views,
    cs.total_conversions,
    cs.conv_rate_pct,
    ta.avg_conv_rate                                AS type_avg_conv_rate,
    ROUND(cs.conv_rate_pct - ta.avg_conv_rate, 2)  AS pct_above_avg
FROM content_stats cs
JOIN type_averages ta ON cs.content_type = ta.content_type
WHERE cs.conv_rate_pct > ta.avg_conv_rate
ORDER BY pct_above_avg DESC;

-- ============================================================
-- 7. AUDIENCE: Customers Who Appear in Multiple Audiences
-- Uses GROUP BY + HAVING with a subquery for audience names
-- ============================================================
SELECT
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name)          AS customer_name,
    c.segment,
    c.email,
    COUNT(DISTINCT am.audience_id)                  AS audience_count,
    -- Subquery to list audience names as comma-separated string
    (
        SELECT GROUP_CONCAT(a.audience_name ORDER BY a.audience_id SEPARATOR ' | ')
        FROM   audience_members am2
        JOIN   audiences a ON am2.audience_id = a.audience_id
        WHERE  am2.customer_id = c.customer_id
    )                                               AS audiences
FROM customers c
JOIN audience_members am ON c.customer_id = am.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name, c.segment, c.email
HAVING COUNT(DISTINCT am.audience_id) >= 2
ORDER BY audience_count DESC;

-- ============================================================
-- 8. MARKETING ANALYTICS: Full Attribution Model (CTE Pipeline)
-- Builds a first-touch, last-touch, and linear attribution model
-- from campaign → lead → order data
-- ============================================================
WITH lead_journey AS (
    -- Step 1: attach campaign channel to each converted lead
    SELECT
        l.lead_id,
        l.customer_id,
        l.deal_value,
        l.created_at                                AS first_touch_date,
        l.converted_at,
        c.channel                                   AS first_touch_channel,
        c.campaign_name                             AS first_touch_campaign
    FROM leads l
    JOIN campaigns c ON l.campaign_id = c.campaign_id
    WHERE l.status = 'converted'
      AND l.deal_value > 0
),
order_summary AS (
    -- Step 2: sum orders per customer
    SELECT
        customer_id,
        SUM(amount)                                 AS total_order_revenue,
        COUNT(order_id)                             AS order_count,
        MAX(order_date)                             AS last_order_date
    FROM orders
    GROUP BY customer_id
),
attribution_base AS (
    -- Step 3: join journey to orders
    SELECT
        lj.first_touch_channel,
        lj.first_touch_campaign,
        lj.deal_value                               AS pipeline_value,
        os.total_order_revenue                      AS actual_revenue,
        DATEDIFF(lj.converted_at, lj.first_touch_date) AS days_to_convert
    FROM lead_journey lj
    LEFT JOIN order_summary os ON lj.customer_id = os.customer_id
)
-- Step 4: attribution summary by channel
SELECT
    first_touch_channel,
    COUNT(*)                                        AS attributed_conversions,
    SUM(pipeline_value)                             AS total_pipeline,
    SUM(actual_revenue)                             AS total_revenue,
    ROUND(AVG(pipeline_value), 2)                   AS avg_deal_size,
    ROUND(AVG(days_to_convert), 1)                  AS avg_days_to_convert,
    -- Linear attribution share: each channel gets proportional credit
    ROUND(
        SUM(actual_revenue)
        / (SELECT SUM(actual_revenue) FROM attribution_base)
        * 100, 2
    )                                               AS revenue_share_pct
FROM attribution_base
GROUP BY first_touch_channel
ORDER BY total_revenue DESC;

-- ============================================================
-- 9. CAMPAIGN OPTIMIZATION: A/B Test Statistical Lift
-- CTE computes control vs variant metrics, then calculates lift
-- ============================================================
WITH variant_metrics AS (
    SELECT
        t.test_id,
        t.test_name,
        t.test_type,
        t.primary_metric,
        t.winner_variant,
        t.confidence_pct,
        v.variant_name,
        v.sample_size,
        v.clicks,
        v.conversions,
        v.revenue,
        ROUND(v.conversions / NULLIF(v.sample_size, 0) * 100, 2) AS conv_rate_pct,
        ROUND(v.revenue / NULLIF(v.conversions, 0), 2)           AS rev_per_conv
    FROM ab_tests t
    JOIN ab_variants v ON t.test_id = v.test_id
    WHERE t.status = 'completed'
),
control_baseline AS (
    SELECT
        test_id,
        conv_rate_pct                               AS control_conv_rate,
        rev_per_conv                                AS control_rpv
    FROM variant_metrics
    WHERE variant_name = 'control'
),
lift_calc AS (
    SELECT
        vm.test_id,
        vm.test_name,
        vm.test_type,
        vm.primary_metric,
        vm.winner_variant,
        vm.confidence_pct,
        vm.variant_name,
        vm.sample_size,
        vm.conv_rate_pct,
        cb.control_conv_rate,
        -- Lift vs control
        ROUND(
            (vm.conv_rate_pct - cb.control_conv_rate)
            / NULLIF(cb.control_conv_rate, 0) * 100, 1
        )                                           AS conv_rate_lift_pct,
        ROUND(
            (vm.rev_per_conv - cb.control_rpv)
            / NULLIF(cb.control_rpv, 0) * 100, 1
        )                                           AS revenue_lift_pct,
        CASE
            WHEN vm.variant_name = vm.winner_variant THEN 'Winner'
            WHEN vm.variant_name = 'control'         THEN 'Baseline'
            ELSE 'Loser'
        END                                         AS result_label
    FROM variant_metrics vm
    JOIN control_baseline cb ON vm.test_id = cb.test_id
)
SELECT *
FROM lift_calc
ORDER BY test_id, variant_name;

-- ============================================================
-- 10. WEBSITE: Full Conversion Funnel by Traffic Source
-- Recursive-style CTE maps funnel stages as sequential steps
-- then subquery shows drop-off between each stage
-- ============================================================
WITH funnel_stages AS (
    SELECT 'All Sessions'               AS stage, 1 AS stage_order,
           COUNT(*)                     AS session_count,
           'all'                        AS filter_source
    FROM web_sessions

    UNION ALL

    SELECT 'Multi-Page Sessions',        2,
           COUNT(*),                     'multi_page'
    FROM web_sessions WHERE pages_viewed > 1

    UNION ALL

    SELECT 'Reached Pricing or Demo',    3,
           COUNT(*),                     'high_intent'
    FROM web_sessions
    WHERE landing_page IN ('/pricing', '/demo', '/trial')
       OR landing_page LIKE '%pricing%'
       OR landing_page LIKE '%demo%'

    UNION ALL

    SELECT 'Converted',                  4,
           SUM(converted),               'converted'
    FROM web_sessions
),
funnel_with_dropoff AS (
    SELECT
        stage,
        stage_order,
        session_count,
        LAG(session_count) OVER (ORDER BY stage_order) AS prev_stage_count
    FROM funnel_stages
)
SELECT
    stage_order,
    stage,
    session_count,
    prev_stage_count,
    ROUND(
        session_count
        / NULLIF(prev_stage_count, 0) * 100, 1
    )                                               AS step_retention_pct,
    ROUND(
        session_count
        / NULLIF(
            FIRST_VALUE(session_count) OVER (ORDER BY stage_order), 0
        ) * 100, 1
    )                                               AS overall_funnel_pct
FROM funnel_with_dropoff
ORDER BY stage_order;

-- ============================================================
-- 11. TRENDS: Campaigns Active During High-Impact Updates
-- Uses EXISTS to find campaigns running during major algorithm
-- updates (impact >= 2) — useful for performance attribution
-- ============================================================
SELECT
    c.campaign_name,
    c.channel,
    c.start_date,
    c.end_date,
    c.spend,
    -- Subquery: count of high-impact updates during campaign window
    (
        SELECT COUNT(*)
        FROM   algorithm_updates au
        WHERE  au.our_impact_score >= 2
          AND  au.update_date BETWEEN c.start_date AND COALESCE(c.end_date, CURDATE())
    )                                               AS high_impact_updates_during_run,
    -- Subquery: most impactful update name during campaign
    (
        SELECT au.update_name
        FROM   algorithm_updates au
        WHERE  au.our_impact_score >= 2
          AND  au.update_date BETWEEN c.start_date AND COALESCE(c.end_date, CURDATE())
        ORDER BY au.our_impact_score DESC
        LIMIT 1
    )                                               AS most_impactful_update
FROM campaigns c
WHERE EXISTS (
    SELECT 1
    FROM   algorithm_updates au
    WHERE  au.our_impact_score >= 2
      AND  au.update_date BETWEEN c.start_date AND COALESCE(c.end_date, CURDATE())
)
ORDER BY c.start_date;

SELECT 'CTE and subquery examples completed' AS status;
