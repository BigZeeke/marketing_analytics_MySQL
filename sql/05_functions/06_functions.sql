-- ============================================================
-- MARKETING ANALYTICS PORTFOLIO PROJECT
-- File: 06_functions.sql
-- Description: 10 scalar User-Defined Functions covering
--              marketing KPI calculations, lead scoring,
--              channel classification, and content grading
-- Run Order: 6 of 10
-- ============================================================

USE marketing_analytics;

-- ============================================================
-- FUNCTION 1: Calculate ROAS
-- Returns revenue / spend, handles divide-by-zero safely
-- Usage: SELECT fn_calculate_roas(pipeline, spend)
-- ============================================================
DROP FUNCTION IF EXISTS fn_calculate_roas;
DELIMITER $$
CREATE FUNCTION fn_calculate_roas(
    p_revenue DECIMAL(12,2),
    p_spend   DECIMAL(12,2)
)
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    IF p_spend IS NULL OR p_spend = 0 THEN
        RETURN NULL;
    END IF;
    RETURN ROUND(p_revenue / p_spend, 2);
END $$
DELIMITER ;

-- ============================================================
-- FUNCTION 2: Lead Score Tier Label
-- Converts numeric score to human-readable tier
-- Usage: SELECT fn_lead_score_tier(score)
-- ============================================================
DROP FUNCTION IF EXISTS fn_lead_score_tier;
DELIMITER $$
CREATE FUNCTION fn_lead_score_tier(
    p_score INT
)
RETURNS VARCHAR(20)
DETERMINISTIC
BEGIN
    DECLARE v_tier VARCHAR(20);
    IF p_score IS NULL THEN
        SET v_tier = 'Unscored';
    ELSEIF p_score >= 85 THEN
        SET v_tier = 'Hot';
    ELSEIF p_score >= 65 THEN
        SET v_tier = 'Warm';
    ELSEIF p_score >= 40 THEN
        SET v_tier = 'Cold';
    ELSE
        SET v_tier = 'Stale';
    END IF;
    RETURN v_tier;
END $$
DELIMITER ;

-- ============================================================
-- FUNCTION 3: Cost Per Lead
-- Returns spend / lead count safely
-- Usage: SELECT fn_cost_per_lead(spend, lead_count)
-- ============================================================
DROP FUNCTION IF EXISTS fn_cost_per_lead;
DELIMITER $$
CREATE FUNCTION fn_cost_per_lead(
    p_spend      DECIMAL(12,2),
    p_lead_count INT
)
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    IF p_lead_count IS NULL OR p_lead_count = 0 THEN
        RETURN NULL;
    END IF;
    RETURN ROUND(p_spend / p_lead_count, 2);
END $$
DELIMITER ;

-- ============================================================
-- FUNCTION 4: Email Health Grade
-- Grades an email campaign A-F based on open rate
-- Usage: SELECT fn_email_health_grade(open_rate_pct)
-- ============================================================
DROP FUNCTION IF EXISTS fn_email_health_grade;
DELIMITER $$
CREATE FUNCTION fn_email_health_grade(
    p_open_rate_pct DECIMAL(5,2)
)
RETURNS VARCHAR(2)
DETERMINISTIC
BEGIN
    DECLARE v_grade VARCHAR(2);
    IF p_open_rate_pct IS NULL THEN
        SET v_grade = 'N/A';
    ELSEIF p_open_rate_pct >= 35 THEN
        SET v_grade = 'A';
    ELSEIF p_open_rate_pct >= 25 THEN
        SET v_grade = 'B';
    ELSEIF p_open_rate_pct >= 18 THEN
        SET v_grade = 'C';
    ELSEIF p_open_rate_pct >= 10 THEN
        SET v_grade = 'D';
    ELSE
        SET v_grade = 'F';
    END IF;
    RETURN v_grade;
END $$
DELIMITER ;

-- ============================================================
-- FUNCTION 5: SEO Rank Tier Label
-- Maps numeric position to rank tier string
-- Usage: SELECT fn_seo_rank_tier(position)
-- ============================================================
DROP FUNCTION IF EXISTS fn_seo_rank_tier;
DELIMITER $$
CREATE FUNCTION fn_seo_rank_tier(
    p_position INT
)
RETURNS VARCHAR(20)
DETERMINISTIC
BEGIN
    DECLARE v_tier VARCHAR(20);
    IF p_position IS NULL THEN
        SET v_tier = 'Not Ranking';
    ELSEIF p_position = 1 THEN
        SET v_tier = 'Position 1';
    ELSEIF p_position BETWEEN 2 AND 3 THEN
        SET v_tier = 'Top 3';
    ELSEIF p_position BETWEEN 4 AND 10 THEN
        SET v_tier = 'Page 1';
    ELSEIF p_position BETWEEN 11 AND 20 THEN
        SET v_tier = 'Page 2';
    ELSE
        SET v_tier = 'Page 3+';
    END IF;
    RETURN v_tier;
