import { NextResponse } from 'next/server';
import { executeQuery } from '@/lib/snowflake';

export async function GET() {
  try {
    // Portfolio KPIs
    const kpis = await executeQuery<Record<string, number>>(`
      SELECT
  ROUND(SUM(TOTAL_GMV) / 1000000000, 1) AS TOTAL_GMV_B,
  COUNT(DISTINCT SELLER_ID) AS ACTIVE_SELLERS,
  ROUND(AVG(FULFILLMENT_RATE), 1) AS AVG_FULFILLMENT,
  ROUND(AVG(AVG_REVIEW_RATING), 2) AS AVG_RATING
FROM CURATED.SELLER_PERFORMANCE
    `);

    // Trend data (last 12 weeks)
    const trend = await executeQuery<{ PERIOD: string; CATEGORY: string; VALUE: number }>(`
      SELECT WEEK_START AS PERIOD, CATEGORY, GMV_MILLIONS AS VALUE
FROM CURATED.CATEGORY_TRENDS
WHERE WEEK_START >= DATEADD('week', -12, CURRENT_DATE())
ORDER BY WEEK_START
    `);

    // Transform trend into time series
    const trendMap = new Map<string, Record<string, number>>();
    for (const row of (trend as any[])) {
      const period = row.PERIOD?.split('T')[0] || row.PERIOD;
      if (!trendMap.has(period)) trendMap.set(period, {});
      trendMap.get(period)![row.CATEGORY] = row.VALUE;
    }
    const timeseries = Array.from(trendMap.entries()).map(([period, vals]) => ({
      period,
      ...vals
    }));

    return NextResponse.json({
      kpis: (kpis as any[])[0] || {},
      timeseries,
      updatedAt: new Date().toISOString()
    });
  } catch (error) {
    console.error('Data fetch error:', error);
    return NextResponse.json(
      { error: 'Failed to fetch data', details: String(error) },
      { status: 500 }
    );
  }
}
