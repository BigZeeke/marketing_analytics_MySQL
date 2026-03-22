# Module 09 — Campaign Optimization

**Estimated time:** 60 minutes
**SQL skills:** A/B lift CTEs, stored procedures, cumulative revenue totals, statistical confidence
**Tables:** `ab_tests`, `ab_variants`, `campaigns`, `leads`

[← Module 08: Trends](08_trends.md) | [Back to Index](README.md) | [Next: Module 10 — Website →](10_website.md)

---

## Engineering Lens — Before You Build Anything in This Module

> 💡 **Engineering Lens** — Profile `ab_variants` before building lift calculations. The most important profiling check is: does every test have exactly one control variant? Run `SELECT test_id, COUNT(*) FROM ab_variants WHERE variant_name = 'control' GROUP BY test_id HAVING COUNT(*) != 1` — any test with zero or multiple control rows will break the lift CTE that isolates the baseline. The `sp_campaign_health_check` procedure was created rather than a view because it takes a `campaign_id` parameter and returns a classification with a recommended action — parameterized, operational logic that runs on demand. The cumulative revenue impact query stayed as an ad-hoc query rather than a view because its value is periodic and strategic, not daily operational. It gets run quarterly in a board presentation, not every morning by an analyst.

---

## What You Will Learn

- How A/B tests are structured and what makes a result statistically valid
- How to calculate conversion rate lift between control and variant
- How to measure the cumulative revenue impact of your testing program
- How to use `sp_campaign_health_check` for proactive optimization
- How to build a testing roadmap from SQL data

---

## 9.1 The A/B Test Tables

```sql
SELECT
    test_id, test_name, test_type, primary_metric,
    winner_variant, confidence_pct, status
FROM ab_tests
ORDER BY start_date;
```

```sql
SELECT
    t.test_name,
    v.variant_name,
    v.sample_size,
    v.conversions,
    ROUND(v.conversions / NULLIF(v.sample_size, 0) * 100, 2) AS conv_rate_pct,
    v.revenue
FROM ab_tests t
JOIN ab_variants v ON t.test_id = v.test_id
ORDER BY t.test_id, v.variant_name;
```

> 📊 **MARKETING NUGGET** — Statistical confidence is the probability that the observed difference between control and variant is not due to random chance. At 95% confidence, there is a 5% chance the result is a fluke. Most marketing teams use 90% as their threshold for "actionable." The tests in this dataset show confidence levels between 88–98% — all above the 90% threshold, meaning every winner in this dataset is statistically sound. In real life, roughly 1 in 3 A/B tests will have no statistically significant winner — which is itself a valid finding.

---

## 9.2 Calculating A/B Lift — The Core CTE

```sql
WITH variant_metrics AS (
    SELECT
        t.test_id,
        t.test_name,
        t.test_type,
        t.winner_variant,
        t.confidence_pct,
        v.variant_name,
        v.sample_size,
        v.conversions,
        v.revenue,
        ROUND(v.conversions / NULLIF(v.sample_size, 0) * 100, 2) AS conv_rate_pct
    FROM ab_tests t
    JOIN ab_variants v ON t.test_id = v.test_id
    WHERE t.status = 'completed'
),
control_baseline AS (
    SELECT test_id, conv_rate_pct AS control_conv_rate, revenue AS control_revenue
    FROM variant_metrics
    WHERE variant_name = 'control'
)
SELECT
    vm.test_name,
    vm.test_type,
    vm.variant_name,
    vm.conv_rate_pct,
    cb.control_conv_rate,
    ROUND(
        (vm.conv_rate_pct - cb.control_conv_rate)
        / NULLIF(cb.control_conv_rate, 0) * 100, 1
    )                                           AS lift_pct,
    vm.confidence_pct,
    CASE WHEN vm.variant_name = vm.winner_variant THEN 'Winner' ELSE 'Loser' END AS result
FROM variant_metrics vm
JOIN control_baseline cb ON vm.test_id = cb.test_id
ORDER BY vm.test_id, vm.variant_name;
```

> 💡 **TIP & TRICK** — The `control_baseline` CTE isolates the control row for each test so you can compare every variant against it. Without the CTE, you would need a self-join on `ab_variants` — messy and hard to read. The two-CTE pattern (one to gather all variants, one to isolate the baseline) is the cleanest way to structure A/B analysis in SQL.

---

## 9.3 Cumulative Revenue Impact of Your Testing Program

Every winning test compounds. This query shows the running total of revenue uplift your testing program has generated:

