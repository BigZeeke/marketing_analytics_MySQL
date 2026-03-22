-- ============================================================
-- MARKETING ANALYTICS PORTFOLIO PROJECT
-- File: 03_data_channels.sql
-- Description: SEO, PPC, Email, GTM, Content, Audiences,
--              AB Tests, Website, and Trends data
-- Run Order: 3 of 10
-- ============================================================

USE marketing_analytics;

-- ============================================================
-- SEO KEYWORDS (40 keywords)
-- ============================================================
INSERT INTO seo_keywords (keyword, search_volume, keyword_difficulty, intent_type, topic_cluster, target_page_url, is_branded) VALUES
('marketing automation software',       8100,  72, 'commercial',     'Marketing Automation', '/products/marketing-automation', 0),
('best marketing automation tools',     5400,  68, 'commercial',     'Marketing Automation', '/blog/best-marketing-automation-tools', 0),
('marketing automation for small business', 2900, 55,'commercial',   'Marketing Automation', '/solutions/smb', 0),
('email marketing automation',          6600,  65, 'commercial',     'Email Marketing',      '/products/email-automation', 0),
('automated email campaigns',           3600,  58, 'transactional',  'Email Marketing',      '/products/email-automation', 0),
('email drip campaign software',        2400,  62, 'transactional',  'Email Marketing',      '/products/email-automation', 0),
('crm integration marketing',           1900,  48, 'informational',  'CRM Integration',      '/blog/crm-integration-guide', 0),
('marketing crm software',              4400,  70, 'commercial',     'CRM Integration',      '/products/crm-integration', 0),
('what is marketing automation',        9900,  40, 'informational',  'Marketing Automation', '/blog/what-is-marketing-automation', 0),
('marketing automation roi',            1600,  44, 'informational',  'Marketing Analytics',  '/blog/marketing-automation-roi', 0),
('marketing analytics dashboard',       2200,  55, 'commercial',     'Marketing Analytics',  '/products/analytics', 0),
('campaign performance reporting',      1400,  45, 'commercial',     'Marketing Analytics',  '/products/analytics', 0),
('lead scoring software',               3300,  66, 'commercial',     'Lead Management',      '/products/lead-scoring', 0),
('lead nurturing best practices',       2700,  42, 'informational',  'Lead Management',      '/blog/lead-nurturing', 0),
('b2b lead generation tools',           5900,  74, 'commercial',     'Lead Management',      '/solutions/b2b', 0),
('marketing attribution software',      2100,  60, 'commercial',     'Attribution',          '/products/attribution', 0),
('multi touch attribution model',       1300,  52, 'informational',  'Attribution',          '/blog/attribution-models', 0),
('seo tools for marketers',             4800,  67, 'commercial',     'SEO',                  '/products/seo-toolkit', 0),
('content marketing strategy',          8800,  58, 'informational',  'Content Marketing',    '/blog/content-marketing-strategy', 0),
('social media marketing tools',        9200,  71, 'commercial',     'Social Media',         '/products/social-scheduler', 0),
('ppc campaign management',             3700,  65, 'commercial',     'PPC',                  '/solutions/ppc', 0),
('google ads optimization tips',        5200,  55, 'informational',  'PPC',                  '/blog/google-ads-optimization', 0),
('marketing automation pricing',        2800,  50, 'commercial',     'Marketing Automation', '/pricing', 0),
('marketing automation vs crm',         3100,  45, 'informational',  'Marketing Automation', '/blog/automation-vs-crm', 0),
('enterprise marketing software',       2600,  78, 'commercial',     'Enterprise',           '/solutions/enterprise', 0),
('marketing software company name',     1200,  20, 'navigational',   'Brand',                '/', 1),
('company name marketing platform',     900,   18, 'navigational',   'Brand',                '/', 1),
('company name reviews',                700,   15, 'navigational',   'Brand',                '/reviews', 1),
('company name pricing',                800,   16, 'navigational',   'Brand',                '/pricing', 1),
('company name vs hubspot',             600,   35, 'commercial',     'Brand',                '/compare/hubspot', 1),
('email marketing best practices',      7400,  50, 'informational',  'Email Marketing',      '/blog/email-best-practices', 0),
('marketing funnel stages',             6100,  42, 'informational',  'Marketing Fundamentals','/blog/marketing-funnel', 0),
('customer segmentation strategies',    4200,  48, 'informational',  'Audience Targeting',   '/blog/customer-segmentation', 0),
('audience targeting digital marketing',3400,  55, 'informational',  'Audience Targeting',   '/blog/audience-targeting', 0),
('conversion rate optimization',        7800,  62, 'informational',  'CRO',                  '/blog/cro-guide', 0),
('landing page optimization',           5500,  58, 'commercial',     'CRO',                  '/blog/landing-page-optimization', 0),
('a b testing marketing',               4900,  52, 'informational',  'Testing',              '/blog/ab-testing-guide', 0),
('marketing dashboard examples',        3200,  45, 'informational',  'Marketing Analytics',  '/blog/dashboard-examples', 0),
('digital marketing trends 2024',       12000, 35, 'informational',  'Trends',               '/blog/digital-marketing-trends', 0),
('ai marketing tools',                  8600,  60, 'commercial',     'AI Marketing',         '/blog/ai-marketing-tools', 0);

-- ============================================================
-- SEO RANKINGS (monthly snapshots Jan 2023 - Dec 2024)
-- Showing position improvement over time for key keywords
-- ============================================================
INSERT INTO seo_rankings (keyword_id, ranking_date, position, page_url, impressions, clicks, ctr_pct) VALUES
-- Keyword 1: marketing automation software
(1,'2023-01-01',18,'/products/marketing-automation',2100,63,3.00),
(1,'2023-04-01',12,'/products/marketing-automation',3200,128,4.00),
(1,'2023-07-01',8,'/products/marketing-automation',4800,240,5.00),
(1,'2023-10-01',6,'/products/marketing-automation',5900,354,6.00),
(1,'2024-01-01',5,'/products/marketing-automation',6800,476,7.00),
(1,'2024-04-01',4,'/products/marketing-automation',7200,576,8.00),
(1,'2024-07-01',3,'/products/marketing-automation',7800,702,9.00),
(1,'2024-10-01',2,'/products/marketing-automation',8100,891,11.00),
-- Keyword 2: best marketing automation tools
(2,'2023-01-01',24,'/blog/best-marketing-automation-tools',800,16,2.00),
(2,'2023-04-01',15,'/blog/best-marketing-automation-tools',1600,64,4.00),
(2,'2023-07-01',9,'/blog/best-marketing-automation-tools',2800,140,5.00),
(2,'2023-10-01',7,'/blog/best-marketing-automation-tools',3600,216,6.00),
(2,'2024-01-01',5,'/blog/best-marketing-automation-tools',4200,294,7.00),
(2,'2024-04-01',4,'/blog/best-marketing-automation-tools',4800,384,8.00),
(2,'2024-07-01',3,'/blog/best-marketing-automation-tools',5100,459,9.00),
(2,'2024-10-01',2,'/blog/best-marketing-automation-tools',5400,594,11.00),
-- Keyword 9: what is marketing automation (high volume informational)
(9,'2023-01-01',14,'/blog/what-is-marketing-automation',4200,168,4.00),
(9,'2023-04-01',9,'/blog/what-is-marketing-automation',5800,290,5.00),
(9,'2023-07-01',6,'/blog/what-is-marketing-automation',7200,432,6.00),
(9,'2023-10-01',4,'/blog/what-is-marketing-automation',8400,588,7.00),
(9,'2024-01-01',3,'/blog/what-is-marketing-automation',9100,728,8.00),
(9,'2024-04-01',2,'/blog/what-is-marketing-automation',9500,855,9.00),
(9,'2024-07-01',2,'/blog/what-is-marketing-automation',9700,970,10.00),
(9,'2024-10-01',1,'/blog/what-is-marketing-automation',9900,1188,12.00),
-- Keyword 19: content marketing strategy
(19,'2023-01-01',32,'/blog/content-marketing-strategy',1200,24,2.00),
(19,'2023-04-01',20,'/blog/content-marketing-strategy',2400,72,3.00),
(19,'2023-07-01',11,'/blog/content-marketing-strategy',4200,168,4.00),
(19,'2023-10-01',8,'/blog/content-marketing-strategy',5600,280,5.00),
(19,'2024-01-01',6,'/blog/content-marketing-strategy',6800,340,5.00),
(19,'2024-04-01',4,'/blog/content-marketing-strategy',7600,456,6.00),
(19,'2024-07-01',3,'/blog/content-marketing-strategy',8200,574,7.00),
(19,'2024-10-01',2,'/blog/content-marketing-strategy',8800,792,9.00),
-- Keyword 39: digital marketing trends
(39,'2023-01-01',45,'/blog/digital-marketing-trends',800,8,1.00),
(39,'2023-04-01',28,'/blog/digital-marketing-trends',2100,63,3.00),
(39,'2023-07-01',15,'/blog/digital-marketing-trends',4800,192,4.00),
(39,'2023-10-01',10,'/blog/digital-marketing-trends',7200,360,5.00),
(39,'2024-01-01',7,'/blog/digital-marketing-trends',9000,540,6.00),
(39,'2024-04-01',5,'/blog/digital-marketing-trends',10200,714,7.00),
(39,'2024-07-01',4,'/blog/digital-marketing-trends',11100,888,8.00),
(39,'2024-10-01',3,'/blog/digital-marketing-trends',11800,1298,11.00);

