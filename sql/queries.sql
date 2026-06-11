-- =====================================================================
-- SUPERSTORE SALES ANALYSIS
-- Investigasi profitabilitas pada data retail Superstore (2014-2017)
-- Database : PostgreSQL
-- Schema   : portofolio.superstore_sales
-- Author   : Muhammad Sawaluddin
-- =====================================================================
-- Catatan: file ini berisi query analisis (BQ #1 - BQ #7).
-- Hasil dan insight lengkap tiap query ada di docs/analysis-findings.md
-- =====================================================================


-- =====================================================================
-- BQ #1 — Tren Revenue vs Profit (2014-2017)
-- Tujuan: melihat apakah pertumbuhan revenue diikuti pertumbuhan margin.
-- =====================================================================
SELECT
    EXTRACT(YEAR FROM order_date)         AS year,
    SUM(sales)                            AS total_revenue,
    SUM(profit)                           AS total_profit,
    ROUND((SUM(profit) / SUM(sales) * 100), 2) AS profit_margin_pct
FROM portofolio.superstore_sales
GROUP BY year
ORDER BY year ASC;


-- =====================================================================
-- BQ #2 — Sub-kategori yang merugi
-- Tujuan: identifikasi sub-kategori dengan margin terendah / negatif.
-- =====================================================================
SELECT
    sub_category,
    category,
    SUM(quantity)                         AS total_quantity,
    SUM(sales)                            AS total_revenue,
    SUM(profit)                           AS total_profit,
    ROUND((SUM(profit) / SUM(sales) * 100), 2) AS profit_margin_pct
FROM portofolio.superstore_sales
GROUP BY sub_category, category
ORDER BY profit_margin_pct ASC;

-- Pendukung BQ #2 — agregasi per kategori
SELECT
    category,
    SUM(quantity)                         AS total_quantity,
    ROUND((SUM(profit) / SUM(sales) * 100), 2) AS profit_margin_pct,
    SUM(profit)                           AS total_profit,
    SUM(sales)                            AS total_revenue
FROM portofolio.superstore_sales
GROUP BY category
ORDER BY profit_margin_pct ASC;


-- =====================================================================
-- BQ #3 — Korelasi discount vs profit margin
-- Tujuan: cari titik kritis (threshold) di mana diskon membuat margin negatif.
-- =====================================================================
SELECT
    discount,
    COUNT(*)                              AS number_of_transactions,
    ROUND((SUM(profit) / SUM(sales) * 100), 2) AS profit_margin_pct
FROM portofolio.superstore_sales
GROUP BY discount
ORDER BY discount ASC;

-- Pendukung BQ #3 — verifikasi proporsi transaksi merugi (diskon >= 30%)
SELECT
    COUNT(*) AS transaksi_merugi,
    ROUND((COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM portofolio.superstore_sales)
    ), 2) AS pct_dari_total
FROM portofolio.superstore_sales
WHERE discount >= 0.30;


-- =====================================================================
-- BQ #4 — Performa regional
-- Tujuan: bandingkan margin antar region/state dan kaitkan dengan diskon.
-- =====================================================================

-- Margin per state dan region
SELECT
    state,
    region,
    ROUND((SUM(profit) / SUM(sales) * 100), 2) AS profit_margin_pct
FROM portofolio.superstore_sales
GROUP BY state, region
ORDER BY profit_margin_pct ASC;

-- Margin per region (keseluruhan)
SELECT
    region,
    ROUND((SUM(profit) / SUM(sales) * 100), 2) AS profit_margin_pct
FROM portofolio.superstore_sales
GROUP BY region
ORDER BY profit_margin_pct ASC;

-- Konsistensi margin region per tahun
SELECT
    region,
    EXTRACT(YEAR FROM order_date) AS year,
    ROUND((SUM(profit) / SUM(sales) * 100), 2) AS profit_margin_pct
FROM portofolio.superstore_sales
GROUP BY region, year
ORDER BY region, year ASC;

-- Rata-rata diskon per region
SELECT
    region,
    ROUND(AVG(discount) * 100, 2)         AS avg_discount_pct,
    ROUND((SUM(profit) / SUM(sales) * 100), 2) AS profit_margin_pct
FROM portofolio.superstore_sales
GROUP BY region
ORDER BY avg_discount_pct DESC;

