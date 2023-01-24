-- 1. How many olympic games have been held?
select count(distinct games) as total_no_olympic_games
from OLYMPICS_HISTORY;

-- 2. List down all olympic games held so far.
select distinct year, season, city
from OLYMPICS_HISTORY
order by year;

-- 3. Mention the total no of nations who participated in each olympics game.
with all_countries as (
	select games, nr.region as country
	from OLYMPICS_HISTORY as oh
	join OLYMPICS_HISTORY_noc_regions as nr on nr.noc = oh.noc
	group by games, nr.region
)
select games, count(1) as total_countries
from all_countries
group by games
order by games;

-- 4. Which year saw the highest and lowest no of countries participating in olympics?
with all_countries as (
	select games, nr.region
	from OLYMPICS_HISTORY as oh
	join OLYMPICS_HISTORY_noc_regions as nr on nr.noc = oh.noc
	group by games, nr.region
),
total_countries as (
	select games, count(1) as total_countries
	from all_countries
	group by games
	order by total_countries
)
select distinct
concat(
	first_value(games) over(order by total_countries),
	' - ',
	first_value(total_countries) over(order by total_countries)
) as Lowest_Countries,
concat(
	first_value(games) over(order by total_countries desc),
	' - ',
	first_value(total_countries) over(order by total_countries desc)
) as Highest_Countries
from total_countries;

-- 5. Which nation has participated in all of the olympic games?
with total_games as (
	select count(distinct games) as total_no_olympic_games
	from OLYMPICS_HISTORY
),
all_countries as (
	select games, nr.region as country
	from OLYMPICS_HISTORY as oh
	join OLYMPICS_HISTORY_noc_regions as nr on nr.noc = oh.noc
	group by games, nr.region
),
countries_participated as (
	select country, count(1) as total_participated_games
	from all_countries
	group by country
)
select * from countries_participated
join total_games on total_games.total_no_olympic_games = countries_participated.total_participated_games

-- 7. Which Sports were just played only once in the olympics?
with t1 as (
	select distinct games, sport
	from OLYMPICS_HISTORY
),
t2 as (
	select sport, count(1) as no_of_games
	from t1
	group by sport
)
select t2.*, t1.games
from t2
join t1 on t1.sport = t2.sport
where t2.no_of_games = 1
order by t1.sport;

-- 8. Fetch the total no of sports played in each olympic games.
with t1 as (
	select distinct games, sport
	from OLYMPICS_HISTORY
),
t2 as (
	select games, count(1) as no_of_sports
	from t1
	group by games
)
select * from t2
order by games

-- 9. Fetch oldest athletes to win a gold medal
select * from OLYMPICS_HISTORY
where age != 'NA' and medal = 'Gold'
order by age desc;

with t1 as (
	select name, sex, cast(case when age = 'NA' then '0' else age end as int) as age,
	team, games, city, sport, event, medal
	from OLYMPICS_HISTORY
),
t2 as (
	select *, rank() over(order by age desc) as rnk
	from t1
	where medal = 'Gold'
)
select * from t2 where rnk = 1;

-- 10. Find the Ratio of male and female athletes participated in all olympic games.

select sex, count(1) as sex_count
from OLYMPICS_HISTORY
group by sex;

-- 12. Fetch the top 5 athletes who have won the most medals (gold/silver/bronze).
with t1 as(
	select name, count(1) as total_medals
	from OLYMPICS_HISTORY
	where medal != 'NA'
	group by name
	order by total_medals desc
),
t2 as (
	select *, dense_rank() over(order by total_medals desc) as rnk
	from t1
)
select *
from t2
where rnk <= 5;

-- 13. Fetch the top 5 most successful countries in olympics. Success is defined by no of medals won.
with t1 as (
	select nr.region as country, count(1) as total_medals
	from OLYMPICS_HISTORY as oh
	join OLYMPICS_HISTORY_noc_regions as nr on nr.noc = oh.noc
	where medal != 'NA'
	group by nr.region
),
t2 as (
	select *, dense_rank() over(order by total_medals desc) as rnk
	from t1
)
select *
from t2
where rnk <= 5;

-- 14. List down total gold, silver and bronze medals won by each country.

select country,
coalesce(gold, 0) as gold,
coalesce(silver, 0) as silver,
coalesce(bronze, 0) as bronze
from crosstab('
	select nr.region as country, medal, count(1) as total_medals
	from OLYMPICS_HISTORY as oh
	join OLYMPICS_HISTORY_noc_regions as nr on nr.noc = oh.noc
	where medal != ''NA''
	group by nr.region, medal',
	'values (''Bronze''), (''Gold''), (''Silver'')
')
as result(country varchar, bronze bigint, gold bigint, silver bigint)
order by gold desc, silver desc, bronze desc;