# StreamFlix — Subscription & Marketing Analytics

StreamFlix is a SQL analytics project on a fictional streaming service, analyzing subscription revenue, retention, and marketing efficiency to answer one question: where should the company spend to grow, and why are customers leaving?

---
**🔗 [View the live Tableau dashboard](https://public.tableau.com/app/profile/duong.ngo6143/viz/StreamFlixSubscriptionMarketingAnalytics/StreamFlixSubscriptionMarketingAnalytics)**

## The Business Problem

StreamFlix, a subscription streaming service, is spending heavily on customer acquisition while losing a significant share of subscribers to churn. Leadership needs to know two things: which marketing channels are worth the investment, and what drives customers to cancel — so budget can be reallocated and at-risk users retained before they leave.

---

## Key Findings

**1. Expensive channels are also the leakiest.** Display and Paid Social have the highest customer acquisition cost ($68 and $55) *and* the worst churn (64% and 61%). They bring in volume, but those customers leave quickly — high cost for low retention.

**2. Two-thirds of the marketing budget is misallocated.** Roughly 66% of spend goes to Display and Paid Social — the two worst-performing channels — while Referral, the cheapest and stickiest channel ($9 CAC, 31% churn), is underfunded.

**3. True retention is far healthier than the headline churn number suggests.** A blended "47% of all users have canceled" figure is misleading — it lumps three-year-old accounts with brand-new signups. Cohort analysis shows mature cohorts retain roughly 72–77% at six months, giving a fair, time-aligned view of retention.

**4. Engagement collapses before customers churn.** In their final two months, churned users watched an average of 9.5 hours/month versus 21.6 earlier — a 50%+ drop. This makes engagement an early-warning signal the company can act on before cancellation.

---

## Recommendation

**1. Cut Display, redirect to Search.** Display has the highest acquisition cost and worst retention, with no offsetting strength — it's the clearest budget to eliminate. Redirect the bulk to Search, which retains far better (38% vs 64% churn) and, unlike Referral, can absorb additional spend to scale.

**2. Fund Referral through incentives, not ad spend.** Referral is the cheapest, stickiest channel, but it grows through existing users inviting others — not by buying traffic. Invest in referral bonuses to expand it, while recognizing it can't absorb the full budget alone.

**3. Build an at-risk churn flag.** Since engagement drops ~50% before cancellation, flag active users whose monthly watch time falls sharply below their own baseline, and trigger re-engagement (recommendations, offers) while they're still subscribers. Target the intervention carefully — not every dip means churn, so blanket discounts would waste money on users who'd have stayed.

*Next step: extend the analysis to LTV:CAC — comparing revenue-per-customer against acquisition cost — for a complete picture of channel profitability.*

---

## The Analyses

| # | Analysis | Business Question | SQL Techniques |
|---|----------|-------------------|----------------|
| A | MRR & Growth | How is monthly recurring revenue trending month over month? | Chained CTEs, window function (`LAG`), date formatting |
| B | Cohort Retention | Grouped by signup month, how well do we retain users over time? | CTEs, date math (`TIMESTAMPDIFF`), `CASE`, conditional aggregation |
| C | Channel CAC vs. Churn | Which acquisition channels deliver low-churn customers at a sustainable cost? | Multi-table joins, multiple CTEs, conditional aggregation |
| D | Churn Drivers | What behavior precedes cancellation? | Window function (`ROW_NUMBER` with `PARTITION BY`), `CASE` bucketing, `AVG` |

Each analysis pairs a business question with the SQL needed to answer it, and ends in a finding that feeds the recommendation above.

---

## Tech & Tools

- **Database:** MySQL
- **SQL techniques:** CTEs (including chained CTEs), window functions (`LAG`, `ROW_NUMBER`, `PARTITION BY`), conditional aggregation (`SUM(CASE...)`), multi-table joins, date functions
- **Visualization:** Tableau
- **Data:** Synthetic dataset (~8,000 users, ~82,000 payment records, ~82,000 engagement records) modeling three years of subscription activity

---

## Repository Structure

```
streamflix/
├── README.md                  # This file
├── 01_schema.sql              # Table definitions + data load
├── streamflix_queries.sql     # The four analyses (A–D)
├── data/                      # Synthetic CSV datasets
│   ├── users.csv
│   ├── subscriptions.csv
│   ├── plans.csv
│   ├── payments.csv
│   ├── engagement.csv
│   └── marketing_spend.csv
└── dashboard/                 # Tableau dashboard (in progress)
```

---

## About the Data

The dataset is synthetic — designed to model realistic subscription dynamics including channel-based acquisition, tenure-driven churn, and engagement decay preceding cancellation. This allowed the analysis to surface patterns that mirror real-world subscription businesses while keeping the data fully shareable.