-- ============================================================
-- ORGANIC TRAFFIC (monthly, 2023 + 2024, key pages)
-- ============================================================
INSERT INTO organic_traffic (traffic_date, page_url, sessions, new_users, bounce_rate_pct, avg_session_sec, goal_completions) VALUES
('/products/marketing-automation','2023-01-01',820,610,48.2,142,12),
('/products/marketing-automation','2023-04-01',1240,880,44.1,158,22),
('/products/marketing-automation','2023-07-01',1890,1320,40.5,172,38),
('/products/marketing-automation','2023-10-01',2400,1640,38.2,185,52),
('/products/marketing-automation','2024-01-01',3100,2080,35.8,198,71),
('/products/marketing-automation','2024-04-01',3800,2480,33.2,212,96),
('/products/marketing-automation','2024-07-01',4500,2880,30.9,224,122),
('/products/marketing-automation','2024-10-01',5200,3240,28.4,238,148),
('/blog/what-is-marketing-automation','2023-01-01',1240,1080,62.4,95,8),
('/blog/what-is-marketing-automation','2023-04-01',1980,1720,59.1,108,14),
('/blog/what-is-marketing-automation','2023-07-01',2840,2380,55.8,122,24),
('/blog/what-is-marketing-automation','2023-10-01',3600,2980,52.4,138,35),
('/blog/what-is-marketing-automation','2024-01-01',4400,3560,49.2,152,48),
('/blog/what-is-marketing-automation','2024-04-01',5100,4080,46.1,168,64),
('/blog/what-is-marketing-automation','2024-07-01',5800,4580,43.2,182,82),
('/blog/what-is-marketing-automation','2024-10-01',6600,5160,40.4,196,104),
('/blog/content-marketing-strategy','2023-01-01',480,420,65.2,88,4),
('/blog/content-marketing-strategy','2023-04-01',820,720,61.8,102,8),
('/blog/content-marketing-strategy','2023-07-01',1380,1180,58.4,116,14),
('/blog/content-marketing-strategy','2023-10-01',1920,1620,55.2,128,22),
('/blog/content-marketing-strategy','2024-01-01',2480,2040,52.4,142,30),
('/blog/content-marketing-strategy','2024-04-01',3100,2520,49.2,156,40),
('/blog/content-marketing-strategy','2024-07-01',3780,3020,46.4,168,52),
('/blog/content-marketing-strategy','2024-10-01',4420,3480,43.8,180,68),
('/pricing','2023-01-01',1820,920,35.4,198,28),
('/pricing','2023-04-01',2240,1120,33.8,212,38),
('/pricing','2023-07-01',2880,1380,31.4,228,52),
('/pricing','2023-10-01',3400,1620,29.8,242,68),
('/pricing','2024-01-01',4100,1920,27.6,256,88),
('/pricing','2024-04-01',4800,2240,25.4,270,112),
('/pricing','2024-07-01',5600,2560,23.8,284,138),
('/pricing','2024-10-01',6400,2880,22.2,298,168);

-- ============================================================
-- PPC: AD GROUPS AND ADS
-- ============================================================
INSERT INTO ad_groups (campaign_id, ad_group_name, bid_strategy, max_cpc, target_cpa, status) VALUES
(2,  'Brand Keywords',          'target_cpa',  NULL,   45.00, 'active'),
(2,  'Product Features',        'manual_cpc',  8.50,   NULL,  'active'),
(2,  'Competitor Comparison',   'manual_cpc',  6.75,   NULL,  'active'),
(10, 'Competitor Brand Terms',  'target_cpa',  NULL,   85.00, 'active'),
(10, 'Pain Point Keywords',     'manual_cpc',  9.25,   NULL,  'active'),
(10, 'Solution Aware Queries',  'target_roas', NULL,   NULL,  'active'),
(14, 'High Intent Buyers',      'target_cpa',  NULL,   65.00, 'active'),
(14, 'Year End Deals',          'maximize_conversions', NULL, NULL, 'active'),
(22, 'Brand Keywords 2024',     'target_cpa',  NULL,   40.00, 'active'),
(22, 'Product Features 2024',   'manual_cpc',  9.00,   NULL,  'active'),
(30, 'Competitor Brand 2024',   'target_cpa',  NULL,   75.00, 'active'),
(30, 'Solution Keywords 2024',  'target_roas', NULL,   NULL,  'active'),
(34, 'High Intent 2024',        'target_cpa',  NULL,   55.00, 'active'),
(34, 'Holiday Deals 2024',      'maximize_conversions', NULL, NULL, 'active');

INSERT INTO ads (ad_group_id, headline_1, headline_2, headline_3, description_1, description_2, final_url, ad_type, status) VALUES
(1,'Marketing Automation','Start Free Trial Today','Rated #1 by G2','Automate your marketing workflows and convert more leads.','Trusted by 5000+ businesses. No credit card required.','/trial','rsa','active'),
(1,'Marketing Platform','See How It Works','Book a Demo',NULL,'Streamline campaigns and prove ROI with real-time analytics.','/demo','rsa','active'),
(2,'Email + CRM + Analytics','All-in-One Platform','See All Features','Connect your tools and unify your marketing data in one place.','Used by marketing teams at leading B2B companies.','/products','rsa','active'),
(3,'vs HubSpot','Compare Features','Switch Today','See why marketing teams choose us over HubSpot.',NULL,'/compare/hubspot','rsa','active'),
(4,'Tired of HubSpot Costs?','Better ROI','Switch in 30 Days','Get the same features for half the price.',NULL,'/compare/hubspot','rsa','active'),
(5,'Stop Losing Leads','Automate Follow Up','Close More Deals','Every lead gets a personalized follow-up automatically.',NULL,'/products','rsa','active'),
(7,'Year End Deal','50% Off First Year','Limited Time','Lock in annual pricing before December 31st.',NULL,'/pricing','rsa','active'),
(8,'Holiday Offer Ends Soon','Book Your Demo','Save This Year','Get onboarded before year end and start 2024 ahead.',NULL,'/demo','rsa','active'),
(9,'Marketing Automation 2024','New AI Features','Start Free',NULL,'Now with AI-powered campaign recommendations.','/trial','rsa','active'),
(10,'All-in-One Marketing','Built for Growth','See Features','The platform that scales with your marketing team.',NULL,'/products','rsa','active'),
(11,'Switch From HubSpot','Save 40% Annually','See Comparison','Marketing teams save an average of $18k per year.',NULL,'/compare/hubspot','rsa','active'),
(13,'Year End Pricing','Save Before 2025','Book Demo Now','Our best pricing of the year. Ends December 31st.',NULL,'/pricing','rsa','active'),
(14,'Close 2024 Strong','Lock In Annual Price','Act Now',NULL,'Start 2025 with your team fully onboarded and running.','/demo','rsa','active');

-- AD PERFORMANCE (monthly, 2023 + 2024)
INSERT INTO ad_performance (ad_id, perf_date, impressions, clicks, spend, conversions, conversion_value, quality_score) VALUES
(1,'2023-01-01',18200,728,3276.00,8,96000.00,7),
(1,'2023-04-01',22400,1008,4032.00,11,132000.00,7),
(1,'2023-07-01',26800,1340,5360.00,14,168000.00,8),
(1,'2023-10-01',31200,1872,6240.00,18,216000.00,8),
(1,'2024-01-01',34800,2088,6264.00,22,264000.00,8),
(1,'2024-04-01',38200,2674,6704.00,28,336000.00,9),
(1,'2024-07-01',41600,3120,7488.00,34,408000.00,9),
(1,'2024-10-01',46200,3696,8554.00,42,504000.00,9),
(4,'2023-07-01',14200,710,4260.00,6,90000.00,6),
(4,'2023-10-01',18400,1104,5888.00,9,135000.00,6),
(4,'2024-01-01',21200,1484,7420.00,11,165000.00,7),
(4,'2024-04-01',24800,1984,9424.00,14,210000.00,7),
(4,'2024-07-01',28400,2556,12141.00,18,270000.00,8),
(4,'2024-10-01',32600,3260,15511.00,22,330000.00,8),
(7,'2023-10-01',28400,1988,9940.00,16,320000.00,7),
(7,'2024-10-01',34200,2736,12312.00,24,480000.00,8),
(9,'2024-01-01',32400,1944,7776.00,18,252000.00,8),
(9,'2024-04-01',36800,2576,9030.00,22,308000.00,8),
(9,'2024-07-01',42200,3376,12154.00,28,392000.00,9),
(9,'2024-10-01',48600,4374,15309.00,36,504000.00,9);

