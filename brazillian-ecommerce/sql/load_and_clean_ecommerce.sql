CREATE TABLE state_mapping (
    state_abbrev VARCHAR(2) PRIMARY KEY,
    state_full_name VARCHAR(50)
);
INSERT INTO
    state_mapping (state_abbrev, state_full_name)
VALUES
    ('AC', 'Acre'),
    ('AL', 'Alagoas'),
    ('AP', 'Amapa'),
    ('AM', 'Amazonas'),
    ('BA', 'Bahia'),
    ('CE', 'Ceara'),
    ('DF', 'Distrito Federal'),
    ('ES', 'Espirito Santo'),
    ('GO', 'Goias'),
    ('MA', 'Maranhao'),
    ('MT', 'Mato Grosso'),
    ('MS', 'Mato Grosso do Sul'),
    ('MG', 'Minas Gerais'),
    ('PA', 'Para'),
    ('PB', 'Paraiba'),
    ('PR', 'Parana'),
    ('PE', 'Pernambuco'),
    ('PI', 'Piaui'),
    ('RJ', 'Rio de Janeiro'),
    ('RN', 'Rio Grande do Norte'),
    ('RS', 'Rio Grande do Sul'),
    ('RO', 'Rondonia'),
    ('RR', 'Roraima'),
    ('SC', 'Santa Catarina'),
    ('SP', 'Sao Paulo'),
    ('SE', 'Sergipe'),
    ('TO', 'Tocantins');
    -- Add the state_full_name column to sellers and customers
ALTER TABLE
    customers
ADD
    COLUMN customer_state_full_name VARCHAR(50);
UPDATE
    customers c
SET
    customer_state_full_name = sm.state_full_name
FROM
    state_mapping sm
WHERE
    c.customer_state = sm.state_abbrev;
ALTER TABLE
    sellers
ADD
    COLUMN seller_state_full_name VARCHAR(50);
UPDATE
    sellers s
SET
    seller_state_full_name = sm.state_full_name
FROM
    state_mapping sm
WHERE
    s.seller_state = sm.state_abbrev;
-- CREATE OR REPLACE VIEW categories AS (SELECT * FROM "DB_ECOMMERCE"."PUBLIC"."CATEGORIES");
    -- CREATE OR REPLACE VIEW closed_deals AS (SELECT * FROM "DB_ECOMMERCE"."PUBLIC"."CLOSED_DEALS");
    -- CREATE OR REPLACE VIEW customers AS (SELECT * FROM "DB_ECOMMERCE"."PUBLIC"."CUSTOMERS");
    -- CREATE OR REPLACE VIEW items AS (SELECT * FROM "DB_ECOMMERCE"."PUBLIC"."ITEMS");
    -- CREATE OR REPLACE VIEW mqls AS (SELECT * FROM "DB_ECOMMERCE"."PUBLIC"."MQL_DF");
    -- CREATE OR REPLACE VIEW orders AS (SELECT * FROM "DB_ECOMMERCE"."PUBLIC"."ORDERS");
    -- CREATE OR REPLACE VIEW payments AS (SELECT * FROM "DB_ECOMMERCE"."PUBLIC"."PAYMENTS");
    -- CREATE OR REPLACE VIEW products AS (SELECT * FROM "DB_ECOMMERCE"."PUBLIC"."PRODUCTS");
    -- CREATE OR REPLACE VIEW reviews AS (SELECT * FROM "DB_ECOMMERCE"."PUBLIC"."REVIEWS");
    -- CREATE OR REPLACE VIEW sellers AS (SELECT * FROM "DB_ECOMMERCE"."PUBLIC"."SELLERS");


    
-- 119,143 rows
CREATE OR REPLACE VIEW one_big_table AS
    SELECT
        -- orders table
        o.order_id AS order_id,
        o.customer_id AS customer_id,
        o.order_status AS order_status,
        o.order_purchase_timestamp::date AS order_purchase_timestamp,
        o.order_approved_at::date AS order_approved_at,
        o.order_delivered_carrier_date::date AS order_delivered_carrier_date,
        o.order_delivered_customer_date::date AS order_delivered_customer_date,
        o.order_estimated_delivery_date::date AS order_estimated_delivery_date, 
