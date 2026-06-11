BQ #1 — REVENUE VS PROFIT TREND (2014-2017)
Query:
sql
SELECT 
    EXTRACT(YEAR FROM order_date)         AS year,
    SUM(sales)                            AS total_revenue,
    SUM(profit)                           AS total_profit,
    ROUND((SUM(profit)/SUM(sales)*100),2) AS profit_margin_pct
FROM portofolio.superstore_sales
GROUP BY year
ORDER BY year ASC;
Hasil:
Tahun │ Total Revenue  │ Total Profit  │ Profit Margin
──────┼────────────────┼───────────────┼──────────────
2014  │ 484,247        │ 49,543        │ 10.23%
2015  │ 470,532        │ 61,618        │ 13.10%
2016  │ 609,205        │ 81,795        │ 13.43%
2017  │ 733,215        │ 93,439        │ 12.74%
Insight: Revenue Superstore tumbuh 55.83% dari 2014 ke 2017. Namun profit margin tidak stabil mencapai puncaknya di 2016 (13.43%) kemudian turun di 2017 (12.74%) meskipun revenue mencapai nilai tertinggi. Ini mengindikasikan adanya inefisiensi yang perlu diinvestigasi lebih dalam pertumbuhan revenue tidak berbanding lurus dengan pertumbuhan profitabilitas.

    
BQ #2 — SUB-KATEGORI YANG MERUGI
Query:
sql
SELECT 
    sub_category,
    category,
    SUM(quantity)                         AS total_quantity,
    SUM(sales)                            AS total_revenue,
    SUM(profit)                           AS total_profit,
    ROUND((SUM(profit)/SUM(sales)*100),2) AS profit_margin_pct
FROM portofolio.superstore_sales
GROUP BY sub_category, category
ORDER BY profit_margin_pct ASC;
Query Pendukung — Per Kategori:
sql
SELECT 
    category,
    SUM(quantity)                         AS total_quantity,
    ROUND((SUM(profit)/SUM(sales)*100),2) AS profit_margin_pct,
    SUM(profit)                           AS total_profit,
    SUM(sales)                            AS total_revenue
FROM portofolio.superstore_sales
GROUP BY category
ORDER BY profit_margin_pct ASC;
Insight:
Kelompok Kritis (margin < 0%): Terdapat 3 sub-kategori dengan profit negatif  Tables (-8.56%), Bookcases (-3.02%), dan Supplies (-2.55%) menghasilkan total kerugian -22,387. Tables adalah yang paling mengkhawatirkan karena revenue-nya besar (206,965) namun tetap merugi, mengindikasikan masalah struktural pada pricing atau cost management.
Kelompok Mengkhawatirkan (margin 0-10%): Machines (1.79%), Chairs (8.10%), dan Storage (9.51%) berada di zona berbahaya. Machines adalah prioritas utama karena marginnya hampir nol kenaikan biaya sekecil apapun akan langsung mendorong Machines ke zona negatif.
Temuan Kategori: Furniture adalah kategori paling bermasalah revenue 741,999 tapi profit hanya 18,451 dengan margin 2.49%. Dari 4 sub-kategori Furniture, 2 sudah merugi (Tables, Bookcases) dan 1 mengkhawatirkan (Chairs). Technology justru paling efisien quantity paling sedikit (6,939) tapi profit absolut tertinggi (145,454) dengan margin 17.40%, membuktikan bahwa nilai per unit dan efisiensi pricing lebih menentukan daripada volume penjualan.
Rekomendasi:
•	Jangka pendek: Audit pricing dan struktur biaya Tables, Bookcases, dan Supplies untuk mengidentifikasi apakah kerugian disebabkan diskon berlebihan, harga jual terlalu rendah, atau biaya terlalu tinggi
•	Jangka menengah: Evaluasi strategi Furniture secara keseluruhan apakah kategori ini masih layak dipertahankan dengan struktur biaya saat ini
•	Jangka panjang: Jadikan model pricing Technology sebagai benchmark untuk kategori lain karena terbukti paling efisien menghasilkan profit

    
BQ #3 — KORELASI DISCOUNT VS PROFIT MARGIN
Query Utama:
sql
SELECT 
    discount,
    COUNT(*)                              AS number_of_transactions,
    ROUND((SUM(profit)/SUM(sales)*100),2) AS profit_margin_pct
