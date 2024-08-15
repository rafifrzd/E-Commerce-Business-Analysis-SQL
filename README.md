# **E-Commerce Business Analysis using SQL**

* **Tools**: PostgreSQL 
* **Visualization**: Microsoft Excel 
* **Dataset**: Kaggle (https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce?select=olist_order_items_dataset.csv) 
<br>
<br>

---

## **Initial Stage: Background and Objective**

Olist is one of the largest department store in Brazilian marketplaces. Olist connects small businesses from all over Brazil to channels without hassle and with a single contract. The merchants are able to sell their products through the Olist Store and ship them directly to the customers using Olist logistics partners.

The dataset was provided by Olist, which contains real-life data and information of 100k orders from 2016 to 2018 made at multiple marketplaces in Brazil. The data contains multiple dimensions: from order status, price, payment and freight performance to customer location, product attributes and reviews written by customers.

This business analysis personal project was done to help Olist explore important business metrics in E-Commerce. The objectives of this project is to gain insight from visualization of:
1. Annual Revenue and Cancelled Order
2. Annual Average Order Value
3. Annual Customer Lifetime Value

## **Stage 1: Data Preparation**

The Olist E-Commerce dataset has 99441 rows containing order information from 2016 to 2018. Additional information such as product, customer, payment type, and review are contained in separate tables.

### **Create Database and ERD**
The steps to create Database and ERD contains as follows:
1. Create database and table using 'CREATE TABLE' function on pgAdmin
2. Import csv data to each table in database
3. Assign Primary Key and Foreign Key using 'ALTER TABLE' function
4. Generate ERD or Entity Relationship Diagram

<details>
  <summary>Click to see query:</summary>

  ```sql
--- CREATE TABLE QUERY ---

CREATE TABLE customers (
customer_id VARCHAR,
customer_unique_id VARCHAR,
customer_zip_code_prefix VARCHAR,
customer_city VARCHAR,
customer_state VARCHAR
);

CREATE TABLE order_items (
order_id VARCHAR, 
order_item_id INT,
product_id VARCHAR,
seller_id VARCHAR,
shipping_limit_date TIMESTAMP,
price DECIMAL,
freight_value DECIMAL
);

CREATE TABLE order_payments (
order_id VARCHAR,
payment_sequential INT,
payment_type VARCHAR,
payment_installments INT,
payment_value DECIMAL
);

CREATE TABLE order_reviews (
review_id VARCHAR,
order_id VARCHAR,
reviews_score INT,
review_comment_title VARCHAR ,
review_comment_message VARCHAR,
review_creation_date TIMESTAMP,
review_answer_timestamp TIMESTAMP
);

CREATE TABLE orders (
order_id VARCHAR,
customer_id VARCHAR,
order_status VARCHAR,
order_purchase_timestamp TIMESTAMP,
order_approved_at TIMESTAMP,
order_delivered_carrier_date TIMESTAMP,
order_delivered_customer_date TIMESTAMP,
order_estimated_delivery_date TIMESTAMP
);

CREATE TABLE products (
product_id VARCHAR,
product_category_name VARCHAR,
product_name_lenght INT,
product_description_lenght INT,
product_photos_qty INT,
product_weight_g INT,
product_length_cm INT,
product_height_cm INT,
product_width_cm INT
);

CREATE TABLE sellers (
seller_id VARCHAR ,
seller_zip_code_prefix VARCHAR,
seller_city VARCHAR,
seller_state VARCHAR
);

CREATE TABLE product_category_name_translation (
product_category_name VARCHAR,
product_category_name_english VARCHAR
);


--- ASSIGN PRIMARY KEY & FOREIGN KEY ---
--- Primary Key
ALTER TABLE customers
ADD CONSTRAINT customers_pk 
PRIMARY KEY(customer_id);

ALTER TABLE orders
ADD CONSTRAINT orders_pk
PRIMARY KEY (order_id);

ALTER TABLE products
ADD CONSTRAINT products_pk
PRIMARY KEY (product_id);

ALTER TABLE sellers
ADD CONSTRAINT sellers_pk
PRIMARY KEY (seller_id);

--- Foreign Key
ALTER TABLE order_items
ADD FOREIGN KEY (order_id)
REFERENCES orders;

ALTER TABLE order_items
ADD FOREIGN KEY (product_id)
REFERENCES products;

ALTER TABLE order_items
ADD FOREIGN KEY (seller_id)
REFERENCES sellers;

ALTER TABLE order_payments
ADD FOREIGN KEY (order_id)
REFERENCES orders;

ALTER TABLE order_reviews
ADD FOREIGN KEY (order_id)
REFERENCES orders;

ALTER TABLE orders
ADD FOREIGN KEY (customer_id)
REFERENCES customers;

  ```
