# SaaS Analytics — SQL Business Analysis

## Project Objective

Analyze SaaS business performance across revenue, customers, subscriptions, plans, retention, cancellation, revenue collection, and acquisition channels.

The objective is to transform operational data into business insights that can support management decisions.

---

# Analysis #1 — Monthly Revenue Performance

### Business Question

How does billed revenue perform month by month?

### Business Approach

Aggregate invoice value by month to establish the company's revenue performance baseline.

### Key Metrics

- Monthly billed revenue
- Revenue trend

### SQL

```sql
SELECT
    DATE_FORMAT(invoice_date, '%Y-%m') AS revenue_month,
    SUM(amount_due) AS monthly_revenue
FROM invoices
GROUP BY DATE_FORMAT(invoice_date, '%Y-%m')
ORDER BY revenue_month;
```

### Key Insight

Monthly billed revenue increased substantially over the analysis period, establishing a strong overall growth trend.

---

# Analysis #2 — Month-over-Month Revenue Growth

### Business Question

How quickly is monthly revenue growing or declining compared with the previous month?

### Business Approach

First calculate monthly revenue, then use `LAG()` to compare each month with the previous month.

### Key Metrics

- Monthly revenue
- Previous-month revenue
- MoM growth %

### SQL

```sql
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
```

### Key Insight

MoM growth provides a more actionable view of revenue momentum than absolute revenue alone by showing how quickly performance changes from one month to the next.

---

# Analysis #3 — Customer / Subscription Performance

### Business Question

Which customer segments generate the most MRR, and how does customer value differ across segments?

### Business Approach

Join accounts with subscriptions and aggregate customer count, total MRR, and average MRR by segment.

### Key Metrics

- Customers
- Total MRR
- Average MRR per customer

### SQL

```sql
SELECT
    a.segment,
    COUNT(a.account_id) AS customers,
    SUM(s.mrr) AS total_mrr,
    ROUND(AVG(s.mrr), 2) AS avg_mrr
FROM accounts a
JOIN subscriptions s
    ON a.account_id = s.account_id
GROUP BY a.segment
ORDER BY total_mrr DESC;
```

### Key Insight

The segments differ significantly in economic value. Mid-market generates the highest total MRR, while enterprise customers generate substantially higher MRR per customer.

---

# Analysis #4 — Plan Adoption Rate

### Business Question

Which subscription plans are customers adopting, and what percentage of customers does each plan represent?

### Business Approach

Count customers by plan and use a window function to calculate each plan's share of the total customer base.

### Key Metrics

- Customers by plan
- Plan adoption %
- Customer distribution

### SQL

```sql
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
        SUM(customers) OVER () AS total_cust
    FROM plan_adoption
)

SELECT
    plan_name,
    customers,
    ROUND(
        (customers / total_cust) * 100,
        2
    ) AS percentage_of_customers
FROM total_customers
ORDER BY percentage_of_customers DESC;
```

### Key Insight

Starter is the dominant plan, representing nearly half of the customer base, while Enterprise represents a much smaller portion of customers.

---

# Analysis #5 — Customer Retention by Segment

### Business Question

How does customer retention differ across customer segments?

### Business Approach

Calculate total customers and active customers by segment, then derive active and non-active customer percentages.

### Key Metrics

- Total customers
- Active customers
- Active %
- Non-active %

### SQL

```sql
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
            CASE
                WHEN s.status = 'active' THEN 1
            END
        ) AS active_customers
    FROM accounts a
    JOIN subscriptions s
        ON s.account_id = a.account_id
    GROUP BY a.segment
) AS x;
```

### Key Insight

Mid-market has the strongest active-customer percentage, while SMB has the largest customer base and therefore represents the largest pool of customers requiring retention attention.

---

# Analysis #6 — Subscription Cancellation Rate

### Business Question

Which customer segments have the highest subscription cancellation rate?

### Business Approach

Count cancelled subscriptions by segment and calculate cancellations as a percentage of the segment's customer base.

### Key Metrics

- Total customers
- Cancelled customers
- Cancellation %

### SQL

```sql
SELECT
    x.segment,
    x.total_customers,
    x.cancelled_customers,
    ROUND(
        (x.cancelled_customers / x.total_customers) * 100,
        2
    ) AS cancellation_percentage
FROM (
    SELECT
        a.segment,
        COUNT(a.account_id) AS total_customers,
        COUNT(
            CASE
                WHEN s.status = 'cancelled' THEN 1
            END
        ) AS cancelled_customers
    FROM accounts a
    JOIN subscriptions s
        ON s.account_id = a.account_id
    GROUP BY a.segment
) AS x;
```

### Key Insight

SMB has the highest cancellation rate, while mid-market has the lowest. This identifies SMB as the segment with the greatest cancellation exposure.

---

# Analysis #7 — Customer Subscription Duration

### Business Question

How long do customers remain subscribed, and how does duration differ between active and cancelled customers?

### Business Approach

Use `DATEDIFF()` to calculate subscription duration.

- Cancelled subscriptions: `ended_at - started_at`
- Active subscriptions: `current date - started_at`

### Key Metrics

- Subscription duration in days
- Average duration
- Active vs. cancelled duration

### SQL

```sql
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
```

### Key Insight

Active customers have substantially longer observed subscription durations than cancelled customers across every segment. Cancelled subscriptions average roughly 344–358 days, while active subscriptions average more than 830 days.

This should be interpreted carefully because active customers continue accumulating subscription days while cancelled customers stop at their cancellation date.

---

# Analysis #8 — Revenue Collection Performance

### Business Question

How much of the revenue billed to customers has actually been collected?

### Business Approach

Use conditional aggregation to separate total billed revenue from revenue associated with paid invoices.

### Key Metrics

- Total billed revenue
- Collected revenue
- Collection %
- Outstanding revenue

### SQL

```sql
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
```

### Key Insight

The business collected approximately 93.67% of billed revenue, leaving approximately 6.33% outstanding. This highlights the gap between revenue billed and cash actually collected.

---

# Analysis #9 — Revenue by Acquisition Channel

### Business Question

Which acquisition channels generate the most MRR, and what share of total MRR does each channel contribute?

### Business Approach

First calculate MRR generated by each acquisition channel. Then use `SUM() OVER()` to calculate total MRR while preserving the channel-level rows.

### Key Metrics

- Channel MRR
- Total MRR
- Acquisition channel share %

### SQL

```sql
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
```

### Key Insight

MRR is distributed relatively evenly across acquisition channels. Partner contributes the highest share at approximately 21%, while outbound contributes approximately 18.7%. No single channel dominates the revenue base, reducing dependence on one acquisition source.