FROM portofolio.superstore_sales
GROUP BY discount
ORDER BY discount ASC;
Query Pendukung — Verifikasi Transaksi Merugi:
sql
SELECT 
    COUNT(*) AS transaksi_merugi,
    ROUND((COUNT(*) * 100.0 / 
        (SELECT COUNT(*) FROM portofolio.superstore_sales)
    ), 2) AS pct_dari_total
FROM portofolio.superstore_sales
WHERE discount >= 0.30;
Hasil Query Utama:
Discount │ Jumlah Transaksi │ Profit Margin
─────────┼──────────────────┼──────────────
0.00     │ 4,798            │  29.51%
0.10     │    94            │  16.61%
0.15     │    52            │   5.15%
0.20     │ 3,657            │  11.82%
0.30     │   227            │ -10.05%
0.32     │    27            │ -16.50%
0.40     │   206            │ -19.81%
0.45     │    11            │ -45.45%
0.50     │    66            │ -34.80%
0.60     │   138            │ -89.46%
0.70     │   418            │ -98.66%
0.80     │   300            │-180.03%

Hasil Query Pendukung:
Transaksi Merugi │ % dari Total
─────────────────┼─────────────
1,393            │ 13.94%

Insight Final:
Temuan 1 — Korelasi Terbukti: Data membuktikan hubungan negatif yang konsisten antara discount dan profit margin  semakin besar discount yang diberikan, semakin kecil profit margin yang dihasilkan bahkan berubah menjadi negatif.
Temuan 2 — Threshold Kritis di 20%: Titik kritis berada antara discount 20% dan 30%. Di angka 20% profit margin masih 11.82%  masih di atas rata-rata industri retail 5-10% berdasarkan data NYU Stern School of Business. Di angka 30% profit sudah negatif (-10.05%). Perusahaan sebaiknya menetapkan batas maksimal discount 20%.
Temuan 3 — Skala Kerusakan: Terdapat 1,393 transaksi (13.94% dari total transaksi) dengan discount di atas 20% yang menghasilkan kerugian. Yang paling parah:
•	418 transaksi discount 70% → margin -98.66%
•	300 transaksi discount 80% → margin -180.03%
•	206 transaksi discount 40% → margin -19.81%
Rekomendasi:
•	Jangka pendek: Tetapkan kebijakan batas maksimal discount 20% di semua kategori produk
•	Jangka menengah: Identifikasi produk dan region mana yang paling sering diberikan diskon berlebihan
•	Jangka panjang: Bangun sistem approval untuk discount di atas 20% sehingga setiap pemberian diskon besar harus melalui persetujuan manajemen

    
BQ #4 — REGIONAL PERFORMANCE
Query 1 — Performa per State dan Region
sql
SELECT 
    state,
    region, 
    ROUND((SUM(profit)/SUM(sales)*100),2) AS profit_margin_pct
FROM portofolio.superstore_sales
GROUP BY state, region
ORDER BY profit_margin_pct ASC;

Query 2 — Performa per Region Keseluruhan
sql
SELECT 
    region, 
    ROUND((SUM(profit)/SUM(sales)*100),2) AS profit_margin_pct
FROM portofolio.superstore_sales
GROUP BY region
ORDER BY profit_margin_pct ASC;

Query 3 — Konsistensi Performa Region per Tahun
sql
SELECT 
    region,
    EXTRACT(YEAR FROM order_date) AS year,
    ROUND((SUM(profit)/SUM(sales)*100),2) AS profit_margin_pct
FROM portofolio.superstore_sales
GROUP BY region, year
ORDER BY region, year ASC;

