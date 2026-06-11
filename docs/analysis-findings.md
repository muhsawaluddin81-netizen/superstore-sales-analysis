# Analysis Findings — Superstore Sales Analysis

Dokumen ini memuat tujuh pertanyaan bisnis (Business Questions / BQ) yang menjadi tulang punggung analisis, lengkap dengan query, hasil, temuan, dan rekomendasi. Seluruh angka dihitung dari data Superstore 2014-2017 menggunakan PostgreSQL.

Benang merah seluruh analisis: **margin yang rapuh dan ketimpangan geografis** — pertumbuhan revenue tidak selalu diikuti profitabilitas, dan akar masalah berulang adalah **kebijakan diskon di atas 20%**.

---

## BQ #1 — Tren Revenue vs Profit (2014-2017)

**Pertanyaan:** Apakah pertumbuhan revenue diikuti pertumbuhan profitabilitas?

| Tahun | Total Revenue | Total Profit | Profit Margin |
|-------|--------------:|-------------:|--------------:|
| 2014  | 484,247       | 49,543       | 10.23%        |
| 2015  | 470,532       | 61,618       | 13.10%        |
| 2016  | 609,205       | 81,795       | 13.43%        |
| 2017  | 733,215       | 93,439       | 12.74%        |

**Temuan:** Revenue tumbuh 51.41% dari 2014 ke 2017, tetapi profit margin tidak stabil — memuncak di 2016 (13.43%) lalu turun di 2017 (12.74%) justru saat revenue tertinggi. Pertumbuhan revenue tidak berbanding lurus dengan profitabilitas; ada inefisiensi yang perlu diinvestigasi.

---

## BQ #2 — Sub-kategori yang Merugi

**Pertanyaan:** Sub-kategori dan kategori mana yang menekan profitabilitas?

**Temuan:**
- **Kelompok kritis (margin < 0%):** Tables (-8.56%), Bookcases (-3.02%), Supplies (-2.55%) — total kerugian -22,387. Tables paling mengkhawatirkan karena revenue besar (206,965) namun tetap merugi → indikasi masalah struktural pricing/cost.
- **Kelompok mengkhawatirkan (margin 0-10%):** Machines (1.79%), Chairs (8.10%), Storage (9.51%). Machines prioritas karena margin nyaris nol.
- **Kategori:** Furniture paling bermasalah — revenue 741,999 tapi profit hanya 18,451 (margin 2.49%); 2 dari 4 sub-kategorinya merugi. Technology paling efisien — quantity paling sedikit tapi profit absolut tertinggi (145,454; margin 17.40%).

**Rekomendasi:** Audit pricing/biaya Tables, Bookcases, Supplies. Evaluasi strategi Furniture. Jadikan model pricing Technology sebagai benchmark.

---

## BQ #3 — Korelasi Discount vs Profit Margin

**Pertanyaan:** Di titik diskon berapa profitabilitas mulai negatif?

| Discount | Jumlah Transaksi | Profit Margin |
|---------:|-----------------:|--------------:|
| 0.00     | 4,798            | 29.51%        |
| 0.20     | 3,657            | 11.82%        |
| 0.30     | 227              | -10.05%       |
| 0.40     | 206              | -19.81%       |
| 0.70     | 418              | -98.66%       |
| 0.80     | 300              | -180.03%      |

*(tabel diringkas; data lengkap di queries.sql)*

**Temuan:**
- **Korelasi negatif terbukti** — makin besar diskon, makin kecil (lalu negatif) margin.
- **Threshold kritis di 20%.** Pada 20% margin masih 11.82% (di atas rata-rata retail 5-10% per NYU Stern). Pada 30% margin sudah -10.05%.
- **Skala kerusakan:** 1,393 transaksi (13.94% dari total) berdiskon di atas 20% dan merugi.

**Rekomendasi:** Tetapkan batas maksimal diskon 20%. Bangun sistem approval untuk diskon di atas 20%.

---

## BQ #4 — Performa Regional

**Pertanyaan:** Region/state mana yang under-perform, dan apa penyebabnya?

**Temuan:**
- **10 state merugi**, tersebar di semua region. Terparah: Ohio (-21.69%), Colorado (-20.33%), Tennessee (-17.42%), Illinois (-15.73%), Texas (-15.12%).
- **Central paling konsisten under-perform** — fluktuatif tiap tahun (0.52% → 11.39% → 13.50% → 5.13%). South turun drastis di 2017 (18.91% → 7.20%).
- **Penyebab teridentifikasi — diskon.** Rata-rata diskon vs margin per region:

| Region  | Avg Discount | Profit Margin |
|---------|-------------:|--------------:|
| Central | 24.04%       | 7.92%         |
| South   | 14.73%       | 11.93%        |
| East    | 14.54%       | 13.48%        |
| West    | 10.93%       | 14.94%        |

