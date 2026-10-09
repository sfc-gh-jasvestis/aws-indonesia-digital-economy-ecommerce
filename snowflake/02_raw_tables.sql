-- Synthetic seller-day observations for a fictional Indonesian online marketplace.
-- A seller is one fictional merchant shipping from one Indonesian city in one category.
-- Nothing is seeded as a prediction. Randomness is HASH-seeded, so every rebuild
-- is reproducible: per-seller cancellation propensity, listing drift between
-- stock syncs, missed stock syncs, category-weighted order issue types,
-- issues resolved without cancellation, and two city-wide courier disruptions.
USE DATABASE IDENTIFIER($DEMO_DB);
USE SCHEMA RAW;
USE WAREHOUSE IDENTIFIER($DEMO_WH);

CREATE TABLE RAW.SELLERS AS
WITH sellers AS (
  SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS SELLER_INDEX
  FROM TABLE(GENERATOR(ROWCOUNT => 40))
), draws AS (
  SELECT SELLER_INDEX,
         MOD(ABS(HASH(SELLER_INDEX, 'age')), 1000000) / 1e6 AS U_AGE,
         MOD(ABS(HASH(SELLER_INDEX, 'rate')), 1000000) / 1e6 AS U_RATE,
         MOD(ABS(HASH(SELLER_INDEX, 'sync')), 1000000) / 1e6 AS U_SYNC,
         MOD(ABS(HASH(SELLER_INDEX, 'discipline')), 1000000) / 1e6 AS U_DISCIPLINE,
         MOD(ABS(HASH(SELLER_INDEX, 'tier')), 1000000) / 1e6 AS U_TIER
  FROM sellers
)
SELECT 'SLR-' || LPAD(SELLER_INDEX::VARCHAR, 4, '0') AS ID,
       'Synthetic seller ' || LPAD(SELLER_INDEX::VARCHAR, 4, '0') AS NAME,
       -- Deterministic spread (5 and 8 are coprime): every city and category is present.
       CASE MOD(SELLER_INDEX, 5) WHEN 0 THEN 'Jakarta' WHEN 1 THEN 'Surabaya'
            WHEN 2 THEN 'Bandung' WHEN 3 THEN 'Medan' ELSE 'Makassar' END AS REGION,
       CASE MOD(SELLER_INDEX, 8) WHEN 0 THEN 'Fashion' WHEN 1 THEN 'Fashion'
            WHEN 2 THEN 'Fashion' WHEN 3 THEN 'Electronics' WHEN 4 THEN 'Electronics'
            WHEN 5 THEN 'Home and living' WHEN 6 THEN 'Health and beauty' ELSE 'Groceries' END AS CATEGORY,
       SELLER_INDEX,
       1 + FLOOR(U_TIER * 3) AS RISK_TIER,
       ROUND(0.2 + U_AGE * 5.8, 1) AS SELLER_AGE_YEARS,
       -- Base daily probability of a cancelled order 0.4%-3%; ~15% of sellers are
       -- chronically weak (x3).
       (0.004 + U_RATE * 0.026) * IFF(U_RATE > 0.85, 3, 1) AS BASE_CANCEL_RATE,
       7 * (1 + FLOOR(U_SYNC * 3)) AS STOCK_SYNC_INTERVAL_DAYS,
       0.55 + U_DISCIPLINE * 0.45 AS STOCK_SYNC_COMPLETION_PROB,
       'Active' AS STATUS
FROM draws;