-- ============================================================
-- EMAIL CAMPAIGNS (20 email sends, 2023 + 2024)
-- ============================================================
INSERT INTO email_campaigns (campaign_id, email_name, subject_line, preview_text, sender_name, audience_segment, email_type, list_size, send_date, status) VALUES
(1, 'Jan 2023 Nurture - Email 1',  'How top marketers save 10 hours a week',           'Automation is the key...',              'Marketing Team', 'Enterprise Nurture List',  'nurture',      4200,  '2023-01-10 09:00:00', 'sent'),
(1, 'Jan 2023 Nurture - Email 2',  'Your leads are slipping through the cracks',       'Here is how to fix that...',            'Marketing Team', 'Enterprise Nurture List',  'nurture',      4200,  '2023-01-24 09:00:00', 'sent'),
(5, 'Q2 2023 Spring Promo',        'Spring into savings - 30% off this month',         'Our biggest offer of Q2...',            'Sales Team',     'All Subscribers',          'promotional',  12800, '2023-04-04 09:00:00', 'sent'),
(5, 'Q2 2023 Spring Reminder',     'Last chance - Spring offer ends Friday',           'Do not miss this...',                   'Sales Team',     'Non-Openers Spring Promo', 'promotional',  6200,  '2023-04-18 09:00:00', 'sent'),
(9, 'Q3 2023 Summer Email 1',      'Your summer marketing playbook is here',           'Download the guide...',                 'Marketing Team', 'All Subscribers',          'newsletter',   13400, '2023-07-06 09:00:00', 'sent'),
(9, 'Q3 2023 Summer Promo',        'Beat the summer slump - exclusive offer inside',   'Limited spots available...',            'Sales Team',     'SMB Segment',              'promotional',  5800,  '2023-07-20 09:00:00', 'sent'),
(13,'Q4 2023 Holiday Email 1',     'Your 2024 marketing plan starts now',              'Get ahead of the competition...',       'Marketing Team', 'All Subscribers',          'newsletter',   14800, '2023-10-05 09:00:00', 'sent'),
(13,'Q4 2023 Holiday Promo',       'Year end deal - lock in 2023 pricing for 2024',    'Biggest offer of the year...',          'Sales Team',     'All Subscribers',          'promotional',  14800, '2023-11-15 09:00:00', 'sent'),
(13,'Q4 2023 Last Chance',         'Final hours to save - offer expires midnight',     'This is your last chance...',           'Sales Team',     'Non-Converters',           'promotional',  8200,  '2023-12-20 09:00:00', 'sent'),
(18,'Q4 2023 Win-Back',            'We miss you - here is something special',          'An offer just for you...',              'Marketing Team', 'Churned 90 Day',           'win_back',     1800,  '2023-11-08 09:00:00', 'sent'),
(21,'Q1 2024 Nurture - Email 1',   'The 2024 marketing automation playbook',           'Everything changed. Here is how...',    'Marketing Team', 'Enterprise Nurture List',  'nurture',      5600,  '2024-01-08 09:00:00', 'sent'),
(21,'Q1 2024 Nurture - Email 2',   'How AI is changing lead scoring forever',          'Our take on the shift...',              'Marketing Team', 'Enterprise Nurture List',  'nurture',      5600,  '2024-01-22 09:00:00', 'sent'),
(25,'Q2 2024 Spring Promo',        'Spring into 2024 - our best offer yet',            'Hurry - limited availability...',       'Sales Team',     'All Subscribers',          'promotional',  15200, '2024-04-02 09:00:00', 'sent'),
(25,'Q2 2024 Spring Reminder',     'You opened but did not act - here is why you should','Still thinking it over...',           'Sales Team',     'Openers No Click',         'promotional',  4800,  '2024-04-16 09:00:00', 'sent'),
(29,'Q3 2024 Summer Newsletter',   'Mid-year marketing audit - is yours on track?',    'Check these 5 metrics now...',          'Marketing Team', 'All Subscribers',          'newsletter',   16400, '2024-07-08 09:00:00', 'sent'),
(29,'Q3 2024 Summer Promo',        'Q3 push - upgrade before September',               'Q3 ends in 8 weeks...',                 'Sales Team',     'Trial Users',              'promotional',  3200,  '2024-07-22 09:00:00', 'sent'),
(33,'Q4 2024 Holiday Email 1',     'Black Friday deal inside - 40% off',               'Our biggest offer ever...',             'Sales Team',     'All Subscribers',          'promotional',  17600, '2024-11-22 09:00:00', 'sent'),
(33,'Q4 2024 Holiday Email 2',     '2025 planning guide - free download',              'Your guide to dominating 2025...',      'Marketing Team', 'All Subscribers',          'newsletter',   17600, '2024-12-03 09:00:00', 'sent'),
(33,'Q4 2024 Last Chance',         'Midnight tonight - year end offer closes',         'Last call...',                          'Sales Team',     'Non-Converters',           'promotional',  9800,  '2024-12-31 09:00:00', 'sent'),
(38,'Q4 2024 Win-Back',            'It has been a while - here is 50% off to return',  'We want you back...',                   'Marketing Team', 'Churned 90 Day',           'win_back',     2200,  '2024-11-12 09:00:00', 'sent');

-- EMAIL EVENTS (aggregated per campaign - open/click/convert events)
INSERT INTO email_events (email_campaign_id, customer_id, event_type, event_at, device_type, email_client) VALUES
-- Email 1: Jan Nurture (4200 sent - showing sample events)
(1,1,'opened','2023-01-10 10:22:00','desktop','outlook'),
(1,1,'clicked','2023-01-10 10:24:00','desktop','outlook'),
(1,2,'opened','2023-01-10 11:08:00','mobile','gmail'),
(1,3,'opened','2023-01-10 09:45:00','desktop','gmail'),
(1,3,'clicked','2023-01-10 09:47:00','desktop','gmail'),
(1,4,'opened','2023-01-10 14:32:00','mobile','apple_mail'),
(1,5,'opened','2023-01-10 08:15:00','desktop','outlook'),
(1,5,'clicked','2023-01-10 08:18:00','desktop','outlook'),
(1,NULL,'opened','2023-01-10 12:44:00','mobile','gmail'),
(1,NULL,'opened','2023-01-10 13:22:00','tablet','gmail'),
(1,NULL,'clicked','2023-01-10 13:24:00','tablet','gmail'),
-- Email 3: Q2 Spring Promo
(3,7,'opened','2023-04-04 09:42:00','desktop','outlook'),
(3,7,'clicked','2023-04-04 09:44:00','desktop','outlook'),
(3,7,'converted','2023-04-04 09:52:00','desktop','outlook'),
(3,9,'opened','2023-04-04 10:18:00','desktop','gmail'),
(3,11,'opened','2023-04-04 11:04:00','mobile','gmail'),
(3,11,'clicked','2023-04-04 11:06:00','mobile','gmail'),
(3,15,'opened','2023-04-04 12:30:00','desktop','apple_mail'),
(3,19,'opened','2023-04-04 08:55:00','desktop','outlook'),
(3,19,'clicked','2023-04-04 09:00:00','desktop','outlook'),
(3,19,'converted','2023-04-04 09:15:00','desktop','outlook'),
-- Email 8: Q4 2023 Holiday Promo
(8,22,'opened','2023-11-15 09:12:00','desktop','outlook'),
(8,22,'clicked','2023-11-15 09:14:00','desktop','outlook'),
(8,22,'converted','2023-11-15 09:28:00','desktop','outlook'),
(8,25,'opened','2023-11-15 10:44:00','desktop','gmail'),
(8,25,'clicked','2023-11-15 10:46:00','desktop','gmail'),
(8,28,'opened','2023-11-15 11:22:00','mobile','gmail'),
(8,31,'opened','2023-11-15 08:48:00','desktop','outlook'),
(8,31,'clicked','2023-11-15 08:50:00','desktop','outlook'),
(8,35,'opened','2023-11-15 13:15:00','desktop','apple_mail'),
(8,39,'opened','2023-11-15 14:02:00','mobile','gmail'),
-- Email 13: Q2 2024 Spring Promo
(13,1,'opened','2024-04-02 09:18:00','desktop','outlook'),
(13,1,'clicked','2024-04-02 09:20:00','desktop','outlook'),
(13,1,'converted','2024-04-02 09:35:00','desktop','outlook'),
(13,3,'opened','2024-04-02 10:44:00','desktop','gmail'),
(13,5,'opened','2024-04-02 08:32:00','desktop','outlook'),
(13,5,'clicked','2024-04-02 08:35:00','desktop','outlook'),
(13,7,'opened','2024-04-02 11:28:00','mobile','gmail'),
(13,9,'opened','2024-04-02 09:55:00','desktop','gmail'),
(13,9,'clicked','2024-04-02 09:57:00','desktop','gmail'),
(13,11,'opened','2024-04-02 12:18:00','desktop','apple_mail'),
(13,11,'clicked','2024-04-02 12:20:00','desktop','apple_mail'),
(13,11,'converted','2024-04-02 12:34:00','desktop','apple_mail'),
-- Email 17: Q4 2024 Holiday Promo
(17,15,'opened','2024-11-22 09:08:00','desktop','outlook'),
(17,15,'clicked','2024-11-22 09:10:00','desktop','outlook'),
(17,15,'converted','2024-11-22 09:22:00','desktop','outlook'),
(17,19,'opened','2024-11-22 10:34:00','desktop','gmail'),
(17,19,'clicked','2024-11-22 10:36:00','desktop','gmail'),
(17,22,'opened','2024-11-22 08:48:00','desktop','outlook'),
(17,25,'opened','2024-11-22 11:22:00','mobile','gmail'),
(17,25,'clicked','2024-11-22 11:24:00','mobile','gmail'),
(17,28,'opened','2024-11-22 12:44:00','desktop','apple_mail'),
(17,28,'converted','2024-11-22 13:02:00','desktop','apple_mail'),
(17,31,'opened','2024-11-22 14:18:00','desktop','outlook'),
(17,35,'opened','2024-11-22 09:52:00','desktop','gmail'),
(17,35,'clicked','2024-11-22 09:54:00','desktop','gmail'),
(17,35,'converted','2024-11-22 10:08:00','desktop','gmail');

