

-- Q1. Which cuisines receive the most orders?
select "cuisine_type",
count(*) as total_orders
from food_delivery_orders
group by "cuisine_type"
order by total_orders desc;

-- Q2: Which cuisines have the highest/lowest restaurant ratings
select "cuisine_type", 
round(avg("restaurant_rating")::numeric, 2) as avg_rating
from food_delivery_orders
group by "cuisine_type"
order by avg_rating desc;

-- Q3: Which cuisines take the longest to prepare?
select "cuisine_type", 
round(avg("preparation_time_min")::numeric, 2) as avg_time
from food_delivery_orders
group by "cuisine_type"
order by avg_time desc;

-- Q4. Does restaurant load affect preparation time?
SELECT "restaurant_load",
       ROUND(AVG("preparation_time_min")::numeric, 2) AS avg_prep_time
FROM food_delivery_orders
GROUP BY "restaurant_load"
ORDER BY avg_prep_time DESC;

-- Q5. Does traffic affect average delivery time?
select "traffic_level" , 
ROUND(AVG("time_taken_min")::numeric, 2) AS avg_delivery_time
FROM food_delivery_orders
GROUP BY "traffic_level"
ORDER BY avg_delivery_time DESC;

-- Q6. Which pickup zones have the longest average delivery times?
SELECT "pickup_zone",
       ROUND(AVG("time_taken_min")::numeric, 2) AS avg_delivery_time
FROM food_delivery_orders
GROUP BY "pickup_zone"
ORDER BY avg_delivery_time DESC;

-- Q6. Which dropoff zones have the longest average delivery times?
SELECT "dropoff_zone",
       ROUND(AVG("time_taken_min")::numeric, 2) AS avg_delivery_time
FROM food_delivery_orders
GROUP BY "dropoff_zone"
ORDER BY avg_delivery_time DESC;

-- Q7. Which pickup-to-dropoff zone combinations have the highest average delivery time, and are these routes also high-volume routes?
select
    pickup_zone,
    dropoff_zone,
    count(*) as total_orders,
    round(avg(time_taken_min), 2) as avg_delivery_time
from food_delivery_orders
group by
    pickup_zone,
    dropoff_zone
having count(*) >= 100
order by
    avg_delivery_time desc;
	
-- Q8: Which high-volume routes experience the longest delivery times and other factors affecting it?
select
    pickup_zone,
    dropoff_zone,
    count(*) as total_orders,
    round(avg(time_taken_min), 2) as avg_delivery_time,
    round(avg(preparation_time_min), 2) as avg_preparation_time,
    round(avg(road_distance_km)::numeric, 2) as avg_road_distance_km,
    mode() within group (order by traffic_level) as common_traffic_level,
    mode() within group (order by restaurant_load) as common_restaurant_load,
	mode() within group (order by vehicle_type) as common_vehicle_type,
	mode() within group (order by weather) as common_weather_condition
	
from food_delivery_orders
group by
    pickup_zone,
    dropoff_zone
having count(*) > 1500
order by
    avg_delivery_time desc;

	
-- Q9: How does order volume change month by month?
SELECT
    TO_CHAR(DATE_TRUNC('month', order_date::date), 'FMMonth') AS month,
    COUNT(*) AS total_orders,
    ROUND(AVG(time_taken_min), 2) AS avg_delivery_time,
    ROUND(AVG(preparation_time_min), 2) AS avg_preparation_time,
    ROUND(AVG(road_distance_km)::numeric, 2) AS avg_road_distance
FROM food_delivery_orders
GROUP BY DATE_TRUNC('month', order_date::date)
ORDER BY DATE_TRUNC('month', order_date::date);

-- Q10. Which hours are busiest, and when are deliveries slowest?
SELECT
    order_hour,
    COUNT(*) AS total_orders,
    ROUND(AVG(time_taken_min), 2) AS avg_delivery_time,
    ROUND(AVG(preparation_time_min), 2) AS avg_prep_time
FROM food_delivery_orders
GROUP BY order_hour
ORDER BY order_hour;

