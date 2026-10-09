-- ============================================================================
-- 06_INTELLIGENCE.SQL - search, anomaly detection, semantic view, agent,
-- live-order alert and on-demand refresh DAG.
-- Run with snowflake/run_intelligence.py (substitutes checked __DEMO_DB__ /
-- __DEMO_WH__ / __ALERT_EMAIL__). Requires 00-05, plus 08 (Snowflake only) or
-- aws/setup_aws.py (AWS build) for RAW.LIVE_ORDERS.
-- Alerts and tasks are created SUSPENDED; run them with EXECUTE ALERT / EXECUTE TASK.
-- ============================================================================
USE DATABASE __DEMO_DB__;
CREATE SCHEMA IF NOT EXISTS SEARCH;
CREATE SCHEMA IF NOT EXISTS APP;

-- ---------- Synthetic order-issue knowledge base (clearly synthetic SOPs) ----------
CREATE OR REPLACE TABLE SEARCH.ISSUE_DOCS AS
WITH types AS (
  SELECT DISTINCT r.ISSUE_TYPE, a.CATEGORY
  FROM RAW.SELLER_DAILY r JOIN RAW.SELLERS a ON a.ID = r.ENTITY_ID
  WHERE r.CANCELLED_COUNT > 0
)
SELECT
  'SOP-' || LPAD(ROW_NUMBER() OVER (ORDER BY CATEGORY, ISSUE_TYPE)::VARCHAR, 3, '0') AS DOC_ID,
  'SOP' AS DOC_TYPE,
  CATEGORY,
  ISSUE_TYPE,
  CATEGORY || ' - ' || ISSUE_TYPE || ' order issue handling' AS TITLE,
  'Synthetic demo SOP. Product category: ' || CATEGORY || '. Order issue type: ' || ISSUE_TYPE || '. '
  || 'Step 1: open a seller case, link the order and pause new listings from the seller in the affected category until the case is triaged. '
  || 'Step 2: ' || CASE
       WHEN ISSUE_TYPE = 'Out of stock after order' THEN 'ask the seller to confirm stock held against stock listed, run a stock sync, and offer the buyer a replacement or a refund before the dispatch deadline.'
       WHEN ISSUE_TYPE = 'Wrong size or variant' THEN 'compare the listing variants with the item photos from the buyer, ask the seller to correct the size chart, and arrange a free exchange.'
       WHEN ISSUE_TYPE = 'Item not as described' THEN 'compare the listing description and photos with the buyer evidence, ask the seller to correct the listing, and refund the buyer if the item cannot be exchanged.'
       WHEN ISSUE_TYPE = 'Damaged in transit' THEN 'collect photos of the packaging, file a claim with the courier, and check the seller packaging standard for the category.'
       WHEN ISSUE_TYPE = 'Counterfeit report' THEN 'take the listing down, request the brand authorisation letter from the seller, and escalate to the trust and safety team.'
       WHEN ISSUE_TYPE = 'Near-expiry item' THEN 'check the batch expiry date against the listing, remove the affected stock, and refund the buyer.'
       ELSE 'review the issue against the seller profile and escalate if unexplained.'
     END
  || ' Step 3: if the return rate for the seller exceeds 5% or the average time to dispatch exceeds 40 hours after triage, keep the case open and request a seller review. '
  || 'Step 4: record the resolution; if the order was cancelled or delivered late, notify the buyer and log it for the seller performance report.' AS CONTENT
FROM types;

CREATE OR REPLACE CORTEX SEARCH SERVICE SEARCH.ISSUE_SOP_SEARCH
  ON CONTENT
  ATTRIBUTES CATEGORY, ISSUE_TYPE
  WAREHOUSE = __DEMO_WH__
  TARGET_LAG = '7 days'
AS (SELECT DOC_ID, TITLE, CATEGORY, ISSUE_TYPE, CONTENT FROM SEARCH.ISSUE_DOCS);

-- ---------- Return rate anomaly detection (train first 75 days, detect last 15) ----------
CREATE OR REPLACE VIEW ML.RETURN_RATE_SERIES AS
SELECT ENTITY_ID, EVENT_DATE::TIMESTAMP_NTZ AS TS, RETURN_RATE_PCT::FLOAT AS RETURN_RATE
FROM RAW.SELLER_DAILY;
CREATE OR REPLACE VIEW ML.RETURN_RATE_TRAIN AS
SELECT * FROM ML.RETURN_RATE_SERIES WHERE TS < (SELECT DATEADD(day, -15, MAX(TS)) FROM ML.RETURN_RATE_SERIES);
CREATE OR REPLACE VIEW ML.RETURN_RATE_DETECT AS
SELECT * FROM ML.RETURN_RATE_SERIES WHERE TS >= (SELECT DATEADD(day, -15, MAX(TS)) FROM ML.RETURN_RATE_SERIES);

