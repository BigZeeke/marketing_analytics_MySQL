-- ============================================================
-- MARKETING ANALYTICS PORTFOLIO PROJECT
-- File: 05_stored_procedures.sql
-- Description: 8 production-grade stored procedures covering
--              campaign management, lead processing, and
--              marketing analytics reporting
-- Run Order: 5 of 10
-- ============================================================

USE marketing_analytics;

-- ============================================================
-- PROCEDURE 1: Get Campaign Performance by Channel + Date Range
-- Demonstrates: IN parameters, joins, dynamic filtering
-- ============================================================
DROP PROCEDURE IF EXISTS sp_campaign_performance;
DELIMITER $$
CREATE PROCEDURE sp_campaign_performance(
    IN p_channel    VARCHAR(50),
    IN p_start_date DATE,
    IN p_end_date   DATE
)
BEGIN
    SELECT
        c.campaign_name,
        c.channel,
        c.campaign_type,
        c.spend,
        COUNT(l.lead_id)                                AS total_leads,
        SUM(CASE WHEN l.status='converted' THEN 1 ELSE 0 END) AS converted,
        ROUND(SUM(CASE WHEN l.status='converted' THEN 1 ELSE 0 END)
            / NULLIF(COUNT(l.lead_id),0)*100,2)         AS conv_rate_pct,
        ROUND(c.spend
            / NULLIF(COUNT(l.lead_id),0),2)             AS cost_per_lead,
        COALESCE(SUM(l.deal_value),0)                   AS pipeline,
        ROUND(COALESCE(SUM(l.deal_value),0)
            / NULLIF(c.spend,0),2)                      AS roas
    FROM campaigns c
    LEFT JOIN leads l ON c.campaign_id = l.campaign_id
    WHERE (p_channel IS NULL OR c.channel = p_channel)
      AND c.start_date BETWEEN p_start_date AND p_end_date
    GROUP BY c.campaign_id, c.campaign_name, c.channel,
             c.campaign_type, c.spend
    ORDER BY roas DESC;
END $$
DELIMITER ;

-- EXAMPLE CALL:
-- CALL sp_campaign_performance('Paid', '2024-01-01', '2024-12-31');
-- CALL sp_campaign_performance(NULL,   '2023-01-01', '2023-12-31');

-- ============================================================
-- PROCEDURE 2: Get Campaign ROI with OUT Parameters
-- Demonstrates: OUT parameters, GET DIAGNOSTICS
-- ============================================================
DROP PROCEDURE IF EXISTS sp_campaign_roi;
DELIMITER $$
CREATE PROCEDURE sp_campaign_roi(
    IN  p_campaign_id   INT,
    OUT p_total_spend    DECIMAL(10,2),
    OUT p_total_pipeline DECIMAL(10,2),
    OUT p_roas           DECIMAL(10,2),
    OUT p_lead_count     INT,
    OUT p_conv_count     INT
)
BEGIN
    SELECT
        c.spend,
        COUNT(l.lead_id),
        SUM(CASE WHEN l.status='converted' THEN 1 ELSE 0 END),
        COALESCE(SUM(l.deal_value), 0)
    INTO p_total_spend, p_lead_count, p_conv_count, p_total_pipeline
    FROM campaigns c
    LEFT JOIN leads l ON c.campaign_id = l.campaign_id
    WHERE c.campaign_id = p_campaign_id
    GROUP BY c.spend;

    SET p_roas = ROUND(p_total_pipeline / NULLIF(p_total_spend, 0), 2);
END $$
DELIMITER ;

-- EXAMPLE CALL:
-- CALL sp_campaign_roi(22, @spend, @pipeline, @roas, @leads, @convs);
-- SELECT @spend, @pipeline, @roas, @leads, @convs;