CREATE TABLE RAW.SELLER_DAILY AS
WITH days AS (
  SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS DAY_INDEX
  FROM TABLE(GENERATOR(ROWCOUNT => 90))
), city_events AS (
  -- Two city-wide courier disruptions; every seller in the city raises an order
  -- issue that is resolved once deliveries resume.
  SELECT * FROM VALUES (27, 'Medan'), (64, 'Makassar') AS o(DAY_INDEX, REGION)
), base AS (
  SELECT s.ID AS ENTITY_ID, s.SELLER_INDEX, s.CATEGORY, s.REGION, s.SELLER_AGE_YEARS,
         s.BASE_CANCEL_RATE, s.STOCK_SYNC_INTERVAL_DAYS, s.STOCK_SYNC_COMPLETION_PROB,
         d.DAY_INDEX,
         DATEADD('day', d.DAY_INDEX - 89, CURRENT_DATE()) AS EVENT_DATE,
         MOD(d.DAY_INDEX + s.SELLER_INDEX * 5, s.STOCK_SYNC_INTERVAL_DAYS) AS DAYS_SINCE_SYNC,
         MOD(ABS(HASH(s.ID, d.DAY_INDEX, 'cancel')), 1000000) / 1e6 AS U_CANCEL,
         MOD(ABS(HASH(s.ID, d.DAY_INDEX, 'detect')), 1000000) / 1e6 AS U_DETECT,
         MOD(ABS(HASH(s.ID, d.DAY_INDEX, 'resolve')), 1000000) / 1e6 AS U_RESOLVE,
         MOD(ABS(HASH(s.ID, d.DAY_INDEX, 'type')), 1000000) / 1e6 AS U_TYPE,
         MOD(ABS(HASH(s.ID, d.DAY_INDEX, 'done')), 1000000) / 1e6 AS U_DONE,
         MOD(ABS(HASH(s.ID, d.DAY_INDEX, 'volume')), 1000000) / 1e6 AS U_VOLUME,
         MOD(ABS(HASH(s.ID, d.DAY_INDEX, 'noise')), 1000000) / 1e6 AS U_NOISE,
         MOD(ABS(HASH(s.ID, d.DAY_INDEX, 'late')), 1000000) / 1e6 AS U_LATE,
         e.REGION IS NOT NULL AS CITY_EVENT
  FROM RAW.SELLERS s CROSS JOIN days d
  LEFT JOIN city_events e ON e.DAY_INDEX = d.DAY_INDEX AND e.REGION = s.REGION
), sync AS (
  SELECT *,
         IFF(DAYS_SINCE_SYNC = 0, 1, 0) AS STOCK_SYNC_DUE,
         IFF(DAYS_SINCE_SYNC = 0 AND U_DONE < STOCK_SYNC_COMPLETION_PROB, 1, 0) AS STOCK_SYNC_DONE,
         -- Listing drift (stock shown versus stock held) rises between stock
         -- syncs; weak sync discipline carries it over.
         DAYS_SINCE_SYNC / STOCK_SYNC_INTERVAL_DAYS + (1 - STOCK_SYNC_COMPLETION_PROB) AS DRIFT
  FROM base
), cancels AS (
  SELECT *,
         CASE WHEN U_CANCEL < LEAST(0.5, BASE_CANCEL_RATE * (0.4 + 1.6 * DRIFT) * (1 + 1 / (1 + SELLER_AGE_YEARS))) / 4 THEN 2
              WHEN U_CANCEL < LEAST(0.5, BASE_CANCEL_RATE * (0.4 + 1.6 * DRIFT) * (1 + 1 / (1 + SELLER_AGE_YEARS))) THEN 1
              ELSE 0 END AS CANCEL_RISK_COUNT
  FROM sync
), issues AS (
  SELECT *,
         -- About 85% of at-risk orders raise an issue and end cancelled; the
         -- rest are delivered late without an issue.
         IFF(CITY_EVENT, 0, IFF(U_DETECT < 0.85, CANCEL_RISK_COUNT, 0)) AS CANCELLED_COUNT,
         -- Issues resolved without cancellation: higher for high-volume categories.
         IFF(CITY_EVENT, 1, IFF(U_RESOLVE < CASE CATEGORY WHEN 'Groceries' THEN 0.20
                                                         WHEN 'Health and beauty' THEN 0.12
                                                         WHEN 'Electronics' THEN 0.14 ELSE 0.08 END, 1, 0)) AS RESOLVED_COUNT
  FROM cancels
), measured AS (
  SELECT *,
         CANCELLED_COUNT + RESOLVED_COUNT AS ISSUE_COUNT,
         ROUND(CASE CATEGORY WHEN 'Groceries' THEN 400 WHEN 'Health and beauty' THEN 150
                             WHEN 'Electronics' THEN 60 WHEN 'Home and living' THEN 80 ELSE 220 END
               * (0.7 + 0.6 * U_VOLUME) * (1 + 0.8 * CANCEL_RISK_COUNT)) AS ORDER_COUNT,
         CASE CATEGORY WHEN 'Groceries' THEN 90000 WHEN 'Health and beauty' THEN 135000
                       WHEN 'Electronics' THEN 2400000 WHEN 'Home and living' THEN 420000 ELSE 185000 END
           * (0.8 + 0.4 * U_NOISE) AS AVG_ORDER_IDR
  FROM issues
)
SELECT ENTITY_ID || '-' || TO_CHAR(EVENT_DATE, 'YYYYMMDD') AS EVENT_ID,
       ENTITY_ID, EVENT_DATE,
       ORDER_COUNT,
       ROUND(ORDER_COUNT * AVG_ORDER_IDR, 0) AS GMV_IDR,
       ISSUE_COUNT, CANCELLED_COUNT,
       IFF(CANCELLED_COUNT > 0 AND U_LATE < 0.6, 1, 0) AS LATE_DELIVERY,
       CASE WHEN ISSUE_COUNT = 0 THEN 'None'
            WHEN CITY_EVENT THEN 'Courier network disruption'
            WHEN CATEGORY = 'Fashion' THEN IFF(U_TYPE < 0.5, 'Wrong size or variant', IFF(U_TYPE < 0.8, 'Item not as described', 'Counterfeit report'))
            WHEN CATEGORY = 'Electronics' THEN IFF(U_TYPE < 0.45, 'Item not as described', IFF(U_TYPE < 0.8, 'Damaged in transit', 'Counterfeit report'))
            WHEN CATEGORY = 'Home and living' THEN IFF(U_TYPE < 0.55, 'Damaged in transit', 'Out of stock after order')
            WHEN CATEGORY = 'Health and beauty' THEN IFF(U_TYPE < 0.45, 'Near-expiry item', IFF(U_TYPE < 0.8, 'Out of stock after order', 'Counterfeit report'))
            ELSE IFF(U_TYPE < 0.5, 'Out of stock after order', IFF(U_TYPE < 0.75, 'Damaged in transit', 'Item not as described')) END AS ISSUE_TYPE,
       STOCK_SYNC_DUE, STOCK_SYNC_DONE,
       ROUND(0.5 + 2.0 * DRIFT + 3.0 * CANCEL_RISK_COUNT + U_NOISE * 0.8, 2) AS RETURN_RATE_PCT,
       ROUND(18 + 12 * DRIFT + 14 * CANCEL_RISK_COUNT + U_NOISE * 6, 1) AS AVG_DISPATCH_HRS,
       CURRENT_TIMESTAMP() AS LOADED_AT
FROM measured;

-- Seller compliance document coverage (snapshot).
CREATE TABLE RAW.COMPLIANCE_DOCUMENTS AS
SELECT ID AS ENTITY_ID,
       CASE CATEGORY WHEN 'Fashion' THEN 'Brand authorisation letter'
                     WHEN 'Electronics' THEN 'Product standard certificate'
                     WHEN 'Home and living' THEN 'Product safety declaration'
                     WHEN 'Health and beauty' THEN 'Cosmetics registration'
                     ELSE 'Food safety and halal certificate' END AS DOC_TYPE,
       1 + MOD(ABS(HASH(ID, 'req')), 4) AS REQUIRED_QTY,
       MOD(ABS(HASH(ID, 'file')), 5) AS ON_FILE_QTY,
       IFF(MOD(ABS(HASH(ID, 'file')), 5) < 1 + MOD(ABS(HASH(ID, 'req')), 4),
           MOD(ABS(HASH(ID, 'pending')), 3), 0) AS PENDING_QTY,
       CURRENT_DATE() AS SNAPSHOT_DATE
FROM RAW.SELLERS;