CREATE OR REPLACE SNOWFLAKE.ML.ANOMALY_DETECTION ML.RETURN_RATE_ANOMALY_MODEL(
  INPUT_DATA => SYSTEM$REFERENCE('VIEW', 'ML.RETURN_RATE_TRAIN'),
  SERIES_COLNAME => 'ENTITY_ID', TIMESTAMP_COLNAME => 'TS', TARGET_COLNAME => 'RETURN_RATE',
  LABEL_COLNAME => '');

CREATE OR REPLACE TABLE ML.RETURN_RATE_ANOMALIES AS
SELECT SERIES::VARCHAR AS ENTITY_ID, TS::DATE AS EVENT_DATE, Y AS RETURN_RATE, FORECAST AS EXPECTED,
       LOWER_BOUND, UPPER_BOUND, IS_ANOMALY, PERCENTILE
FROM TABLE(ML.RETURN_RATE_ANOMALY_MODEL!DETECT_ANOMALIES(
  INPUT_DATA => SYSTEM$REFERENCE('VIEW', 'ML.RETURN_RATE_DETECT'),
  SERIES_COLNAME => 'ENTITY_ID', TIMESTAMP_COLNAME => 'TS', TARGET_COLNAME => 'RETURN_RATE'));

-- ---------- Semantic view ----------
CREATE OR REPLACE SEMANTIC VIEW APP.MARKETPLACE_ANALYTICS
  TABLES (
    sellers AS CURATED.PERFORMANCE_SUMMARY PRIMARY KEY (ENTITY_ID)
      WITH SYNONYMS = ('entities', 'merchants', 'shops')
      COMMENT = 'One row per marketplace seller (city and product category), 90-day totals',
    risk AS ML.CANCEL_RISK_SCORES PRIMARY KEY (ENTITY_ID)
      COMMENT = 'Latest next-7-day order-cancellation probability per seller',
    issues AS CURATED.ISSUE_SUMMARY PRIMARY KEY (ISSUE_TYPE)
      COMMENT = 'Order issues, cancelled orders and late deliveries by issue type, 90 days',
    daily AS CURATED.TREND_ANALYSIS PRIMARY KEY (METRIC_DATE)
      COMMENT = 'Marketplace-wide totals per day'
  )
  RELATIONSHIPS (risk_seller AS risk (ENTITY_ID) REFERENCES sellers)
  FACTS (
    sellers.issues_f AS ISSUE_COUNT,
    sellers.cancelled_f AS CANCELLED_COUNT,
    sellers.late_f AS LATE_DELIVERY_COUNT,
    sellers.orders_f AS ORDER_COUNT,
    sellers.gmv_f AS GMV_IDR,
    sellers.sync_due_f AS STOCK_SYNC_DUE,
    sellers.sync_done_f AS STOCK_SYNC_DONE,
    risk.cancel_prob_f AS CANCEL_PROB_7D,
    issues.type_issues_f AS ISSUE_COUNT,
    issues.type_cancelled_f AS CANCELLED_COUNT,
    issues.type_late_f AS LATE_DELIVERY_COUNT,
    issues.type_gmv_f AS EXPOSED_GMV_IDR,
    daily.day_issues_f AS ISSUE_COUNT,
    daily.day_cancelled_f AS CANCELLED_COUNT,
    daily.day_gmv_f AS GMV_IDR
  )
  DIMENSIONS (
    sellers.seller_id AS ENTITY_ID WITH SYNONYMS = ('seller', 'merchant', 'entity', 'shop'),
    sellers.seller_name AS ENTITY_NAME,
    sellers.city AS REGION WITH SYNONYMS = ('city', 'region', 'location')
      COMMENT = 'Indonesian city the seller ships from',
    sellers.category AS CATEGORY WITH SYNONYMS = ('product category', 'vertical'),
    sellers.risk_tier AS RISK_TIER COMMENT = 'Seller fulfilment risk tier 1 (low) to 3 (high)',
    risk.risk_band AS RISK_BAND COMMENT = 'High >= 0.5, Medium >= 0.25, else Low',
    risk.scored_as_of AS SCORED_AS_OF,
    issues.issue_type AS ISSUE_TYPE WITH SYNONYMS = ('issue', 'complaint type', 'issue reason'),
    daily.metric_date AS METRIC_DATE
  )
  METRICS (
    sellers.seller_count AS COUNT(sellers.seller_id) WITH SYNONYMS = ('number of sellers', 'number of entities', 'how many sellers'),
    sellers.clean_order_rate_pct AS 100 * (SUM(sellers.orders_f) - SUM(sellers.issues_f)) / NULLIF(SUM(sellers.orders_f), 0)
      WITH SYNONYMS = ('clean order rate', 'perfect order rate')
      COMMENT = 'Orders without an issue / orders processed',
    sellers.issue_cancellation_pct AS 100 * SUM(sellers.cancelled_f) / NULLIF(SUM(sellers.issues_f), 0)
      COMMENT = 'Cancelled orders / order issues raised',
    sellers.issues_raised AS SUM(sellers.issues_f) WITH SYNONYMS = ('order issues', 'complaints'),
    sellers.cancelled_orders AS SUM(sellers.cancelled_f) WITH SYNONYMS = ('cancellations', 'cancelled'),
    sellers.late_deliveries AS SUM(sellers.late_f) WITH SYNONYMS = ('late orders', 'delivery delays'),
    sellers.orders_processed AS SUM(sellers.orders_f) WITH SYNONYMS = ('orders', 'order volume'),
    sellers.total_gmv_idr AS SUM(sellers.gmv_f) WITH SYNONYMS = ('GMV', 'gross merchandise value', 'sales in IDR'),
    sellers.stock_sync_compliance_pct AS 100 * SUM(sellers.sync_done_f) / NULLIF(SUM(sellers.sync_due_f), 0)
      COMMENT = 'Stock syncs completed / stock syncs due',
    risk.avg_cancel_prob AS AVG(risk.cancel_prob_f),
    issues.type_issues AS SUM(issues.type_issues_f),
    issues.type_cancelled AS SUM(issues.type_cancelled_f),
    issues.type_late AS SUM(issues.type_late_f),
    issues.type_cancel_share_pct AS 100 * SUM(issues.type_cancelled_f) / NULLIF(SUM(issues.type_issues_f), 0),
    daily.daily_issues AS SUM(daily.day_issues_f),
    daily.daily_cancelled AS SUM(daily.day_cancelled_f),
    daily.daily_gmv_idr AS SUM(daily.day_gmv_f)
  )
  COMMENT = 'Synthetic Indonesia online marketplace operations analytics (demo)';