-- ============================================================
-- PROCEDURE 3: Lead Quality Summary with Variables
-- Demonstrates: DECLARE variables, multi-step calculation
-- ============================================================
DROP PROCEDURE IF EXISTS sp_lead_quality_summary;
DELIMITER $$
CREATE PROCEDURE sp_lead_quality_summary(
    IN p_campaign_id INT
)
BEGIN
    DECLARE v_total_leads     INT           DEFAULT 0;
    DECLARE v_qualified_leads INT           DEFAULT 0;
    DECLARE v_converted_leads INT           DEFAULT 0;
    DECLARE v_total_spend     DECIMAL(10,2) DEFAULT 0;
    DECLARE v_qual_rate       DECIMAL(5,2)  DEFAULT 0;
    DECLARE v_conv_rate       DECIMAL(5,2)  DEFAULT 0;
    DECLARE v_cpl             DECIMAL(10,2) DEFAULT 0;

    SELECT COUNT(*),
           SUM(CASE WHEN status IN ('qualified','converted') THEN 1 ELSE 0 END),
           SUM(CASE WHEN status = 'converted' THEN 1 ELSE 0 END)
    INTO v_total_leads, v_qualified_leads, v_converted_leads
    FROM leads
    WHERE campaign_id = p_campaign_id;

    SELECT spend INTO v_total_spend
    FROM campaigns WHERE campaign_id = p_campaign_id;

    SET v_qual_rate = ROUND(v_qualified_leads / NULLIF(v_total_leads,0)*100, 2);
    SET v_conv_rate = ROUND(v_converted_leads / NULLIF(v_total_leads,0)*100, 2);
    SET v_cpl       = ROUND(v_total_spend     / NULLIF(v_converted_leads,0), 2);

    SELECT
        v_total_leads     AS total_leads,
        v_qualified_leads AS qualified_leads,
        v_converted_leads AS converted_leads,
        v_qual_rate       AS qualification_rate_pct,
        v_conv_rate       AS conversion_rate_pct,
        v_total_spend     AS total_spend,
        v_cpl             AS cost_per_converted_lead;
END $$
DELIMITER ;

-- EXAMPLE CALL: CALL sp_lead_quality_summary(22);

-- ============================================================
-- PROCEDURE 4: Campaign Health Check with IF/ELSE
-- Demonstrates: IF/ELSEIF/ELSE logic, business rule classification
-- ============================================================
DROP PROCEDURE IF EXISTS sp_campaign_health_check;
DELIMITER $$
CREATE PROCEDURE sp_campaign_health_check(
    IN p_campaign_id INT
)
BEGIN
    DECLARE v_roas        DECIMAL(10,2) DEFAULT 0;
    DECLARE v_conv_rate   DECIMAL(5,2)  DEFAULT 0;
    DECLARE v_pacing_pct  DECIMAL(5,2)  DEFAULT 0;
    DECLARE v_health      VARCHAR(20);
    DECLARE v_action      VARCHAR(300);

    SELECT
        ROUND(COALESCE(SUM(l.deal_value),0) / NULLIF(c.spend,0), 2),
        ROUND(SUM(CASE WHEN l.status='converted' THEN 1 ELSE 0 END)
            / NULLIF(COUNT(l.lead_id),0)*100, 2),
        ROUND(c.spend / NULLIF(c.budget,0)*100, 2)
    INTO v_roas, v_conv_rate, v_pacing_pct
    FROM campaigns c
    LEFT JOIN leads l ON c.campaign_id = l.campaign_id
    WHERE c.campaign_id = p_campaign_id
    GROUP BY c.spend, c.budget;

    IF v_roas >= 4.0 AND v_conv_rate >= 10.0 THEN
        SET v_health = 'Healthy';
        SET v_action = 'Increase budget 20% - campaign is above target ROAS and conversion rate';
    ELSEIF v_roas >= 2.0 AND v_conv_rate >= 5.0 THEN
        SET v_health = 'On Track';
        SET v_action = 'Monitor weekly - metrics within acceptable range';
    ELSEIF v_roas >= 1.0 THEN
        SET v_health = 'At Risk';
        SET v_action = 'Review targeting and creative - ROAS below 2.0 threshold';
    ELSE
        SET v_health = 'Critical';
        SET v_action = 'Pause campaign immediately - negative ROI';
    END IF;

    SELECT
        v_roas           AS roas,
        v_conv_rate      AS conversion_rate_pct,
        v_pacing_pct     AS budget_pacing_pct,
        v_health         AS health_status,
        v_action         AS recommended_action;
END $$
DELIMITER ;

-- EXAMPLE CALL: CALL sp_campaign_health_check(22);

