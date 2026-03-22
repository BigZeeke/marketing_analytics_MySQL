-- ============================================================
-- MARKETING ANALYTICS PORTFOLIO PROJECT
-- File: 07_triggers.sql
-- Description: 7 triggers covering auto-scoring, audit trails,
--              budget enforcement, and data integrity
-- Run Order: 7 of 10
-- ============================================================

USE marketing_analytics;

-- ============================================================
-- TRIGGER 1: Auto-score new leads on INSERT
-- Assigns a baseline score based on source and deal value
-- ============================================================
DROP TRIGGER IF EXISTS trg_leads_score_on_insert;
DELIMITER $$
CREATE TRIGGER trg_leads_score_on_insert
BEFORE INSERT ON leads
FOR EACH ROW
BEGIN
    DECLARE v_score INT DEFAULT 0;

    -- Score by source
    SET v_score = v_score + CASE NEW.lead_source
        WHEN 'Referral' THEN 40
        WHEN 'Organic'  THEN 30
        WHEN 'Paid'     THEN 20
        WHEN 'Social'   THEN 15
        ELSE                 10
    END;

    -- Score by deal value
    SET v_score = v_score + CASE
        WHEN COALESCE(NEW.deal_value, 0) >= 50000 THEN 50
        WHEN COALESCE(NEW.deal_value, 0) >= 25000 THEN 35
        WHEN COALESCE(NEW.deal_value, 0) >= 10000 THEN 20
        WHEN COALESCE(NEW.deal_value, 0) >  0     THEN 10
        ELSE 0
    END;

    -- Only assign if score not explicitly provided
    IF NEW.score IS NULL THEN
        SET NEW.score = LEAST(v_score, 99);
    END IF;
END $$
DELIMITER ;

-- ============================================================
-- TRIGGER 2: Log campaign status changes to audit table
-- Fires AFTER UPDATE on campaigns when status changes
-- ============================================================
DROP TRIGGER IF EXISTS trg_campaigns_audit_on_update;
DELIMITER $$
CREATE TRIGGER trg_campaigns_audit_on_update
AFTER UPDATE ON campaigns
FOR EACH ROW
BEGIN
    IF OLD.status != NEW.status THEN
        INSERT INTO campaign_audit_log
            (campaign_id, action, performed_by, status, notes, logged_at)
        VALUES (
            NEW.campaign_id,
            CONCAT('STATUS_CHANGE: ', OLD.status, ' -> ', NEW.status),
            COALESCE(NEW.closed_by, 'system'),
            NEW.status,
            CONCAT(
                'Budget: $', FORMAT(NEW.budget, 2),
                ' | Spend: $', FORMAT(NEW.spend, 2),
                ' | Final ROAS: ', COALESCE(NEW.final_roas, 'N/A')
            ),
            NOW()
        );
    END IF;
END $$
DELIMITER ;

-- ============================================================
-- TRIGGER 3: Enforce budget cap — prevent overspend on INSERT
-- Fires BEFORE INSERT on ad_performance
-- ============================================================
DROP TRIGGER IF EXISTS trg_adperf_budget_check;
DELIMITER $$
CREATE TRIGGER trg_adperf_budget_check
BEFORE INSERT ON ad_performance
FOR EACH ROW
BEGIN
    DECLARE v_campaign_id  INT;
    DECLARE v_campaign_budget DECIMAL(10,2);
    DECLARE v_total_spend  DECIMAL(10,2);

    -- Trace ad -> ad_group -> campaign
    SELECT ag.campaign_id
    INTO   v_campaign_id
    FROM   ads a
    JOIN   ad_groups ag ON a.ad_group_id = ag.ad_group_id
    WHERE  a.ad_id = NEW.ad_id;

    SELECT budget INTO v_campaign_budget
    FROM   campaigns WHERE campaign_id = v_campaign_id;

    SELECT COALESCE(SUM(p.spend), 0)
    INTO   v_total_spend
    FROM   ad_performance p
    JOIN   ads a          ON p.ad_id       = a.ad_id
    JOIN   ad_groups ag   ON a.ad_group_id = ag.ad_group_id
    WHERE  ag.campaign_id = v_campaign_id;

    IF (v_total_spend + NEW.spend) > (v_campaign_budget * 1.10) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT =
            'Ad spend would exceed campaign budget by more than 10%. Insert blocked.';
    END IF;
END $$
DELIMITER ;