-- Pendukung BQ #4 — jumlah state dengan margin negatif
SELECT COUNT(*) AS state_merugi
FROM (
    SELECT
        state,
        ROUND((SUM(profit) / SUM(sales) * 100), 2) AS profit_margin_pct
    FROM portofolio.superstore_sales
    GROUP BY state
) AS state_summary
WHERE profit_margin_pct < 0;


-- =====================================================================
-- BQ #5 — Perilaku produk per wilayah
-- Tujuan: lihat apakah kategori yang sama berperforma beda antar region.
-- =====================================================================

-- Margin per category per region
SELECT
    region,
    category,
    ROUND((SUM(profit) / SUM(sales) * 100), 2) AS profit_margin_pct
FROM portofolio.superstore_sales
GROUP BY region, category
ORDER BY profit_margin_pct DESC;

-- Rata-rata diskon per category per region
SELECT
    region,
    category,
    ROUND(AVG(discount) * 100, 2)         AS avg_discount_pct,
    ROUND((SUM(profit) / SUM(sales) * 100), 2) AS profit_margin_pct
FROM portofolio.superstore_sales
GROUP BY region, category
ORDER BY category, avg_discount_pct DESC;


-- =====================================================================
-- BQ #6 — Estimasi pemulihan profit jika sub-kategori rugi di-reprice
-- Asumsi: harga_asli = sales / (quantity * (1 - discount)); volume tetap.
-- Simulasi membatasi diskon menjadi maksimal 20% pada transaksi diskon >20%.
-- =====================================================================

-- Verifikasi asumsi harga (reverse pricing)
SELECT
    product_id,
    discount,
    quantity,
    sales,
    ROUND((sales / quantity)::numeric, 2)                    AS harga_per_unit_apa_adanya,
    ROUND((sales / (quantity * (1 - discount)))::numeric, 2) AS harga_asli_hasil_reverse
FROM portofolio.superstore_sales
WHERE product_id IN (
    SELECT product_id
    FROM portofolio.superstore_sales
    GROUP BY product_id
    HAVING COUNT(DISTINCT discount) > 1
)
ORDER BY product_id, discount
LIMIT 40;

-- Simulasi reprice (diskon dibatasi 20%) untuk sub-kategori rugi
SELECT
    sub_category,
    ROUND(SUM(sales - profit), 2)                                          AS total_cost,
    ROUND(SUM(sales), 2)                                                   AS total_sales_aktual,
    ROUND(SUM(profit), 2)                                                  AS total_profit_aktual,
    ROUND((SUM(profit) / SUM(sales) * 100), 2)                             AS profit_margin_aktual_pct,
    ROUND(SUM((sales / (quantity * (1 - discount))) * quantity * 0.80), 2) AS total_sales_baru,
    ROUND(SUM(((sales / (quantity * (1 - discount))) * quantity * 0.80)
        - (sales - profit)), 2)                                           AS total_profit_baru,
    ROUND((
        SUM(((sales / (quantity * (1 - discount))) * quantity * 0.80)
            - (sales - profit))
        / SUM((sales / (quantity * (1 - discount))) * quantity * 0.80)
        * 100
    ), 2)                                                                 AS profit_margin_baru_pct,
    ROUND(SUM(((sales / (quantity * (1 - discount))) * quantity * 0.80)
        - (sales - profit)) - SUM(profit), 2)                            AS potential_recovery
FROM portofolio.superstore_sales
WHERE sub_category IN ('Tables', 'Bookcases', 'Supplies')
  AND discount > 0.20
GROUP BY sub_category;


-- =====================================================================
-- BQ #7 — Potensi nilai tambah jika region under-perform capai margin nasional
-- Benchmark: profit margin nasional = 12.47%. Asumsi: volume penjualan tetap.
-- =====================================================================

-- Margin nasional (benchmark)
SELECT ROUND(SUM(profit) / SUM(sales) * 100, 2) AS profit_margin_nasional
FROM portofolio.superstore_sales;

-- Potential gain Central & South jika capai 12.47%
SELECT
    region,
    ROUND(SUM(sales), 2)                          AS total_sales,
    ROUND(SUM(profit), 2)                         AS total_profit_aktual,
    ROUND(SUM(sales) * 0.1247, 2)                 AS profit_seharusnya,
    ROUND((SUM(sales) * 0.1247) - SUM(profit), 2) AS potential_gain
FROM portofolio.superstore_sales
WHERE region IN ('Central', 'South')
GROUP BY region;
