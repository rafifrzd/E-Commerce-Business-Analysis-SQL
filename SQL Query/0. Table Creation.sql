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