-- ============================================================
-- GTM TAGS
-- ============================================================
INSERT INTO gtm_tags (tag_name, tag_type, trigger_type, trigger_detail, is_active, firing_option) VALUES
('GA4 - Page View',                    'GA4 Event',              'Page View',       'All Pages',                  1, 'once_per_page'),
('GA4 - CTA Click - Demo Request',     'GA4 Event',              'Click',           'Button text contains Demo',  1, 'once_per_event'),
('GA4 - CTA Click - Free Trial',       'GA4 Event',              'Click',           'Button text contains Trial', 1, 'once_per_event'),
('GA4 - Form Submit - Contact',        'GA4 Event',              'Form Submit',     'Form ID = contact-form',     1, 'once_per_event'),
('GA4 - Form Submit - Demo Form',      'GA4 Event',              'Form Submit',     'Form ID = demo-form',        1, 'once_per_event'),
('Google Ads - Demo Conversion',       'Google Ads Conversion',  'Form Submit',     'Form ID = demo-form',        1, 'once_per_event'),
('Google Ads - Trial Signup',          'Google Ads Conversion',  'Form Submit',     'Form ID = trial-form',       1, 'once_per_event'),
('Meta Pixel - PageView',              'Meta Pixel',             'Page View',       'All Pages',                  1, 'once_per_page'),
('Meta Pixel - Lead',                  'Meta Pixel',             'Form Submit',     'Any Form',                   1, 'once_per_event'),
('Meta Pixel - Purchase',              'Meta Pixel',             'Custom Event',    'purchase',                   1, 'once_per_event'),
('LinkedIn Insight Tag',               'LinkedIn',               'Page View',       'All Pages',                  1, 'once_per_page'),
('LinkedIn - Lead Gen Form',           'LinkedIn',               'Form Submit',     'LinkedIn Lead Gen',          1, 'once_per_event'),
('GA4 - Scroll Depth 50pct',           'GA4 Event',              'Scroll Depth',    '50% scroll depth',           1, 'once_per_page'),
('GA4 - Scroll Depth 90pct',           'GA4 Event',              'Scroll Depth',    '90% scroll depth',           1, 'once_per_page'),
('GA4 - Video Play',                   'GA4 Event',              'YouTube Video',   'Any YouTube video',          1, 'once_per_event'),
('GA4 - Outbound Click',               'GA4 Event',              'Click',           'Link URL does not contain domain', 1, 'once_per_event'),
('Google Ads Remarketing Tag',         'Google Ads Remarketing', 'Page View',       'All Pages',                  1, 'once_per_page'),
('Hotjar Tracking Code',               'Custom HTML',            'Page View',       'All Pages',                  1, 'once_per_page'),
('GA4 - File Download',                'GA4 Event',              'Click',           'Link URL ends with pdf',     1, 'once_per_event'),
('GA4 - Site Search',                  'GA4 Event',              'Custom Event',    'search query parameter',     0, 'once_per_event');

-- WEB EVENTS (sample tracking events)
INSERT INTO web_events (session_id, customer_id, tag_id, page_url, event_name, event_category, event_value, device_type, traffic_source, created_at) VALUES
('sess_001',1,1,'/','page_view','Navigation',NULL,'desktop','google_organic','2023-01-15 09:00:00'),
('sess_001',1,13,'/','scroll_50','Engagement',NULL,'desktop','google_organic','2023-01-15 09:01:30'),
('sess_001',1,2,'/','cta_click','CTA',NULL,'desktop','google_organic','2023-01-15 09:02:15'),
('sess_001',1,5,'/demo','form_submit','Lead',NULL,'desktop','google_organic','2023-01-15 09:04:42'),
('sess_002',5,1,'/products/marketing-automation','page_view','Navigation',NULL,'desktop','google_paid','2023-02-05 10:00:00'),
('sess_002',5,14,'/products/marketing-automation','scroll_90','Engagement',NULL,'desktop','google_paid','2023-02-05 10:02:18'),
('sess_002',5,6,'/products/marketing-automation','cta_click','Lead',NULL,'desktop','google_paid','2023-02-05 10:03:45'),
('sess_003',NULL,1,'/blog/what-is-marketing-automation','page_view','Navigation',NULL,'mobile','google_organic','2023-03-10 14:00:00'),
('sess_003',NULL,13,'/blog/what-is-marketing-automation','scroll_50','Engagement',NULL,'mobile','google_organic','2023-03-10 14:01:45'),
('sess_004',9,1,'/pricing','page_view','Navigation',NULL,'desktop','google_paid','2023-04-12 11:00:00'),
('sess_004',9,2,'/pricing','cta_click','CTA',NULL,'desktop','google_paid','2023-04-12 11:02:30'),
('sess_005',NULL,1,'/blog/content-marketing-strategy','page_view','Navigation',NULL,'desktop','google_organic','2023-05-20 09:00:00'),
('sess_005',NULL,19,'/blog/content-marketing-strategy','file_download','Content',NULL,'desktop','google_organic','2023-05-20 09:03:12'),
('sess_006',15,1,'/','page_view','Navigation',NULL,'desktop','linkedin','2023-06-08 10:00:00'),
('sess_006',15,3,'/','cta_click','CTA',NULL,'desktop','linkedin','2023-06-08 10:01:22'),
('sess_007',22,1,'/products/marketing-automation','page_view','Navigation',NULL,'desktop','email','2024-01-10 09:00:00'),
('sess_007',22,2,'/products/marketing-automation','cta_click','Lead',NULL,'desktop','email','2024-01-10 09:01:48'),
('sess_007',22,5,'/demo','form_submit','Lead',NULL,'desktop','email','2024-01-10 09:04:22'),
('sess_008',NULL,1,'/blog/digital-marketing-trends','page_view','Navigation',NULL,'mobile','google_organic','2024-02-14 15:00:00'),
('sess_009',29,1,'/pricing','page_view','Navigation',NULL,'desktop','google_paid','2024-03-22 11:00:00'),
('sess_009',29,3,'/pricing','cta_click','CTA',NULL,'desktop','google_paid','2024-03-22 11:01:55'),
('sess_010',35,1,'/','page_view','Navigation',NULL,'desktop','facebook','2024-04-05 10:00:00'),
('sess_010',35,8,'/','page_view','Navigation',NULL,'desktop','facebook','2024-04-05 10:00:00'),
('sess_010',35,2,'/','cta_click','Lead',NULL,'desktop','facebook','2024-04-05 10:02:18'),
('sess_011',41,1,'/products/marketing-automation','page_view','Navigation',NULL,'desktop','email','2024-05-15 09:00:00'),
('sess_011',41,14,'/products/marketing-automation','scroll_90','Engagement',NULL,'desktop','email','2024-05-15 09:02:44'),
('sess_012',NULL,1,'/compare/hubspot','page_view','Navigation',NULL,'desktop','google_paid','2024-06-20 14:00:00'),
('sess_013',47,1,'/blog/email-best-practices','page_view','Navigation',NULL,'mobile','google_organic','2024-07-08 10:00:00'),
('sess_014',3,1,'/pricing','page_view','Navigation',NULL,'desktop','google_organic','2024-08-14 11:00:00'),
('sess_014',3,2,'/pricing','cta_click','Lead',NULL,'desktop','google_organic','2024-08-14 11:01:32'),
('sess_015',9,1,'/','page_view','Navigation',NULL,'desktop','google_paid','2024-09-05 09:00:00'),
('sess_015',9,6,'/','cta_click','Lead',NULL,'desktop','google_paid','2024-09-05 09:01:18'),
('sess_015',9,5,'/trial','form_submit','Lead',800.00,'desktop','google_paid','2024-09-05 09:03:44');

