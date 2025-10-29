create database hospitalityanalysis;
use hospitalityanalysis;
select*from dim_date;
select*from dim_hotels;
select*from dim_rooms;
select*from fact_bookings;
select*from fact_aggregated_bookings;
-- 1) (a) Total Revenue Realized
Select concat('₹',format(sum(revenue_realized),0,'en_IN')) as Total_Revenue_Realized
from fact_bookings;
-- (b) Total Revenue Generated
Select concat('₹',format(sum(revenue_generated),0,'en_IN')) as Total_Revenue
from fact_bookings;
-- 2) Occupancy Rate
select concat(SUM(successful_bookings) / SUM(capacity) * 100,'%') as Occupancy_Rate
from fact_aggregated_bookings;
-- 3)Cancellation Rate
select (count(*) * 100.0 / (select count(*) from fact_bookings)) as Cancellation_Percentage
from fact_bookings
where booking_status = 'Cancelled';
-- 4) Total Bookings
select count(booking_id) as Total_Booking
from fact_bookings;
-- 5) Utilized Capacity
select sum(capacity) AS Utilized_Capacity
from fact_aggregated_bookings;

-- 6) Trend Analysis
select t1.week_no,
	   concat('₹',round(sum(t2.revenue_generated)/1000000.0,2),'M') as Revenue
from dim_date as t1
inner join fact_bookings as t2
on t1.date = t2.booking_date
group by t1.week_no
order by t1.week_no;
-- 7) Weekday & Weekend Revenue and Booking
-- (a) Revenue
select h1.day_type,
	   concat('₹',round(sum(h2.revenue_generated)/1000000.0,2),'M') as Revenue
from dim_date as h1
inner join fact_bookings as h2
on h1.date = h2.booking_date
group by day_type;
-- (b) Bookings
select b1.day_type,
	   sum(b2.successful_bookings) as Total_Bookings
from dim_date as b1
inner join fact_aggregated_bookings as b2
on b1.date = b2.check_in_date
group by day_type;
-- 8) Revenue by State & Hotel
-- (a) Revenue by State
select h1.city,
	   concat('₹',round(sum(h2.revenue_generated)/1000000.0,2),'M') as Revenue
from dim_hotels as h1
inner join fact_bookings as h2
on h1.property_id = h2.property_id
group by h1.city
order by sum(h2.revenue_generated) desc;
-- (b) Revenue by hotels
select h1.property_name,
	   concat('₹',round(sum(h2.revenue_generated)/1000000.0,2),'M') as Revenue
from dim_hotels as h1
inner join fact_bookings as h2
on h1.property_id = h2.property_id
group by h1.property_name
order by sum(h2.revenue_generated) desc;
-- 9) Class Wise Revenue
select h1.room_class,
	   concat('₹',round(sum(h2.revenue_generated)/1000000.0,2),'M') as Revenue
from dim_rooms as h1
inner join fact_bookings as h2
on h1.room_id = h2.room_category
group by h1.room_class
order by sum(h2.revenue_generated) desc;

-- 10) Checked Out / Cancel / No Show
with overall_revenue as (select sum(revenue_realized) as total_overall_revenue
from fact_bookings)
select fb.booking_status,
    concat('₹', round(sum(fb.revenue_realized) / 1000000.0, 2), 'M') as Total_Revenue,
    concat(round((sum(fb.revenue_realized) * 100.0) / orv.total_overall_revenue,2),'%') as Revenue_Percentage
from fact_bookings as fb
cross join overall_revenue AS orv
group by fb.booking_status,orv.total_overall_revenue 
order by sum(fb.revenue_realized) desc;

-- 11) Weekly Report
WITH WeeklyRevenue AS (
SELECT dd.week_no AS week_no,
        SUM(fb.revenue_generated) AS weekly_revenue
FROM dim_date AS dd
INNER JOIN fact_bookings AS fb ON dd.date = SUBSTR(fb.check_in_date, 1, 10)
GROUP BY dd.week_no  ),
WeeklyBookingsOcc AS (SELECT dd.week_no AS week_no, 
SUM(fab.successful_bookings) AS weekly_bookings,
SUM(fab.capacity) AS weekly_capacity
FROM dim_date AS dd
INNER JOIN fact_aggregated_bookings AS fab 
ON dd.date = fab.check_in_date
GROUP BY dd.week_no )
SELECT wbo.week_no,
CONCAT(ROUND((COALESCE(wr.weekly_revenue, 0) * 100.0) / COALESCE((SELECT SUM(revenue_generated) FROM fact_bookings), 1),2),'%') AS 
Revenue_Percentage,
CONCAT(ROUND((wbo.weekly_bookings * 100.0) / (SELECT SUM(successful_bookings) FROM fact_aggregated_bookings), 2),'%') AS 
Bookings_Percentage,
CONCAT(ROUND(wbo.weekly_bookings * 100.0 / COALESCE(wbo.weekly_capacity, 1), 2), '%') AS Occupancy_Rate
FROM
WeeklyBookingsOcc AS wbo
LEFT JOIN WeeklyRevenue AS wr 
ON wbo.week_no = wr.week_no 
ORDER BY wbo.week_no ASC;

select h1.category,h1.city,
concat('₹',round(sum(fb.revenue_generated)/1000000.0,2),'M') as Total_Revenue
from dim_hotels as h1
inner join fact_bookings as fb
on h1.property_id = fb.property_id
group by h1.category,h1.city
order by h1.category,sum(revenue_generated) desc;

select h1.property_name,
concat('₹',round(sum(fb.revenue_realized)/1000000.0,2),'M') as Total_Revenue
from dim_hotels as h1
inner join fact_bookings as fb
on h1.property_id = fb.property_id
group by h1.property_name
order by sum(revenue_realized) desc;