Query 4 — Rata-rata Diskon per Region
sql
SELECT 
    region,
    ROUND(AVG(discount)*100, 2)           AS avg_discount_pct,
    ROUND((SUM(profit)/SUM(sales)*100),2) AS profit_margin_pct
FROM portofolio.superstore_sales
GROUP BY region
ORDER BY avg_discount_pct DESC;

Query Pendukung — Verifikasi Jumlah State Merugi
sql
SELECT COUNT(*) AS state_merugi
FROM (
    SELECT 
        state, 
        ROUND((SUM(profit)/SUM(sales)*100),2) AS profit_margin_pct
    FROM portofolio.superstore_sales
    GROUP BY state
) AS state_summary
WHERE profit_margin_pct < 0;

Insight Final
Temuan 1 — 10 State Merugi: Terdapat 10 state dengan profit margin negatif. Yang paling parah:
Ohio           → East    → -21.69%
Colorado       → West    → -20.33%
Tennessee      → South   → -17.42%
Illinois       → Central → -15.73%
Texas          → Central → -15.12%
North Carolina → South   → -13.47%
Pennsylvania   → East    → -13.35%
Arizona        → West    →  -9.72%
Oregon         → West    →  -6.83%
Florida        → South   →  -3.80%
State yang merugi tersebar di semua region artinya masalah ini bukan semata masalah regional tapi ada faktor lain yang perlu diinvestigasi lebih dalam di masing-masing state.
Temuan 2 — Central Paling Konsisten Under-Perform: Performa region Central per tahun menunjukkan ketidakstabilan yang mengkhawatirkan:
2014 →  0.52% (hampir nol, jauh di bawah rata-rata Superstore ~12%)
2015 → 11.39% (membaik tapi masih terendah dibanding region lain)
2016 → 13.50% (membaik signifikan bahkan melampaui East)
2017 →  5.13% (turun drastis 8.37 poin)
South juga mengalami penurunan drastis di 2017 dari 18.91% menjadi 7.20% — turun 11.71 poin dalam satu tahun.
Temuan 3 — Penyebab Under-Perform Central Teridentifikasi: Data avg discount per region mengungkap korelasi yang kuat:
Central → avg discount 24.04% → profit margin  7.92%
South   → avg discount 14.73% → profit margin 11.93%
East    → avg discount 14.54% → profit margin 13.48%
West    → avg discount 10.93% → profit margin 14.94%
Pola ini konsisten dengan temuan BQ #3  semakin tinggi rata-rata diskon, semakin rendah profit margin. Central adalah satu-satunya region yang rata-rata diskonnya melewati threshold kritis 20% yang sudah kita tetapkan di BQ #3. Ini adalah bukti kuat bahwa kebijakan diskon berlebihan di Central menjadi penyebab utama under-perform region ini.
Rekomendasi:
•	Jangka pendek: Terapkan kebijakan batas maksimal diskon 20% secara ketat di region Central. region ini adalah prioritas utama karena avg discountnya sudah melewati threshold kritis
•	Jangka menengah: Investigasi lebih dalam 10 state yang merugi khususnya Ohio, Colorado, Tennessee, Illinois, dan Texas untuk mengidentifikasi apakah penyebabnya sama yaitu diskon berlebihan atau ada faktor lain
•	Jangka panjang: Monitor performa South yang mengalami penurunan drastis di 2017 untuk memastikan ini bukan tanda awal masalah yang sama dengan Central

    
BQ #5 — PERILAKU PRODUK PER WILAYAH
Query 1 — Profit Margin per Category per Region
sql
SELECT 
    region, 
    category,
    ROUND((SUM(profit)/SUM(sales)*100),2) AS profit_margin_pct
FROM portofolio.superstore_sales
GROUP BY region, category
ORDER BY profit_margin_pct DESC;

Query 2 — Avg Discount per Category per Region
sql
SELECT 
    region,
    category,
    ROUND(AVG(discount)*100, 2)           AS avg_discount_pct,
    ROUND((SUM(profit)/SUM(sales)*100),2) AS profit_margin_pct
FROM portofolio.superstore_sales
GROUP BY region, category
ORDER BY category, avg_discount_pct DESC;