-- ============================================================
-- CONTENT PIECES (30 pieces)
-- ============================================================
INSERT INTO content_pieces (title, content_type, topic_cluster, target_keyword, author, word_count, publish_date, status, cta_type, campaign_id) VALUES
('What Is Marketing Automation? The Complete 2023 Guide',   'blog_post',   'Marketing Automation', 'what is marketing automation',        'Content Team', 3200, '2023-01-15', 'published', 'demo_request',  1),
('10 Best Marketing Automation Tools for 2023',             'blog_post',   'Marketing Automation', 'best marketing automation tools',     'Content Team', 4100, '2023-02-01', 'published', 'demo_request',  NULL),
('How to Build a Lead Nurturing Email Sequence',            'blog_post',   'Email Marketing',      'email drip campaign software',        'Email Team',   2800, '2023-02-15', 'published', 'download',      1),
('Marketing Automation ROI Calculator',                     'landing_page','Marketing Analytics',  'marketing automation roi',            'Web Team',     800,  '2023-03-01', 'published', 'contact',       NULL),
('The Ultimate Content Marketing Strategy Guide',           'blog_post',   'Content Marketing',    'content marketing strategy',          'Content Team', 5200, '2023-03-15', 'published', 'download',      4),
('B2B Lead Generation Playbook 2023',                       'whitepaper',  'Lead Management',      'b2b lead generation tools',           'Content Team', 8400, '2023-04-01', 'published', 'download',      5),
('Marketing Attribution Models Explained',                  'blog_post',   'Attribution',          'multi touch attribution model',       'Analytics Team',2600,'2023-04-15', 'published', 'demo_request',  NULL),
('Email Marketing Best Practices Guide',                    'blog_post',   'Email Marketing',      'email marketing best practices',      'Email Team',   3400, '2023-05-01', 'published', 'download',      5),
('How We Helped TechCorp 4x Their Lead Volume',             'case_study',  'Marketing Automation', 'marketing automation software',       'Content Team', 1800, '2023-05-15', 'published', 'demo_request',  NULL),
('Customer Segmentation Strategies That Convert',           'blog_post',   'Audience Targeting',   'customer segmentation strategies',    'Content Team', 3100, '2023-06-01', 'published', 'demo_request',  NULL),
('Digital Marketing Trends to Watch in 2023',               'blog_post',   'Trends',               'digital marketing trends 2024',       'Content Team', 2900, '2023-06-15', 'published', 'subscribe',     NULL),
('Marketing Automation vs CRM - Which Do You Need?',        'blog_post',   'Marketing Automation', 'marketing automation vs crm',         'Content Team', 2400, '2023-07-01', 'published', 'demo_request',  NULL),
('How to Set Up GA4 for Marketing Analytics',               'blog_post',   'Marketing Analytics',  'marketing analytics dashboard',       'Analytics Team',3600,'2023-07-15', 'published', 'download',      NULL),
('A/B Testing Guide for Marketers',                         'blog_post',   'Testing',              'a b testing marketing',               'Content Team', 3800, '2023-08-01', 'published', 'demo_request',  9),
('Conversion Rate Optimization Checklist',                  'blog_post',   'CRO',                  'conversion rate optimization',        'Web Team',     2200, '2023-08-15', 'published', 'download',      NULL),
('Landing Page Optimization: 15 Proven Tactics',            'blog_post',   'CRO',                  'landing page optimization',           'Web Team',     3400, '2023-09-01', 'published', 'demo_request',  NULL),
('Q4 Marketing Playbook: Close the Year Strong',            'whitepaper',  'Marketing Analytics',  'campaign performance reporting',      'Content Team', 6200, '2023-09-15', 'published', 'download',      13),
('SEO for Marketers: A Practical Guide',                    'blog_post',   'SEO',                  'seo tools for marketers',             'SEO Team',     4200, '2023-10-01', 'published', 'demo_request',  NULL),
('Email Automation Webinar: Live Q&A Recap',                'blog_post',   'Email Marketing',      'automated email campaigns',           'Email Team',   1800, '2023-10-15', 'published', 'subscribe',     13),
('AI Marketing Tools: What Actually Works in 2024',         'blog_post',   'AI Marketing',         'ai marketing tools',                  'Content Team', 3600, '2024-01-10', 'published', 'demo_request',  21),
('Lead Scoring 101: Build a System That Predicts Revenue',  'blog_post',   'Lead Management',      'lead scoring software',               'Analytics Team',3200,'2024-01-25', 'published', 'demo_request',  21),
('10 Best Marketing Automation Tools for 2024',             'blog_post',   'Marketing Automation', 'best marketing automation tools',     'Content Team', 4600, '2024-02-05', 'published', 'demo_request',  NULL),
('How to Master PPC Campaign Optimization',                 'blog_post',   'PPC',                  'ppc campaign management',             'PPC Team',     4100, '2024-02-20', 'published', 'demo_request',  22),
('The 2024 B2B Marketing Benchmark Report',                 'whitepaper',  'Marketing Analytics',  'marketing analytics dashboard',       'Content Team', 9800, '2024-03-01', 'published', 'download',      NULL),
('GTM Setup Guide for Marketing Teams',                     'blog_post',   'Marketing Analytics',  'campaign performance reporting',      'Analytics Team',3800,'2024-03-15', 'published', 'download',      NULL),
('Content Marketing Strategy for 2024',                     'blog_post',   'Content Marketing',    'content marketing strategy',          'Content Team', 5400, '2024-04-01', 'published', 'download',      25),
('Digital Marketing Trends to Watch in 2024',               'blog_post',   'Trends',               'digital marketing trends 2024',       'Content Team', 3200, '2024-04-15', 'published', 'subscribe',     NULL),
('Marketing Attribution: Moving Beyond Last Click',         'blog_post',   'Attribution',          'marketing attribution software',      'Analytics Team',3100,'2024-05-01', 'published', 'demo_request',  NULL),
('How to Build a Marketing Analytics Dashboard in SQL',     'blog_post',   'Marketing Analytics',  'marketing analytics dashboard',       'Analytics Team',4800,'2024-06-01', 'published', 'demo_request',  NULL),
('2025 Marketing Predictions: AI, Privacy, and Performance','blog_post',   'Trends',               'digital marketing trends 2024',       'Content Team', 3600, '2024-11-01', 'published', 'subscribe',     33);

-- CONTENT PERFORMANCE (monthly data for top pieces)
INSERT INTO content_performance (content_id, perf_date, page_views, unique_visitors, avg_time_sec, bounce_rate_pct, social_shares, comments, backlinks_earned, cta_clicks, conversions) VALUES
(1,'2023-02-01',2840,2420,142,58.2,124,18,8,98,12),
(1,'2023-05-01',4200,3580,168,54.4,186,24,14,154,22),
(1,'2023-08-01',6100,5060,188,50.8,242,31,22,228,34),
(1,'2023-11-01',8400,6920,204,47.2,314,42,31,308,48),
(1,'2024-02-01',10800,8840,218,44.2,388,52,42,402,64),
(1,'2024-05-01',13400,10840,232,41.4,462,64,54,496,82),
(1,'2024-08-01',16200,13000,244,38.8,538,76,68,590,102),
(1,'2024-11-01',19400,15440,256,36.4,614,89,84,684,124),
(5,'2023-04-01',1820,1560,198,52.4,88,12,6,64,8),
(5,'2023-07-01',3200,2720,224,48.8,148,20,12,112,14),
(5,'2023-10-01',4800,4040,244,45.4,214,28,18,168,22),
(5,'2024-01-01',6400,5360,264,42.2,282,38,26,224,32),
(5,'2024-04-01',8200,6840,282,39.4,352,48,36,288,44),
(5,'2024-07-01',10200,8440,298,36.8,428,60,48,352,58),
(5,'2024-10-01',12400,10200,314,34.4,504,74,62,420,74),
(20,'2024-02-01',4200,3640,168,54.8,198,28,12,148,18),
(20,'2024-05-01',7800,6680,188,50.4,368,48,24,284,36),
(20,'2024-08-01',12400,10480,208,46.2,568,72,38,448,58),
(20,'2024-11-01',18200,15280,226,42.4,784,98,56,624,84);

-- ============================================================
-- AUDIENCES
-- ============================================================
INSERT INTO audiences (audience_name, channel, audience_type, criteria_description, size_estimate, match_rate_pct, is_active) VALUES
('Enterprise Decision Makers',          'LinkedIn',  'demographic',  'Job title: VP, Director, C-Suite. Company size: 500+. Industry: Tech, Finance, Healthcare', 48000,  NULL,  1),
('SMB Marketing Managers',              'LinkedIn',  'demographic',  'Job title: Marketing Manager. Company size: 10-500. Any industry',                          124000, NULL,  1),
('All Website Visitors 30 Day',         'Google',    'remarketing',  'Visited any page on our site in last 30 days',                                               18400,  NULL,  1),
('Pricing Page Visitors',               'Google',    'remarketing',  'Visited /pricing in last 14 days. Did not convert',                                           2800,  NULL,  1),
('Demo Page Non-Converters',            'Google',    'remarketing',  'Visited /demo but did not submit form. Last 30 days',                                         1600,  NULL,  1),
('Blog Readers - High Engagement',      'Google',    'remarketing',  'Visited 3+ blog posts in 30 days',                                                            4200,  NULL,  1),
('Lookalike - Converted Customers',     'Meta',      'lookalike',    '1% lookalike of our converted customer list. USA only',                                      820000, NULL,  1),
('Lookalike - Enterprise Customers',    'Meta',      'lookalike',    '2% lookalike of Enterprise segment customers',                                               1400000,NULL,  1),
('Interest - Marketing Software',       'Meta',      'interest',     'Interests: Marketing Software, CRM, Email Marketing, Digital Marketing',                    2200000,NULL,  1),
('In-Market - CRM and Marketing Tools', 'Google',    'in_market',    'Google in-market audience: CRM and Marketing Software buyers',                              480000, NULL,  1),
('Existing Customers - Upsell',         'Email',     'custom',       'Active customers on Starter or Pro plan. Tenure 6+ months',                                   3800,  92.4,  1),
('Churned Customers 90 Day',            'Email',     'custom',       'Customers who cancelled in last 90 days. Exclude hard bounces',                               1200,  88.6,  1),
('Trial Users - Day 7',                 'Email',     'custom',       'Free trial users who have not converted by day 7',                                            640,   94.2,  1),
('High Intent Content Readers',         'Organic',   'custom',       'Read 5+ blog posts on marketing automation topic cluster',                                    2100,  NULL,  1),
('B2B Finance Decision Makers',         'LinkedIn',  'demographic',  'Job title: CFO, Finance Director, VP Finance. Company 200+',                                 32000, NULL,  1);

