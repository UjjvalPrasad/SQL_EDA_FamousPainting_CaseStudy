-- SQL Painiting Dataset Case Study Project 

-- 1) Fetch all the paintings which are not displayed on any museums?
select * from work
 where museum_id is null;

-- 2) Are there museuems without any paintings?
select * from museum m
join work w on m.museum_id = w.museum_id
where w.work_id is null
order by m.museum_id;

select * from museum m
where not exists (select 1 from work w
					where w.museum_id=m.museum_id)

-- 3) How many paintings have an asking price of more than their regular price? 
select * from product_size
where sale_price > regular_price;

select count(*) from product_size
where sale_price > regular_price;

-- 4) Identify the paintings whose asking price is less than 50% of its regular price
select * from product_size
where sale_price < (0.5 * regular_price);

-- 5) Which canva size costs the most?
select top 1 cs.label as canva, ps.sale_price from canvas_size cs
join product_size ps on cs.size_id = ps.size_id
order by sale_price desc;

select cs.label as canva, ps.sale_price
	from (select *
		  , rank() over(order by sale_price desc) as rnk 
		  from product_size) ps
	join canvas_size cs on cs.size_id = ps.size_id
	where ps.rnk=1;					 

-- 6) Delete duplicate records from work, product_size, subject and image_link tables
with cte1 as
(
select *,
row_number() over(partition by work_id, name, artist_id,museum_id order by work_id) rownum1
from work
)
delete 
from cte1
where rownum1 > 1;

with cte2 as
(
select *,
row_number() over(partition by work_id, size_id order by work_id) rownum2
from product_size
)
delete
from cte2
where rownum2 > 1;

with cte3 as
(
select *,
row_number() over(partition by work_id, subject order by work_id) rownum3
from subject
)
delete
from cte3
where rownum3 > 1;

with cte4 as
(
select *,
row_number() over(partition by work_id, url  order by work_id) rownum4
from image_link
)
delete
from cte4
where rownum4 > 1;

-- 7) Identify the museums with invalid city information in the given dataset
select * from museum 
where city like '[0-9]%';

-- 8) Fetch the top 10 most famous painting subject
select * 
from (
	select s.subject,count(1) as no_of_paintings
	,rank() over(order by count(1) desc) as ranking
	from work w
	join subject s on s.work_id=w.work_id
	group by s.subject ) x
where ranking <= 10;

-- 9) Identify the museums which are open on both Sunday and Monday. Display museum name, city.
select name, city from museum m
join museum_hours mh on m.museum_id = mh.museum_id
where day = 'Sunday' 
and exists (select 1 from museum_hours mh2 
				where mh2.museum_id=mh.museum_id 
			    and mh2.day='Monday');

-- 10) How many museums are open every single day?
with alldaymuseum as
(
select museum_id, count(1) cnt
		  from museum_hours
		  group by museum_id
		  having count(1) = 7
)
select count(*) from alldaymuseum;

-- 11) Which are the top 5 most popular museum? (Popularity is defined based on most no of paintings in a museum)
with popular_museum as
(
select m.name, count(work_id) cnt,
rank() over(order by count(work_id) desc) rnk
from museum m
join work w on m.museum_id = w.museum_id
group by m.name
)
select * from popular_museum
where rnk <= 5;

-- 12) Who are the top 5 most popular artist? (Popularity is defined based on most no of paintings done by an artist)
select top 5 a.full_name, a.artist_id, count(work_id) work_count, 
rank() over(order by count(work_id) desc) rnk
from artist a
join work w on a.artist_id = w.artist_id
group by a.full_name, a.artist_id;

with top_artist as
(
select a.full_name, a.artist_id, count(work_id) work_count, 
rank() over(order by count(work_id) desc) rnk
from artist a
join work w on a.artist_id = w.artist_id
group by a.full_name, a.artist_id
)
select * from top_artist 
where rnk < 6;

-- 13) Display the 3 least popular canva sizes
with least_popular_painiting as
(
select label, count(w.work_id) as num,
rank() over(order by count(w.work_id)) rnk
from work w
join product_size ps on w.work_id = ps.work_id
join canvas_size cs on ps.size_id = cs.size_id
group by label
)
select * from least_popular_painiting
where rnk < 4;

