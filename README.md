# SaaS Analytics — SQL Portfolio Project

A business-focused SQL analytics project analyzing revenue, customers, subscriptions, plans, retention, cancellation, revenue collection, and acquisition performance for a SaaS business.

## Project Objective

The objective of this project is to use SQL to answer practical business questions and turn operational SaaS data into actionable insights.

The analysis follows the customer and revenue lifecycle:

**Revenue → Customer Economics → Product Adoption → Retention → Cancellation → Revenue Collection → Acquisition**

## Business Analyses

The project contains 9 business analyses:

1. **Monthly Revenue Performance** — How does billed revenue perform month by month?
2. **Month-over-Month Revenue Growth** — How quickly is revenue growing or declining?
3. **Customer / Subscription Performance** — Which customer segments generate the most MRR and average customer value?
4. **Plan Adoption Rate** — Which subscription plans are most widely adopted?
5. **Customer Retention by Segment** — How does customer retention differ across segments?
6. **Subscription Cancellation Rate** — Which segments have the highest cancellation rates?
7. **Customer Subscription Duration** — How long do customers remain subscribed?
8. **Revenue Collection Performance** — How much billed revenue has actually been collected?
9. **Revenue by Acquisition Channel** — Which acquisition channels generate the most MRR?

## Key SQL Concepts

- `SELECT`, `WHERE`, `GROUP BY`, `ORDER BY`
- Aggregate functions: `SUM()`, `COUNT()`, `AVG()`
- Conditional aggregation with `CASE`
- Multi-table `JOIN`
- Common Table Expressions (`CTEs`)
- Window functions
- `LAG()`
- `SUM() OVER()`
- Date functions
- Percentage calculations
- Customer-level and segment-level aggregation
- Data validation and business metric calculations

## Repository Structure

```text
saas_analysis/
│
├── docs/
│   └── analysis.md
│
├── sql/
│   └── saas_analysis.sql
│
└── README.md
```

### `docs/analysis.md`

Contains the business questions, analytical approach, key metrics, SQL, and business insights for each analysis.

### `sql/saas_analysis.sql`

Contains the SQL queries used to perform all 9 analyses.

## Tools

- MySQL
- MySQL Workbench
- GitHub

## Project Focus

This project focuses on demonstrating the ability to:

**Understand a business requirement → identify the right metric → design the SQL logic → validate the result → communicate the business insight.**
