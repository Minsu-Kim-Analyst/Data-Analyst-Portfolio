/*
-------------------------------------------------------------------
Data Exploration of Netflix Shows Dataset

Skills Used: JOINs, GROUP BYs, CTEs, Window Functions, Views, etc.
-------------------------------------------------------------------
*/


-- Table structure

CREATE TABLE netflix_shows (
	show_id varchar(8) PRIMARY KEY,
	type varchar(8),
	title varchar(128),
	director text,
	"cast" text,
	country text,
	date_added date,
	released_year integer,
	rating varchar(8),
	duration varchar(16),
	listed_in text,
	description text
);


-- Remove NULL values in title, if there is any

DELETE FROM netflix_shows
WHERE title IS NULL;


-- Remove duplicate values in title, if there is any

DELETE FROM
  netflix_shows AS n1
	USING netflix_shows AS n2
WHERE n1.show_id < n2.show_id
  AND n1.title = n2.title;


-- Set title as the new primary key

ALTER TABLE netflix_shows
DROP CONSTRAINT netflix_shows_pkey;

ALTER TABLE netflix_shows
ADD PRIMARY KEY (title);


-- Remove unnecessary columns

ALTER TABLE netflix_shows
DROP COLUMN show_id,
DROP COLUMN description;


-- Rename columns

ALTER TABLE netflix_shows
RENAME COLUMN director TO list_directors;

ALTER TABLE netflix_shows
RENAME COLUMN "cast" TO list_casts;

ALTER TABLE netflix_shows
RENAME COLUMN countries TO list_countries;

ALTER TABLE netflix_shows
RENAME COLUMN genres TO list_genres;


-- Creating views to unnest columns in listed format

CREATE VIEW list_directors_unnested AS
SELECT
  type, 
  title, 
  UNNEST(STRING_TO_ARRAY(list_directors, ', ')) AS director, 
  released_year, 
  rating, 
  duration
FROM netflix_shows;

CREATE VIEW list_casts_unnested AS
SELECT
  type, 
  title, 
  UNNEST(STRING_TO_ARRAY(list_casts, ', ')) AS "cast", 
  released_year, 
  rating, 
  duration
FROM netflix_shows;

CREATE VIEW list_countries_unnested AS
SELECT
  type, 
  title, 
  UNNEST(STRING_TO_ARRAY(list_countries, ', ')) AS country, 
  released_year, 
  rating, 
  duration
FROM netflix_shows;

CREATE VIEW list_genres_unnested AS
SELECT
  type, 
  title, 
  UNNEST(STRING_TO_ARRAY(list_genres, ', ')) AS genre, 
  released_year, 
  rating, 
  duration
FROM netflix_shows;


-- Global Numbers

SELECT
  COUNT(title) AS total_shows,
  COUNT(CASE
	WHEN LOWER(type) = 'movie' THEN title
	ELSE NULL
  END) AS total_movies,
  COUNT(CASE
	WHEN LOWER(type) = 'tv show' THEN title
  END) AS total_tv_shows,
  (SELECT COUNT(DISTINCT genre) AS total_genres FROM list_genres_unnested) AS total_genres,
  (SELECT COUNT(DISTINCT country) AS total_countries_streamed FROM list_countries_unnested) AS total_countries
FROM netflix_shows;


-- Number of shows, movies, and tv shows by year released

SELECT
  released_year,
  COUNT(title) AS released_shows,
  COUNT(CASE
	WHEN LOWER(type) = 'movie' THEN title
	ELSE NULL
  END) AS released_movies,
  COUNT(CASE
	WHEN LOWER(type) = 'tv show' THEN title
  END) AS released_tv_shows
FROM netflix_shows
GROUP BY released_year
ORDER BY released_year;


-- Most common movie genres

SELECT
  genre,
  COUNT(title) AS total_movies
FROM list_genres_unnested
WHERE LOWER(type) = 'movie'
GROUP BY genre
ORDER BY total_movies DESC;


-- Most common tv show genres

SELECT
  genre,
  COUNT(title) AS total_tv_shows
FROM list_genres_unnested
WHERE LOWER(type) = 'tv show'
GROUP BY genre
ORDER BY total_tv_shows DESC;


-- Countries with most number of available shows

SELECT
  country,
  COUNT(title) AS total_shows
FROM list_countries_unnested
GROUP BY country
ORDER BY total_shows DESC;


-- Most appeared cast and director each year

WITH casts_ranking AS (
  SELECT
	released_year,
	"cast",
	ROW_NUMBER() OVER(PARTITION BY released_year ORDER BY COUNT(title) DESC) AS ranking
  FROM list_casts_unnested
  GROUP BY released_year, "cast"
),
directors_ranking AS (
  SELECT
	released_year,
	director,
	ROW_NUMBER() OVER(PARTITION BY released_year ORDER BY COUNT(title) DESC) AS ranking
  FROM list_directors_unnested
  GROUP BY released_year, director
)

SELECT
  c.released_year,
  "cast" AS most_appeared_cast,
  director AS most_appeared_director
FROM casts_ranking AS c
JOIN directors_ranking AS d
  ON c.released_year = d.released_year
WHERE c.ranking = 1
  AND d.ranking = 1;