-- AUDIENCE MEMBERS (link customers to audiences)
INSERT INTO audience_members (audience_id, customer_id, added_at, added_by) VALUES
(11,1,'2023-06-01 00:00:00','system'),(11,2,'2023-06-01 00:00:00','system'),(11,3,'2023-06-01 00:00:00','system'),
(11,5,'2023-06-01 00:00:00','system'),(11,7,'2023-06-01 00:00:00','system'),(11,9,'2023-06-01 00:00:00','system'),
(11,11,'2023-06-01 00:00:00','system'),(11,15,'2023-06-01 00:00:00','system'),(11,19,'2023-06-01 00:00:00','system'),
(11,22,'2023-06-01 00:00:00','system'),(11,25,'2023-06-01 00:00:00','system'),(11,29,'2023-06-01 00:00:00','system'),
(12,16,'2023-09-01 00:00:00','system'),(12,26,'2023-09-01 00:00:00','system'),(12,30,'2023-09-01 00:00:00','system'),
(12,33,'2023-09-01 00:00:00','system'),(12,36,'2023-09-01 00:00:00','system'),
(13,NULL,'2023-10-01 00:00:00','import'),
(14,NULL,'2024-01-01 00:00:00','system');

-- ============================================================
-- A/B TESTS (12 tests across 2023 + 2024)
-- ============================================================
INSERT INTO ab_tests (test_name, campaign_id, content_id, email_campaign_id, test_type, hypothesis, start_date, end_date, status, winner_variant, confidence_pct, primary_metric) VALUES
('Email Subject Line Test - Q1 2023',       NULL, NULL, 1,  'subject_line',   'Personalized subject lines will improve open rate by 15%',                     '2023-01-10','2023-01-24','completed','variant_a', 94.2, 'open_rate'),
('Landing Page CTA Test - Q1 2023',         NULL, 4,   NULL,'landing_page',   'Changing CTA from Get Demo to Start Free Trial will increase conversions',     '2023-02-01','2023-03-01','completed','variant_a', 97.8, 'conversion_rate'),
('Ad Copy Test - Q2 2023 Facebook',         6,    NULL, NULL,'ad_copy',       'Pain point focused headlines will outperform feature headlines on social',     '2023-04-05','2023-04-26','completed','variant_a', 91.4, 'ctr'),
('Email Frequency Test - Nurture',          1,    NULL, 2,  'subject_line',   'Biweekly sends will have higher engagement than weekly',                       '2023-04-24','2023-06-24','completed','control',   88.6, 'click_rate'),
('Pricing Page Layout Test',                NULL, NULL, NULL,'landing_page',  'Annual pricing first will improve annual plan selection rate',                  '2023-06-01','2023-07-01','completed','variant_a', 95.2, 'annual_plan_rate'),
('Blog CTA Placement Test',                 NULL, 5,   NULL,'landing_page',   'Inline CTA mid-article will outperform end-of-article CTA',                    '2023-07-01','2023-08-01','completed','variant_a', 92.8, 'cta_click_rate'),
('Q4 Email Offer Test',                     13,   NULL, 8,  'subject_line',   'Percentage discount subject lines will outperform dollar amount discounts',    '2023-11-15','2023-11-29','completed','variant_a', 89.4, 'click_rate'),
('Google Ads Bid Strategy Test',            22,   NULL, NULL,'bid_strategy',  'Target CPA bidding will outperform Manual CPC for qualified lead volume',      '2024-01-10','2024-02-10','completed','variant_a', 96.2, 'cost_per_lead'),
('Email Personalization Test Q1 2024',      NULL, NULL, 11, 'subject_line',   'First name personalization in subject will lift open rate by 20%',             '2024-01-08','2024-01-22','completed','variant_a', 93.6, 'open_rate'),
('Demo Page Headline Test',                 NULL, NULL, NULL,'landing_page',  'Outcome focused headline will outperform feature focused headline',             '2024-03-01','2024-04-01','completed','variant_a', 98.1, 'form_submission_rate'),
('Q2 2024 Ad Audience Test',                25,   NULL, NULL,'audience',      'Interest targeting will outperform broad targeting for CPL on Meta',           '2024-04-05','2024-05-05','completed','variant_a', 90.8, 'cost_per_lead'),
('Content Upgrade Test',                    NULL, 20,  NULL,'landing_page',   'Offering a content upgrade download will improve blog conversion rate',        '2024-05-01','2024-06-01','completed','variant_a', 94.4, 'conversion_rate');

-- AB VARIANTS
INSERT INTO ab_variants (test_id, variant_name, variant_detail, sample_size, impressions, clicks, conversions, revenue) VALUES
(1,'control',   'Subject: How top marketers save 10 hours a week',               2100, 2100, 504,  18,  0.00),
(1,'variant_a', 'Subject: [First Name], here is how to save 10 hours a week',    2100, 2100, 672,  26,  0.00),
(2,'control',   'CTA Button: Get a Demo',                                         800,  800,  NULL, 38,  114000.00),
(2,'variant_a', 'CTA Button: Start Free Trial',                                   800,  800,  NULL, 58,  174000.00),
(3,'control',   'Headline: All-in-One Marketing Platform',                        8400, 8400, 252,  14,  168000.00),
(3,'variant_a', 'Headline: Stop Losing Leads to Competitors',                     8400, 8400, 420,  22,  264000.00),
(4,'control',   'Weekly email sends (7 day cadence)',                             2100, 2100, 441,  42,  0.00),
(4,'variant_a', 'Biweekly email sends (14 day cadence)',                          2100, 2100, 399,  38,  0.00),
(5,'control',   'Monthly pricing shown first',                                    1200, 1200, NULL, 48,  172800.00),
(5,'variant_a', 'Annual pricing shown first with savings badge',                  1200, 1200, NULL, 72,  345600.00),
(6,'control',   'CTA at end of article only',                                     3800, 3800, 228,  12,  0.00),
(6,'variant_a', 'CTA inline after 3rd paragraph + end of article',               3800, 3800, 380,  22,  0.00),
(7,'control',   'Subject: Year end deal - lock in 2023 pricing',                  7400, 7400, 1258, 88,  0.00),
(7,'variant_a', 'Subject: Save 30% before December 31st - expires Friday',        7400, 7400, 1628, 118, 0.00),
(8,'control',   'Manual CPC bidding - max $8.50',                                 4200, 4200, 168,  12,  180000.00),
(8,'variant_a', 'Target CPA bidding - target $65',                                4200, 4200, 210,  22,  330000.00),
(9,'control',   'Subject: The 2024 marketing automation playbook',                2800, 2800, 588,  28,  0.00),
(9,'variant_a', 'Subject: [First Name] your 2024 marketing playbook is here',    2800, 2800, 756,  42,  0.00),
(10,'control',  'Headline: Book a Demo - See How It Works',                       1800, 1800, NULL, 72,  288000.00),
(10,'variant_a','Headline: See How We 4x Lead Volume in 90 Days',                 1800, 1800, NULL, 116, 464000.00),
(11,'control',  'Broad targeting - all US audiences',                             12400,12400, 372,  18,  270000.00),
(11,'variant_a','Interest targeting - Marketing Software + CRM + Email Marketing',12400,12400, 620,  34,  510000.00),
(12,'control',  'Standard blog post - no content upgrade',                        5200, 5200, 208,  14,  0.00),
(12,'variant_a','Blog post with downloadable AI tools checklist offer',           5200, 5200, 416,  38,  0.00);

