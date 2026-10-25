-- SaaS Analytics SQL Portfolio
-- Business-focused analysis of revenue, customers,
-- subscriptions, retention, collection, and acquisition.

-- =========================================================
-- Analysis #1 — Monthly Revenue Performance
-- =========================================================

SELECT
    DATE_FORMAT(invoice_date, '%Y-%m') AS revenue_month,
    SUM(amount_due) AS monthly_revenue
FROM invoices
GROUP BY DATE_FORMAT(invoice_date, '%Y-%m')
ORDER BY revenue_month;


-- =========================================================
-- Analysis #2 — Month-over-Month Revenue Growth
-- =========================================================

WITH monthly_revenue AS (
    SELECT
        DATE_FORMAT(invoice_date, '%Y-%m') AS revenue_month,
        SUM(amount_due) AS monthly_revenue
    FROM invoices
    GROUP BY DATE_FORMAT(invoice_date, '%Y-%m')
)

SELECT
    revenue_month,
    monthly_revenue,
    LAG(monthly_revenue) OVER (
        ORDER BY revenue_month
    ) AS previous_month_revenue,
    ROUND(
        (
            monthly_revenue -
            LAG(monthly_revenue) OVER (
                ORDER BY revenue_month
            )
        )
        / LAG(monthly_revenue) OVER (
            ORDER BY revenue_month
        ) * 100,
        2
    ) AS mom_growth_percentage
FROM monthly_revenue
ORDER BY revenue_month;


-- =========================================================
-- Analysis #3 — Customer / Subscription Performance
-- =========================================================

WITH customer_mrr AS (
    SELECT
        a.account_id,
        a.segment,
        SUM(s.mrr) AS customer_mrr
    FROM accounts a
    JOIN subscriptions s
        ON a.account_id = s.account_id
    GROUP BY
        a.account_id,
        a.segment
)

SELECT
    segment,
    COUNT(account_id) AS customers,
    SUM(customer_mrr) AS total_mrr,
    ROUND(AVG(customer_mrr), 2) AS avg_mrr_per_customer
FROM customer_mrr
GROUP BY segment
ORDER BY total_mrr DESC;


-- =========================================================
-- Analysis #4 — Plan Adoption Rate
-- =========================================================

WITH plan_adoption AS (
    SELECT
        p.plan_name,
        COUNT(DISTINCT s.account_id) AS customers
    FROM subscriptions s
    JOIN plans p
        ON s.plan_id = p.plan_id
    GROUP BY p.plan_name
),

total_customers AS (
    SELECT
        plan_name,
        customers,
        SUM(customers) OVER () AS total_customers
    FROM plan_adoption
)

SELECT
    plan_name,
    customers,
    ROUND(
        (customers / total_customers) * 100,
        2
    ) AS percentage_of_customers
FROM total_customers
ORDER BY percentage_of_customers DESC;


-- =========================================================
-- Analysis #5 — Customer Retention by Segment
-- =========================================================

SELECT
    x.segment,
    x.total_customers,
    x.active_customers,
    ROUND(
        (x.active_customers / x.total_customers) * 100,
        2
    ) AS active_percentage,
    ROUND(
        ((x.total_customers - x.active_customers)
        / x.total_customers) * 100,
        2
    ) AS non_active_percentage
FROM (
    SELECT
        a.segment,
        COUNT(DISTINCT a.account_id) AS total_customers,
        COUNT(
            DISTINCT CASE
                WHEN s.status = 'active'
                    THEN a.account_id
            END
        ) AS active_customers
    FROM accounts a
    JOIN subscriptions s
        ON s.account_id = a.account_id
    GROUP BY a.segment
) AS x;


-- =========================================================
-- Analysis #6 — Subscription Cancellation Rate
-- =========================================================

SELECT
    x.segment,
    x.total_subscriptions,
    x.cancelled_subscriptions,
    ROUND(
        (x.cancelled_subscriptions / x.total_subscriptions) * 100,
        2
    ) AS cancellation_percentage
FROM (
    SELECT
        a.segment,
        COUNT(s.subscription_id) AS total_subscriptions,
        COUNT(
            CASE
                WHEN s.status = 'cancelled'
                    THEN s.subscription_id
            END
        ) AS cancelled_subscriptions
    FROM accounts a
    JOIN subscriptions s
        ON s.account_id = a.account_id
    GROUP BY a.segment
) AS x;


-- =========================================================
-- Analysis #7 — Customer Subscription Duration
-- =========================================================

WITH sub_analysis AS (
    SELECT
        a.segment,
        s.status,
        DATEDIFF(
            CASE
                WHEN s.status = 'cancelled'
                    THEN s.ended_at
                ELSE CURDATE()
            END,
            s.started_at
        ) AS subscription_days
    FROM subscriptions s
    JOIN accounts a
        ON a.account_id = s.account_id
)

SELECT
    segment,
    status,
    ROUND(AVG(subscription_days)) AS avg_subscription_days
FROM sub_analysis
GROUP BY
    segment,
    status
ORDER BY
    segment,
    status;


-- =========================================================
-- Analysis #8 — Revenue Collection Performance
-- =========================================================

WITH revenue_collection AS (
    SELECT
        SUM(amount_due) AS total_billed_revenue,
        SUM(
            CASE
                WHEN invoice_status = 'paid'
                    THEN amount_due
                ELSE 0
            END
        ) AS collected_revenue
    FROM invoices
)

SELECT
    total_billed_revenue,
    collected_revenue,
    ROUND(
        (collected_revenue / total_billed_revenue) * 100,
        2
    ) AS collected_percentage,
    total_billed_revenue - collected_revenue AS outstanding_revenue
FROM revenue_collection;


-- =========================================================
-- Analysis #9 — Revenue by Acquisition Channel
-- =========================================================

WITH acquisition_share AS (
    SELECT
        a.acquisition_channel,
        SUM(s.mrr) AS channel_mrr
    FROM accounts a
    JOIN subscriptions s
        ON a.account_id = s.account_id
    GROUP BY a.acquisition_channel
),

channel_share AS (
    SELECT
        acquisition_channel,
        channel_mrr,
        SUM(channel_mrr) OVER () AS total_mrr
    FROM acquisition_share
)

SELECT
    acquisition_channel,
    channel_mrr,
    ROUND(
        (channel_mrr / total_mrr) * 100,
        2
    ) AS acquisition_share_percentage
FROM channel_share
ORDER BY channel_mrr DESC;
