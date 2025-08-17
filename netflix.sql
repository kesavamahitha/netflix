DROP TABLE IF EXISTS netflix;
CREATE TABLE netflix
(
	show_id varchar(6),
	type_show varchar(10),
	title varchar(110),
	director varchar(210),
	casts varchar(772),
	country varchar(124),
	date_added varchar(20),
	release_year int,
	rating varchar(10),
	duration varchar(10),
	listed_in varchar(80),
	description varchar(250)
);

SELECT * FROM netflix;

--Find the total number of Movies vs TV Shows.
SELECT 
	type_show,
	count(*)
FROM netflix
GROUP BY type_show;

--Find the top 5 countries producing the most content on Netflix.
SELECT
	trim(unnest(STRING_TO_ARRAY(country, ','))) as countries,
	count(*)
FROM netflix
GROUP BY countries 
ORDER BY 2 desc
LIMIT 5;

--Find the most common rating for Movies and TV Shows separately.
SELECT 
	type_show,
	rating,
	rate_counting
FROM (SELECT
	type_show,
	rating,
	count(*) AS rate_counting,
	RANK() OVER (PARTITION BY type_show order by count(*) desc) AS ranks
	FROM netflix
	GROUP BY 1,2
)
WHERE ranks = 1;

--Find the year with the highest number of releases.
SELECT 
	release_year,
	count(*)
FROM netflix
GROUP BY release_year
ORDER BY 2 desc
LIMIT 1;

--Show how many titles were added to Netflix each year (trend analysis).
SELECT 
	count(title),
	release_year
FROM netflix
GROUP BY release_year
ORDER BY 2;

--Find the average age of movies on Netflix (from release_year vs today).
SELECT 
	AVG(2025 - release_year)
FROM netflix
WHERE type_show = 'Movie';

--Find the director with the most titles on Netflix.
SELECT
	trim(unnest(STRING_TO_ARRAY(director, ','))) as directors,
	count(*)
FROM netflix
GROUP BY 1
ORDER BY 2 desc
LIMIT 1;

--List the actors who appear in the most Movies.
SELECT
	trim(unnest(STRING_TO_ARRAY(casts, ','))) as actors,
	count(*)
FROM netflix
WHERE type_show = 'Movie'
GROUP BY 1
ORDER BY 2 desc;

--Find how many shows feature both "Salman Khan" and "Shah Rukh Khan" in the cast.
SELECT
	count(*)
FROM netflix
WHERE casts LIKE '%Salman Khan%'
AND casts LIKE '%Shah Rukh Khan%';

--Find the top 5 most common genres (listed_in).
SELECT 
	trim(UNNEST(STRING_TO_ARRAY(listed_in, ','))) as genre,
	count(*)
FROM netflix
GROUP BY genre
ORDER BY 2 desc
LIMIT 5;

--Show the average release year for each genre.
SELECT 
	trim(UNNEST(STRING_TO_ARRAY(listed_in, ','))) as genre,
	AVG(release_year)
FROM netflix
GROUP BY genre;

--Find the genres most popular in India vs USA.
SELECT 
	trim(UNNEST(STRING_TO_ARRAY(listed_in, ','))) as genre,
	count(*),
	country
FROM netflix
WHERE country LIKE '%India%'
OR country LIKE '%United States%'
GROUP BY genre, country
ORDER BY 2 desc;

--Find all shows that were added in the last 5 years.
SELECT 
	type_show,
	title,
	date_added
FROM netflix
WHERE CAST(date_added as DATE) >= (current_date - INTERVAL '5 years')
ORDER BY date_added;

--Find the percentage of TV Shows vs Movies added each year.
SELECT
	EXTRACT(YEAR FROM CAST(date_added AS DATE)) AS YEAR_ADDED,
	type_show,
	count(*),
	ROUND(100.0 * count(*)/sum(count(*)) OVER (PARTITION BY EXTRACT(YEAR FROM CAST(date_added AS DATE))),2) AS percentage
FROM netflix
WHERE date_added IS NOT NULL
GROUP BY YEAR_ADDED, type_show
ORDER BY YEAR_ADDED desc, percentage desc;

--For each country, find the most popular rating.
WITH EXPANDED AS(
SELECT
	TRIM(UNNEST(STRING_TO_ARRAY(country, ','))) AS countries,
	rating
FROM netflix
WHERE country IS NOT NULL
),
RATING_CNT AS(
SELECT 
	countries,
	rating,
	count(rating) as cnt_rating
FROM EXPANDED
GROUP BY countries, rating
)
SELECT * 
FROM(
SELECT
	countries,
	rating,
	cnt_rating,
	RANK() OVER (PARTITION BY countries ORDER BY cnt_rating desc) as RNK
FROM RATING_CNT
GROUP BY countries, rating, cnt_rating
)
WHERE RNK = 1;

--Find the longest movie and the longest-running TV Show
SELECT
	title,
	type_show,
	duration
FROM (
SELECT
	title,
	type_show,
	duration,
	RANK() OVER (PARTITION BY type_show ORDER BY CAST(REGEXP_REPLACE(duration, '[^0-9]', '', 'g') AS INT) desc) AS RNK
FROM netflix
WHERE duration IS NOT NULL)
WHERE RNK = 1;

--Create a query that returns the Netflix library growth rate year-over-year.
WITH YEARLY_CNT AS(
	SELECT
	EXTRACT(YEAR FROM CAST(date_added AS DATE)) AS YEAR_ADDED,
	count(*) as cnt
	FROM netflix
	WHERE date_added IS NOT NULL
	GROUP BY YEAR_ADDED
)
SELECT 
	YEAR_ADDED,
	cnt,
	LAG(cnt) OVER (ORDER BY YEAR_ADDED) AS PREVIOUS_YEAR,
	ROUND(100.0 * (cnt - (LAG(cnt) OVER (ORDER BY YEAR_ADDED)))/NULLIF(LAG(cnt) OVER (ORDER BY YEAR_ADDED),0), 2) as YOY_GROWTH
FROM YEARLY_CNT
ORDER BY YEAR_ADDED;

--Use a window function to rank movies by release year within each country
SELECT * FROM(
SELECT 
	TRIM(UNNEST(STRING_TO_ARRAY(country, ','))) as countries, 
	title, 
	release_year,
       RANK() OVER (PARTITION BY TRIM(UNNEST(STRING_TO_ARRAY(country, ','))) ORDER BY release_year DESC) AS rank_in_country
FROM netflix
GROUP BY title,countries, release_year
)
WHERE countries <> '';

--Write a query to find which actor has worked with the most directors.
WITH ACTOR_DIRECTOR AS(
SELECT
	TRIM(UNNEST(STRING_TO_ARRAY(casts, ','))) as actors,
	TRIM(UNNEST(STRING_TO_ARRAY(director, ','))) as director
FROM netflix
WHERE casts IS NOT NULL
AND director IS NOT NULL
)

--Find if there’s any correlation between movie ratings and duration (grouping + averages).
WITH movie_data AS (
    SELECT
        rating,
        CAST(REGEXP_REPLACE(duration, '[^0-9]', '', 'g') AS INT) AS duration_min
    FROM netflix
    WHERE type_show = 'Movie'
      AND duration IS NOT NULL
      AND duration ~ '^[0-9]+'
),
rating_map AS (
    SELECT rating,
           ROW_NUMBER() OVER (ORDER BY rating) AS rating_code
    FROM (SELECT DISTINCT rating FROM movie_data) r
)
SELECT
    corr(rm.rating_code::float, md.duration_min::float) AS correlation
FROM movie_data md
JOIN rating_map rm ON md.rating = rm.rating;
