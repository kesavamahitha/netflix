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
ORDER BY 2;