--- Average Order Value Query ---

WITH aov_temp AS (
--- Menggabungkan tabel Order dan tabel Order Item untuk mendapatkan keterangan order dan harga per produk
SELECT o.order_id AS order_id, o.order_status AS order_status, o.order_purchase_timestamp AS order_date, oi.price AS order_price
FROM orders o
LEFT JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.order_status NOT IN ('canceled', 'unavailable')
),

aov_final AS (
--- Ekstraksi keterangan tahun pada order_date untuk dihitung per tahun
SELECT EXTRACT(YEAR FROM order_date) AS order_year,

--- Menghitung jumlah total order dan total revenue
COUNT(DISTINCT order_id) AS total_order,
SUM(order_price) AS total_order_value,
	
--- Menghitung Average Order Value
(SUM(order_price)/COUNT(DISTINCT order_id)) AS average_order_value
FROM aov_temp
GROUP BY EXTRACT(YEAR FROM order_date)
ORDER BY EXTRACT(YEAR FROM order_date)
)

--- Memunculkan tabel akhir dan memunculkan Total Order Value dan Average Order Value menjadi 2 angka dibelakang koma
SELECT order_year, total_order, 
ROUND(total_order_value, 2) as total_order_value,
ROUND(average_order_value, 2) as average_order_value
FROM aov_final
;


--- Bundling Recommendation Query ---

WITH aov_bdl_i AS (
--- Membuat tabel keseluruhan berisi keterangan order_id, waktu, status, produk, dan harga produk
SELECT
o.order_id AS order_id, 
o.order_purchase_timestamp AS purchase_date, 
o.order_status AS order_status,
oi.product_id AS product_id, pd.product_category_name AS product_name, oi.price AS order_value
FROM orders o
LEFT JOIN order_items oi ON oi.order_id = o.order_id
LEFT JOIN products pd ON pd.product_id = oi.product_id

--- Filter order yang terkonfirmasi dan keterangan kategori produk tidak null
WHERE o.order_status NOT IN ('unavailable', 'canceled') AND pd.product_category_name IS NOT null
),

aov_bdl_t2 AS (
--- Membuat tabel baru order_id, produk terjual, dan jumlah total barang dalam 1 order 
SELECT
order_id,
product_name,

--- Query jumlah total barang yang dibeli dalam satu order_id menggunakan Partition By 
COUNT(order_id) OVER(PARTITION BY order_id) AS total_item
FROM aov_bdl_i
),

aov_bdl_t3 AS ( 
--- Membuat tabel baru order_id dan menghitung jumlah produk unik dalam satu order
SELECT order_id, COUNT(DISTINCT product_name) AS total_distinct_item
FROM aov_bdl_t2
GROUP BY order_id
),

aov_bdl_t4 AS (
--- Menggabungkan tabel jumlah total  barang dalam 1 order dan tabel perhitungan jumlah produk unik dalam satu order
SELECT abt2.order_id AS order_id, abt2.product_name AS product_name_pt, pt.product_category_name_english AS product_name, 
abt2.total_item AS total_item, abt3.total_distinct_item AS total_distinct_item
FROM aov_bdl_t2 abt2
LEFT JOIN aov_bdl_t3 abt3 ON abt3.order_id = abt2.order_id
	
--- Menggabungkan tabel dengan translasi nama produk
LEFT JOIN product_category_name_translation pt ON pt.product_category_name = abt2.product_name
	
--- Filter order bundling, dengan kondisi jumlah total barang dan jumlah produk unik lebih dari 1
WHERE total_item > 1 AND total_distinct_item > 1
ORDER BY order_id ASC, product_name asc
),

aov_bdl_ft AS (
--- Menggabungkan dua/lebih row produk menjadi 1 row produk berdasarkan order_id
SELECT order_id, ARRAY_AGG(product_name) AS distinct_combined_products FROM aov_bdl_t4 GROUP BY order_id
)

--- Memunculkan tabel akhir dan menghitung total order produk yang dibundling untuk dijadikan rekomendasi
SELECT distinct_combined_products, COUNT(distinct_combined_products) AS total_combined_orders
FROM aov_bdl_ft
GROUP BY distinct_combined_products
ORDER BY total_combined_orders DESC, distinct_combined_products ASC

--- Memunculkan hanya Top 10
LIMIT 10
;