-- ============================================================
-- PROCEDURE 5: Load Lead with Error Handling + Audit Log
-- Demonstrates: EXIT HANDLER, ROLLBACK, GET DIAGNOSTICS,
--               transaction management, SIGNAL SQLSTATE
-- ============================================================
DROP PROCEDURE IF EXISTS sp_load_campaign_lead;
DELIMITER $$
CREATE PROCEDURE sp_load_campaign_lead(
    IN p_campaign_id  INT,
    IN p_email        VARCHAR(255),
    IN p_first_name   VARCHAR(100),
    IN p_last_name    VARCHAR(100),
    IN p_lead_source  VARCHAR(100),
    IN p_deal_value   DECIMAL(10,2)
)
BEGIN
    DECLARE v_error_code INT          DEFAULT 0;
    DECLARE v_error_msg  VARCHAR(500) DEFAULT '';
    DECLARE v_camp_exists INT         DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            v_error_code = MYSQL_ERRNO,
            v_error_msg  = MESSAGE_TEXT;
        ROLLBACK;
        INSERT INTO pipeline_error_log
            (procedure_name, error_code, error_message, campaign_id, failed_at)
        VALUES
            ('sp_load_campaign_lead', v_error_code, v_error_msg,
             p_campaign_id, NOW());
        SELECT 'FAILED' AS status, v_error_code AS code, v_error_msg AS message;
    END;

    -- Validate campaign exists
    SELECT COUNT(*) INTO v_camp_exists
    FROM campaigns WHERE campaign_id = p_campaign_id;

    IF v_camp_exists = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Campaign ID does not exist';
    END IF;

    START TRANSACTION;
        INSERT INTO leads
            (campaign_id, email, first_name, last_name,
             lead_source, status, deal_value, created_at)
        VALUES
            (p_campaign_id, p_email, p_first_name, p_last_name,
             p_lead_source, 'new', p_deal_value, NOW());
    COMMIT;

    SELECT 'SUCCESS' AS status, LAST_INSERT_ID() AS new_lead_id;
END $$
DELIMITER ;

-- EXAMPLE CALL:
-- CALL sp_load_campaign_lead(22,'newlead@test.com','John','Doe','Paid',15000.00);

-- ============================================================
-- PROCEDURE 6: Apply Lead Scores Using Cursor
-- Demonstrates: CURSOR, LOOP, FETCH, CONTINUE HANDLER,
--               row-by-row processing
-- ============================================================
DROP PROCEDURE IF EXISTS sp_apply_lead_scores;
DELIMITER $$
CREATE PROCEDURE sp_apply_lead_scores()
BEGIN
    DECLARE v_done          INT           DEFAULT 0;
    DECLARE v_lead_id       INT;
    DECLARE v_source        VARCHAR(100);
    DECLARE v_deal_value    DECIMAL(10,2);
    DECLARE v_days_old      INT;
    DECLARE v_score         INT           DEFAULT 0;
    DECLARE v_scored_count  INT           DEFAULT 0;

    DECLARE lead_cursor CURSOR FOR
        SELECT
            lead_id,
            lead_source,
            COALESCE(deal_value, 0),
            DATEDIFF(NOW(), created_at)
        FROM leads
        WHERE score IS NULL
          AND status != 'stale';

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = 1;

    OPEN lead_cursor;

    score_loop: LOOP
        FETCH lead_cursor INTO v_lead_id, v_source, v_deal_value, v_days_old;
        IF v_done = 1 THEN LEAVE score_loop; END IF;

        SET v_score = 0;

        -- Score by lead source
        IF      v_source = 'Referral' THEN SET v_score = v_score + 40;
        ELSEIF  v_source = 'Organic'  THEN SET v_score = v_score + 30;
        ELSEIF  v_source = 'Paid'     THEN SET v_score = v_score + 20;
        ELSEIF  v_source = 'Social'   THEN SET v_score = v_score + 15;
        ELSE                               SET v_score = v_score + 10;
        END IF;

        -- Score by deal value
        IF      v_deal_value >= 50000 THEN SET v_score = v_score + 50;
        ELSEIF  v_deal_value >= 25000 THEN SET v_score = v_score + 35;
        ELSEIF  v_deal_value >= 10000 THEN SET v_score = v_score + 20;
        ELSEIF  v_deal_value > 0      THEN SET v_score = v_score + 10;
        END IF;

        -- Penalize stale leads
        IF v_days_old > 60  THEN SET v_score = v_score - 30;
        ELSEIF v_days_old > 30 THEN SET v_score = v_score - 15;
        END IF;

        UPDATE leads SET score = GREATEST(v_score, 0)
        WHERE lead_id = v_lead_id;

        SET v_scored_count = v_scored_count + 1;
    END LOOP;

    CLOSE lead_cursor;
    SELECT v_scored_count AS leads_scored;
END $$
DELIMITER ;

-- EXAMPLE CALL: CALL sp_apply_lead_scores();