select label as canvas_size, rnk
from (
		select label, count(w.work_id) as num,
		row_number() over(order by count(w.work_id)) rnk
		from work w
		join product_size ps on w.work_id = ps.work_id
		join canvas_size cs on ps.size_id = cs.size_id
		group by label
	  ) x
where x.rnk < 4;

select label,ranking,no_of_paintings
from (
	select cs.size_id,cs.label,count(1) as no_of_paintings
	, dense_rank() over(order by count(1) ) as ranking
	from work w
	join product_size ps on ps.work_id=w.work_id
	join canvas_size cs on cs.size_id = ps.size_id
	group by cs.size_id,cs.label) x
where x.ranking<=3;

-- 14) Which museum has the most no of most popular painting style?
with pop_style as 
		(select style
		,rank() over(order by count(1) desc) as rnk
		from work
		group by style),
	cte as
		(select w.museum_id,m.name as museum_name,ps.style, count(1) as no_of_paintings
		,rank() over(order by count(1) desc) as rnk
		from work w
		join museum m on m.museum_id=w.museum_id
		join pop_style ps on ps.style = w.style
		where w.museum_id is not null
		and ps.rnk=1
		group by w.museum_id, m.name,ps.style)
select museum_name,style,no_of_paintings
from cte
order by no_of_paintings desc;

-- 15) Identify the artists whose paintings are displayed in multiple countries
select distinct a.full_name, count(distinct m.country) no_of_countries from artist a
join work w on a.artist_id = w.artist_id
join museum m on w.museum_id = m.museum_id
group by a.full_name
having count(distinct m.country) > 1
order by no_of_countries desc;

-- 16) Display the country and the city with most no of museums. Output 2 seperate columns to mention the city and country. If there are multiple value, seperate them with comma.
WITH MuseumCounts AS (
    SELECT country, city, COUNT(*) AS museum_count
    FROM museum
    GROUP BY country, city
),
MaxCount AS (
    SELECT MAX(museum_count) AS max_count
    FROM MuseumCounts
),
TopLocations AS (
				SELECT country, city
				FROM MuseumCounts
				WHERE museum_count = (SELECT max_count FROM MaxCount)
)
SELECT 
    STRING_AGG(city, ', ') AS cities,
    STRING_AGG(country, ', ') AS countries
FROM TopLocations;

-- 17) Identify the artist and the museum where the most expensive and least expensive painting is placed. 
--     Display the artist name, sale_price, painting name, museum name, museum city and canvas label
with cte as 
	(select *,
	rank() over(order by sale_price desc) as rnk1,
	rank() over(order by sale_price ) as rnk2
	from product_size )
select a.full_name artist_name, cte.sale_price, w.name painting_name, m.name museum_name, m.city museum_city,  cz.label canvas_label
from cte
join work w on w.work_id=cte.work_id
join museum m on m.museum_id=w.museum_id
join artist a on a.artist_id=w.artist_id
join canvas_size cz on cz.size_id = cte.size_id
where rnk1=1 or rnk2=1;


-- 18) Which country has the 5th highest no of paintings?
with fivth_painting as
(
select m.country, count(work_id) no_of_painting,
rank() over (order by count(work_id) desc) rnk
from work w
join museum m on m.museum_id = w.museum_id
group by country
)
select * from fivth_painting 
where rnk = 5;

-- 19) Which are the 3 most popular and 3 least popular painting styles?
with cte as 
(
select style, count(work_id) as cnt, 
rank() over(order by count(work_id) desc) rnk,
count(1) over() as no_of_records
from work
where style is not null
group by style)
select style
, case when rnk <=3 then 'Most Popular' else 'Least Popular' end as remarks 
from cte
where rnk <=3
or rnk > no_of_records - 3;

-- 20) Which artist has the most no of Portraits paintings outside USA?. Display artist name, no of paintings and the artist nationality.
select full_name as artist_name, nationality, no_of_paintings
	from (
		select a.full_name, a.nationality,
		count(w.work_id) as no_of_paintings,
		rank() over(order by count(w.work_id) desc) as rnk
		from work w
		join artist a on a.artist_id=w.artist_id
		join subject s on s.work_id=w.work_id
		join museum m on m.museum_id=w.museum_id
		where s.subject='Portraits'
		and m.country != 'USA'
		group by a.full_name, a.nationality) x
	where rnk=1;