-- ============================================================
-- WEB PAGES
-- ============================================================
INSERT INTO web_pages (page_url, page_type, page_title, cta_text, cta_destination, published_at, is_active) VALUES
('/',                                    'homepage',     'Marketing Automation Platform | Company Name',           'Get a Free Demo',      '/demo',       '2022-06-01', 1),
('/products/marketing-automation',       'product',      'Marketing Automation Software',                          'Start Free Trial',     '/trial',      '2022-06-01', 1),
('/products/email-automation',           'product',      'Email Marketing Automation',                             'See It in Action',     '/demo',       '2022-07-01', 1),
('/products/crm-integration',            'product',      'CRM Integration',                                        'Connect Your CRM',     '/demo',       '2022-07-01', 1),
('/products/analytics',                  'product',      'Marketing Analytics Dashboard',                          'View Demo',            '/demo',       '2022-08-01', 1),
('/solutions/enterprise',                'landing_page', 'Enterprise Marketing Platform',                          'Book Enterprise Demo', '/demo',       '2022-09-01', 1),
('/solutions/smb',                       'landing_page', 'Marketing Automation for Small Business',                'Start Free',           '/trial',      '2022-09-01', 1),
('/solutions/b2b',                       'landing_page', 'B2B Lead Generation Tools',                              'Get Demo',             '/demo',       '2022-10-01', 1),
('/pricing',                             'landing_page', 'Pricing Plans | Marketing Automation',                   'Get Started',          '/trial',      '2022-06-01', 1),
('/demo',                                'landing_page', 'Book a Demo | See It in 30 Minutes',                     'Book My Demo',         '/demo/confirm','2022-06-01',1),
('/trial',                               'landing_page', 'Start Your Free Trial',                                  'Create Account',       '/trial/signup','2022-06-01',1),
('/compare/hubspot',                     'landing_page', 'vs HubSpot | Which Is Right for You',                    'See the Comparison',   '/demo',       '2022-11-01', 1),
('/blog',                                'blog',         'Marketing Blog | Tips, Guides, and Strategies',          'Subscribe',            '/newsletter', '2022-06-01', 1),
('/blog/what-is-marketing-automation',   'blog',         'What Is Marketing Automation? Complete Guide',           'Get Demo',             '/demo',       '2023-01-15', 1),
('/blog/content-marketing-strategy',     'blog',         'Content Marketing Strategy Guide',                       'Download Template',    '/resources',  '2023-03-15', 1),
('/blog/email-best-practices',           'blog',         'Email Marketing Best Practices',                         'Get Demo',             '/demo',       '2023-05-01', 1),
('/blog/best-marketing-automation-tools','blog',         '10 Best Marketing Automation Tools',                     'Compare Tools',        '/compare',    '2023-02-01', 1),
('/blog/digital-marketing-trends',       'blog',         'Digital Marketing Trends 2024',                          'Subscribe',            '/newsletter', '2024-04-15', 1),
('/blog/ai-marketing-tools',             'blog',         'AI Marketing Tools: What Actually Works',                'Get Demo',             '/demo',       '2024-01-10', 1),
('/about',                               'about',        'About Us | Our Story',                                   'Join Our Team',        '/careers',    '2022-06-01', 1),
('/contact',                             'contact',      'Contact Us',                                             'Send Message',         '/contact',    '2022-06-01', 1),
('/reviews',                             'landing_page', 'Customer Reviews and Case Studies',                      'Read All Reviews',     '/reviews',    '2022-12-01', 1);

-- WEB SESSIONS (monthly aggregated sessions, 2023 + 2024)
INSERT INTO web_sessions (session_id, customer_id, landing_page, referrer_source, referrer_medium, utm_campaign, device_type, browser, session_start, session_end, pages_viewed, converted, conversion_value) VALUES
('agg_001',NULL,'/',                              'google',      'organic',  NULL,                      'desktop','chrome','2023-01-01 00:00:00','2023-01-01 00:03:42',3,0,NULL),
('agg_002',NULL,'/products/marketing-automation', 'google',      'cpc',      'q1-2023-brand',           'desktop','chrome','2023-01-15 00:00:00','2023-01-15 00:06:18',4,1,14000.00),
('agg_003',NULL,'/blog/what-is-marketing-automation','google',   'organic',  NULL,                      'mobile', 'safari','2023-02-01 00:00:00','2023-02-01 00:02:15',2,0,NULL),
('agg_004',NULL,'/pricing',                       'google',      'cpc',      'q1-2023-brand',           'desktop','firefox','2023-02-15 00:00:00','2023-02-15 00:08:44',5,1,18500.00),
('agg_005',NULL,'/demo',                          'linkedin',    'cpc',      'q1-2023-linkedin',        'desktop','chrome','2023-03-01 00:00:00','2023-03-01 00:05:22',3,1,24000.00),
('agg_006',NULL,'/',                              'facebook',    'cpc',      'q2-2023-facebook',        'mobile', 'chrome','2023-04-15 00:00:00','2023-04-15 00:02:48',2,0,NULL),
('agg_007',NULL,'/pricing',                       'google',      'organic',  NULL,                      'desktop','chrome','2023-05-01 00:00:00','2023-05-01 00:07:15',6,1,28000.00),
('agg_008',NULL,'/blog/content-marketing-strategy','google',     'organic',  NULL,                      'desktop','chrome','2023-06-01 00:00:00','2023-06-01 00:04:38',3,0,NULL),
('agg_009',NULL,'/products/marketing-automation', 'google',      'organic',  NULL,                      'desktop','safari','2023-07-01 00:00:00','2023-07-01 00:05:52',4,1,16000.00),
('agg_010',NULL,'/compare/hubspot',               'google',      'cpc',      'q3-2023-competitor',      'desktop','chrome','2023-08-01 00:00:00','2023-08-01 00:09:14',7,1,42000.00),
('agg_011',NULL,'/solutions/enterprise',          'linkedin',    'cpc',      'q3-2023-linkedin',        'desktop','chrome','2023-09-01 00:00:00','2023-09-01 00:06:44',5,1,35000.00),
('agg_012',NULL,'/pricing',                       'google',      'cpc',      'q4-2023-year-end',        'desktop','chrome','2023-10-15 00:00:00','2023-10-15 00:08:22',6,1,48000.00),
('agg_013',NULL,'/',                              'email',       'email',    'q4-2023-holiday',         'desktop','outlook','2023-11-15 00:00:00','2023-11-15 00:04:18',4,1,22000.00),
('agg_014',NULL,'/demo',                          'google',      'cpc',      'q4-2023-year-end',        'desktop','chrome','2023-12-01 00:00:00','2023-12-01 00:07:44',5,1,55000.00),
('agg_015',NULL,'/',                              'direct',      'direct',   NULL,                      'desktop','chrome','2024-01-15 00:00:00','2024-01-15 00:03:28',3,0,NULL),
('agg_016',NULL,'/products/marketing-automation', 'google',      'cpc',      'q1-2024-brand',           'desktop','chrome','2024-02-01 00:00:00','2024-02-01 00:06:52',5,1,52000.00),
('agg_017',NULL,'/blog/ai-marketing-tools',       'google',      'organic',  NULL,                      'mobile', 'safari','2024-02-15 00:00:00','2024-02-15 00:03:14',2,0,NULL),
('agg_018',NULL,'/pricing',                       'google',      'organic',  NULL,                      'desktop','chrome','2024-03-01 00:00:00','2024-03-01 00:09:18',7,1,34000.00),
('agg_019',NULL,'/solutions/enterprise',          'linkedin',    'cpc',      'q1-2024-linkedin',        'desktop','chrome','2024-04-01 00:00:00','2024-04-01 00:07:42',6,1,67000.00),
('agg_020',NULL,'/blog/digital-marketing-trends', 'google',      'organic',  NULL,                      'mobile', 'chrome','2024-04-15 00:00:00','2024-04-15 00:02:44',2,0,NULL),
('agg_021',NULL,'/pricing',                       'facebook',    'cpc',      'q2-2024-facebook',        'desktop','chrome','2024-05-01 00:00:00','2024-05-01 00:08:16',6,1,44000.00),
('agg_022',NULL,'/compare/hubspot',               'google',      'cpc',      'q2-2024-competitor',      'desktop','firefox','2024-06-01 00:00:00','2024-06-01 00:10:42',8,1,58000.00),
('agg_023',NULL,'/products/marketing-automation', 'google',      'organic',  NULL,                      'desktop','chrome','2024-07-01 00:00:00','2024-07-01 00:07:28',5,1,38000.00),
('agg_024',NULL,'/blog/content-marketing-strategy','google',     'organic',  NULL,                      'desktop','safari','2024-08-01 00:00:00','2024-08-01 00:05:44',4,0,NULL),
('agg_025',NULL,'/demo',                          'linkedin',    'cpc',      'q3-2024-linkedin',        'desktop','chrome','2024-09-01 00:00:00','2024-09-01 00:06:18',5,1,46000.00),
('agg_026',NULL,'/pricing',                       'google',      'cpc',      'q4-2024-year-end',        'desktop','chrome','2024-10-15 00:00:00','2024-10-15 00:09:44',7,1,71000.00),
('agg_027',NULL,'/',                              'email',       'email',    'q4-2024-holiday',         'desktop','outlook','2024-11-22 00:00:00','2024-11-22 00:04:52',4,1,31500.00),
('agg_028',NULL,'/solutions/enterprise',          'google',      'organic',  NULL,                      'desktop','chrome','2024-12-01 00:00:00','2024-12-01 00:08:22',6,1,28000.00);

