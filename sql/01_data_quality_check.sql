-- ============================================================
-- PORTFOLIO #3 - SUPERSTORE SALES ANALYSIS
-- File    : 01_data_quality_check.sql
-- Tujuan  : Memastikan kualitas data sebelum analisis —
--           cek NULL, rentang tanggal, dan nilai unik
--           di kolom kategorikal
-- Dataset : portofolio.superstore_sales
-- Periode : 2014 - 2017
-- ============================================================


-- ------------------------------------------------------------
-- QUERY 1 — Cek NULL di Kolom Penting
-- Tujuan  : Memastikan tidak ada nilai kosong di kolom
--           yang akan digunakan dalam analisis
-- ------------------------------------------------------------

SELECT 
    COUNT(*)            AS total_rows,
    COUNT(order_id)     AS order_id_filled,
    COUNT(order_date)   AS order_date_filled,
    COUNT(sales)        AS sales_filled,
    COUNT(profit)       AS profit_filled,
    COUNT(customer_id)  AS customer_id_filled
FROM portofolio.superstore_sales;


-- ------------------------------------------------------------
-- QUERY 2 — Cek Rentang Tanggal
-- Tujuan  : Memverifikasi periode data yang tersedia
--           untuk memastikan kelengkapan data time series
-- ------------------------------------------------------------

SELECT 
    MIN(order_date) AS tanggal_awal,
    MAX(order_date) AS tanggal_akhir
FROM portofolio.superstore_sales;


-- ------------------------------------------------------------
-- QUERY 3 — Cek Nilai Unik Kolom Kategorikal
-- Tujuan  : Memahami dimensi dan granularitas dataset —
--           berapa banyak customer, produk, order,
--           region, category, sub-category, dan state
-- ------------------------------------------------------------

SELECT 
    COUNT(DISTINCT customer_id)  AS total_customer,
    COUNT(DISTINCT product_id)   AS total_product,
    COUNT(DISTINCT order_id)     AS total_order,
    COUNT(DISTINCT region)       AS total_region,
    COUNT(DISTINCT category)     AS total_category,
    COUNT(DISTINCT sub_category) AS total_sub_category,
    COUNT(DISTINCT state)        AS total_state
FROM portofolio.superstore_sales;


-- ------------------------------------------------------------
-- HASIL
-- ------------------------------------------------------------
-- Query 1 — Null Check:
--   total_rows = 9,994 | semua kolom penting terisi penuh
--   Tidak ada nilai NULL — data sangat bersih
--
-- Query 2 — Rentang Tanggal:
--   tanggal_awal  = 2014-01-03
--   tanggal_akhir = 2017-12-30
--   Tepat 4 tahun data — ideal untuk Time Intelligence
--
-- Query 3 — Nilai Unik:
--   total_customer    = 793
--   total_product     = 1,862
--   total_order       = 5,009
--   total_region      = 4  (East, West, Central, South)
--   total_category    = 3  (Furniture, Office Supplies, Technology)
--   total_sub_category= 17
--   total_state       = 49


-- ------------------------------------------------------------
-- KESIMPULAN
-- ------------------------------------------------------------
-- Data quality check lulus semua pemeriksaan:
-- 1. Tidak ada nilai NULL di seluruh kolom penting
-- 2. Periode data lengkap 4 tahun (2014-2017)
-- 3. Dimensi data terkonfirmasi — 9,994 transaksi,
--    793 customers, 1,862 produk, 4 region, 3 kategori
-- Dataset siap dianalisis tanpa perlu data cleaning lebih lanjut
