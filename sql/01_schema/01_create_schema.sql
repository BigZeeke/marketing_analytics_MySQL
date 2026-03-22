-- ============================================================
-- MARKETING ANALYTICS PORTFOLIO PROJECT
-- File: 01_create_schema.sql
-- Description: Full schema for all 25 tables covering SEO,
--              PPC, Email, GTM, Content, Audience, AB Testing,
--              Website Analytics, and Trends tracking
-- Run Order: 1 of 10
-- ============================================================

DROP SCHEMA IF EXISTS marketing_analytics;
CREATE SCHEMA marketing_analytics;
USE marketing_analytics;

-- ============================================================
-- CORE TABLES (Foundation)
-- ============================================================

CREATE TABLE products (
    product_id          INT             NOT NULL AUTO_INCREMENT,
    name                VARCHAR(200)    NOT NULL,
    category            VARCHAR(100)    NOT NULL,
    unit_price          DECIMAL(10,2)   NOT NULL,
    quantity_in_stock   INT             NOT NULL DEFAULT 0,
    PRIMARY KEY (product_id)
);

CREATE TABLE customers (
    customer_id     INT             NOT NULL AUTO_INCREMENT,
    first_name      VARCHAR(100)    NOT NULL,
    last_name       VARCHAR(100)    NOT NULL,
    email           VARCHAR(255)    NOT NULL,
    phone           VARCHAR(20)     NULL,
    city            VARCHAR(100)    NULL,
    state           VARCHAR(50)     NULL,
    segment         VARCHAR(50)     NULL,
    points          INT             NOT NULL DEFAULT 0,
    balance         DECIMAL(10,2)   NOT NULL DEFAULT 0,
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (customer_id),
    UNIQUE KEY uq_customer_email (email)
);

CREATE TABLE campaigns (
    campaign_id         INT             NOT NULL AUTO_INCREMENT,
    campaign_name       VARCHAR(200)    NOT NULL,
    channel             VARCHAR(50)     NOT NULL,
    campaign_type       VARCHAR(50)     NOT NULL,
    objective           VARCHAR(100)    NULL,
    budget              DECIMAL(10,2)   NOT NULL DEFAULT 0,
    spend               DECIMAL(10,2)   NOT NULL DEFAULT 0,
    status              VARCHAR(20)     NOT NULL DEFAULT 'active',
    start_date          DATE            NOT NULL,
    end_date            DATE            NULL,
    closed_at           DATETIME        NULL,
    closed_by           VARCHAR(100)    NULL,
    final_spend         DECIMAL(10,2)   NULL,
    final_leads         INT             NULL,
    final_roas          DECIMAL(10,2)   NULL,
    target_audience     VARCHAR(200)    NULL,
    created_at          DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (campaign_id)
);