-- FEATURE ENGINEERING
        
        -- order classification
        (
            CASE
                WHEN order_status IN ('unavailable', 'canceled') THEN 'lost sales'
                ELSE 'completed sales'
            END
        ) AS order_class,
        
        -- reviews table
        r.review_id AS review_id,
        r.review_score AS review_score,
        r.review_creation_date::date AS review_creation_date,
        
        -- customers table
        c.customer_unique_id AS customer_unique_id,
        c.customer_state AS customer_state,
        c.customer_state_full_name AS customer_state_full_name,
        
        -- payments table
        pa.payment_sequential AS payment_sequential,
        pa.payment_type AS payment_type,
        pa.payment_installments::int AS payment_installments,
        pa.payment_value AS payment_value,
        
        -- items table
        i.order_item_id AS order_item_id, 
        i.shipping_limit_date::date AS shipping_limit_date,
        i.price AS item_price,
        i.freight_value AS freight_value,
        
        -- sellers table
        s.seller_id AS seller_id,
        s.seller_state AS seller_state,
        s.seller_state_full_name AS seller_state_full_name,
        
        -- products table
        p.product_name_lenght AS product_name_length,
        p.product_description_lenght AS product_description_length,
        p.product_photos_qty::int AS product_photos_qty,
        p.product_weight_g AS product_weight_g,
        p.product_length_cm AS product_length_cm,
        p.product_height_cm AS product_height_cm,
        p.product_width_cm AS product_width_cm,
        
        -- categories table
        cat.product_category_name_english AS product_category_name_english,
        
        -- closed_deals table
        cd.mql_id AS mql_id,
        cd.sdr_id AS sdr_id,
        cd.sr_id AS sr_id,
        cd.won_date::date AS won_date,
        cd.business_segment AS business_segment,
        cd.lead_type AS lead_type,
        cd.lead_behaviour_profile AS lead_behaviour_profile,
        cd.business_type AS business_type,
        cd.declared_monthly_revenue AS declared_monthly_revenue,
        
        -- mql_df table
        mql.first_contact_date AS first_contact_date,
        mql.landing_page_id AS landing_page_id,
        mql.origin AS origin
        
    FROM
        DB_ECOMMERCE.PUBLIC.orders o
        LEFT JOIN DB_ECOMMERCE.PUBLIC.reviews r USING (order_id)
        LEFT JOIN DB_ECOMMERCE.PUBLIC.payments pa USING (order_id)
        INNER JOIN DB_ECOMMERCE.PUBLIC.customers c USING (customer_id) -- we only want customers who made orders
        LEFT JOIN DB_ECOMMERCE.PUBLIC.items i USING (order_id)
        LEFT JOIN DB_ECOMMERCE.PUBLIC.sellers s USING (seller_id)
        LEFT JOIN DB_ECOMMERCE.PUBLIC.products p USING (product_id)
        LEFT JOIN DB_ECOMMERCE.PUBLIC.categories cat USING (product_category_name)
        LEFT JOIN DB_ECOMMERCE.PUBLIC.closed_deals cd USING (seller_id)
        LEFT JOIN DB_ECOMMERCE.PUBLIC.mql_df mql USING (mql_id)
;



SELECT
    *
FROM
    one_big_table
LIMIT 5;

    -- WHERE mql_id IS NOT NULL
    -- GROUP BY seller_id;
    -- WHERE order_id = '00143d0f86d6fbd9f9b38ab440ac16f5'
    -- WHERE seller_id = 'cac876b37d3abcd6bd76caca30277996';
    
SELECT
    s.seller_id,
    cd.won_date,
    m.mql_id
FROM
    sellers s
    LEFT JOIN closed_deals cd USING (seller_id)
    INNER JOIN mql_df m USING (mql_id)
WHERE
    seller_id = 'a17f621c590ea0fab3d5d883e1630ec6';
ALTER TABLE
    sellers
ADD
    PRIMARY KEY (seller_id);
ALTER TABLE
    closed_deals
ADD
    PRIMARY KEY (seller_id, mql_id);
-- 380 sellers acquired through marketing activities and identifiable in the sellers table
SELECT
    *
FROM
    closed_deals cd
WHERE
    EXISTS (
        SELECT
            *
        FROM
            sellers s
        WHERE
            s.seller_id = cd.seller_id
    );
    -- 462 sellers acquired from marketing but not identifiable in the sellers table (3095 sellers in total)
SELECT
    *
FROM
    closed_deals cd
WHERE
    NOT EXISTS (
        SELECT
            *
        FROM
            sellers s
        WHERE
            s.seller_id = cd.seller_id
    );


SELECT order_status, order_purchased_time_stamp, order_approved_at, order_delivered_carrier_date, order_delivered_customer_date
FROM one_big_table
WHERE order_status = 'delivered';