Hasil Query 1
Region   │ Category        │ Profit Margin
─────────┼─────────────────┼──────────────
West     │ Office Supplies │ 23.82%
East     │ Office Supplies │ 19.96%
Central  │ Technology      │ 19.77%
East     │ Technology      │ 17.91%
West     │ Technology      │ 17.58%
South    │ Office Supplies │ 15.91%
South    │ Technology      │ 13.44%
South    │ Furniture       │  5.77%
Central  │ Office Supplies │  5.32%
West     │ Furniture       │  4.55%
East     │ Furniture       │  1.46%
Central  │ Furniture       │ -1.75%
________________________________________
Hasil Query 2
Region   │ Category        │ Avg Discount │ Profit Margin
─────────┼─────────────────┼──────────────┼──────────────
Central  │ Furniture       │ 29.74%       │ -1.75%
East     │ Furniture       │ 15.41%       │  1.46%
West     │ Furniture       │ 13.14%       │  4.55%
South    │ Furniture       │ 12.15%       │  5.77%
Central  │ Office Supplies │ 25.27%       │  5.32%
South    │ Office Supplies │ 16.74%       │ 15.91%
East     │ Office Supplies │ 14.29%       │ 19.96%
West     │ Office Supplies │  9.34%       │ 23.82%
East     │ Technology      │ 14.34%       │ 17.91%
West     │ Technology      │ 13.39%       │ 17.58%
Central  │ Technology      │ 13.31%       │ 19.77%
South    │ Technology      │ 10.78%       │ 13.44%
________________________________________
Insight Final
Temuan Utama — Produk yang Sama Berperilaku Berbeda di Wilayah Berbeda: Ya, terbukti dari data bahwa kategori produk yang sama menghasilkan profit margin yang sangat berbeda tergantung wilayahnya. Perbedaan ini secara konsisten berkorelasi dengan tingkat diskon yang diberikan di wilayah tersebut.
Temuan 1 — Furniture: Furniture adalah kategori yang paling sensitif terhadap perbedaan wilayah:
Central → discount 29.74% → margin -1.75%  ← satu-satunya yang merugi
East    → discount 15.41% → margin  1.46%
West    → discount 13.14% → margin  4.55%
South   → discount 12.15% → margin  5.77%
Central adalah satu-satunya region di mana Furniture merugi dan ini terjadi karena rata-rata diskon yang diberikan (29.74%) jauh melewati threshold kritis 20% yang sudah kita tetapkan di BQ #3. Di South dengan diskon hanya 12.15%, Furniture masih menghasilkan margin positif 5.77%.
Temuan 2 — Office Supplies: Office Supplies menunjukkan perbedaan performa paling ekstrem antar wilayah:
Central → discount 25.27% → margin  5.32%   ← terendah
South   → discount 16.74% → margin 15.91%
East    → discount 14.29% → margin 19.96%
West    → discount  9.34% → margin 23.82%   ← tertinggi
Perbedaan margin antara Central (5.32%) dan West (23.82%) mencapai 18.5 poin sangat signifikan. West yang memberikan diskon paling rendah (9.34%) justru menghasilkan margin tertinggi. Ini membuktikan bahwa kebijakan diskon adalah faktor penentu utama performa Office Supplies.
Temuan 3 — Technology: Technology adalah kategori paling stabil antar wilayah:
East    → discount 14.34% → margin 17.91%
West    → discount 13.39% → margin 17.58%
Central → discount 13.31% → margin 19.77%
South   → discount 10.78% → margin 13.44%
Tidak ada region yang memberikan diskon di atas threshold 20% untuk Technology hasilnya margin semua region masih positif dan relatif stabil. Ini membuktikan bahwa Technology adalah kategori yang dikelola dengan lebih baik dari sisi kebijakan diskon.
Koneksi dengan BQ Sebelumnya:
•	BQ #2: Furniture terbukti sebagai kategori paling bermasalah diperkuat di sini dengan bukti bahwa Central + Furniture adalah kombinasi terburuk (-1.75%)
•	BQ #3: Korelasi discount vs profit margin terbukti kembali di semua kategori dan semua region, semakin tinggi diskon semakin rendah margin
•	BQ #4: Under-perform Central terjawab secara lebih spesifik Central memberikan diskon berlebihan di dua kategori sekaligus (Furniture 29.74% dan Office Supplies 25.27%) yang keduanya melewati threshold 20%
Rekomendasi:
•	Jangka pendek: Terapkan batas maksimal diskon 20% secara ketat di Central khususnya untuk kategori Furniture dan Office Supplies yang diskonnya paling berlebihan
•	Jangka menengah: Jadikan West sebagai benchmark kebijakan diskon West memberikan diskon paling rendah untuk Office Supplies (9.34%) dan menghasilkan margin tertinggi (23.82%)
•	Jangka panjang: Replikasi model pengelolaan Technology ke kategori lain. Technology terbukti stabil di semua region karena kebijakan diskon yang lebih terkontrol di bawah threshold 20%