-- ---------- Cortex Agent ----------
CREATE OR REPLACE AGENT APP.MARKETPLACE_AGENT
  COMMENT = 'Marketplace operations assistant over a synthetic Indonesian online marketplace'
  FROM SPECIFICATION
$$
models:
  orchestration: claude-sonnet-4-5
instructions:
  response: "Answer only from tool results. State that data is synthetic. Give seller IDs and numbers with units (IDR, %)."
  orchestration: "Use marketplace_analyst for orders, GMV, order issues, cancelled orders, late deliveries, clean order rate, stock sync compliance, sellers, cities, categories, issue types and cancellation risk. Use sop_search for order-issue handling procedures."
tools:
  - tool_spec:
      type: cortex_analyst_text_to_sql
      name: marketplace_analyst
      description: "Orders processed, GMV in IDR, order issues, cancelled orders, late deliveries, clean order rate, stock sync compliance, issue types and order-cancellation risk scores by seller, city and category"
  - tool_spec:
      type: cortex_search
      name: sop_search
      description: "Synthetic order-issue handling SOPs by product category and issue type"
tool_resources:
  marketplace_analyst:
    semantic_view: __DEMO_DB__.APP.MARKETPLACE_ANALYTICS
    execution_environment:
      type: warehouse
      warehouse: __DEMO_WH__
  sop_search:
    name: __DEMO_DB__.SEARCH.ISSUE_SOP_SEARCH
    max_results: 3
    id_column: DOC_ID
    title_column: TITLE
$$;

-- ---------- Live-order alert ----------
CREATE TABLE IF NOT EXISTS APP.ALERT_LOG (
  ALERTED_AT TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP(), SELLER_ID VARCHAR,
  EVENT_TS TIMESTAMP_NTZ, AMOUNT_IDR FLOAT, DISPATCH_MINUTES FLOAT, SOP_HINT VARCHAR);

CREATE OR REPLACE NOTIFICATION INTEGRATION ID_ECOM_EMAIL_INT
  TYPE = EMAIL ENABLED = TRUE ALLOWED_RECIPIENTS = ('__ALERT_EMAIL__');

CREATE OR REPLACE PROCEDURE APP.LOG_LIVE_ALERTS()
RETURNS NUMBER
LANGUAGE SQL
EXECUTE AS OWNER
AS
$$
DECLARE
  n NUMBER;
