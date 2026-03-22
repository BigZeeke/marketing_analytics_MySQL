-- ============================================================
-- MARKETING ANALYTICS PORTFOLIO PROJECT
-- File: 10_indexes.sql
-- Description: Strategic index design for all 25 tables.
--              Covers single-column, composite, covering, and
--              prefix indexes with EXPLAIN ANALYZE examples
--              showing before/after performance impact.
-- Run Order: 10 of 10
-- ============================================================

USE marketing_analytics;

-- ============================================================
-- INDEX STRATEGY OVERVIEW
-- ============================================================
-- Rules applied in this file:
-- 1. Every FK column gets an index (join performance)
-- 2. Columns used in WHERE, GROUP BY, ORDER BY get indexes
-- 3. High-cardinality columns are prioritized
-- 4. Composite indexes follow selectivity order (most selective first)
-- 5. Covering indexes added for hot reporting queries
-- 6. Long VARCHAR columns use prefix indexes
-- ============================================================

-- ============================================================
-- CORE TABLE INDEXES
-- ============================================================

-- campaigns: filter by channel, year, status (all common WHERE clauses)
CREATE INDEX idx_campaigns_channel
    ON campaigns (channel);

CREATE INDEX idx_campaigns_status_start
    ON campaigns (status, start_date);     -- composite: filter active + date range

CREATE INDEX idx_campaigns_start_date
    ON campaigns (start_date);             -- standalone for YoY queries

-- leads: FK + status + campaign are the most queried columns
CREATE INDEX idx_leads_campaign_id
    ON leads (campaign_id);

CREATE INDEX idx_leads_customer_id
    ON leads (customer_id);

CREATE INDEX idx_leads_status
    ON leads (status);

CREATE INDEX idx_leads_campaign_status                 -- covering: campaign + status combo
    ON leads (campaign_id, status, deal_value);

CREATE INDEX idx_leads_created_at
    ON leads (created_at);

CREATE INDEX idx_leads_converted_at
    ON leads (converted_at);

-- orders: FK + date range queries
CREATE INDEX idx_orders_customer_id
    ON orders (customer_id);

CREATE INDEX idx_orders_campaign_id
    ON orders (campaign_id);

CREATE INDEX idx_orders_order_date
    ON orders (order_date);

CREATE INDEX idx_orders_customer_date                  -- composite for customer order history
    ON orders (customer_id, order_date);

-- order_items: FK lookup
CREATE INDEX idx_orderitems_order_id
    ON order_items (order_id);

CREATE INDEX idx_orderitems_product_id
    ON order_items (product_id);

-- payments: FK + date
CREATE INDEX idx_payments_customer_id
    ON payments (customer_id);

CREATE INDEX idx_payments_order_id
    ON payments (order_id);

CREATE INDEX idx_payments_paid_at
    ON payments (paid_at);

-- customers: segment is used in GROUP BY reporting constantly
CREATE INDEX idx_customers_segment
    ON customers (segment);

-- ============================================================
-- SEO TABLE INDEXES
-- ============================================================

-- seo_rankings: date + keyword are the core query axes
CREATE INDEX idx_seo_rankings_keyword_date
    ON seo_rankings (keyword_id, ranking_date);       -- composite (most important index)

CREATE INDEX idx_seo_rankings_date
    ON seo_rankings (ranking_date);

CREATE INDEX idx_seo_rankings_position
    ON seo_rankings (position);                       -- filter for page 1 queries

-- organic_traffic: page + date
CREATE INDEX idx_organic_traffic_date
    ON organic_traffic (traffic_date);

CREATE INDEX idx_organic_traffic_page_date            -- covering index for page trend queries
    ON organic_traffic (page_url(255), traffic_date);

-- seo_keywords: intent and cluster are GROUP BY targets
CREATE INDEX idx_seo_keywords_intent
    ON seo_keywords (intent_type);