BQ #6 — ESTIMASI PENINGKATAN PROFIT JIKA SUB-KATEGORI RUGI DI-REPRICE
CATATAN ASUMSI: 
Simulasi ini mengasumsikan sales = harga_asli * quantity * (1 - discount), sehingga harga asli dipulihkan dengan: sales / (quantity * (1 - discount)). Asumsi divalidasi lewat query verifikasi di bawah; hasilnya konsisten. Simulasi juga mengasumsikan volume penjualan tetap (lihat catatan akhir).
LANGKAH 1: Verifikasi asumsi harga 
SELECT
    product_id,
    discount,
    quantity,
    sales,
    ROUND((sales / quantity)::numeric, 2)                          AS harga_per_unit_apa_adanya,
    ROUND((sales / (quantity * (1 - discount)))::numeric, 2)       AS harga_asli_hasil_reverse
FROM portofolio.superstore_sales
WHERE product_id IN (
    SELECT product_id
    FROM portofolio.superstore_sales
    GROUP BY product_id
    HAVING COUNT(DISTINCT discount) > 1
)
ORDER BY product_id, discount
LIMIT 40;
Query:
sql
SELECT
    sub_category,
    ROUND(SUM(sales - profit), 2)                                                AS total_cost,
    ROUND(SUM(sales), 2)                                                         AS total_sales_aktual,
    ROUND(SUM(profit), 2)                                                        AS total_profit_aktual,
    ROUND((SUM(profit) / SUM(sales) * 100), 2)                                   AS profit_margin_aktual_pct,
    ROUND(SUM((sales / (quantity * (1 - discount))) * quantity * 0.80), 2)       AS total_sales_baru,
    ROUND(SUM(((sales / (quantity * (1 - discount))) * quantity * 0.80)
        - (sales - profit)), 2)                                                  AS total_profit_baru,
    ROUND((
        SUM(((sales / (quantity * (1 - discount))) * quantity * 0.80)
            - (sales - profit))
        / SUM((sales / (quantity * (1 - discount))) * quantity * 0.80)
        * 100
    ), 2)                                                                        AS profit_margin_baru_pct,
    ROUND(SUM(((sales / (quantity * (1 - discount))) * quantity * 0.80)
        - (sales - profit)) - SUM(profit), 2)                                   AS potential_recovery
FROM portofolio.superstore_sales
WHERE sub_category IN ('Tables', 'Bookcases', 'Supplies')
  AND discount > 0.20
