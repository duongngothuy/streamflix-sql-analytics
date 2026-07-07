-- ============================================================
-- StreamFlix — Subscription & Marketing Analytics
-- Four SQL analyses answering: where should we spend to grow,
-- and why are customers leaving?
-- Database: MySQL  |  Run after 01_schema.sql has loaded the data
-- ============================================================


-- ============================================================
-- ANALYSIS A: Monthly Recurring Revenue (MRR) + Month-over-Month Growth
-- Question: How is recurring revenue trending over time?
-- Skills: chained CTEs, window function (LAG), date formatting
-- Finding: MRR grew from ~$1.7K to ~$56K over 36 months. The growth
--   RATE decelerates over time (from +116% to ~+3%), but that reflects
--   growth off a larger base (law of large numbers) — not a decline.
--   Revenue rises every single month.
-- ============================================================
WITH monthly_mrr AS (
    SELECT DATE_FORMAT(payment_date, '%Y-%m') AS per_month,
           SUM(amount) AS revenue_per_month
    FROM payments
    GROUP BY per_month
),
mrr_with_lag AS (
    SELECT per_month,
           revenue_per_month,
           LAG(revenue_per_month) OVER (ORDER BY per_month) AS prev_month_revenue
    FROM monthly_mrr
)
SELECT per_month,
       revenue_per_month,
       prev_month_revenue,
       ROUND( (revenue_per_month - prev_month_revenue) / prev_month_revenue * 100, 1) AS mom_growth_pct
FROM mrr_with_lag
ORDER BY per_month;


-- ============================================================
-- ANALYSIS B: Cohort Retention
-- Question: Grouped by signup month, what % of each cohort is still
--   active 1, 3, and 6 months later?
-- Skills: CTEs, date math (TIMESTAMPDIFF), CASE, conditional aggregation
-- Finding: Mature cohorts retain ~72-77% at 6 months (i.e. ~25% early
--   churn) — far healthier than the blended "47% of all users canceled"
--   headline, which unfairly mixes 3-year-old accounts with brand-new
--   signups. NOTE: the newest cohorts (mid-2025 on) show artificial 0%
--   at later milestones because they haven't had enough time to reach
--   them yet (immature cohorts / ragged edge) — exclude when comparing.
-- ============================================================
WITH cohort_data AS (
    SELECT
        user_id,
        DATE_FORMAT(start_date, '%Y-%m') AS cohort_month,
        CASE
            WHEN end_date IS NULL
                THEN TIMESTAMPDIFF(MONTH, start_date, '2025-12-31')  -- active: measure to data end
            ELSE TIMESTAMPDIFF(MONTH, start_date, end_date)          -- churned: measure to cancel date
        END AS tenure_months
    FROM subscriptions
)
SELECT
    cohort_month,
    COUNT(*) AS cohort_size,
    ROUND(SUM(CASE WHEN tenure_months >= 1 THEN 1 ELSE 0 END) / COUNT(*) * 100, 1) AS month_1_pct,
    ROUND(SUM(CASE WHEN tenure_months >= 3 THEN 1 ELSE 0 END) / COUNT(*) * 100, 1) AS month_3_pct,
    ROUND(SUM(CASE WHEN tenure_months >= 6 THEN 1 ELSE 0 END) / COUNT(*) * 100, 1) AS month_6_pct
FROM cohort_data
GROUP BY cohort_month
ORDER BY cohort_month;


-- ============================================================
-- ANALYSIS C: Channel CAC vs. Churn (the headline analysis)
-- Question: Which acquisition channels deliver low-churn customers
--   at a sustainable cost?
-- Skills: multiple CTEs, multi-table joins, conditional aggregation
-- Finding: CAC and churn move together — the more expensive a channel,
--   the worse it retains. Display ($68 CAC, 64% churn) and Paid Social
--   ($55, 61%) are worst on both axes; Referral ($9, 31%) and Organic
--   ($4, 37%) are cheapest AND stickiest. ~2/3 of budget goes to the
--   two worst channels.
-- ============================================================
WITH spend_per_channel AS (
    SELECT channel,
           SUM(spend) AS total_spend
    FROM marketing_spend
    GROUP BY channel
),
channel_stats AS (
    SELECT u.acquisition_channel AS channel,
           COUNT(*) AS users_acquired,
           ROUND(SUM(CASE WHEN s.status = 'canceled' THEN 1 ELSE 0 END) / COUNT(*) * 100, 1) AS churn_rate_pct
    FROM users u
    JOIN subscriptions s ON u.user_id = s.user_id
    GROUP BY u.acquisition_channel
)
SELECT c.channel,
       sp.total_spend,
       c.users_acquired,
       ROUND(sp.total_spend / c.users_acquired, 2) AS cac,
       c.churn_rate_pct
FROM channel_stats c
JOIN spend_per_channel sp ON c.channel = sp.channel
ORDER BY cac DESC;


-- ============================================================
-- ANALYSIS D: Churn Drivers — Engagement Collapse Before Churn
-- Question: Do customers disengage before they cancel?
-- Skills: window function (ROW_NUMBER with PARTITION BY), CASE, AVG
-- ============================================================

-- D1: Baseline check — lifetime average engagement, active vs canceled
-- Finding: churned users are less engaged overall (18.8 hrs vs 23.1),
--   but averaging over the whole lifetime understates the real signal.
SELECT s.status,
       ROUND(AVG(e.hours_watched), 1) AS avg_hours,
       ROUND(AVG(e.days_active), 1) AS avg_days_active
FROM subscriptions s
JOIN engagement e ON s.user_id = e.user_id
GROUP BY s.status;

-- D2: The sharper cut — engagement in the FINAL 2 months before churn
--   vs earlier months (per churned user, using ROW_NUMBER to find each
--   user's last months relative to their own cancel date).
-- Finding: churned users watched just 9.5 hrs/month in their final two
--   months vs 21.6 earlier — a 50%+ collapse. Engagement drop is an
--   actionable early-warning signal for churn.
WITH churned_engagement AS (
    SELECT e.user_id,
           e.hours_watched,
           ROW_NUMBER() OVER (PARTITION BY e.user_id ORDER BY e.activity_month DESC) AS months_from_end
    FROM engagement e
    JOIN subscriptions s ON e.user_id = s.user_id
    WHERE s.status = 'canceled'
)
SELECT
    CASE WHEN months_from_end <= 2 THEN 'Final 2 months'
         ELSE 'Earlier months' END AS period,
    ROUND(AVG(hours_watched), 1) AS avg_hours
FROM churned_engagement
GROUP BY CASE WHEN months_from_end <= 2 THEN 'Final 2 months'
              ELSE 'Earlier months' END;