-- ============================================================
-- TRIGGER 4: Stamp converted_at when lead status -> 'converted'
-- Fires BEFORE UPDATE on leads
-- ============================================================
DROP TRIGGER IF EXISTS trg_leads_stamp_converted;
DELIMITER $$
CREATE TRIGGER trg_leads_stamp_converted
BEFORE UPDATE ON leads
FOR EACH ROW
BEGIN
    -- Set timestamp the first time status becomes 'converted'
    IF NEW.status = 'converted' AND OLD.status != 'converted' THEN
        IF NEW.converted_at IS NULL THEN
            SET NEW.converted_at = NOW();
        END IF;
    END IF;

    -- Prevent re-opening a converted lead to 'new'
    IF OLD.status = 'converted' AND NEW.status = 'new' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot revert a converted lead back to new status.';
    END IF;
END $$
DELIMITER ;

-- ============================================================
-- TRIGGER 5: Sync campaign spend total when order amount changes
-- Fires AFTER UPDATE on orders — keeps spend in sync with revenue
-- NOTE: In a real system this would update a summary table.
--       Here it logs the sync event to the audit log.
-- ============================================================
DROP TRIGGER IF EXISTS trg_orders_log_on_update;
DELIMITER $$
CREATE TRIGGER trg_orders_log_on_update
AFTER UPDATE ON orders
FOR EACH ROW
BEGIN
    IF OLD.amount != NEW.amount AND NEW.campaign_id IS NOT NULL THEN
        INSERT INTO campaign_audit_log
            (campaign_id, action, performed_by, status, notes, logged_at)
        VALUES (
            NEW.campaign_id,
            'ORDER_AMOUNT_UPDATED',
            'system',
            'active',
            CONCAT(
                'Order #', NEW.order_id,
                ' amount changed from $', FORMAT(OLD.amount, 2),
                ' to $', FORMAT(NEW.amount, 2)
            ),
            NOW()
        );
    END IF;
END $$
DELIMITER ;

-- ============================================================
-- TRIGGER 6: Prevent deletion of campaigns that have leads
-- Fires BEFORE DELETE on campaigns
-- ============================================================
DROP TRIGGER IF EXISTS trg_campaigns_no_delete_with_leads;
DELIMITER $$
CREATE TRIGGER trg_campaigns_no_delete_with_leads
BEFORE DELETE ON campaigns
FOR EACH ROW
BEGIN
    DECLARE v_lead_count INT DEFAULT 0;

    SELECT COUNT(*) INTO v_lead_count
    FROM leads WHERE campaign_id = OLD.campaign_id;

    IF v_lead_count > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT =
            'Cannot delete campaign with existing leads. Archive it instead.';
    END IF;
END $$
DELIMITER ;

-- ============================================================
-- TRIGGER 7: Auto-set email campaign status on send date
-- Fires BEFORE UPDATE on email_campaigns
-- ============================================================
DROP TRIGGER IF EXISTS trg_email_campaigns_auto_status;
DELIMITER $$
CREATE TRIGGER trg_email_campaigns_auto_status
BEFORE UPDATE ON email_campaigns
FOR EACH ROW
BEGIN
    -- Auto-advance to 'sent' if send_date has passed and status is 'scheduled'
    IF NEW.status = 'scheduled' AND NEW.send_date <= NOW() THEN
        SET NEW.status = 'sent';
    END IF;

    -- Prevent editing a sent email's subject line
    IF OLD.status = 'sent' AND NEW.subject_line != OLD.subject_line THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot change the subject line of an already-sent email campaign.';
    END IF;
END $$
DELIMITER ;

-- ============================================================
-- TRIGGER VERIFICATION
-- Demonstrate each trigger is working
-- ============================================================

-- Test Trigger 1: Insert a lead without a score → score auto-assigned
INSERT INTO leads
    (campaign_id, email, first_name, last_name, lead_source, status, deal_value)
VALUES
    (22, 'trigger.test@example.com', 'Trigger', 'Test', 'Referral', 'new', 35000.00);

SELECT lead_id, email, lead_source, deal_value, score,
       fn_lead_score_tier(score) AS score_tier
FROM leads
WHERE email = 'trigger.test@example.com';

-- Test Trigger 4: Mark that lead as converted → converted_at auto-stamped
UPDATE leads SET status = 'converted'
WHERE email = 'trigger.test@example.com';

SELECT lead_id, status, score, converted_at
FROM leads
WHERE email = 'trigger.test@example.com';

-- Test Trigger 2: Audit log populated from campaign update
UPDATE campaigns
SET status = 'active', closed_by = 'system'
WHERE campaign_id = 4;   -- currently closed

SELECT * FROM campaign_audit_log ORDER BY logged_at DESC LIMIT 5;

SELECT 'Triggers created and verified successfully' AS status;