GROUP BY sub_category;
Hasil:
Sub-kategori │ Profit Aktual │ Margin Aktual │ Profit Baru  │ Margin Baru │ Potential Recovery
─────────────┼───────────────┼───────────────┼──────────────┼─────────────┼───────────────────
Bookcases    │ -11,097.76    │ -38.88%       │ 555.77       │ 1.38%       │ 11,653.53
Tables       │ -30,698.22    │ -34.13%       │ -1,197.79    │ -1.00%      │ 29,500.43
Supplies     │ tidak muncul  │ —             │ —            │ —           │ —
Insight:
Temuan 1 — Bookcases: Masalah Diskon, Bisa Diselamatkan Bookcases memiliki profit margin aktual -38.88% pada transaksi dengan diskon di atas 20%. Setelah simulasi pembatasan diskon maksimal 20%, profit margin berubah menjadi +1.38% dengan potential recovery sebesar 11,653.53. Artinya kerugian Bookcases pada segmen transaksi bermasalah ini sepenuhnya disebabkan oleh diskon berlebihan bukan masalah struktural. Namun perlu dicatat, margin 1.38% masih jauh di bawah rata-rata industri retail 5-10% berdasarkan data NYU Stern School of Business, sehingga pembatasan diskon saja belum cukup perlu diikuti dengan evaluasi pricing secara menyeluruh.
Temuan 2 — Tables: Diskon Memperparah, Tapi Masalah Lebih Dalam Tables memiliki profit margin aktual -34.13% pada transaksi diskon di atas 20%. Setelah simulasi pembatasan diskon maksimal 20%, margin hanya membaik menjadi -1.00% dengan potential recovery 29,500.43. Fakta bahwa Tables masih merugi meskipun diskon sudah dibatasi 20% membuktikan bahwa diskon berlebihan hanya salah satu penyebab ada masalah struktural lain seperti harga jual terlalu rendah atau cost of goods terlalu tinggi yang harus diinvestigasi lebih dalam.
Temuan 3 — Supplies: Bukan Masalah Diskon Supplies tidak muncul dalam hasil query karena diskon tertinggi yang pernah diberikan hanya 20% tidak ada satu pun transaksi yang melewati threshold kritis. Ini membuktikan bahwa kerugian Supplies bukan disebabkan diskon berlebihan, melainkan kemungkinan besar disebabkan oleh cost struktur yang tidak efisien harga pokok terlalu tinggi relatif terhadap harga jual yang ada. Supplies membutuhkan cost audit dan repricing yang berbeda pendekatannya dari dua sub-kategori lainnya.
Rekomendasi:
•	Jangka pendek: Terapkan batas maksimal diskon 20% untuk Bookcases dan Tables potential recovery gabungan mencapai 41,153.96 jika kebijakan ini dijalankan konsisten. Simulasi ini mengasumsikan volume penjualan tidak berubah setelah pembatasan diskon. Dalam praktik, mengurangi diskon dapat menurunkan jumlah unit terjual (price elasticity), sehingga potential recovery 41,153.96 adalah batas atas teoretis, bukan jaminan.
•	Jangka menengah: Lakukan evaluasi pricing menyeluruh untuk Tables pembatasan diskon saja tidak cukup karena masalahnya lebih dari sekadar diskon
•	Jangka panjang: Lakukan cost audit untuk Supplies investigasi apakah harga pokok bisa ditekan atau harga jual perlu dinaikkan untuk mencapai margin yang sehat di atas 5%

    
BQ#7 — POTENSI NILAI TAMBAH JIKA REGION UNDER-PERFORM MENCAPAI RATA-RATA PROFIT MARGIN NASIONAL
Query Pendukung — Profit Margin Nasional:
sql
SELECT ROUND(SUM(profit)/SUM(sales)*100, 2) AS profit_margin_nasional
FROM portofolio.superstore_sales;
Hasil: 12.47%
Query Utama:
sql
SELECT
    region,
    ROUND(SUM(sales), 2)                                AS total_sales,
    ROUND(SUM(profit), 2)                               AS total_profit_aktual,
    ROUND(SUM(sales) * 0.1247, 2)                       AS profit_seharusnya,
    ROUND((SUM(sales) * 0.1247) - SUM(profit), 2)       AS potential_gain
