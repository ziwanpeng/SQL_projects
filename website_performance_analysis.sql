## this is a website performance analysis
## 1.website content analysis: understanding which webpages are seen the most by users
## 2.landing page analysis: understanding the performance of key landing pages, evaluated by bounce rate and its weekly trend
## 3.conversion funnel analysis: optimizing each step of user's experience on their journey toward purchasing products
##   evaluated by click-through rate


## 1.1top website pages
-- homepage has the largest volume
select
	pageview_url,
    count(distinct website_pageview_id) as sessions
from website_pageviews
where created_at < '2012-06-09'
group by 1
order by 2 desc;



## 1.2 top entry pages
-- step1: create temporary table for the entry page id
create temporary table entry_page_view
select
	website_session_id,
    min(website_pageview_id) as entry_page_id
from website_pageviews
where created_at < '2012-06-12'
group by website_session_id;

-- step2: find the url for the entry page and count sessions hitting this entry page
-- homepage always is the first entry page
select
	pageview_url as entry_page,
    count(distinct e.website_session_id) as sessions_hittting_this_entry_page
from entry_page_view as e
left join website_pageviews as w
	on e.entry_page_id=w.website_pageview_id
group by pageview_url
order by 2 desc;


## 2. bounce rate for homepage
-- step1: find the website sessions with homepage as entry page
create temporary table entry_page_view_home
select
	website_session_id,
    min(website_pageview_id) as entry_page_id
from website_pageviews
where created_at < '2012-06-14' and pageview_url='/home'
group by website_session_id;

-- step2: count how many pages for each sessions with homepage as entry page
create temporary table count_page_views
select
	eh.website_session_id,
	count(distinct website_pageview_id) as page_views
from entry_page_view_home as eh
inner join website_pageviews as wp
	on eh.website_session_id=wp.website_session_id
group by eh.website_session_id;

-- step3: calculate bounce rate 
select
	count(distinct website_session_id) as sessions,
    count(distinct case when page_views=1 then website_session_id else null end) as bounced_sessions,
    count(distinct case when page_views=1 then website_session_id else null end)/count(distinct website_session_id) as bounce_rate
from count_page_views;


## 2.2 bounce rate comparision after lauching a new landing page 'lander-1'
-- step1: find when the new landing page lander-1 started to get website sessions
select
	min(website_pageview_id)
from website_pageviews
where pageview_url='/lander-1'
	and created_at is not null;
    
-- step2: find the entry page for each website session
create temporary table entry_page_view_test
select
	wp.website_session_id,
    min(wp.website_pageview_id) as entry_page_id
from website_pageviews as wp
inner join website_sessions as ws
	on wp.website_session_id=ws.website_session_id
where ws.created_at < '2012-07-28' 
	and utm_source='gsearch' 
	and utm_campaign='nonbrand'
    and wp.website_pageview_id > 23504
group by website_session_id;

-- step3: match the url
create temporary table entry_page_url_test
select
	et.website_session_id,
    pageview_url as entry_page
from entry_page_view_test as et
left join website_pageviews as wp
	on et.entry_page_id=wp.website_pageview_id;
    
-- step4: countthe amount of pages a website session viewed
create temporary table count_page_views_test
select
	eut.website_session_id,
    entry_page,
    count(distinct wp.website_pageview_id) as page_views
from entry_page_url_test as eut
left join website_pageviews as wp
	on eut.website_session_id=wp.website_session_id
group by eut.website_session_id,entry_page;

-- step5: calculate the bounce rates for homepange and lander-1
select
	entry_page,
	count(distinct website_session_id) as sessions,
    count(distinct case when page_views=1 then website_session_id else null end) as bounced_sessions,
    count(distinct case when page_views=1 then website_session_id else null end)/count(distinct website_session_id) as bounce_rate
from count_page_views_test
group by entry_page;

## 2.3 weekly trend of bounce rate, sessions by different landing pages
-- lower bounce rate after fulling transformed to lander-1
-- step1: find bounced sessions(following the similar steps as last question)
create temporary table entry_page_view_trend
select
	wp.website_session_id,
    ws.created_at as created_time,
    min(wp.website_pageview_id) as entry_page_id
