# Demo Script: E-Commerce Marketplace Analytics
## ~4-Minute Recorded Walkthrough
**Format**: Screen recording with voiceover
**Target**: Customer meeting / booth loop / social share
**Narrative**: "Snowflake powers marketplace intelligence — Dynamic Tables maintain real-time GMV and seller performance, ML.FORECAST projects seasonal demand, and Cortex AI generates personalized seller growth recommendations"
**Demo Mode**: Open app with `?demo=true` for presenter notes

---

## Two Personas

| Persona | Role | Tool | What they care about |
|---|---|---|---|
| **Kevin Susanto** | VP Marketplace Operations | React App (SPCS) | GMV growth, seller health, buyer retention, take rate optimization, Harbolnas planning |
| **Maya Anggraini** | Data Science Lead | Amazon QuickSight | Demand forecasting, seller churn, category trends, pricing optimization, fraud patterns |

---

## What's Built

| Layer | Component | Detail |
|---|---|---|
| **RAW** | 6 tables | ORDERS (50000000), SELLERS (500000), BUYERS (10000000), PRODUCTS (20000000), CAMPAIGNS (10000), SELLER_DOCS (150) |
| **CURATED** | 4 Dynamic Tables | GMV_DASHBOARD, SELLER_HEALTH_SCORE, DEMAND_SIGNALS, CAMPAIGN_ROI |
| **ML** | ML.FORECAST | Forecasting + anomaly detection |
| **AI** | COMPLETE, AI_CLASSIFY, SUMMARIZE | Classification + extraction |
| **Search** | Cortex Search | 150 documents indexed |
| **Agent** | MARKETPLACE_INTELLIGENCE_AGENT | Semantic View + Search tools |


---

## The Story

Indonesia's e-commerce market has reached US$82 billion — the largest in Southeast Asia. A leading marketplace platform manages 500,000 sellers and 10 million active buyers, but faces rising competition, seller churn among high-value merchants, and the need to optimize Harbolnas (12.12) — the year's biggest shopping event worth Rp 18 trillion in GMV.

---

## Script

### [0:00–0:45] MARKETPLACE OVERVIEW

**Show**: Marketplace Overview tab

> "Rp 120 trillion annual GMV from 500,000 sellers and 10 million active buyers."

**Action**: Point at Rp 120T GMV and 28% growth

### [0:45–1:30] SELLER INTELLIGENCE

**Show**: Seller Intelligence tab

> "500,000 sellers segmented into 4 tiers — top 2% generate 45% of GMV."

**Action**: Show seller tier distribution and GMV contribution

### [1:30–2:15] CAMPAIGN OPTIMIZATION

**Show**: Campaign Optimization tab

> "10,000 campaigns analyzed — average ROI at 2.8x incremental GMV."

**Action**: Show campaign ROI comparison chart

### [2:15–3:00] ASK AI

**Show**: Ask AI tab

> "Kevin asks: 'What's our GMV run-rate this quarter?'"

**Action**: Type GMV question

### [3:00–3:45] ARCHITECTURE & DATA

**Show**: Architecture & Data tab

> "Six Snowflake capabilities, six AWS services."

**Action**: Walk through architecture diagram


---

## Key Demo Differentiators

1. **ML.FORECAST for GMV demand forecasting** — Only demo using ML.FORECAST for e-commerce demand prediction at marketplace scale
2. **AI-powered seller growth recommendations** — Cortex AI generates personalized seller strategy by tier and category
3. **Dynamic Tables for real-time GMV tracking** — Maintains live marketplace KPIs from 50M monthly orders
4. **Indonesian e-commerce context** — US$82B market, Harbolnas 12.12, 500K sellers, Rupiah economics


---

## Demo Prep Checklist

### Data Verification
- [ ] `SELECT COUNT(*) FROM ECOMMERCE_ANALYTICS.RAW.ORDERS` → 50000000
- [ ] `SELECT COUNT(*) FROM ECOMMERCE_ANALYTICS.RAW.SELLERS` → 500000
- [ ] `SELECT COUNT(*) FROM ECOMMERCE_ANALYTICS.RAW.BUYERS` → 10000000

### ML Model Verification
- [ ] `SELECT COUNT(*) FROM ECOMMERCE_ANALYTICS.ML.GMV_FORECAST_RESULTS` → >0

### AI/Agent Verification
- [ ] `SELECT COUNT(*) FROM ECOMMERCE_ANALYTICS.AI.SELLER_CLASSIFICATION` → 500000