BEGIN
  INSERT INTO APP.ALERT_LOG (SELLER_ID, EVENT_TS, AMOUNT_IDR, DISPATCH_MINUTES, SOP_HINT)
    SELECT p.SELLER_ID, p.EVENT_TS, p.AMOUNT_IDR, p.DISPATCH_MINUTES,
           'Check ' || r.CATEGORY || ' order-issue SOPs; current risk band ' || COALESCE(s.RISK_BAND, 'n/a')
    FROM RAW.LIVE_ORDERS p
    JOIN RAW.SELLERS r ON r.ID = p.SELLER_ID
    LEFT JOIN ML.CANCEL_RISK_SCORES s ON s.ENTITY_ID = p.SELLER_ID
    WHERE p.STATUS = 'ISSUE'
      AND NOT EXISTS (SELECT 1 FROM APP.ALERT_LOG l WHERE l.SELLER_ID = p.SELLER_ID AND l.EVENT_TS = p.EVENT_TS);
  n := SQLROWCOUNT;
  IF (n > 0) THEN
    CALL SYSTEM$SEND_EMAIL('ID_ECOM_EMAIL_INT', '__ALERT_EMAIL__',
      '[Demo] Order issue alert',
      'New live order issues logged in APP.ALERT_LOG: ' || :n || '. Data is synthetic.');
  END IF;
  RETURN n;
END;
$$;

CREATE OR REPLACE ALERT APP.LIVE_ORDER_ALERT
  WAREHOUSE = __DEMO_WH__
  SCHEDULE = '5 MINUTE'
  IF (EXISTS (
    SELECT 1 FROM RAW.LIVE_ORDERS p
    WHERE p.STATUS = 'ISSUE'
      AND NOT EXISTS (SELECT 1 FROM APP.ALERT_LOG l WHERE l.SELLER_ID = p.SELLER_ID AND l.EVENT_TS = p.EVENT_TS)))
  THEN CALL APP.LOG_LIVE_ALERTS();

-- ---------- On-demand refresh DAG (suspended; run with EXECUTE TASK APP.TASK_REFRESH_CURATED) ----------
CREATE OR REPLACE PROCEDURE APP.REFRESH_CURATED()
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS OWNER
AS
$$
BEGIN
  ALTER DYNAMIC TABLE CURATED.PERFORMANCE_SUMMARY REFRESH;
  ALTER DYNAMIC TABLE CURATED.TREND_ANALYSIS REFRESH;
  ALTER DYNAMIC TABLE CURATED.ISSUE_SUMMARY REFRESH;
  ALTER DYNAMIC TABLE CURATED.KPI_SUMMARY REFRESH;
  RETURN 'refreshed';
END;
$$;

CREATE OR REPLACE TASK APP.TASK_REFRESH_CURATED
  WAREHOUSE = __DEMO_WH__
AS
  CALL APP.REFRESH_CURATED();

CREATE OR REPLACE TASK APP.TASK_RESCORE_RISK
  WAREHOUSE = __DEMO_WH__
  AFTER APP.TASK_REFRESH_CURATED
AS
  CREATE OR REPLACE TABLE ML.CANCEL_RISK_SCORES COPY GRANTS AS
  WITH latest AS (
    SELECT * FROM ML.CANCEL_FEATURES QUALIFY ROW_NUMBER() OVER (PARTITION BY ENTITY_ID ORDER BY EVENT_DATE DESC) = 1
  ), p AS (
    SELECT ENTITY_ID, EVENT_DATE,
           ML.CANCEL_RISK_MODEL!PREDICT(INPUT_DATA => OBJECT_CONSTRUCT(
             'CATEGORY', CATEGORY, 'RISK_TIER', RISK_TIER, 'SELLER_AGE_YEARS', SELLER_AGE_YEARS,
             'RETURN_RATE_PCT', RETURN_RATE_PCT, 'AVG_DISPATCH_HRS', AVG_DISPATCH_HRS,
             'RETURN_RATE_7D', RETURN_RATE_7D, 'CANCELLED_30D', CANCELLED_30D)) AS PRED
    FROM latest
  )
  SELECT ENTITY_ID, EVENT_DATE AS SCORED_AS_OF, ROUND(PRED:probability:CANCEL::FLOAT, 4) AS CANCEL_PROB_7D,
         CASE WHEN PRED:probability:CANCEL::FLOAT >= 0.5 THEN 'High'
              WHEN PRED:probability:CANCEL::FLOAT >= 0.25 THEN 'Medium' ELSE 'Low' END AS RISK_BAND,
         CURRENT_TIMESTAMP() AS SCORED_AT
  FROM p;