-- ============================================================
-- PROCEDURE 7: Process Campaign Close (Full Production Pattern)
-- Demonstrates: All patterns combined - params, vars, IF/ELSE,
--               error handling, transactions, audit logging
-- ============================================================
DROP PROCEDURE IF EXISTS sp_process_campaign_close;
DELIMITER $$
CREATE PROCEDURE sp_process_campaign_close(
    IN  p_campaign_id    INT,
    IN  p_closed_by      VARCHAR(100),
    OUT p_result_status  VARCHAR(50),
    OUT p_result_message VARCHAR(500)
)
BEGIN
    DECLARE v_exists       TINYINT       DEFAULT 0;
    DECLARE v_curr_status  VARCHAR(50)   DEFAULT '';
    DECLARE v_spend        DECIMAL(10,2) DEFAULT 0;
    DECLARE v_leads        INT           DEFAULT 0;
    DECLARE v_convs        INT           DEFAULT 0;
    DECLARE v_roas         DECIMAL(10,2) DEFAULT 0;
    DECLARE v_pipeline     DECIMAL(10,2) DEFAULT 0;
    DECLARE v_error_code   INT           DEFAULT 0;
    DECLARE v_error_msg    VARCHAR(500)  DEFAULT '';

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            v_error_code = MYSQL_ERRNO,
            v_error_msg  = MESSAGE_TEXT;
        ROLLBACK;
        INSERT INTO campaign_audit_log
            (campaign_id, action, performed_by, status, notes, logged_at)
        VALUES
            (p_campaign_id, 'CLOSE_ATTEMPT', p_closed_by, 'FAILED',
             CONCAT('Error ', v_error_code, ': ', v_error_msg), NOW());
        SET p_result_status  = 'FAILED';
        SET p_result_message = CONCAT('Error ', v_error_code, ': ', v_error_msg);
    END;

    -- Validate
    SELECT COUNT(*), status INTO v_exists, v_curr_status
    FROM campaigns WHERE campaign_id = p_campaign_id;

    IF v_exists = 0 THEN
        SET p_result_status  = 'INVALID';
        SET p_result_message = 'Campaign ID does not exist';
        LEAVE sp_process_campaign_close;
    END IF;

    IF v_curr_status = 'closed' THEN
        SET p_result_status  = 'SKIPPED';
        SET p_result_message = 'Campaign is already closed';
        LEAVE sp_process_campaign_close;
    END IF;

    -- Gather metrics
    SELECT spend, COUNT(l.lead_id),
           SUM(CASE WHEN l.status='converted' THEN 1 ELSE 0 END),
           COALESCE(SUM(l.deal_value), 0)
    INTO v_spend, v_leads, v_convs, v_pipeline
    FROM campaigns c
    LEFT JOIN leads l ON c.campaign_id = l.campaign_id
    WHERE c.campaign_id = p_campaign_id
    GROUP BY c.spend;

    SET v_roas = ROUND(v_pipeline / NULLIF(v_spend, 0), 2);

    -- Execute close
    START TRANSACTION;
        UPDATE campaigns
        SET status     = 'closed',
            closed_at  = NOW(),
            closed_by  = p_closed_by,
            final_spend= v_spend,
            final_leads= v_leads,
            final_roas = v_roas
        WHERE campaign_id = p_campaign_id;

        UPDATE leads SET status = 'stale'
        WHERE campaign_id = p_campaign_id AND status = 'new';

        INSERT INTO campaign_audit_log
            (campaign_id, action, performed_by, status, notes, logged_at)
        VALUES
            (p_campaign_id, 'CAMPAIGN_CLOSED', p_closed_by, 'SUCCESS',
             CONCAT('ROAS: ', v_roas, ' | Leads: ', v_leads,
                    ' | Converted: ', v_convs), NOW());
    COMMIT;

    SET p_result_status  = 'SUCCESS';
    SET p_result_message = CONCAT('Campaign closed. ROAS: ', v_roas,
                                  ' | Leads: ', v_leads,
                                  ' | Converted: ', v_convs);

    SELECT p_result_status AS status, p_result_message AS message,
           v_spend AS final_spend, v_leads AS final_leads,
           v_convs AS converted_leads, v_roas AS final_roas;
END $$
DELIMITER ;

-- EXAMPLE CALL:
-- CALL sp_process_campaign_close(1, 'steve.lopez', @status, @msg);
-- SELECT @status, @msg;

-- ============================================================
-- PROCEDURE 8: YoY Channel Performance Report
-- Demonstrates: complex grouping, conditional aggregation,
--               reporting procedure pattern
-- ============================================================
DROP PROCEDURE IF EXISTS sp_yoy_channel_report;
DELIMITER $$
CREATE PROCEDURE sp_yoy_channel_report(
    IN p_channel VARCHAR(50)
)
BEGIN
    SELECT
        channel,
        campaign_year,
        total_campaigns,
        total_spend,
        total_leads,
        total_conversions,
        conversion_rate_pct,
        cost_per_lead,
        total_pipeline,
        roas
    FROM vw_channel_yoy
    WHERE (p_channel IS NULL OR channel = p_channel)
    ORDER BY channel, campaign_year;
END $$
DELIMITER ;

-- EXAMPLE CALL:
-- CALL sp_yoy_channel_report('Email');
-- CALL sp_yoy_channel_report(NULL);  -- all channels

SELECT 'Stored procedures created successfully' AS status;
