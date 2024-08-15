# **E-Commerce Business Analysis using SQL**

**Tools**: PostgreSQL <br>
**Visualization**: Microsoft Excel <br>
**Dataset**: Kaggle (https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce?select=olist_order_items_dataset.csv) 
<br>
<br>
<br>

---

## **Initial Stage: Background and Objective**

Olist is one of the largest department store in Brazilian marketplaces. Olist connects small businesses from all over Brazil to channels without hassle and with a single contract. The merchants are able to sell their products through the Olist Store and ship them directly to the customers using Olist logistics partners.

The dataset was provided by Olist, which contains real-life data and information of 100k orders from 2016 to 2018 made at multiple marketplaces in Brazil. Its features The data contains multiple dimensions: from order status, price, payment and freight performance to customer location, product attributes and reviews written by customers.

This business analysis personal project was done to help Olist identify many important metrics in E-Commerce. The objectives of this project is to gain insight from visualization of:
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

Click to see query:
[QUERY]

Table 2. Top 3 Products by Year
[TABEL]

[VIZ]
Picture 3. Top 3 Products by Year Graph 

In 2017 and 2018, the top 3 most sold products are consistently Health Beauty, Bed Bath Table, and Watches Gifts. Meanwhile, Health Beauty consistently appears as top 3 products from 2016, even though 2016 transaction data starts from September. 

This meant that in Olist, majority of people were looking for Health Beauty, Bed Bath Table, and Watches Gifts.

Click to see query:
[QUERY]

Table 3. Cancelled Order by Year
[TABEL]

[VIZ]
Picture 4. Cancelled Order by Year Graph 

From 2016 to 2017, there is an increase in number of cancelled orders, but the number of revenue lost (total revenue) decreased. This indicated that Average Order Value (Revenue/Order) for cancelled orders decreased, and there may be a decrease in overall Average Order Value. 

To find out why the order was cancelled, a table containing cancellation reasons was created.

Click to see query:
[QUERY]

Table 4. Cancellation Reason by Year
[TABEL]

[VIZ]
Picture 5. Cancellation Reason by Year Graph

From 2016 to 2018, cancellation by customers was the most common reason for cancelled orders. This was caused by either customer tendency to look at cheaper products in another E-Commerce platform/sellers or difficulty in payment procedure.

From 2017 to 2018, cancellation because of Courier/Third Party Logistics increased significantly. For the next year onwards, Olist needs to implement a new system to penalize the Third Party Logistics for cancelled orders in order to decrease order cancellation.

2. Annual Average Order Value
Average Order Value is defined as average amount spent each time a customer places an order. Average Order Value is calculated by dividing total revenue and total order.

Click to see query:
[QUERY]

Table 5. Average Order Value by Year
[TABEL]

[VIZ]
Picture 6. Cancellation Reason by Year Graph

From 2016 to 2017, Average Order Value decreased significantly. This was caused by a lower number of orders in 2016, which attributed from the fact that data in 2016 started in September.

Meanwhile, 2017 to 2018 shows a decrease in Average Order Value despite higher number of order, which was caused by revenue that didn't increase proporsionally with order increase.

Click to see query:
[QUERY]

Table 6. Top 10 Bundled Products
[TABEL]

[VIZ]
Picture 7. Top 10 Bundled Products Graph

Top 10 Bundled Products was created to help Olist increase Average Order Value from product bundling recommendations. Top 3 most bundled products were a combination of home furnitures and living products (bed bath table + furniture decor, furniture decor + housewares). Meanwhile, baby products are mostly combined with toys and/or bed bath table, and Health Beauty products are most commonly purchased with sports leisure and perfumery products.

3. Annual Customer Lifetime Value

Customer Lifetime Value (CLV) helps business to find out how much can a business spend to acquire and retain each customer. Ideally, acquisition cost for new customer should be one third of CLV.

Click to see query:
[QUERY]

Table 7. Annual Customer Lifetime Value
[TABEL]

[VIZ]
Picture 8. Annual Customer Lifetime Value Graph

In 2016, Customer Lifetime Value was much lower than 2017 and 2018 because transaction data started in September. From 2017 to 2018, Customer Lifetime Value was decreased significantly. Based on Customer Lifetime Value in 2018, Olist business maximum spending to acquire and retain customers is 31,38.

To increase Customer Lifetime Value, several things can be done, such as: Optimizing and offering bundling scheme, create loyalty program, build relationship with customers from events or personalized email marketing, and provide reasonable discounts.

--- Stage 3: Summary

* From Annual Revenue analysis, it is concluded that Olist revenue were increasing from 2016 to 2018, with top selling products including Health Beauty, Bed Bath Table, and Watches Gifts. Olist can potentially increase revenue and awareness by creating relevant campaign theme related to the category of top selling products (example: Beauty is You, etc).
* Cancelled Order analysis reveals that most order are cancelled because of cancellation by customer and courier issue. Olist need to adress high cancellation by customers by deep diving into other data (click-through rate, etc.), and implement penalty system for couriers with order cancelled.
* From Annual Average Order Value analysis, average order value continued to decrease. To increase Average Order Value, Olist can implement bundling scheme for top bundled products (Bed Bath Table + Furniture Decor, Baby + Toys, Health Beauty + Perfumery, etc).
* Customer Lifetime Value decreases from 2017 to 2018. Relevant things to increase CLV include offering bundling scheme, create relationship-building activities, and provide discounts.

