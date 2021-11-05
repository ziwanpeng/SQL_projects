# this is a traffic source analysis for an e-commerce website


## what the output shows
-- conclusions/observations/analysis/actions from the output



## website sessions, breakdown by source, campaign, and referring domain
-- gsearch nonbrand campaign generates the most website sessions
select utm_source,utm_campaign,http_referer,
	count(distinct ws.website_session_id) as sessions
from website_sessions as ws
where created_at < '2012-04-12'
group by utm_source,utm_campaign,http_referer
order by sessions desc;


## session to orders conversion rate for by gsearch nonbrand campaign
-- the conversion rate is lower than 4% which leads the marketing department to dial down the search bids
select 
	count(distinct ws.website_session_id) as ws_sessions,
    count(distinct o.order_id) as o_orders,
    count(distinct o.order_id)/count(distinct ws.website_session_id) as conv_rt
from website_sessions as ws
left join orders as o
on o.website_session_id=ws.website_session_id
where utm_source='gsearch' and utm_campaign='nonbrand' and ws.created_at<'2012-04-14' ;


## sessions weekly trends
-- gsearch nonbrand campaign is fairly sensitive to bids changes
select 
    min(date(created_at)) as week_start_date,
	count(distinct website_session_id) as sessions
from website_sessions
where utm_source='gsearch' and utm_campaign='nonbrand' and created_at <'2012-05-10'
group by year(created_at),week(created_at);


## conversion rate by device type
-- desktop has much higher conversion rate than mobile
-- markerting department bids desktop campaign up
select 
	device_type,
	count(distinct ws.website_session_id) as sessions,
	count(distinct o.order_id) as orders,
    count(distinct o.order_id)/count(distinct ws.website_session_id) as conv_rt
from website_sessions as ws
left join orders as o
on o.website_session_id=ws.website_session_id
where utm_source='gsearch' and utm_campaign='nonbrand' and ws.created_at<'2012-05-11'
group by device_type;


## weekly trends after bidding gsearch nonbrand desktop campaigns up
-- the volumn of website sessions by desktop is significantly increasing
select 
    min(date(created_at)) as week_start_date,
	count(distinct case when device_type='mobile' then website_session_id else null end) as mobile_volume,
	count(distinct case when device_type='desktop' then website_session_id else null end) as desktop_volume
from website_sessions
where utm_source='gsearch' and utm_campaign='nonbrand' and created_at between '2012-04-15' and '2012-06-09'
group by year(created_at),week(created_at);