-- WEB VITALS (quarterly, key pages)
INSERT INTO web_vitals (page_url, vital_date, lcp_ms, fid_ms, cls_score, ttfb_ms, mobile_score, desktop_score) VALUES
('/',                                   '2023-01-01',3800,120,0.18,820,58,78),
('/',                                   '2023-04-01',3400,98,0.14,740,64,82),
('/',                                   '2023-07-01',2900,82,0.11,680,70,86),
('/',                                   '2023-10-01',2600,68,0.09,620,74,88),
('/',                                   '2024-01-01',2400,58,0.08,580,78,90),
('/',                                   '2024-04-01',2200,48,0.07,540,82,92),
('/',                                   '2024-07-01',2000,42,0.06,500,86,94),
('/',                                   '2024-10-01',1900,38,0.05,480,88,95),
('/pricing',                            '2023-01-01',4200,140,0.22,920,52,74),
('/pricing',                            '2023-07-01',3400,108,0.14,760,62,80),
('/pricing',                            '2024-01-01',2800,82,0.10,640,72,86),
('/pricing',                            '2024-07-01',2200,58,0.07,540,80,90),
('/pricing',                            '2024-10-01',2000,48,0.06,500,84,92),
('/products/marketing-automation',      '2023-01-01',3600,110,0.16,800,60,80),
('/products/marketing-automation',      '2023-07-01',2900,84,0.11,680,68,84),
('/products/marketing-automation',      '2024-01-01',2400,62,0.08,580,76,88),
('/products/marketing-automation',      '2024-07-01',2000,44,0.06,500,82,92),
('/products/marketing-automation',      '2024-10-01',1850,38,0.05,470,86,94),
('/blog/what-is-marketing-automation',  '2023-01-01',3200,90,0.14,720,64,82),
('/blog/what-is-marketing-automation',  '2023-07-01',2700,70,0.10,620,72,86),
('/blog/what-is-marketing-automation',  '2024-01-01',2300,54,0.07,550,78,90),
('/blog/what-is-marketing-automation',  '2024-10-01',1900,40,0.05,480,86,94);

-- ============================================================
-- INDUSTRY TRENDS
-- ============================================================
INSERT INTO industry_trends (trend_name, category, impact_level, date_identified, our_adoption, notes) VALUES
('AI-Generated Content at Scale',                'AI Tools',        'high',   '2023-01-15', 'adopted',     'Adopted GPT-based content assist tools for blog drafting in Q2 2023. Reduced production time 40%.'),
('ChatGPT for Marketing Workflows',              'AI Tools',        'high',   '2023-02-01', 'adopted',     'Integrated into email copy review, ad headline generation, and customer Q&A.'),
('Predictive Lead Scoring with AI',              'AI Tools',        'high',   '2023-03-15', 'planned',     'Evaluating vendors. Plan to launch in Q1 2024.'),
('Zero-Party Data Collection',                   'Privacy',         'high',   '2023-02-15', 'adopted',     'Added preference center to email. Running interactive content for data collection.'),
('Third-Party Cookie Deprecation',               'Privacy',         'high',   '2023-04-01', 'adopted',     'Shifted to first-party data strategy. Invested in CDP integration.'),
('GA4 Migration from Universal Analytics',       'Search',          'high',   '2023-01-01', 'adopted',     'Migrated all properties to GA4 by May 2023 ahead of July deadline.'),
('Short-Form Video Marketing',                   'Content Format',  'high',   '2023-03-01', 'evaluating',  'Piloting LinkedIn short-form video. Results pending Q4 2023.'),
('Interactive Content - Calculators and Quizzes','Content Format',  'medium', '2023-04-15', 'adopted',     'Launched ROI calculator page. 28% conversion rate on organic traffic.'),
('Dark Social Attribution',                      'Attribution',     'medium', '2023-05-01', 'evaluating',  'Investigating UTM-independent attribution methods.'),
('LinkedIn B2B Thought Leadership',              'Platform Feature','medium', '2023-06-01', 'adopted',     'Launched executive LinkedIn content program. 3x follower growth in 6 months.'),
('Email List Hygiene and Deliverability',        'Email',           'medium', '2023-07-15', 'adopted',     'Implemented quarterly list cleaning. Improved deliverability from 94% to 98%.'),
('Google SGE - Search Generative Experience',    'Search',          'high',   '2023-08-01', 'planned',     'Monitoring impact on organic CTR. Will adjust content strategy when rollout completes.'),
('Personalization at Scale',                     'AI Tools',        'high',   '2023-09-01', 'adopted',     'Using dynamic content blocks in email. 22% lift in click rate.'),
('Revenue Attribution Over Lead Volume',         'Attribution',     'high',   '2023-10-01', 'adopted',     'Shifted KPIs from MQL volume to pipeline contribution. New dashboards in Q4 2023.'),
('Conversational Marketing and AI Chat',         'AI Tools',        'medium', '2023-11-01', 'planned',     'Evaluating AI chat vendors for website. Target Q2 2024 launch.'),
('First-Party Data Ads - Meta and Google',       'Platform Feature','high',   '2024-01-15', 'adopted',     'Launched customer match campaigns on both platforms. 40% better CPL vs cold audiences.'),
('AI Search Overviews Impact on SEO',            'Search',          'high',   '2024-03-01', 'adopted',     'Adapting content to FAQ and schema markup formats. Monitoring click rate closely.'),
('Privacy-First Analytics - Server-Side GTM',    'Privacy',         'medium', '2024-04-01', 'planned',     'Planning server-side GTM migration to improve data accuracy post-cookie.'),
('Generative AI in Email Personalization',       'AI Tools',        'high',   '2024-05-15', 'adopted',     'Running AI-generated personalized email sequences. 18% lift in conversion rate.'),
('LinkedIn Thought Leadership Ads',              'Platform Feature','medium', '2024-07-01', 'adopted',     'Running promoted thought leadership posts. Lower CPL than standard sponsored content.');

-- ALGORITHM UPDATES
INSERT INTO algorithm_updates (platform, update_name, update_date, update_type, impact_description, our_impact_score, action_taken) VALUES
('Google Search','March 2023 Core Update',       '2023-03-15','core_update',   'Broad quality update affecting YMYL and thin content pages.',                  2,  'Audited bottom 20% of blog posts. Consolidated 8 thin posts. Saw 12% traffic lift in 6 weeks.'),
('Google Search','April 2023 Reviews Update',    '2023-04-12','spam_update',   'Targeted product and service review pages with thin or unoriginal content.',   1,  'Not significantly affected. Reviews pages updated with first-party data.'),
('Google Ads','Broad Match Expansion',           '2023-05-01','feature_launch','Broad match keywords now use more signals including landing page content.',     1,  'Expanded broad match usage with strong negative keyword lists.'),
('Meta',      'Ad Relevance Diagnostic Update',  '2023-06-15','policy_change', 'Changed ad quality metrics. Quality Ranking now key performance indicator.',    -1, 'Updated creatives. Improved Quality Ranking from Below Average to Average.'),
('Google Search','August 2023 Core Update',      '2023-08-22','core_update',   'Focused on helpful content. Sites with people-first content benefited.',        3,  'Traffic up 18% in 30 days post-update. Content strategy validated.'),
('Google Search','October 2023 Core Update',     '2023-10-05','core_update',   'Continued helpful content focus. AI-generated thin content targeted.',          2,  'Minimal impact. All content is original and expert-authored.'),
('Google Ads','Performance Max Updates',         '2023-11-01','feature_launch','New asset group reporting and brand safety controls added.',                    1,  'Implemented brand safety exclusions. Improved targeting controls.'),
('LinkedIn',  'Thought Leadership Ad Format',    '2023-12-01','feature_launch','New ad format promoting individual posts from employee profiles.',               3,  'Launched TL ads for CEO content. 42% lower CPL than standard sponsored content.'),
('Google Search','March 2024 Core Update',       '2024-03-05','core_update',   'Largest core update in years. 40% reduction in unhelpful content in SERPs.',    3,  'Traffic up 24% in 45 days. Site quality strategy paying off significantly.'),
('Google Search','AI Overviews Launch',          '2024-05-14','feature_launch','AI-generated search summaries appear above organic results for many queries.',  -2, 'CTR declined 8% on informational queries. Optimizing for featured snippets and schema.'),
('Google Ads','Smart Bidding Enhancements',      '2024-06-01','feature_launch','New target ROAS options and improved conversion value rules.',                   2,  'Implemented value-based bidding for enterprise vs SMB leads.'),
('Meta',      'Advantage+ Campaign Updates',     '2024-07-15','feature_launch','Expanded automation in campaign creation and audience expansion.',               1,  'Testing Advantage+ alongside manual campaigns. Early results positive.'),
('Google Search','August 2024 Core Update',      '2024-08-15','core_update',   'Continued AI overview expansion. User-generated content gaining ranking signals.',1, 'Added customer stories and Q&A sections to key product pages.'),
('LinkedIn',  'Predictive Audiences Launch',     '2024-09-01','feature_launch','AI-predicted audiences based on conversion likelihood.',                         3,  'Running Predictive Audiences test on demo campaign. 28% CPL improvement.'),
('Google Search','November 2024 Core Update',    '2024-11-12','core_update',   'Holiday season update. E-commerce and commercial intent queries reshuffled.',    2,  'Pricing and comparison pages gained positions. Q4 organic revenue up 18%.');

SELECT 'Channel data loaded successfully' AS status;