</details>

**ERD Result:**<br>

<p align="center">
  <kbd><img src="Asset/0.%20ERD.jpeg" width=800px> </kbd> <br>
  Picture 1. Entity Relationship Diagram
</p>
<br>
<br>

---

## **Stage 2: Data Analysis**

### **1. Annual Revenue and Cancelled Orders** 

E-Commerce main business metrics consist of Revenue and Cancelled Orders. The insight that are provided are as follows: <br>
<br>
**Revenue**: Annual Revenue & Top 3 Most Sold Products <br>
**Cancelled Orders**: Annual Cancelled Order & Order Cancellation Reasons <br>

<details>
  <summary>Click to see query:</summary>

  ```sql
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
```
</details>

<p align="center">
  <kbd><img src="Asset/1.%20Revenue%20by%20Year.jpeg" width=600px> </kbd> <br>
  Table 1. Annual Revenue
</p>

<br>
<p align="center">
  <kbd><img src="Asset/1.%20Revenue%20by%20Year%20-%20V.png" width=600px> </kbd> <br>
  Picture 2. Annual Revenue Graph
</p>

<br>

Overall, Olist revenue was increasing from 2016 to 2018. There is a significant increase from 2016 to 2017 because of 2016 transaction data started from September.

<br>

<details>
  <summary>Click to see query:</summary>

  ```sql
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
```
</details>

<p align="center">
  <kbd><img src="Asset/2.%20Top%203%20Products%20by%20Year.jpeg" width=600px> </kbd> <br>
  Table 2. Top 3 Products by Year
</p>

<br>
<p align="center">
  <kbd><img src="Asset/2.%20Top%203%20Products%20by%20Year%20-%20V.png" width=600px> </kbd> <br>
  Picture 3. Top 3 Products by Year Graph 
</p>

<br>

In 2017 and 2018, the top 3 most sold products are consistently Health Beauty, Bed Bath Table, and Watches Gifts. Meanwhile, Health Beauty consistently appears as top 3 products from 2016, even though 2016 transaction data starts from September. 

This meant that in Olist, majority of people were looking for Health Beauty, Bed Bath Table, and Watches Gifts.

<br>

<details>
  <summary>Click to see query:</summary>

  ```sql
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
```
</details>

<p align="center">
  <kbd><img src="Asset/3.%20Cancelled%20Orders%20by%20Year.jpeg" width=600px> </kbd> <br>
  Table 3. Cancelled Order by Year
</p>

<br>
<p align="center">
  <kbd><img src="Asset/3.%20Cancelled%20Orders%20by%20Year%20-%20V.png" width=600px> </kbd> <br>
  Picture 4. Cancelled Order by Year Graph  
</p>

<br>

From 2016 to 2017, there is an increase in number of cancelled orders, but the number of revenue lost (total revenue) decreased. This indicated that Average Order Value (Revenue/Order) for cancelled orders decreased, and there may be a decrease in overall Average Order Value. 

To find out why the order was cancelled, a table containing cancellation reasons was created.

<br>

<details>
  <summary>Click to see query:</summary>

  ```sql
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
```
</details>

<p align="center">
  <kbd><img src="Asset/4.%20Cancellation%20Reasons.jpeg" width=600px> </kbd> <br>
  Table 4. Cancellation Reason by Year
</p>

<br>
<p align="center">
  <kbd><img src="Asset/4.%20Cancellation%20Reasons%20-%20V.png" width=600px> </kbd> <br>
  Picture 5. Cancellation Reason by Year Graph  
</p>

<br>

From 2016 to 2018, cancellation by customers was the most common reason for cancelled orders. This was caused by either customer tendency to look at cheaper products in another E-Commerce platform/sellers or difficulty in payment procedure.