-- Q11. What drives the slow hours? Traffic mix and speed by hour
SELECT
    order_hour,
    COUNT(*) AS total_orders,
    ROUND(AVG(time_taken_min), 2) AS avg_delivery_time,
    ROUND(100.0 * SUM(CASE WHEN traffic_level IN ('High','Severe') THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_high_severe_traffic,
    ROUND(AVG(average_speed_kmph)::numeric, 2) AS avg_speed_kmph,
    ROUND(AVG(road_distance_km)::numeric, 2) AS avg_distance_km
FROM food_delivery_orders
GROUP BY order_hour
ORDER BY order_hour;

--Q12. Is traffic or rush hour the reason for delay?
SELECT
    CASE WHEN order_hour IN (8,9,10,18,19,20,21) THEN 'Rush hour' ELSE 'Off-peak' END AS period,
    traffic_level,
    COUNT(*) AS total_orders,
    ROUND(AVG(time_taken_min), 2) AS avg_delivery_time,
    ROUND(AVG(average_speed_kmph)::numeric, 2) AS avg_speed_kmph
FROM food_delivery_orders
GROUP BY period, traffic_level
ORDER BY period, avg_delivery_time;

--Q13. Does weather push traffic up?
SELECT
    weather,
    traffic_level,
    COUNT(*) AS total_orders,
    ROUND(AVG(average_speed_kmph)::numeric, 2) AS avg_speed_kmph,
    ROUND(AVG(time_taken_min), 2) AS avg_delivery_time
FROM food_delivery_orders
GROUP BY weather, traffic_level
ORDER BY
    CASE weather WHEN 'Clear' THEN 1 WHEN 'Cloudy' THEN 2 WHEN 'Fog' THEN 3 WHEN 'Rain' THEN 4 ELSE 5 END,
    CASE traffic_level WHEN 'Low' THEN 1 WHEN 'Moderate' THEN 2 WHEN 'High' THEN 3 ELSE 4 END;

--Q14. Vehicle what to use to reduce del time
SELECT
    vehicle_type,
    weather,
    COUNT(*) AS total_orders,
    ROUND(AVG(average_speed_kmph)::numeric, 2) AS avg_speed_kmph,
    ROUND(AVG(time_taken_min), 2) AS avg_delivery_time
FROM food_delivery_orders
GROUP BY vehicle_type, weather
ORDER BY vehicle_type,
    CASE weather WHEN 'Clear' THEN 1 WHEN 'Cloudy' THEN 2 WHEN 'Fog' THEN 3 WHEN 'Rain' THEN 4 ELSE 5 END;

	
-- Q15.  Order items vs prep time and delivery time
	SELECT
    order_items,
    COUNT(*) AS total_orders,
    ROUND(AVG(preparation_time_min), 2) AS avg_prep_time,
    ROUND(AVG(time_taken_min), 2) AS avg_delivery_time,
    ROUND(AVG(time_taken_min - preparation_time_min), 2) AS avg_non_prep_time,
    ROUND(AVG(road_distance_km)::numeric, 2) AS avg_distance_km,
    ROUND(AVG(average_speed_kmph)::numeric, 2) AS avg_speed_kmph
FROM food_delivery_orders
GROUP BY order_items
ORDER BY order_items;


--Q16. Cuisine: prep, delivery, and share of total time
SELECT
    cuisine_type,
    COUNT(*) AS total_orders,
    ROUND(AVG(preparation_time_min), 2) AS avg_prep_time,
    ROUND(AVG(time_taken_min), 2) AS avg_delivery_time,
    ROUND(100.0 * AVG(preparation_time_min) / AVG(time_taken_min), 1) AS prep_pct_of_total,
    ROUND(AVG(order_items), 2) AS avg_items,
    ROUND(AVG(restaurant_rating)::numeric, 2) AS avg_rating,
    ROUND(AVG(road_distance_km)::numeric, 2) AS avg_distance_km
FROM food_delivery_orders
GROUP BY cuisine_type
ORDER BY avg_prep_time DESC;