END $$
DELIMITER ;

-- ============================================================
-- FUNCTION 6: Web Vitals LCP Rating
-- Rates Largest Contentful Paint score (ms) per Google spec
-- Good < 2500ms | Needs Improvement < 4000ms | Poor >= 4000ms
-- Usage: SELECT fn_lcp_rating(lcp_ms)
-- ============================================================
DROP FUNCTION IF EXISTS fn_lcp_rating;
DELIMITER $$
CREATE FUNCTION fn_lcp_rating(
    p_lcp_ms INT
)
RETURNS VARCHAR(20)
DETERMINISTIC
BEGIN
    DECLARE v_rating VARCHAR(20);
    IF p_lcp_ms IS NULL THEN
        SET v_rating = 'No Data';
    ELSEIF p_lcp_ms < 2500 THEN
        SET v_rating = 'Good';
    ELSEIF p_lcp_ms < 4000 THEN
        SET v_rating = 'Needs Improvement';
    ELSE
        SET v_rating = 'Poor';
    END IF;
    RETURN v_rating;
END $$
DELIMITER ;

-- ============================================================
-- FUNCTION 7: Channel Performance Tier
-- Classifies ROAS into investment decision buckets
-- Usage: SELECT fn_channel_perf_tier(roas)
-- ============================================================
DROP FUNCTION IF EXISTS fn_channel_perf_tier;
DELIMITER $$
CREATE FUNCTION fn_channel_perf_tier(
    p_roas DECIMAL(10,2)
)
RETURNS VARCHAR(20)
DETERMINISTIC
BEGIN
    DECLARE v_tier VARCHAR(20);
    IF p_roas IS NULL THEN
        SET v_tier = 'No Data';
    ELSEIF p_roas >= 6.0 THEN
        SET v_tier = 'Star';
    ELSEIF p_roas >= 3.0 THEN
        SET v_tier = 'Scale';
    ELSEIF p_roas >= 1.5 THEN
        SET v_tier = 'Maintain';
    ELSEIF p_roas >= 1.0 THEN
        SET v_tier = 'Watch';
    ELSE
        SET v_tier = 'Pause';
    END IF;
    RETURN v_tier;
END $$
DELIMITER ;

-- ============================================================
-- FUNCTION 8: Content Quality Score
-- Combines engagement signals into a 0-100 score
-- Usage: SELECT fn_content_quality_score(views, time_sec, bounce_pct, shares)
-- ============================================================
DROP FUNCTION IF EXISTS fn_content_quality_score;
DELIMITER $$
CREATE FUNCTION fn_content_quality_score(
    p_page_views    INT,
    p_avg_time_sec  INT,
    p_bounce_rate   DECIMAL(5,2),
    p_social_shares INT
)
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE v_time_score    INT DEFAULT 0;
    DECLARE v_bounce_score  INT DEFAULT 0;
    DECLARE v_share_score   INT DEFAULT 0;
    DECLARE v_view_score    INT DEFAULT 0;

    -- Time on page (max 40 pts): > 3 min is excellent
    SET v_time_score = CASE
        WHEN p_avg_time_sec >= 180 THEN 40
        WHEN p_avg_time_sec >= 120 THEN 30
        WHEN p_avg_time_sec >= 60  THEN 20
        WHEN p_avg_time_sec >= 30  THEN 10
        ELSE 0
    END;

    -- Bounce rate (max 30 pts): lower is better
    SET v_bounce_score = CASE
        WHEN p_bounce_rate < 35  THEN 30
        WHEN p_bounce_rate < 50  THEN 22
        WHEN p_bounce_rate < 65  THEN 14
        WHEN p_bounce_rate < 75  THEN 7
        ELSE 0
    END;

    -- Social shares (max 20 pts)
    SET v_share_score = CASE
        WHEN p_social_shares >= 500 THEN 20
        WHEN p_social_shares >= 200 THEN 15
        WHEN p_social_shares >= 50  THEN 10
        WHEN p_social_shares >= 10  THEN 5
        ELSE 0
    END;

    -- Page views (max 10 pts)
    SET v_view_score = CASE
        WHEN p_page_views >= 10000 THEN 10
        WHEN p_page_views >= 5000  THEN 8
        WHEN p_page_views >= 1000  THEN 5
        WHEN p_page_views >= 100   THEN 2
        ELSE 0
    END;

    RETURN LEAST(v_time_score + v_bounce_score + v_share_score + v_view_score, 100);