from website_pageviews as wp
inner join website_sessions as ws
	on wp.website_session_id=ws.website_session_id
where ws.created_at < '2012-08-31' 
	and ws.created_at > '2012-06-01' 
	and utm_source='gsearch' 
	and utm_campaign='nonbrand'
group by website_session_id;

create temporary table entry_page_url_trend
select
	et.website_session_id,
    created_time,
    pageview_url as entry_page
from entry_page_view_trend as et
left join website_pageviews as wp
	on et.entry_page_id=wp.website_pageview_id;

create temporary table count_page_views_trend
select
	eut.website_session_id,
    created_time,
    entry_page,
    count(distinct wp.website_pageview_id) as page_views
from entry_page_url_trend as eut
left join website_pageviews as wp
	on eut.website_session_id=wp.website_session_id
group by eut.website_session_id, created_time,entry_page;

-- step2: weekly trend of bounce rate and session volume
select
	min(date(created_time)) as week_start_date,
	count(distinct case when page_views=1 then website_session_id else null end)/count(distinct website_session_id) as bounce_rate,
    count(distinct case when entry_page='/home' then website_session_id else null end) as home_sessions,
    count(distinct case when entry_page='/lander-1' then website_session_id else null end) as lander_sessions
from count_page_views_trend
group by year(created_time), week(created_time);


## 3.1 click through rate in each step
-- lander, mrfuzzy, billing pages have the lowest click through rates
create temporary table conv_list
select
	website_session_id,
    sum(product_made) as to_products,
    sum(mrfuzzy_made) as to_mrfuzzy,
    sum(cart_made) as to_cart,
    sum(shipping_made) as to_shipping,
    sum(billing_made) as to_billing,
    sum(thankyou_made) as to_thankyou
from(
select
	ws.website_session_id,
    pageview_url,
    case when pageview_url='/products' then 1 else 0 end as product_made,
    case when pageview_url='/the-original-mr-fuzzy' then 1 else 0 end as mrfuzzy_made,
    case when pageview_url='/cart' then 1 else 0 end as cart_made,
    case when pageview_url='/shipping' then 1 else 0 end as shipping_made,
	case when pageview_url='/billing' then 1 else 0 end as billing_made,
	case when pageview_url='/thank-you-for-your-order' then 1 else 0 end as thankyou_made
from website_sessions as ws
left join website_pageviews as wp
	on ws.website_session_id=wp.website_session_id
where ws.created_at > '2012-08-05' 
	and ws.created_at < '2012-09-05' 
	and utm_source='gsearch' 
	and utm_campaign='nonbrand') as raw
group by website_session_id;

select
    sum(to_products)/count(distinct website_session_id) as lander_click_rt,
    sum(to_mrfuzzy)/sum(to_products) as product_click_rt,
    sum(to_cart)/sum(to_mrfuzzy) as mrfuzzy_click_rt,
    sum(to_shipping)/sum(to_cart) as cart_click_rt,
	sum(to_billing)/sum(to_shipping) as shipping_click_rt,
    sum(to_thankyou)/sum(to_billing) as billing_click_rt
from conv_list;

## 3.2 click through rate for updated billing page
-- step1: find the earlest billing page with billing-2
select
	min(website_pageview_id)
from website_pageviews
where pageview_url='/billing-2'
	and created_at is not null; -- 53550

-- step2: calculate click through from billing pages to orders
select
	pageview_url,
	count(distinct website_session_id) as sessions,
    count(distinct order_id ) as orders,
    count(distinct order_id )/count(distinct website_session_id) as billing_to_order_click_rt
from
(select
	wp.website_session_id,
    pageview_url,
    order_id
from website_pageviews as wp
left join orders as o
    on wp.website_session_id=o.website_session_id
where wp.created_at <'2012-11-10'
	 and website_pageview_id >= 53550
     and pageview_url in ('/billing','/billing-2')) as sesssion_to_orders
group by pageview_url;
