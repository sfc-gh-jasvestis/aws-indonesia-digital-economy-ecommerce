# Indonesia Marketplace Operations

**Indonesia - Online Marketplace**
Use case: Order issues, cancellations, seller controls and seller quality risk

> Operations monitoring for 40 fictional sellers on a fictional Indonesian online marketplace, shipping from Jakarta, Surabaya, Bandung, Medan and Makassar: dynamic tables, a holdout-evaluated order-cancellation classifier, an order-issue forecast and return rate anomaly detection, a Cortex Agent with SOP citations, a live order feed with an alert, and an SPCS app.

## Why Snowflake

- **Dynamic tables** reconcile orders, order issues, cancelled orders, late deliveries and stock sync compliance from RAW seller data, with checks in `run_core.py`
- **Order-cancellation classification** gives a holdout-evaluated next-7-day probability per seller
- **Order-issue forecast** projects 14 days of marketplace-wide order issues with prediction intervals, for support staffing
- **Grounded AI**: the Cortex Agent (Analyst over a semantic view, plus Search over SOPs) shows its SQL and SOP citations
- **Live orders**: a native simulator (Snowflake only) or Firehose, S3 and Snowpipe (AWS build), then an alert and email

## What is built

| | |
|---|---|
| Dimension table | `RAW.SELLERS` (40 rows) |
| Fact table | `RAW.SELLER_DAILY` (3,600 seller-days, 90 days) |
| Curated layer | `CURATED.KPI_SUMMARY`, `PERFORMANCE_SUMMARY`, `ISSUE_SUMMARY`, `TREND_ANALYSIS` |
| ML | `ML.CANCEL_RISK_SCORES`, `ML.CANCEL_RISK_HOLDOUT_METRICS`, `ML.ISSUE_FORECAST`, `ML.RETURN_RATE_ANOMALIES` |

Currency: IDR. Cities: Jakarta, Surabaya, Bandung, Medan, Makassar.
Categories: Fashion, Electronics, Home and living, Health and beauty, Groceries.

## KPI cards (live from `CURATED.KPI_SUMMARY`; no fallback values)

| Card | Value from the seeded data |
|---|---|
| Clean Order Rate | 99.91% |
| Order Issues Raised | 627 |
| Cancelled Orders | 170 |
| Issue Cancellation Rate | 27.1% |
| Late Deliveries | 84 |
| GMV (IDR B) | 233 |
| Orders Processed | 662,753 |
| Stock Sync Compliance | 83.3% |
| Sellers Monitored | 40 |
| Compliance Document Coverage | 84.5% |
| Compliance Documents Pending | 7 |

Values are synthetic. A rebuild reproduces them because the data is HASH-seeded; dates are relative to the build day.

## Demo flow

1. Executive Cockpit: KPIs, daily order issues against cancelled orders, issues and cancellations by issue type, seller table
2. Predictive: holdout metrics, risk bands, 14-day order-issue forecast, return rate anomalies
3. Controls: stock sync compliance, compliance document coverage and pending documents, stock sync compliance against cancelled orders, then generate the action memo
4. Live Orders: run `CALL APP.SIMULATE_ORDERS(20)` (Snowflake only) or `python aws/publish_orders.py --count 20` (AWS build). Then run `EXECUTE ALERT APP.LIVE_ORDER_ALERT` and show the alert log and email
5. Ask AI: the Cortex Agent answers metric questions through the semantic view and cites SOPs from Cortex Search. The SQL is shown.
6. QuickSight (AWS build): the same Snowflake tables through DIRECT_QUERY
7. Architecture: both builds side by side

## Talking points

- 99.91% of orders arrive without an issue; the 627 order issues are where operations time goes, and about 1 in 4 of them (27.1%) end as cancelled orders.
- Wrong size or variant issues produce the most cancelled orders (40 of 83). Courier network disruptions hit every seller in a city at once and are always resolved.
- The risk model is evaluated on a time-based holdout: precision 0.41 and recall 0.44 at 0.5, against a 0.19 base rate. Present it as triage, not a verdict.
- Courier network disruptions are excluded from model training, because they are not seller-driven.

## Business impact

Use only the sourced references in `README.md` (Business Impact).
