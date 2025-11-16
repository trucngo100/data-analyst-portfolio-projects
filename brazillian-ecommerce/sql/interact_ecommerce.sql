SELECT
    *
FROM
    one_big_table
LIMIT
    5;
-- WHERE mql_id IS NOT NULL
    -- GROUP BY seller_id;
    -- WHERE order_id = '00143d0f86d6fbd9f9b38ab440ac16f5'
    -- WHERE seller_id = 'cac876b37d3abcd6bd76caca30277996';

SELECT
    order_status,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date
FROM
    one_big_table
WHERE
    order_status = 'delivered';


/* CHECK FOR NULL VALUES */

SELECT
    round(avg(CASE WHEN order_purchase_timestamp IS NULL THEN 1 ELSE 0 END), 2) as pct_purchase_timestamp_nulls, 
    round(avg(CASE WHEN order_approved_at IS NULL THEN 1 ELSE 0 END), 2) as pct_approved_at_nulls, 
    round(avg(CASE WHEN order_delivered_carrier_date IS NULL THEN 1 ELSE 0 END), 2) as pct_delivered_carrier_date_nulls, -- 2%
    round(avg(CASE WHEN order_delivered_customer_date IS NULL THEN 1 ELSE 0 END), 2) as pct_delivered_customer_date_nulls, -- 3 %
    round(avg(CASE WHEN payment_processing_day IS NULL THEN 1 ELSE 0 END), 2) as pct_payment_processing_day_nulls,
    round(avg(CASE WHEN order_prep_day IS NULL THEN 1 ELSE 0 END), 2) as pct_order_prep_day_nulls, -- 2%
    round(avg(CASE WHEN customer_shipping_day IS NULL THEN 1 ELSE 0 END), 2) as pct_customer_shipping_day_nulls -- 3%
FROM one_big_table;
-- leave the null values as they are

/* CHECK FOR THE AVERAGE TIME NEEDED FOR EACH PROCESS */
-- INSIGHT: the average days taken give a good insight into how we can improve our delivery service to improve customer's satisfaction 
-- INSIGHT 2: was the avg_customer_shipping days a direct result from avg_order_prep day
-- INSIGHT 3: was the avg_customer_shipping the reason that leads to low review score 
SELECT
    round(avg(CASE WHEN payment_processing_day IS NOT NULL THEN payment_processing_day ELSE 0 END), 2) as avg_payment_processing_days, -- 0.52
    round(avg(CASE WHEN order_prep_day IS NOT NULL THEN order_prep_day ELSE 0 END), 2) as avg_order_prep, -- 2.71 days
    round(avg(CASE WHEN customer_shipping_day IS NOT NULL THEN customer_shipping_day ELSE 0 END), 2) as avg_customer_shipping -- 8.89 days
FROM one_big_table;


-- does the missing dates in order_delivered_carrier_date has anything to do with the order_status
-- most of the time they are missing because customer cancelled or we were out of stock
-- the other errors must be by system because the order has already got delivered 
SELECT 
    order_class,
    order_status,
    COUNT(*)
FROM one_big_table
WHERE order_delivered_carrier_date IS NULL
GROUP BY order_class, order_status
ORDER BY COUNT(*);

SELECT 
    order_class,
    order_status,
    COUNT(*)
FROM one_big_table
WHERE order_delivered_carrier_date IS NULL AND order_delivered_customer_date IS NULL
GROUP BY order_class, order_status
ORDER BY COUNT(*);

/* CHECK IF THERE IS ANY REPEAT CUSTOMER 
but the pct of return customers and repeat customers is really small
=> INSIGHT: we must discover the reasons why we do not have a high percentage of return customers
=> Hypothesis: delivery days, low satisfaction scores (who return give a higher satisfaction score), who return buy more but in less amount, who are one-time buyers can do improvise purchases
~ discover the relationship between buyers and product's category */
SELECT 
    ROUND(AVG(CASE WHEN customer_class = 'return customer' THEN 1 ELSE 0 END), 2) AS pct_return_customer,
    ROUND(AVG(CASE WHEN customer_class = 'repeat customer' THEN 1 ELSE 0 END), 2) AS pct_repeat_customer,
    ROUND(AVG(CASE WHEN customer_class = 'one-time buyer' THEN 1 ELSE 0 END), 2) AS pct_one_time_buyer
FROM one_big_table

SELECT
    MIN(order_purchase_timestamp), MAX(order_purchase_timestamp),
    MIN(order_approved_at), MAX(order_approved_at),
    MIN(order_delivered_carrier_date), MAX(order_delivered_carrier_date),
    MIN(order_delivered_customer_date), MAX(order_delivered_customer_date)
FROM
    one_big_table


/* Customer acquisition growth */
WITH first_purchase_dates AS (
    SELECT
        customer_id, 
        MIN(order_purchase_timestamp) OVER (PARTITION BY customer_id) AS first_purchase_date, 
        COUNT(DISTINCT order_id) OVER (PARTITION BY customer_id) AS num_orders_made
    FROM orders
    ORDER BY customer_id
)
SELECT
    f.customer_id, o.order_id, f.first_purchase_date,
    o.order_purchase_timestamp, 
FROM one_big_table o 
LEFT JOIN first_purchase_dates f USING (customer_id)
WHERE f.num_orders_made > 4
ORDER BY customer_id, order_purchase_timestamp ASC;
-- FLAG: first_purchase_date = order_purchase_timestamp : IsNewCustomer

/* seller acquisition rate: 10.53% */
SELECT
    ROUND( (SELECT COUNT(*) FROM closed_deals) / (SELECT COUNT(*) FROM mql_df)*100::numeric, 2) as seller_acquisition_rate

SELECT
   (CASE WHEN cd.mql_id IS NOT NULL THEN 1 ELSE 0 END)::int AS mql_success_flag
FROM closed_deals cd
RIGHT JOIN mql_df m 
    ON cd.mql_id = m.mql_id
ORDER BY cd.mql_id NULLS FIRST;    


SELECT
    AVG(mql_success_flag) 
FROM one_big_table

SELECT seller_acquisition_rate
FROM one_big_table