Central satu-satunya region yang rata-rata diskonnya melewati threshold kritis 20% → bukti kuat diskon berlebihan adalah penyebab utama under-perform.

**Rekomendasi:** Terapkan batas diskon 20% ketat di Central (prioritas utama). Investigasi 10 state merugi. Monitor South sebagai early warning.

---

## BQ #5 — Perilaku Produk per Wilayah

**Pertanyaan:** Apakah kategori yang sama berperilaku beda di wilayah berbeda?

**Temuan:** Ya — kategori sama menghasilkan margin sangat berbeda tergantung wilayah, dan konsisten berkorelasi dengan tingkat diskon.

- **Furniture** (paling sensitif): Central (diskon 29.74% → margin -1.75%, satu-satunya merugi) vs South (diskon 12.15% → margin 5.77%).
- **Office Supplies** (perbedaan paling ekstrem): Central (25.27% → 5.32%) vs West (9.34% → 23.82%) — selisih 18.5 poin.
- **Technology** (paling stabil): semua region positif, tidak ada yang berdiskon di atas 20%.

**Rekomendasi:** Batas diskon 20% di Central, khususnya Furniture & Office Supplies. Jadikan West benchmark kebijakan diskon. Replikasi pengelolaan Technology ke kategori lain.

---

## BQ #6 — Estimasi Pemulihan Profit jika Sub-kategori Rugi Di-reprice

**Pertanyaan:** Berapa profit yang bisa dipulihkan jika diskon sub-kategori rugi dibatasi 20%?

> **Asumsi penting:** simulasi mengasumsikan harga asli = `sales / (quantity * (1 - discount))` dan **volume penjualan tetap**. Dalam praktik, menurunkan diskon dapat menurunkan unit terjual (*price elasticity*), sehingga angka *recovery* adalah **batas atas teoretis**, bukan jaminan.

| Sub-kategori | Margin Aktual | Margin Baru | Potential Recovery |
|--------------|--------------:|------------:|-------------------:|
| Bookcases    | -38.88%       | +1.38%      | 11,653.53          |
| Tables       | -34.13%       | -1.00%      | 29,500.43          |
| Supplies     | —             | —           | (tidak ada diskon >20%) |

**Temuan:**
- **Bookcases** — kerugian murni karena diskon; bisa diselamatkan (jadi +1.38%), meski masih perlu evaluasi pricing menyeluruh.
- **Tables** — diskon memperparah, tapi masih -1.00% setelah dibatasi → ada masalah struktural lebih dalam (harga jual/cost).
- **Supplies** — tidak pernah berdiskon di atas 20%; kerugiannya struktural, butuh cost audit, bukan pembatasan diskon.

**Total potential recovery (Bookcases + Tables) ≈ 41,154** — angka inilah yang menjadi callout "~$41K" di dashboard (Profitability Deep Dive).

**Rekomendasi:** Batas diskon 20% untuk Bookcases & Tables. Evaluasi pricing menyeluruh Tables. Cost audit Supplies.

---

## BQ #7 — Potensi Nilai Tambah jika Region Under-perform Capai Margin Nasional

**Pertanyaan:** Berapa tambahan profit jika Central & South mencapai margin nasional 12.47%?

> **Asumsi penting:** simulasi mengasumsikan peningkatan margin **tidak mengubah volume penjualan** (demand konstan). Angka *potential gain* menggambarkan potensi maksimum.

| Region  | Total Sales | Profit Aktual | Profit Seharusnya | Potential Gain |
|---------|------------:|--------------:|------------------:|---------------:|
| Central | 501,239.89  | 39,706.36     | 62,504.61         | 22,798.25      |
| South   | 391,721.91  | 46,749.43     | 48,847.72         | 2,098.29       |

**Temuan:**
- **Central** — gap terbesar (4.55 poin di bawah nasional), potensi terbesar (~22,798). Penyebab sudah jelas dari BQ #3-4: rata-rata diskon 24.04% melewati threshold 20%.
- **South** — gap kecil (0.54 poin), potensi terbatas (~2,098). Tapi penurunan drastis 2017 adalah sinyal peringatan.
- **Total potential gain ≈ 24,897** — setara 26.64% dari profit aktual 2017. Angka inilah callout "~$25K" di dashboard (Regional Performance).

**Rekomendasi:** Batas diskon 20% di Central segera (potential gain tertinggi). Monitor South ketat. Jadikan East & West benchmark.

---

## Kesimpulan Lintas-BQ

Satu akar masalah berulang di hampir semua temuan: **diskon di atas 20%**.
- BQ #3 menetapkan threshold-nya (20%).
- BQ #4 & #5 menunjukkan Central melanggarnya (diskon 24%+).
- BQ #6 & #7 mengukur dampak finansialnya (~$41K + ~$25K potensi perbaikan).

Rekomendasi tunggal yang paling berdampak: **terapkan dan tegakkan batas maksimal diskon 20%, dengan prioritas region Central.**