END $$
DELIMITER ;

-- ============================================================
-- FUNCTION 9: Budget Pacing Status
-- Evaluates whether spend is on track given time elapsed
-- Usage: SELECT fn_budget_pacing_status(spend, budget, days_elapsed, total_days)
-- ============================================================
DROP FUNCTION IF EXISTS fn_budget_pacing_status;
DELIMITER $$
CREATE FUNCTION fn_budget_pacing_status(
    p_spend        DECIMAL(12,2),
    p_budget       DECIMAL(12,2),
    p_days_elapsed INT,
    p_total_days   INT
)
RETURNS VARCHAR(20)
DETERMINISTIC
BEGIN
    DECLARE v_expected_spend DECIMAL(12,2);
    DECLARE v_pacing_ratio   DECIMAL(8,4);

    IF p_budget IS NULL OR p_budget = 0 OR p_total_days = 0 THEN
        RETURN 'No Data';
    END IF;

    SET v_expected_spend = p_budget * (p_days_elapsed / p_total_days);
    SET v_pacing_ratio   = p_spend / v_expected_spend;

    RETURN CASE
        WHEN v_pacing_ratio > 1.20 THEN 'Over Pacing'
        WHEN v_pacing_ratio > 1.05 THEN 'Slightly Over'
        WHEN v_pacing_ratio >= 0.90 THEN 'On Track'
        WHEN v_pacing_ratio >= 0.75 THEN 'Slightly Under'
        ELSE 'Under Pacing'
    END;
END $$
DELIMITER ;

-- ============================================================
-- FUNCTION 10: Customer Lifetime Value Tier
-- Segments customers by total revenue generated
-- Usage: SELECT fn_clv_tier(total_revenue)
-- ============================================================
DROP FUNCTION IF EXISTS fn_clv_tier;
DELIMITER $$
CREATE FUNCTION fn_clv_tier(
    p_total_revenue DECIMAL(12,2)
)
RETURNS VARCHAR(20)
DETERMINISTIC
BEGIN
    RETURN CASE
        WHEN p_total_revenue >= 100000 THEN 'Platinum'
        WHEN p_total_revenue >= 50000  THEN 'Gold'
        WHEN p_total_revenue >= 20000  THEN 'Silver'
        WHEN p_total_revenue >= 5000   THEN 'Bronze'
        WHEN p_total_revenue > 0       THEN 'Entry'
        ELSE 'No Revenue'
    END;
END $$
DELIMITER ;

-- ============================================================
-- FUNCTION USAGE EXAMPLES
-- Run these queries to see all functions in action
-- ============================================================

-- Example 1: Lead scoring tier applied to all active leads
SELECT
    lead_id,
    first_name,
    last_name,
    lead_source,
    status,
    score,
    fn_lead_score_tier(score)   AS score_tier
FROM leads
WHERE status != 'stale'
ORDER BY score DESC
LIMIT 20;

-- Example 2: Campaign ROAS classification
SELECT
    campaign_name,
    channel,
    spend,
    fn_calculate_roas(
        (SELECT COALESCE(SUM(deal_value),0) FROM leads l
         WHERE l.campaign_id = c.campaign_id),
        c.spend
    )                           AS roas,
    fn_channel_perf_tier(
        fn_calculate_roas(
            (SELECT COALESCE(SUM(deal_value),0) FROM leads l
             WHERE l.campaign_id = c.campaign_id),
            c.spend
        )
    )                           AS invest_decision
FROM campaigns c
WHERE status = 'closed'
ORDER BY spend DESC;

-- Example 3: Web vitals LCP rating by page
SELECT
    page_url,
    vital_date,
    lcp_ms,
    fn_lcp_rating(lcp_ms)       AS lcp_rating,
    mobile_score,
    desktop_score
FROM web_vitals
ORDER BY vital_date DESC, lcp_ms DESC;

-- Example 4: Customer CLV tiers by segment
SELECT
    cu.segment,
    cu.first_name,
    cu.last_name,
    SUM(o.amount)               AS total_revenue,
    fn_clv_tier(SUM(o.amount))  AS clv_tier
FROM customers cu
LEFT JOIN orders o ON cu.customer_id = o.customer_id
GROUP BY cu.customer_id, cu.segment, cu.first_name, cu.last_name
ORDER BY total_revenue DESC;

SELECT 'Functions created successfully' AS status;