CREATE OR REPLACE VIEW one_big_table AS (
SELECT
        -- orders table
        o.order_id AS order_id,
        o.order_status AS order_status,
        o.order_purchase_timestamp::date AS order_purchase_timestamp,
        o.order_approved_at::date AS order_approved_at,
        o.order_delivered_carrier_date::date AS order_delivered_carrier_date,
        o.order_delivered_customer_date::date AS order_delivered_customer_date,
        o.order_estimated_delivery_date::date AS order_estimated_delivery_date, 
-- FEATURE ENGINEERING
        
        -- order classification
        (CASE
            WHEN order_status IN ('unavailable', 'canceled') THEN 'lost sales'
            ELSE 'completed sales'
        END) AS order_class,
        
        -- reviews table
        r.review_id AS review_id,
        r.review_score AS review_score,
        r.review_creation_date::date AS review_creation_date,
        
        -- customers table
        c.customer_unique_id AS customer_id,
        c.customer_state AS customer_state,
        c.customer_state_full_name AS customer_state_full_name,
        
        -- payments table
        pa.payment_sequential AS payment_sequential,
        pa.payment_type AS payment_type,
        pa.payment_installments::int AS payment_installments,
        pa.payment_value AS payment_value,
        
        -- items table
        i.order_item_id AS order_item_id, 
        i.product_id,
        i.shipping_limit_date::date AS shipping_limit_date,
        i.price AS item_price,
        i.freight_value AS freight_value,
        
        -- sellers table
        s.seller_id AS seller_id,
        s.seller_state AS seller_state,
        s.seller_state_full_name AS seller_state_full_name,
        
        -- products table
        p.product_name_lenght AS product_name_length,
        p.product_description_lenght AS product_description_length,
        p.product_photos_qty::int AS product_photos_qty,
        p.product_weight_g AS product_weight_g,
        p.product_length_cm AS product_length_cm,
        p.product_height_cm AS product_height_cm,
        p.product_width_cm AS product_width_cm,
        
        -- categories table
        cat.product_category_name_english AS product_category_name_english,
        
        -- closed_deals table
        cd.sdr_id AS sdr_id,
        cd.sr_id AS sr_id,
        cd.won_date::date AS won_date,
        cd.business_segment AS business_segment,
        cd.lead_type AS lead_type,
        cd.lead_behaviour_profile AS lead_behaviour_profile,
        cd.business_type AS business_type,
        cd.declared_monthly_revenue AS declared_monthly_revenue,
        
        -- mql_df table
        mql.first_contact_date AS first_contact_date,
        mql.landing_page_id AS landing_page_id,
        mql.origin AS origin,

        -- delivery-related metrics
        (CASE WHEN order_approved_at IS NOT NULL AND order_purchase_timestamp IS NOT NULL THEN DATEDIFF('day', order_purchase_timestamp, order_approved_at) ELSE NULL END) AS payment_processing_day,
        (CASE WHEN order_approved_at IS NOT NULL AND order_delivered_carrier_date IS NOT NULL THEN DATEDIFF('day', order_approved_at, order_delivered_carrier_date) ELSE NULL END) AS order_prep_day,
        (CASE WHEN order_delivered_carrier_date IS NOT NULL AND order_delivered_customer_date IS NOT NULL THEN DATEDIFF('day', order_delivered_carrier_date, order_delivered_customer_date) ELSE NULL END) AS customer_shipping_day,

        -- customer classification based on how many orders they have made on our platform
        (CASE 
            WHEN COUNT(DISTINCT order_id) OVER (PARTITION BY customer_unique_id) > 2 THEN 'repeat customer'
            WHEN COUNT(DISTINCT order_id) OVER (PARTITION BY customer_unique_id) > 1 THEN 'return customer'
        ELSE 'one-time buyer' 
    END) AS customer_class,

        -- customer growth calculation
        MIN(order_purchase_timestamp) OVER (PARTITION BY customer_id) AS first_purchase_date, 
        COUNT(DISTINCT order_id) OVER (PARTITION BY customer_unique_id) AS num_orders_made,

        -- lead convert rate
        ROUND( (SELECT COUNT(*) FROM closed_deals) / (SELECT COUNT(*) FROM mql_df)*100::numeric, 2) as seller_acquisition_rate
    FROM
        DB_ECOMMERCE.PUBLIC.orders o
        LEFT JOIN DB_ECOMMERCE.PUBLIC.reviews r USING (order_id)
        LEFT JOIN DB_ECOMMERCE.PUBLIC.payments pa USING (order_id)
        INNER JOIN DB_ECOMMERCE.PUBLIC.customers c USING (customer_id) -- we only want customers who made orders
        LEFT JOIN DB_ECOMMERCE.PUBLIC.items i USING (order_id)
        LEFT JOIN DB_ECOMMERCE.PUBLIC.sellers s USING (seller_id)
        LEFT JOIN DB_ECOMMERCE.PUBLIC.products p USING (product_id)
        LEFT JOIN DB_ECOMMERCE.PUBLIC.categories cat USING (product_category_name)
        LEFT JOIN DB_ECOMMERCE.PUBLIC.closed_deals cd USING (seller_id)
        -- error
        LEFT JOIN DB_ECOMMERCE.PUBLIC.mql_df mql ON cd.mql_id = mql.mql_id 
);

SELECT *
FROM one_big_table;