```sql
WITH test_lift AS (
    SELECT
        t.test_id,
        t.test_name,
        t.start_date,
        MAX(CASE WHEN v.variant_name = 'control'      THEN v.revenue END) AS control_rev,
        MAX(CASE WHEN v.variant_name != 'control'
                  AND v.variant_name = t.winner_variant THEN v.revenue END) AS winner_rev
    FROM ab_tests t
    JOIN ab_variants v ON t.test_id = v.test_id
    WHERE t.status = 'completed'
      AND t.winner_variant != 'control'
    GROUP BY t.test_id, t.test_name, t.start_date
)
SELECT
    test_name,
    start_date,
    control_rev,
    winner_rev,
    winner_rev - control_rev                    AS revenue_lift,
    SUM(winner_rev - control_rev) OVER (
        ORDER BY start_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    )                                           AS cumulative_lift
FROM test_lift
ORDER BY start_date;
```

> 🎯 **CMO QUESTION** — *"What has our testing program actually been worth?"* The final row's `cumulative_lift` is your answer. This is the total revenue delta between your tested winners and what you would have earned running only the control variants across your entire testing history. This number justifies the testing infrastructure investment — and typically surprises executives who underestimate how much compounded improvement testing drives.

---

## Test Yourself — Module 09

**Question 1:** Which A/B test achieved the highest conversion rate lift? What was being tested?

**Question 2:** Are there any tests where the control outperformed the variant? What should you do in those cases?

**Question 3:** What is the average confidence level across all completed tests? Is the testing program statistically rigorous?

**Question 4 (Challenge):** Write a query that calculates the estimated annualized revenue impact if the winner from each completed test were permanently implemented at the variant's conversion rate, applied to the original list/sample size.

---

### Answers

**Answer 1:**
```sql
WITH baseline AS (
    SELECT test_id, conversions / NULLIF(sample_size, 0) * 100 AS ctrl_rate
    FROM ab_variants WHERE variant_name = 'control'
)
SELECT
    t.test_name, t.test_type, v.variant_name,
    ROUND(v.conversions / NULLIF(v.sample_size, 0) * 100, 2) AS variant_rate,
    ROUND(b.ctrl_rate, 2)                                     AS control_rate,
    ROUND((v.conversions / NULLIF(v.sample_size, 0) - b.ctrl_rate / 100)
        / NULLIF(b.ctrl_rate / 100, 0) * 100, 1)             AS lift_pct
FROM ab_tests t
JOIN ab_variants v ON t.test_id = v.test_id
JOIN baseline b    ON t.test_id = b.test_id
WHERE t.status = 'completed' AND v.variant_name != 'control'
ORDER BY lift_pct DESC
LIMIT 3;
```

**Answer 2:**
```sql
SELECT t.test_name, t.winner_variant
FROM ab_tests t
WHERE t.winner_variant = 'control'
  AND t.status = 'completed';
```
When the control wins, you keep the current approach. The insight is that the hypothesis was wrong — document why and use that learning to inform future test hypotheses. Not all tests produce winners, and that is correct.

**Answer 3:**
```sql
SELECT ROUND(AVG(confidence_pct), 1) AS avg_confidence
FROM ab_tests
WHERE status = 'completed';
```

**Answer 4 (Challenge):**
```sql
WITH winner_rates AS (
    SELECT
        t.test_id, t.test_name, t.start_date,
        v.sample_size,
        v.revenue AS winner_revenue,
        ROUND(v.revenue / NULLIF(v.conversions, 0), 2) AS rev_per_conversion,
        ROUND(v.conversions / NULLIF(v.sample_size, 0) * 100, 2) AS winner_conv_rate
    FROM ab_tests t
    JOIN ab_variants v ON t.test_id = v.test_id
    WHERE t.status = 'completed'
      AND v.variant_name = t.winner_variant
      AND t.winner_variant != 'control'
)
SELECT
    test_name,
    sample_size,
    winner_conv_rate,
    rev_per_conversion,
    ROUND(sample_size * winner_conv_rate / 100 * rev_per_conversion, 2)     AS estimated_period_revenue,
    ROUND(sample_size * winner_conv_rate / 100 * rev_per_conversion * 12, 2) AS estimated_annual_revenue
FROM winner_rates
ORDER BY estimated_annual_revenue DESC;
```

---

[← Module 08: Trends](08_trends.md) | [Back to Index](README.md) | [Next: Module 10 — Website →](10_website.md)
