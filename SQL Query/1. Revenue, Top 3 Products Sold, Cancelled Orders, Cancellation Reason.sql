--- YEARLY ORDER AND REVENUE ---

WITH yearly_rev_table AS (
--- Menggabungkan tabel orders, order_items, dan products untuk mendapatkan keterangan waktu order, status, dan revenue
SELECT 
o.order_id, o.order_status, EXTRACT(YEAR FROM o.order_purchase_timestamp) AS order_year, 
oi.product_id, pr.product_category_name, oi.price
FROM orders o
LEFT JOIN order_items oi ON oi.order_id = o.order_id
LEFT JOIN products pr ON pr.product_id = oi.product_id

--- Filter hanya order yang diproses
WHERE order_status NOT IN ('unavailable', 'canceled')
)

--- Memunculkan tabel akhir Yearly Quantity Sold dan Revenue
SELECT order_year,

--- Menghitung total quantity sold dan total revenue per tahun
COUNT(product_id) as quantity_sold, SUM(price) AS total_revenue

FROM yearly_rev_table
GROUP BY order_year
ORDER BY order_year ASC
;


--- TOP 3 PRODUCTS SOLD YEARLY (BY QUANTITY AND GMV) ---

WITH orders_with_products AS (
--- Menggabungkan tabel orders, order_items, dan products untuk mendapatkan keterangan waktu order, status, dan revenue
SELECT 
o.order_id, o.order_status, EXTRACT(YEAR FROM o.order_purchase_timestamp) AS order_year, 
oi.product_id, pr.product_category_name, oi.price
FROM orders o
LEFT JOIN order_items oi ON oi.order_id = o.order_id
LEFT JOIN products pr ON pr.product_id = oi.product_id
LEFT JOIN product_category_name_translation prt ON pr.product_category_name = prt.product_category_name_english
	
-- Filter hanya order yang diproses
WHERE order_status NOT IN ('unavailable', 'canceled')
),

product_total_order_and_revenue AS (
--- Memunculkan tabel tahun order, nama produk, total produk terjual, total revenue dan ranking revenue
SELECT 
order_year, product_category_name AS product_name, 
	
--- Menghitung total produk terjual dan total revenue
COUNT(product_id) AS total_products_sold, SUM(price) AS total_revenue,
	
--- Memberikan ranking revenue menggunakan function row_number dan Partition By dengan tujuan agar dapat memfilter berdasarkan ranking tertentu saja  
ROW_NUMBER() OVER(PARTITION BY order_year ORDER BY SUM(price) DESC) AS revenue_rank

FROM orders_with_products
GROUP BY order_year, product_name
),

product_total_order_and_revenue_final AS (
--- Menggabungkan tabel akhir dengan terjemahan nama product category name
SELECT 
por.order_year, por.product_name, pt.product_category_name_english AS product, 
por.total_products_sold, por.total_revenue, por.revenue_rank
FROM product_total_order_and_revenue por
LEFT JOIN product_category_name_translation pt ON pt.product_category_name = por.product_name
)

--- Memunculkan tabel akhir
SELECT order_year, product, total_products_sold, total_revenue
FROM product_total_order_and_revenue_final

--- Filter hanya Top 3 Produk yang terjual pada masing-masing tahung
WHERE revenue_rank BETWEEN 1 AND 3
;


--- YEARLY CANCELLED ORDER ---

WITH canceled_order AS (
--- Menggabungkan tabel orders, order_items, dan products untuk mendapatkan keterangan waktu order, status, dan revenue yang canceled
SELECT 
o.order_id, o.order_status, EXTRACT(YEAR FROM o.order_purchase_timestamp) AS order_year, 
oi.product_id, pr.product_category_name, oi.price
FROM orders o
LEFT JOIN order_items oi ON oi.order_id = o.order_id
LEFT JOIN products pr ON pr.product_id = oi.product_id
WHERE order_status = 'canceled'
)

--- Memunculkan tabel akhir
SELECT order_year, 

--- Menghitung total order cancelled dan total revenue yang hilang
COUNT(DISTINCT order_id) AS total_order_cancelled,

SUM(price) AS total_revenue
FROM canceled_order
GROUP BY order_year
ORDER BY order_year
;


--- Cancellation Reasons ---

