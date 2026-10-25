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

Monthly billed revenue establishes the baseline for understanding the company's financial performance and provides the foundation for evaluating revenue growth.

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

Which customer segments generate the most MRR, and how much MRR does the average customer generate within each segment?

### Business Approach

First aggregate MRR at the customer level to ensure each customer is represented once. Then summarize customer count, total MRR, and average MRR per customer by segment.

### Key Metrics

- Customers
- Total MRR
- Average MRR per customer

### SQL

```sql
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
```

### Key Insight

This analysis distinguishes between segment size and customer value. A segment may generate high total MRR because it has more customers, while another may generate higher MRR per individual customer.

---

# Analysis #4 — Plan Adoption Rate

### Business Question

Which subscription plans are customers adopting, and what percentage of customers does each plan represent?

### Business Approach

Count distinct customers associated with each plan and compare each plan's customer count with the overall customer base.

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
```

### Key Insight

Plan adoption reveals which subscription offerings are most widely used and helps management understand customer preference across the SaaS product portfolio.

---

# Analysis #5 — Customer Retention by Segment

### Business Question

How does customer retention differ across customer segments?

### Business Approach

Calculate distinct customers and distinct active customers within each segment, then derive the active customer percentage.

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
```

### Key Insight

Customer retention differs across segments. Comparing active-customer percentages helps identify which customer groups have stronger ongoing engagement and which segments require greater retention attention.

---

# Analysis #6 — Subscription Cancellation Rate

### Business Question

Which customer segments have the highest subscription cancellation rate?

### Business Approach

Calculate the number of cancelled subscriptions against the total number of subscriptions within each segment.

### Key Metrics

- Total subscriptions
- Cancelled subscriptions
- Cancellation %

### SQL

```sql
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
```

### Key Insight

Cancellation rate identifies the customer segments experiencing the greatest subscription loss and provides a direct measure of churn exposure.

---

# Analysis #7 — Customer Subscription Duration

### Business Question

How long do customers remain subscribed, and how does duration differ between active and cancelled subscriptions?

### Business Approach

Use `DATEDIFF()` to calculate subscription duration.

- Cancelled subscriptions: `ended_at - started_at`
- Active subscriptions: current date - `started_at`

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

Active customers have substantially longer observed subscription durations than cancelled customers. This provides lifecycle context for understanding customer behavior.

The comparison should be interpreted carefully because active subscriptions continue accumulating days, while cancelled subscriptions stop accumulating duration at their cancellation date.

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

The business collected approximately 93.67% of billed revenue, leaving approximately 6.33% outstanding. This highlights the gap between revenue billed and revenue actually collected.

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

MRR is distributed relatively evenly across acquisition channels. No single channel dominates the revenue base, reducing dependence on one acquisition source.