From 2017 to 2018, cancellation because of Courier/Third Party Logistics increased significantly. For the next year onwards, Olist needs to implement a new system to penalize the Third Party Logistics for cancelled orders in order to decrease order cancellation.

<br>

### **2. Annual Average Order Value**
Average Order Value is defined as average amount spent each time a customer places an order. Average Order Value is calculated by dividing total revenue and total order.

<br>

<details>
  <summary>Click to see query:</summary>

  ```sql
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
```
</details>

<p align="center">
  <kbd><img src="Asset/5.%20Average%20Order%20Value%20by%20Year.jpeg" width=600px> </kbd> <br>
  Table 5. Average Order Value by Year
</p>

<br>
<p align="center">
  <kbd><img src="Asset/5.%20Average%20Order%20Value%20by%20Year%20-%20V.png" width=600px> </kbd> <br>
  Picture 6. Average Order Value by Year Graph
</p>

<br>

From 2016 to 2017, Average Order Value decreased significantly. This was caused by a lower number of orders in 2016, which attributed from the fact that data in 2016 started in September.

Meanwhile, 2017 to 2018 shows a decrease in Average Order Value despite higher number of order, which was caused by revenue that didn't increase proporsionally with order increase.

<br>

<details>
  <summary>Click to see query:</summary>

  ```sql
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
```
</details>

<p align="center">
  <kbd><img src="Asset/6.%20Top%2010%20Bundled%20Products.jpeg" width=600px> </kbd> <br>
  Table 6. Top 10 Bundled Products
</p>

<br>
<p align="center">
  <kbd><img src="Asset/6.%20Top%2010%20Bundled%20Products%20-%20V.png" width=600px> </kbd> <br>
  Picture 7. Top 10 Bundled Products Graph
</p>

<br>

Top 10 Bundled Products was created to help Olist increase Average Order Value from product bundling recommendations. Top 3 most bundled products were a combination of home furnitures and living products (bed bath table + furniture decor, furniture decor + housewares). Meanwhile, baby products are mostly combined with toys and/or bed bath table, and Health Beauty products are most commonly purchased with sports leisure and perfumery products.

### **3. Annual Customer Lifetime Value**

Customer Lifetime Value (CLV) helps business to find out how much can a business spend to acquire and retain each customer. Ideally, acquisition cost for new customer should be one third of CLV.

<br>

<details>
  <summary>Click to see query:</summary>

  ```sql
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
```
</details>

<p align="center">
  <kbd><img src="Asset/7.%20Customer%20Lifetime%20Value.jpeg" width=600px> </kbd> <br>
  Table 7. Annual Customer Lifetime Value
</p>

<br>
<p align="center">
  <kbd><img src="Asset/7.%20Customer%20Lifetime%20Value%20-%20V.png" width=600px> </kbd> <br>
  Picture 8. Annual Customer Lifetime Value Graph
</p>

<br>

In 2016, Customer Lifetime Value was much lower than 2017 and 2018 because transaction data started in September. From 2017 to 2018, Customer Lifetime Value was decreased significantly. Based on Customer Lifetime Value in 2018, Olist business maximum spending to acquire and retain customers is 31,38.

To increase Customer Lifetime Value, several things can be done, such as: Optimizing and offering bundling scheme, create loyalty program, build relationship with customers from events or personalized email marketing, and provide reasonable discounts.

<br>
<br>

---

## **Stage 3: Summary**

* From Annual Revenue analysis, it is concluded that **Olist revenue were increasing from 2016 to 2018, with top selling products including Health Beauty, Bed Bath Table, and Watches Gifts**. Olist can potentially **increase revenue and awareness by creating relevant campaign theme** related to the category of top selling products (example: Beauty is You, etc).
* Cancelled Order analysis reveals that **most order are cancelled because of cancellation by customer and courier issue**. Olist need to adress high cancellation by customers by deep diving into other data (click-through rate, etc.), and **implement penalty system for couriers with order cancelled**.
* From Annual Average Order Value analysis, **average order value continued to decrease**. To increase Average Order Value, Olist can **implement bundling scheme for top bundled products (Bed Bath Table + Furniture Decor, Baby + Toys, Health Beauty + Perfumery, etc)**.
* **Customer Lifetime Value decreases from 2017 to 2018**. Relevant things to increase CLV include offering bundling scheme, create relationship-building activities, and provide discounts.

