/*
IMDB Top 1000 Movies Data Exploration

Skills Used: Join, Group By, Common Table Expression, Subquery, Window Function, Aggregate Function, etc.
*/



-- Remove unnecessary columns

ALTER TABLE imdb_top_1000
DROP COLUMN poster_link,
DROP COLUMN overview;



-- Standardize runtime column format and data type

ALTER TABLE imdb_top_1000
ALTER COLUMN runtime SET DATA TYPE integer USING REPLACE(runtime, ' min', '')::integer;



-- Top 5 IMDB rated movies

SELECT * 
FROM imdb_top_1000
WHERE imdb_rating IS NOT NULL
ORDER BY imdb_rating DESC
LIMIT 5;



-- Top 5 Metascore rated movies

SELECT * 
FROM imdb_top_1000
WHERE meta_score IS NOT NULL
ORDER BY meta_score DESC
LIMIT 5;



-- Number of movies released by year

SELECT
	released_year,
	COUNT(*) AS movies_released
FROM imdb_top_1000
GROUP BY released_year
ORDER BY released_year;



-- Top 5 actors with most appearances

WITH actors AS (
	SELECT star1 AS name FROM imdb_top_1000
	UNION ALL
	SELECT star2 FROM imdb_top_1000
	UNION ALL
	SELECT star3 FROM imdb_top_1000
	UNION ALL
	SELECT star4 FROM imdb_top_1000
)

SELECT
	name,
	COUNT(*) AS appearances
FROM actors
GROUP BY name
ORDER BY appearances DESC
LIMIT 5;



-- Top 5 directors with most number of movies directed

SELECT
	director,
    COUNT(*) AS movies_directed
FROM imdb_top_1000
GROUP BY director
ORDER BY movies_directed DESC
LIMIT 5;



-- Top 5 directors with highest average imdb rating (those who directed more than 1 movie)

SELECT
	director,
	ROUND(AVG(imdb_rating), 2) AS avg_imdb_rating
FROM imdb_top_1000
GROUP BY director
HAVING COUNT(*) > 1
ORDER BY avg_imdb_rating DESC
LIMIT 5;



-- Highest imdb rated movie by year

WITH imdb_ranking AS (
	SELECT
		released_year,
		title,
		imdb_rating,
		ROW_NUMBER() OVER(PARTITION BY released_year ORDER BY imdb_rating DESC) AS ranking
	FROM imdb_top_1000
)

SELECT
	released_year,
	title AS best_imdb_rated_movie,
	imdb_rating
FROM imdb_ranking
WHERE ranking = 1
ORDER BY released_year;



-- Average movie runtime by genre

SELECT
	UNNEST(STRING_TO_ARRAY(genre, ', ')) AS genre,
	ROUND(AVG(runtime)) AS avg_movie_runtime
FROM imdb_top_1000
GROUP BY UNNEST(STRING_TO_ARRAY(genre, ', '))
ORDER BY avg_movie_runtime;



-- Average gross earnings by movie runtime

SELECT
	CASE
		WHEN runtime_ntile = 1 THEN 'Short'
		WHEN runtime_ntile = 2 THEN 'Average'
		WHEN runtime_ntile = 3 THEN 'Long'
	END AS runtime_category,
	ROUND(AVG(gross_earnings)) AS avg_gross_earnings
FROM (
	SELECT
	    NTILE(3) OVER(ORDER BY runtime) AS runtime_ntile,
		gross_earnings
	FROM imdb_top_1000
	WHERE gross_earnings IS NOT NULL
) AS movie_runtime_categorization
GROUP BY
	CASE
		WHEN runtime_ntile = 1 THEN 'Short'
		WHEN runtime_ntile = 2 THEN 'Average'
		WHEN runtime_ntile = 3 THEN 'Long'
	END
ORDER BY avg_gross_earnings;



-- List of directors who also acts

SELECT DISTINCT i1.director
FROM imdb_top_1000 AS i1
JOIN imdb_top_1000 AS i2
	ON i1.director IN (i2.star1, i2.star2, i2.star3, i2.star4);