CREATE TABLE leads (
    lead_id         INT             NOT NULL AUTO_INCREMENT,
    campaign_id     INT             NOT NULL,
    customer_id     INT             NULL,
    email           VARCHAR(255)    NOT NULL,
    first_name      VARCHAR(100)    NULL,
    last_name       VARCHAR(100)    NULL,
    lead_source     VARCHAR(100)    NOT NULL,
    status          VARCHAR(20)     NOT NULL DEFAULT 'new',
    deal_value      DECIMAL(10,2)   NULL DEFAULT 0,
    score           INT             NULL,
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    converted_at    DATETIME        NULL,
    PRIMARY KEY (lead_id),
    CONSTRAINT fk_lead_campaign
        FOREIGN KEY (campaign_id) REFERENCES campaigns(campaign_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_lead_customer
        FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
        ON DELETE SET NULL ON UPDATE CASCADE
);

CREATE TABLE orders (
    order_id        INT             NOT NULL AUTO_INCREMENT,
    customer_id     INT             NOT NULL,
    campaign_id     INT             NULL,
    order_date      DATE            NOT NULL,
    shipped_date    DATE            NULL,
    status          VARCHAR(20)     NOT NULL DEFAULT 'pending',
    amount          DECIMAL(10,2)   NOT NULL DEFAULT 0,
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (order_id),
    CONSTRAINT fk_order_customer
        FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_order_campaign
        FOREIGN KEY (campaign_id) REFERENCES campaigns(campaign_id)
        ON DELETE SET NULL ON UPDATE CASCADE
);

CREATE TABLE order_items (
    order_item_id   INT             NOT NULL AUTO_INCREMENT,
    order_id        INT             NOT NULL,
    product_id      INT             NOT NULL,
    quantity        INT             NOT NULL DEFAULT 1,
    unit_price      DECIMAL(10,2)   NOT NULL,
    PRIMARY KEY (order_item_id),
    CONSTRAINT fk_orderitem_order
        FOREIGN KEY (order_id) REFERENCES orders(order_id)
        ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE payments (
    payment_id      INT             NOT NULL AUTO_INCREMENT,
    customer_id     INT             NOT NULL,
    order_id        INT             NULL,
    amount          DECIMAL(10,2)   NOT NULL,
    paid_at         DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (payment_id),
    CONSTRAINT fk_payment_customer
        FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_payment_order
        FOREIGN KEY (order_id) REFERENCES orders(order_id)
        ON DELETE SET NULL ON UPDATE CASCADE
);

-- ============================================================
-- SEO TABLES
-- ============================================================

CREATE TABLE seo_keywords (
    keyword_id          INT             NOT NULL AUTO_INCREMENT,
    keyword             VARCHAR(300)    NOT NULL,
    search_volume       INT             NOT NULL DEFAULT 0,
    keyword_difficulty  INT             NOT NULL DEFAULT 0,  -- 0-100
    intent_type         VARCHAR(30)     NOT NULL,            -- informational, navigational, commercial, transactional
    topic_cluster       VARCHAR(100)    NULL,
    target_page_url     VARCHAR(500)    NULL,
    is_branded          TINYINT(1)      NOT NULL DEFAULT 0,
    created_at          DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (keyword_id)
);

CREATE TABLE seo_rankings (
    ranking_id      INT             NOT NULL AUTO_INCREMENT,
    keyword_id      INT             NOT NULL,
    ranking_date    DATE            NOT NULL,
    position        INT             NOT NULL,
    page_url        VARCHAR(500)    NOT NULL,
    impressions     INT             NOT NULL DEFAULT 0,
    clicks          INT             NOT NULL DEFAULT 0,
    ctr_pct         DECIMAL(5,2)    NOT NULL DEFAULT 0,
    PRIMARY KEY (ranking_id),
    CONSTRAINT fk_ranking_keyword
        FOREIGN KEY (keyword_id) REFERENCES seo_keywords(keyword_id)
        ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE organic_traffic (
    traffic_id      INT             NOT NULL AUTO_INCREMENT,
    traffic_date    DATE            NOT NULL,
    page_url        VARCHAR(500)    NOT NULL,
    sessions        INT             NOT NULL DEFAULT 0,
    new_users       INT             NOT NULL DEFAULT 0,
    bounce_rate_pct DECIMAL(5,2)    NOT NULL DEFAULT 0,
    avg_session_sec INT             NOT NULL DEFAULT 0,
    goal_completions INT            NOT NULL DEFAULT 0,
    PRIMARY KEY (traffic_id)
);

-- ============================================================
-- PPC TABLES
-- ============================================================

CREATE TABLE ad_groups (
    ad_group_id     INT             NOT NULL AUTO_INCREMENT,
    campaign_id     INT             NOT NULL,
    ad_group_name   VARCHAR(200)    NOT NULL,
    bid_strategy    VARCHAR(50)     NOT NULL,  -- manual_cpc, target_cpa, target_roas, maximize_conversions
    max_cpc         DECIMAL(8,2)    NULL,
    target_cpa      DECIMAL(8,2)    NULL,
    status          VARCHAR(20)     NOT NULL DEFAULT 'active',
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (ad_group_id),
    CONSTRAINT fk_adgroup_campaign
        FOREIGN KEY (campaign_id) REFERENCES campaigns(campaign_id)
        ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE ads (
    ad_id           INT             NOT NULL AUTO_INCREMENT,
    ad_group_id     INT             NOT NULL,
    headline_1      VARCHAR(30)     NOT NULL,
    headline_2      VARCHAR(30)     NULL,
    headline_3      VARCHAR(30)     NULL,
    description_1   VARCHAR(90)     NULL,
    description_2   VARCHAR(90)     NULL,
    final_url       VARCHAR(500)    NULL,
    ad_type         VARCHAR(30)     NOT NULL DEFAULT 'rsa',  -- rsa, dsa, display, video
    status          VARCHAR(20)     NOT NULL DEFAULT 'active',
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (ad_id),
    CONSTRAINT fk_ad_adgroup
        FOREIGN KEY (ad_group_id) REFERENCES ad_groups(ad_group_id)
        ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE ad_performance (
    perf_id         INT             NOT NULL AUTO_INCREMENT,
    ad_id           INT             NOT NULL,
    perf_date       DATE            NOT NULL,
    impressions     INT             NOT NULL DEFAULT 0,
    clicks          INT             NOT NULL DEFAULT 0,
    spend           DECIMAL(10,2)   NOT NULL DEFAULT 0,
    conversions     INT             NOT NULL DEFAULT 0,
    conversion_value DECIMAL(10,2)  NOT NULL DEFAULT 0,
    quality_score   INT             NULL,   -- 1-10 Google Quality Score
    PRIMARY KEY (perf_id),
    CONSTRAINT fk_perf_ad
        FOREIGN KEY (ad_id) REFERENCES ads(ad_id)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- ============================================================
-- EMAIL MARKETING TABLES
-- ============================================================

CREATE TABLE email_campaigns (
    email_campaign_id   INT             NOT NULL AUTO_INCREMENT,
    campaign_id         INT             NULL,
    email_name          VARCHAR(200)    NOT NULL,
    subject_line        VARCHAR(200)    NOT NULL,
    preview_text        VARCHAR(200)    NULL,
    sender_name         VARCHAR(100)    NOT NULL DEFAULT 'Marketing Team',
    audience_segment    VARCHAR(100)    NOT NULL,
    email_type          VARCHAR(50)     NOT NULL,  -- newsletter, promotional, nurture, transactional, win_back
    list_size           INT             NOT NULL DEFAULT 0,
    send_date           DATETIME        NOT NULL,
    status              VARCHAR(20)     NOT NULL DEFAULT 'draft',  -- draft, scheduled, sent, cancelled
    created_at          DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (email_campaign_id),
    CONSTRAINT fk_emailcamp_campaign
        FOREIGN KEY (campaign_id) REFERENCES campaigns(campaign_id)
        ON DELETE SET NULL ON UPDATE CASCADE
);

CREATE TABLE email_events (
    event_id            INT             NOT NULL AUTO_INCREMENT,
    email_campaign_id   INT             NOT NULL,
    customer_id         INT             NULL,
    event_type          VARCHAR(30)     NOT NULL,  -- sent, delivered, opened, clicked, unsubscribed, bounced, converted, spam_report
    event_at            DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    device_type         VARCHAR(20)     NULL,      -- desktop, mobile, tablet
    email_client        VARCHAR(50)     NULL,      -- gmail, outlook, apple_mail, other
    link_clicked        VARCHAR(500)    NULL,
    PRIMARY KEY (event_id),
    CONSTRAINT fk_event_emailcamp
        FOREIGN KEY (email_campaign_id) REFERENCES email_campaigns(email_campaign_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_event_customer
        FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
        ON DELETE SET NULL ON UPDATE CASCADE
);

-- ============================================================
-- GTM / WEB TRACKING TABLES
-- ============================================================

CREATE TABLE gtm_tags (
    tag_id          INT             NOT NULL AUTO_INCREMENT,
    tag_name        VARCHAR(200)    NOT NULL,
    tag_type        VARCHAR(100)    NOT NULL,  -- GA4 Event, Google Ads Conversion, Meta Pixel, Custom HTML
    trigger_type    VARCHAR(100)    NOT NULL,  -- Page View, Click, Form Submit, Custom Event, Scroll Depth
    trigger_detail  VARCHAR(200)    NULL,
    is_active       TINYINT(1)      NOT NULL DEFAULT 1,
    firing_option   VARCHAR(50)     NOT NULL DEFAULT 'once_per_event',
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_fired_at   DATETIME        NULL,
    PRIMARY KEY (tag_id)
);

CREATE TABLE web_events (
    web_event_id    INT             NOT NULL AUTO_INCREMENT,
    session_id      VARCHAR(100)    NOT NULL,
    customer_id     INT             NULL,
    tag_id          INT             NULL,
    page_url        VARCHAR(500)    NOT NULL,
    event_name      VARCHAR(100)    NOT NULL,  -- page_view, cta_click, form_submit, video_play, scroll_50, purchase
    event_category  VARCHAR(100)    NULL,
    event_value     DECIMAL(10,2)   NULL,
    device_type     VARCHAR(20)     NULL,
    traffic_source  VARCHAR(50)     NULL,
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (web_event_id),
    CONSTRAINT fk_webevent_customer
        FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_webevent_tag
        FOREIGN KEY (tag_id) REFERENCES gtm_tags(tag_id)
        ON DELETE SET NULL ON UPDATE CASCADE
);

-- ============================================================
-- CONTENT MARKETING TABLES
-- ============================================================

CREATE TABLE content_pieces (
    content_id      INT             NOT NULL AUTO_INCREMENT,
    title           VARCHAR(300)    NOT NULL,
    content_type    VARCHAR(50)     NOT NULL,  -- blog_post, whitepaper, case_study, video, infographic, podcast, webinar, landing_page
    topic_cluster   VARCHAR(100)    NULL,
    target_keyword  VARCHAR(200)    NULL,
    author          VARCHAR(100)    NOT NULL,
    word_count      INT             NULL,
    publish_date    DATE            NULL,
    status          VARCHAR(20)     NOT NULL DEFAULT 'draft',  -- draft, review, published, archived
    cta_type        VARCHAR(100)    NULL,  -- demo_request, download, subscribe, contact, purchase
    campaign_id     INT             NULL,
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (content_id),
    CONSTRAINT fk_content_campaign
        FOREIGN KEY (campaign_id) REFERENCES campaigns(campaign_id)
        ON DELETE SET NULL ON UPDATE CASCADE
);

CREATE TABLE content_performance (
    perf_id         INT             NOT NULL AUTO_INCREMENT,
    content_id      INT             NOT NULL,
    perf_date       DATE            NOT NULL,
    page_views      INT             NOT NULL DEFAULT 0,
    unique_visitors INT             NOT NULL DEFAULT 0,
    avg_time_sec    INT             NOT NULL DEFAULT 0,
    bounce_rate_pct DECIMAL(5,2)    NOT NULL DEFAULT 0,
    social_shares   INT             NOT NULL DEFAULT 0,
    comments        INT             NOT NULL DEFAULT 0,
    backlinks_earned INT            NOT NULL DEFAULT 0,
    cta_clicks      INT             NOT NULL DEFAULT 0,
    conversions     INT             NOT NULL DEFAULT 0,
    PRIMARY KEY (perf_id),
    CONSTRAINT fk_contentperf_content
        FOREIGN KEY (content_id) REFERENCES content_pieces(content_id)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- ============================================================
-- AUDIENCE SEGMENTATION TABLES
-- ============================================================

CREATE TABLE audiences (
    audience_id         INT             NOT NULL AUTO_INCREMENT,
    audience_name       VARCHAR(200)    NOT NULL,
    channel             VARCHAR(50)     NOT NULL,  -- Google, Meta, LinkedIn, Email, Organic
    audience_type       VARCHAR(50)     NOT NULL,  -- lookalike, remarketing, interest, custom, in_market, demographic
    criteria_description VARCHAR(500)   NOT NULL,
    size_estimate       INT             NOT NULL DEFAULT 0,
    match_rate_pct      DECIMAL(5,2)    NULL,
    is_active           TINYINT(1)      NOT NULL DEFAULT 1,
    created_at          DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (audience_id)
);

CREATE TABLE audience_members (
    member_id       INT             NOT NULL AUTO_INCREMENT,
    audience_id     INT             NOT NULL,
    customer_id     INT             NOT NULL,
    added_at        DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    added_by        VARCHAR(50)     NOT NULL DEFAULT 'system',  -- system, manual, import
    PRIMARY KEY (member_id),
    CONSTRAINT fk_member_audience
        FOREIGN KEY (audience_id) REFERENCES audiences(audience_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_member_customer
        FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- ============================================================
-- A/B TESTING TABLES
-- ============================================================

CREATE TABLE ab_tests (
    test_id         INT             NOT NULL AUTO_INCREMENT,
    test_name       VARCHAR(200)    NOT NULL,
    campaign_id     INT             NULL,
    content_id      INT             NULL,
    email_campaign_id INT           NULL,
    test_type       VARCHAR(50)     NOT NULL,  -- subject_line, ad_copy, landing_page, cta, audience, bid_strategy
    hypothesis      VARCHAR(500)    NOT NULL,
    start_date      DATE            NOT NULL,
    end_date        DATE            NULL,
    status          VARCHAR(20)     NOT NULL DEFAULT 'running',  -- running, completed, stopped
    winner_variant  VARCHAR(100)    NULL,
    confidence_pct  DECIMAL(5,2)    NULL,
    primary_metric  VARCHAR(100)    NOT NULL,
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (test_id),
    CONSTRAINT fk_abtest_campaign
        FOREIGN KEY (campaign_id) REFERENCES campaigns(campaign_id)
        ON DELETE SET NULL ON UPDATE CASCADE
);

CREATE TABLE ab_variants (
    variant_id      INT             NOT NULL AUTO_INCREMENT,
    test_id         INT             NOT NULL,
    variant_name    VARCHAR(100)    NOT NULL,  -- control, variant_a, variant_b
    variant_detail  VARCHAR(500)    NULL,
    sample_size     INT             NOT NULL DEFAULT 0,
    impressions     INT             NOT NULL DEFAULT 0,
    clicks          INT             NOT NULL DEFAULT 0,
    conversions     INT             NOT NULL DEFAULT 0,
    revenue         DECIMAL(10,2)   NOT NULL DEFAULT 0,
    PRIMARY KEY (variant_id),
    CONSTRAINT fk_variant_test
        FOREIGN KEY (test_id) REFERENCES ab_tests(test_id)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- ============================================================
-- WEBSITE TABLES
-- ============================================================

CREATE TABLE web_pages (
    page_id         INT             NOT NULL AUTO_INCREMENT,
    page_url        VARCHAR(500)    NOT NULL,
    page_type       VARCHAR(50)     NOT NULL,  -- homepage, landing_page, product, blog, contact, pricing, about
    page_title      VARCHAR(300)    NOT NULL,
    cta_text        VARCHAR(200)    NULL,
    cta_destination VARCHAR(500)    NULL,
    published_at    DATE            NULL,
    is_active       TINYINT(1)      NOT NULL DEFAULT 1,
    PRIMARY KEY (page_id),
    UNIQUE KEY uq_page_url (page_url(255))
);

CREATE TABLE web_sessions (
    session_id      VARCHAR(100)    NOT NULL,
    customer_id     INT             NULL,
    landing_page    VARCHAR(500)    NOT NULL,
    referrer_source VARCHAR(100)    NULL,  -- google_organic, google_paid, facebook, email, direct, referral, linkedin
    referrer_medium VARCHAR(50)     NULL,  -- organic, cpc, email, social, referral, direct
    utm_campaign    VARCHAR(200)    NULL,
    device_type     VARCHAR(20)     NOT NULL DEFAULT 'desktop',  -- desktop, mobile, tablet
    browser         VARCHAR(50)     NULL,
    session_start   DATETIME        NOT NULL,
    session_end     DATETIME        NULL,
    pages_viewed    INT             NOT NULL DEFAULT 1,
    converted       TINYINT(1)      NOT NULL DEFAULT 0,
    conversion_value DECIMAL(10,2)  NULL,
    PRIMARY KEY (session_id),
    CONSTRAINT fk_session_customer
        FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
        ON DELETE SET NULL ON UPDATE CASCADE
);

CREATE TABLE web_vitals (
    vital_id        INT             NOT NULL AUTO_INCREMENT,
    page_url        VARCHAR(500)    NOT NULL,
    vital_date      DATE            NOT NULL,
    lcp_ms          INT             NULL,   -- Largest Contentful Paint in ms (good < 2500)
    fid_ms          INT             NULL,   -- First Input Delay in ms (good < 100)
    cls_score       DECIMAL(5,3)    NULL,   -- Cumulative Layout Shift (good < 0.1)
    ttfb_ms         INT             NULL,   -- Time to First Byte in ms (good < 800)
    mobile_score    INT             NULL,   -- PageSpeed score 0-100
    desktop_score   INT             NULL,   -- PageSpeed score 0-100
    PRIMARY KEY (vital_id)
);

-- ============================================================
-- TRENDS & ALGORITHM TRACKING TABLES
-- ============================================================

CREATE TABLE industry_trends (
    trend_id        INT             NOT NULL AUTO_INCREMENT,
    trend_name      VARCHAR(200)    NOT NULL,
    category        VARCHAR(100)    NOT NULL,  -- AI Tools, Content Format, Platform Feature, Privacy, Attribution, Search
    impact_level    VARCHAR(20)     NOT NULL,  -- high, medium, low
    date_identified DATE            NOT NULL,
    our_adoption    VARCHAR(20)     NOT NULL DEFAULT 'evaluating',  -- adopted, evaluating, planned, not_applicable
    notes           TEXT            NULL,
    PRIMARY KEY (trend_id)
);

CREATE TABLE algorithm_updates (
    update_id           INT             NOT NULL AUTO_INCREMENT,
    platform            VARCHAR(50)     NOT NULL,  -- Google Search, Google Ads, Meta, LinkedIn, Email
    update_name         VARCHAR(200)    NOT NULL,
    update_date         DATE            NOT NULL,
    update_type         VARCHAR(100)    NULL,       -- core_update, spam_update, policy_change, feature_launch
    impact_description  TEXT            NULL,
    our_impact_score    INT             NULL,       -- -5 (very negative) to +5 (very positive)
    action_taken        VARCHAR(500)    NULL,
    PRIMARY KEY (update_id)
);

-- ============================================================
-- AUDIT / LOGGING TABLES
-- ============================================================

CREATE TABLE pipeline_error_log (
    log_id          INT             NOT NULL AUTO_INCREMENT,
    procedure_name  VARCHAR(100)    NOT NULL,
    error_code      INT             NULL,
    error_message   VARCHAR(1000)   NULL,
    campaign_id     INT             NULL,
    failed_at       DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (log_id)
);

CREATE TABLE campaign_audit_log (
    audit_id        INT             NOT NULL AUTO_INCREMENT,
    campaign_id     INT             NOT NULL,
    action          VARCHAR(100)    NOT NULL,
    performed_by    VARCHAR(100)    NOT NULL,
    status          VARCHAR(20)     NOT NULL,
    notes           VARCHAR(1000)   NULL,
    logged_at       DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (audit_id)
);

SELECT 'Schema created successfully' AS status;
SELECT table_name, table_type
FROM information_schema.tables
WHERE table_schema = 'marketing_analytics'
ORDER BY table_name;
