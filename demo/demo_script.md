# E-Commerce Marketplace Analytics

**Indonesia - Digital Economy & E-Commerce**
Use case: Marketplace Analytics

> Seller and buyer intelligence for Indonesia's US$82B e-commerce market — ML.FORECAST projects GMV growth, Dynamic Tables build real-time marketplace dashboards, and Cortex AI generates seller recommendations.

## Why Snowflake

Snowflake powers marketplace intelligence — Dynamic Tables maintain real-time GMV and seller performance, ML.FORECAST projects seasonal demand, and Cortex AI generates personalized seller growth recommendations

- **ML.FORECAST for GMV demand forecasting** - Only demo using ML.FORECAST for e-commerce demand prediction at marketplace scale
- **AI-powered seller growth recommendations** - Cortex AI generates personalized seller strategy by tier and category
- **Dynamic Tables for real-time GMV tracking** - Maintains live marketplace KPIs from 50M monthly orders
- **Indonesian e-commerce context** - US$82B market, Harbolnas 12.12, 500K sellers, Rupiah economics

## What is deployed

| | |
|---|---|
| Database | `ID_DIGITAL_ECONOMY_ECOMMERCE` |
| Service | `ID_DIGITAL_ECONOMY_ECOMMERCE_APP` |
| Compute pool | `SEA_DEMOS_INDONESIA_POOL` |
| Dimension table | `RAW.SELLER_DOCS` (20 rows) |
| Fact table | `RAW.ORDERS` (250,000 rows, 90 days) |
| Curated layer | `CURATED.PERFORMANCE_SUMMARY`, `CURATED.TREND_ANALYSIS`, `CURATED.KPI_SUMMARY` |
| Currency | IDR (Rp) |

Regions in play: Jakarta, North Sumatra, Riau, East Kalimantan, Sulawesi
Segments: Electronics, Fashion, Home and Living, Health and Beauty

Dynamic tables are created suspended and refreshed on demand:

```bash
./refresh_demo_data.sh ID_DIGITAL_ECONOMY_ECOMMERCE
```

## KPI cards

Every card below is served live from `CURATED.KPI_SUMMARY`. The app keeps the
original literal as a fallback, so it still renders if Snowflake is unreachable.

| Card | Value | Backed by |
|---|---|---|
| GMV (MTD) | `Rp 4.8T` | total across Seller Docs |
| Active Merchants | `124K` | total across Seller Docs |
| Fraud Rate | `0.08%` | average per event |
| Order Fulfillment | `96.2%` | average per event |
| Avg Order Value | `Rp 287K` | average per event |
| Repeat Purchase | `42%` | average per event |
| Cart Abandonment | `68%` | average per event |


## Demo flow

1. Marketplace Overview
2. Seller Intelligence
3. Campaign Optimization
4. Ask AI
5. Architecture & Data

## Talking points

- **Rp 120T GMV** - annual gross merchandise value (28% YoY growth)
- **500K sellers** - marketplace merchants across all categories
- **10M buyers** - active buyers in trailing 12 months
- **3,200 at-risk** - high-value sellers with elevated churn score
- **50M orders/month** - monthly transaction volume at peak

## Business impact

- Indonesia's e-commerce GMV reached US$82B in 2023 — largest in SEA (Google-Temasek-Bain SEA Report)
- Harbolnas (12.12) generated US$1.2B in single-day GMV in 2023 (iPrice Group)
- Seller churn reduction of 10% can increase marketplace GMV by 15-20% (McKinsey Digital)
- Indonesia has 196 million internet users — 4th largest online market globally (We Are Social)

---
Generated from `generator/demo_specs/aws-indonesia-digital-economy-ecommerce.json`. Do not hand-edit: run
`python3 generator/gen_repo_docs.py aws-indonesia-digital-economy-ecommerce` instead.