WITH otdc1 AS (
--- Menggabungkan tabel orders dan order_items untuk mendapatkan detail waktu, status, dan batas tanggal pengiriman
SELECT
o.order_id, o.order_status, o.order_purchase_timestamp, 
oi.shipping_limit_date, o.order_delivered_carrier_date AS delivered_actual, 
	
--- Menghitung perbedaan batas penerimaan di pihak kurir dan tanggal penerimaan di kurir. 
(oi.shipping_limit_date - o.order_delivered_carrier_date) AS delivered_difference,

o.order_estimated_delivery_date AS estimated_arrival, o.order_delivered_customer_date AS actual_arrival,

--- Menghitung perbedaan batas pengiriman ke customer dan tanggal pengiriman ke customer.
(o.order_estimated_delivery_date - o.order_delivered_customer_date) AS arrival_difference
FROM orders o
LEFT JOIN order_items oi ON oi.order_id = o.order_id

--- Filter hanya order yang telah canceled	
WHERE order_status = 'canceled'
),

otdc2 AS (
--- Membuat tabel sebelumnya dengan kolom tambahan untuk melihat penyebab order canceled 
SELECT
order_id, order_status, order_purchase_timestamp, 
shipping_limit_date, delivered_actual, delivered_difference,
estimated_arrival, actual_arrival, arrival_difference,
	
--- Membuat kolom penyebab 1 berdasarkan perbedaan penerimaan di pihak kurir: 
--- Jika perbedaan > 0, maka order dicancel setelah Delivery. 
--- Jika nilai perbedaan NULL, maka order dicancel sebelum Delivery. 
--- Jika perbedaan < 0, maka kemungkinan cancel karena masalah Fulfilment/Product.
			CASE WHEN delivered_difference > '0' THEN 'After Delivery'
					WHEN delivered_difference IS NULL THEN 'Before Delivery'
					ELSE 'Fulfilment/Product Issue'
			END AS cancelation_reason_1,
	
--- Membuat kolom penyebab 2 berdasarkan perbedaan pengiriman ke customer: 
--- Jika perbedaan < 0, maka order dicancel karena masalah Fulfilment, karena pengiriman ke customer melebihi batas pengiriman.
--- Jika perbedaan > 0, maka order dicancel karena masalah Product.
			CASE WHEN arrival_difference < '0' THEN 'Fulfilment'
					WHEN arrival_difference > '0' THEN 'Product'
			END AS cancelation_reason_2,
	
--- Membuat kolom penyebab 3 berdasarkan kolom penyebab 1 dan 2:
--- Jika perbedaan delivered_difference < 0 dan perbedaan arrival_difference = null, maka order dicancel karena kesalahan Seller dan Courier (kurir).
--- Jika perbedaan delivered_difference > 0 dan perbedaan arrival_difference = null, maka order dicancel karena kesalahan kurir.
--- Jika tidak ada perbedaan pada delivered_difference arrival_difference, maka order dicancel customer karena tidak ada pengiriman ke kurir.
			CASE WHEN (delivered_difference < '0' AND arrival_difference IS null) THEN 'Seller & Courier Fault'
					WHEN (delivered_difference > '0' AND arrival_difference IS null) THEN 'Courier'
					WHEN (delivered_difference IS null AND arrival_difference IS null) THEN 'Cancel by Customer'
					ELSE null
			END AS cancelation_reason_3
FROM otdc1
),

cancel_orders_and_reason_final AS (
--- Mengekstraksi tahun dari order_purchase_timestamp
SELECT
order_id, order_status, order_purchase_timestamp, EXTRACT(YEAR FROM order_purchase_timestamp) AS order_year,
shipping_limit_date, delivered_actual, delivered_difference,
estimated_arrival, actual_arrival, arrival_difference,
cancelation_reason_1, cancelation_reason_2, cancelation_reason_3,
	
--- Menggabungkan ketiga kolom penyebab cancel untuk mengetahui penyebab spesifik order dicancel
CONCAT(cancelation_reason_1, ' ', '-', ' ', cancelation_reason_2, ' ', '-', ' ', cancelation_reason_3) AS cancel_reason
FROM otdc2
)

--- Memunculkan tabel akhir
SELECT
order_year,
cancel_reason AS reason_of_cancellation,

--- Menghitung jumlah order yang dicancel
COUNT(order_id) AS total_order_cancelled

FROM cancel_orders_and_reason_final
GROUP BY order_year, cancel_reason
ORDER BY order_year ASC, total_order_cancelled DESC
;