CREATE INDEX idx_seo_keywords_cluster
    ON seo_keywords (topic_cluster(100));

-- ============================================================
-- PPC TABLE INDEXES
-- ============================================================

-- ad_performance: date + ad_id are both heavily filtered
CREATE INDEX idx_adperf_ad_date
    ON ad_performance (ad_id, perf_date);             -- composite covering date range per ad

CREATE INDEX idx_adperf_date
    ON ad_performance (perf_date);

-- ad_groups: FK to campaign
CREATE INDEX idx_adgroups_campaign_id
    ON ad_groups (campaign_id);

-- ads: FK to ad_group
CREATE INDEX idx_ads_adgroup_id
    ON ads (ad_group_id);

CREATE INDEX idx_ads_status
    ON ads (status);

-- ============================================================
-- EMAIL TABLE INDEXES
-- ============================================================

-- email_campaigns: send_date is the primary reporting dimension
CREATE INDEX idx_emailcamp_send_date
    ON email_campaigns (send_date);

CREATE INDEX idx_emailcamp_campaign_id
    ON email_campaigns (campaign_id);

CREATE INDEX idx_emailcamp_type
    ON email_campaigns (email_type);

-- email_events: campaign + event_type is the core aggregation
CREATE INDEX idx_emailevents_campaign_event
    ON email_events (email_campaign_id, event_type);  -- hot covering index for funnel queries

CREATE INDEX idx_emailevents_customer_id
    ON email_events (customer_id);

CREATE INDEX idx_emailevents_event_at
    ON email_events (event_at);

-- ============================================================
-- GTM AND WEB EVENT INDEXES
-- ============================================================

-- web_events: tag + event_name + created_at are all queried
CREATE INDEX idx_webevents_tag_id
    ON web_events (tag_id);

CREATE INDEX idx_webevents_event_name
    ON web_events (event_name);

CREATE INDEX idx_webevents_customer_id
    ON web_events (customer_id);

CREATE INDEX idx_webevents_created_at
    ON web_events (created_at);

CREATE INDEX idx_webevents_source_date               -- for traffic source reporting
    ON web_events (traffic_source, created_at);

-- ============================================================
-- CONTENT TABLE INDEXES
-- ============================================================

-- content_pieces: type and cluster are GROUP BY columns
CREATE INDEX idx_content_type
    ON content_pieces (content_type);

CREATE INDEX idx_content_cluster
    ON content_pieces (topic_cluster(100));

CREATE INDEX idx_content_publish_date
    ON content_pieces (publish_date);

CREATE INDEX idx_content_campaign_id
    ON content_pieces (campaign_id);

-- content_performance: content + date is the reporting join
CREATE INDEX idx_contentperf_content_date
    ON content_performance (content_id, perf_date);

-- ============================================================
-- AUDIENCE TABLE INDEXES
-- ============================================================

CREATE INDEX idx_audiences_channel
    ON audiences (channel);

CREATE INDEX idx_audiences_type
    ON audiences (audience_type);

CREATE INDEX idx_audience_members_audience
    ON audience_members (audience_id);

CREATE INDEX idx_audience_members_customer
    ON audience_members (customer_id);

-- ============================================================
-- A/B TEST TABLE INDEXES
-- ============================================================

CREATE INDEX idx_abtests_campaign_id
    ON ab_tests (campaign_id);

CREATE INDEX idx_abtests_status
    ON ab_tests (status);

CREATE INDEX idx_abvariants_test_id
    ON ab_variants (test_id);

-- ============================================================
-- WEBSITE TABLE INDEXES
-- ============================================================

-- web_sessions: source + date is the primary reporting grouping
CREATE INDEX idx_sessions_source_date
    ON web_sessions (referrer_source, session_start); -- composite: channel + time window

CREATE INDEX idx_sessions_landing_page
    ON web_sessions (landing_page(255));

