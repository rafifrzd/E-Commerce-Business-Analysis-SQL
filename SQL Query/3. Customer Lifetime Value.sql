-- Customer Lifetime Value ---

WITH cltv_a_table AS (
--- Menggabungkan tabel orders, customers, dan order_items untuk mendapatkan keterangan order, customer, dan harga produk
    SELECT
        o.order_id, 
        o.order_status, 
        o.customer_id, 
        cu.customer_unique_id, 
        oi.product_id, 
        oi.price, 
        o.order_purchase_timestamp,
	
--- Mengekstraksi tahun dari kolom order_purchase_timestamp
        EXTRACT(year FROM order_purchase_timestamp) AS order_year

    FROM orders o
    LEFT JOIN customers cu ON cu.customer_id = o.customer_id
    LEFT JOIN order_items oi ON oi.order_id = o.order_id
	
--- Filter order yang tidak cancel
    WHERE order_status NOT IN ('unavailable', 'canceled')
),

cltv_init_1 AS (
--- Membuat tabel untuk menghitung average order value dan average customer lifespan
    SELECT 
        order_year, 
        SUM(price) AS total_revenue, 
        CAST(COUNT(DISTINCT order_id) AS DECIMAL) AS total_order,
        CAST(COUNT(DISTINCT customer_unique_id) AS DECIMAL) AS total_customer,
	
--- Menghitung average order value
        (SUM(price)/COUNT(DISTINCT order_id)) AS average_order_value,
	
--- Menghitung average customer lifespan
        ((EXTRACT(day FROM (MIN(order_purchase_timestamp) - MAX(order_purchase_timestamp)))) * (-1.0)) AS average_customer_lifespan
    
	FROM cltv_a_table
    GROUP BY order_year
),

cltv_init_2 AS (
--- Membuat tabel untuk menghitung average order frequency dan average customer value
    SELECT 
        order_year, 
        total_revenue, 
        total_order, 
        total_customer,
        ROUND(average_order_value, 2) AS average_order_value, 
	
--- Menghitung average order frequency
        (total_order/total_customer) AS average_order_frequency,
	
--- Menghitung average customer value
        (average_order_value * (total_order/total_customer)) AS average_customer_value,
	
        (average_customer_lifespan/365) AS average_customer_lifespan
    FROM cltv_init_1
),

cltv_final AS (
--- Membuat tabel akhir untuk menghitung customer lifetime value
	SELECT 
        order_year, 
        total_revenue, 
        total_order, 
        total_customer,
        average_order_value, 
        ROUND(average_order_frequency, 2) AS average_order_frequency, 
        ROUND(average_customer_value, 2) AS average_customer_value, 
        ROUND(average_customer_lifespan, 2) AS average_customer_lifespan,
	
--- Menghitung customer lifetime value
        ROUND((average_customer_lifespan * average_customer_value), 2) AS customer_lifetime_value
    FROM cltv_init_2
)

--- Memunculkan tabel akhir
SELECT	order_year, customer_lifetime_value
FROM cltv_final;