FROM portofolio.superstore_sales
WHERE region IN ('Central', 'South')
GROUP BY region;
Hasil:
Region   │ Total Sales    │ Profit Aktual │ Profit Seharusnya │ Potential Gain
─────────┼────────────────┼───────────────┼───────────────────┼───────────────
Central  │ 501,239.89     │ 39,706.36     │ 62,504.61         │ 22,798.25
South    │ 391,721.91     │ 46,749.43     │ 48,847.72         │ 2,098.29
Insight:
Konteks — Rata-Rata Profit Margin Nasional Profit margin nasional Superstore secara keseluruhan adalah 12.47% dihitung dari total profit dibagi total sales seluruh transaksi 2014-2017. Angka ini menjadi benchmark simulasi BQ #7. Dari 4 region, dua berada di bawah benchmark ini:
Central → 7.92%  ← under-perform, gap 4.55 poin
South   → 11.93% ← under-perform, gap 0.54 poin
East    → 13.48% ← di atas rata-rata nasional
West    → 14.94% ← di atas rata-rata nasional
Temuan 1 — Central: Gap Terbesar, Potensi Terbesar Central memiliki profit margin aktual 7.92%  gap 4.55 poin di bawah rata-rata nasional. Dengan total sales 501,239.89, jika Central bisa mencapai margin nasional 12.47%, profit yang seharusnya dihasilkan adalah 62,504.61 atau 22,798.25 lebih tinggi dari profit aktual saat ini. Ini adalah potential gain terbesar di antara kedua region karena gap margin-nya paling lebar. Penyebab utamanya sudah teridentifikasi sejak BQ #3 dan BQ #4 Central adalah satu-satunya region yang rata-rata diskonnya melewati threshold kritis 20% (24.04%), yang secara langsung menekan profit margin ke angka terendah di antara semua region.
Temuan 2 — South: Gap Kecil, Potensi Terbatas South memiliki profit margin aktual 11.93% hanya 0.54 poin di bawah rata-rata nasional. Dengan total sales 391,721.91, potential gain-nya hanya 2,098.29 jauh lebih kecil dibanding Central. Ini wajar karena gap margin-nya memang kecil. Namun perlu diwaspadai dari BQ #4 kita sudah tahu bahwa South mengalami penurunan drastis di 2017 dari 18.91% menjadi 7.20%, turun 11.71 poin dalam satu tahun. Jika tren ini berlanjut, South berpotensi menjadi masalah serius di tahun berikutnya.
Temuan 3 — Total Potential Gain Gabungan Jika kedua region berhasil mencapai rata-rata nasional, total potential gain yang bisa diraih adalah:
Central + South = 22,798.25 + 2,098.29 = 24,896.54
Jika Central dan South berhasil mencapai rata-rata profit margin nasional (12.47%), total potential gain yang bisa diraih adalah 24,896.54 setara dengan peningkatan profit sebesar 26.64% dari total profit aktual tahun 2017 sebesar 93,439.27. Simulasi mengasumsikan peningkatan margin tidak memengaruhi volume penjualan. Angka potential gain 24,896.54 menggambarkan potensi maksimum dengan asumsi demand konstan.
Koneksi dengan BQ Sebelumnya:
•	BQ #3: Diskon berlebihan di atas 20% terbukti menjadi akar masalah Central avg discount 24.04% langsung menekan margin ke 7.92%
•	BQ #4: Central adalah region paling konsisten under-perform masalahnya bukan fluktuasi tahunan tapi kebijakan diskon sistemik
•	BQ #5: Central memberikan diskon berlebihan di dua kategori sekaligus Furniture (29.74%) dan Office Supplies (25.27%) keduanya melewati threshold 20%
Rekomendasi:
•	Jangka pendek: Terapkan kebijakan batas maksimal diskon 20% di Central secara ketat dan segera ini adalah intervensi dengan potential gain tertinggi (22,798.25) dan akar masalahnya sudah jelas teridentifikasi
•	Jangka menengah: Monitor South secara ketat walaupun potential gain-nya kecil saat ini, penurunan drastis di 2017 adalah early warning signal yang tidak boleh diabaikan
•	Jangka panjang: Jadikan East dan West sebagai benchmark kebijakan diskon untuk seluruh region keduanya konsisten di atas rata-rata nasional karena mengelola diskon di bawah threshold 20%