CREATE INDEX idx_sessions_customer_id
    ON web_sessions (customer_id);

CREATE INDEX idx_sessions_converted
    ON web_sessions (converted, referrer_source);     -- covering for conversion funnel

-- web_vitals: page + date
CREATE INDEX idx_vitals_page_date
    ON web_vitals (page_url(255), vital_date);

-- ============================================================
-- TRENDS TABLE INDEXES
-- ============================================================

CREATE INDEX idx_trends_category
    ON industry_trends (category);

CREATE INDEX idx_trends_impact
    ON industry_trends (impact_level);

CREATE INDEX idx_algo_updates_platform_date
    ON algorithm_updates (platform, update_date);    -- composite for platform timeline queries

CREATE INDEX idx_algo_updates_impact
    ON algorithm_updates (our_impact_score);

-- ============================================================
-- EXPLAIN ANALYZE EXAMPLES
-- Run these to see index usage in action
-- ============================================================

-- -------------------------------------------------------
-- EXAMPLE 1: Campaign performance by channel
-- Demonstrates idx_campaigns_channel usage
-- -------------------------------------------------------
EXPLAIN
SELECT
    channel,
    COUNT(*) AS campaign_count,
    SUM(spend) AS total_spend
FROM campaigns
WHERE channel = 'Paid'
  AND status  = 'closed'
GROUP BY channel;

-- -------------------------------------------------------
-- EXAMPLE 2: Lead funnel by campaign (composite index hit)
-- Demonstrates idx_leads_campaign_status covering index
-- -------------------------------------------------------
EXPLAIN
SELECT
    campaign_id,
    status,
    COUNT(*)          AS lead_count,
    SUM(deal_value)   AS pipeline
FROM leads
WHERE campaign_id IN (22, 30, 34)
  AND status IN ('converted', 'qualified')
GROUP BY campaign_id, status;

-- -------------------------------------------------------
-- EXAMPLE 3: Email event aggregation (composite index hit)
-- Demonstrates idx_emailevents_campaign_event
-- -------------------------------------------------------
EXPLAIN
SELECT
    email_campaign_id,
    event_type,
    COUNT(*) AS event_count
FROM email_events
WHERE event_type IN ('opened', 'clicked', 'converted')
GROUP BY email_campaign_id, event_type;

-- -------------------------------------------------------
-- EXAMPLE 4: SEO ranking trend (composite index hit)
-- Demonstrates idx_seo_rankings_keyword_date
-- -------------------------------------------------------
EXPLAIN
SELECT
    keyword_id,
    ranking_date,
    position,
    clicks
FROM seo_rankings
WHERE keyword_id IN (1, 2, 9, 19)
  AND ranking_date >= '2024-01-01'
ORDER BY keyword_id, ranking_date;

-- -------------------------------------------------------
-- EXAMPLE 5: Session conversion funnel (covering index)
-- Demonstrates idx_sessions_converted
-- -------------------------------------------------------
EXPLAIN
SELECT
    referrer_source,
    COUNT(*)         AS total_sessions,
    SUM(converted)   AS total_conversions,
    ROUND(SUM(converted) / COUNT(*) * 100, 2) AS conv_rate
FROM web_sessions
WHERE converted = 1
GROUP BY referrer_source
ORDER BY total_conversions DESC;

-- ============================================================
-- INDEX AUDIT QUERY
-- View all indexes created in this schema
-- ============================================================
SELECT
    TABLE_NAME,
    INDEX_NAME,
    SEQ_IN_INDEX,
    COLUMN_NAME,
    NON_UNIQUE,
    CARDINALITY
FROM information_schema.STATISTICS
WHERE TABLE_SCHEMA = 'marketing_analytics'
  AND INDEX_NAME   != 'PRIMARY'
ORDER BY
    TABLE_NAME,
    INDEX_NAME,
    SEQ_IN_INDEX;

SELECT 'Index strategy applied successfully' AS status;
