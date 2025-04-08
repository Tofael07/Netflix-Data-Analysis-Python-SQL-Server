-- Data Cleaning and Transformation of Netflix data

USE retail_orders;

SELECT *
FROM netflix_raw; 

-- Handling foreign characters

DROP TABLE netflix_raw;


CREATE TABLE [dbo].[netflix_raw](
	[show_id] [varchar](10) PRIMARY KEY,
	[type] [varchar](10) NULL,
	[title] [nvarchar](250) NULL,
	[director] [varchar](250) NULL,
	[cast] [varchar](1000) NULL,
	[country] [varchar](150) NULL,
	[date_added] [varchar](20) NULL,
	[release_year] [bigint] NULL,
	[rating] [varchar](10) NULL,
	[duration] [varchar](15) NULL,
	[listed_in] [varchar](100) NULL,
	[description] [varchar](500) NULL
);

SELECT *
FROM netflix_raw;

-- Remove Duplicates

SELECT show_id, COUNT(*)
FROM netflix_raw
GROUP BY show_id
HAVING COUNT(*)>1;


SELECT title,type
FROM netflix_raw
GROUP BY title,type
HAVING COUNT(*)>1;

-- Removing Duplicates

WITH cte AS(
SELECT *,ROW_NUMBER() OVER(PARTITION BY title,type ORDER BY show_id) AS row_num
FROM netflix_raw
)
SELECT *
FROM cte
WHERE row_num = 1;

-- New table for listed in, director, country, cast
-- Creating directors table

SELECT show_id, TRIM(VALUE) AS director
INTO netflix_directors
FROM netflix_raw
CROSS APPLY string_split(director,',');

SELECT *
FROM netflix_directors;

-- Creating country table

SELECT show_id, TRIM(VALUE) AS country
INTO netflix_country
FROM netflix_raw
CROSS APPLY string_split(country,',');

SELECT *
FROM netflix_country;

--Creating cast table

SELECT show_id, TRIM(VALUE) AS cast
INTO netflix_cast
FROM netflix_raw
CROSS APPLY string_split(cast,',');

SELECT *
FROM netflix_cast;

DROP TABLE netflix_genre;

--Creating genre table

SELECT show_id, TRIM(VALUE) AS genre
INTO netflix_genre
FROM netflix_raw
CROSS APPLY string_split(listed_in,',');

SELECT *
FROM netflix_genre;

-- Data type conversion

WITH cte AS(
SELECT *,ROW_NUMBER() OVER(PARTITION BY title,type ORDER BY show_id) AS row_num
FROM netflix_raw
)
SELECT show_id,type,title,CAST(date_added AS DATE) AS date_added, release_year,rating,duration,description
FROM cte
WHERE row_num = 1;

-- Poulate null values

-- Creating mapping for country

 SELECT director,country
 FROM netflix_country nc
 JOIN netflix_directors nd
 ON nc.show_id = nd.show_id
 GROUP BY director, country; 


INSERT INTO netflix_country 
SELECT show_id,m.country
FROM netflix_raw nr
JOIN(
	 SELECT nd.director,nc.country
	 FROM netflix_country nc
	 JOIN netflix_directors nd
	 ON nc.show_id = nd.show_id
	 GROUP BY nd.director, nc.country
	) AS m ON nr.director = m.director
 WHERE nr.country IS NULL;

-- Populate duration column

 SELECT *
 FROM netflix_raw
 WHERE duration IS NULL;

-- Insert the cleaned data into a new table

WITH cte AS(
SELECT *,ROW_NUMBER() OVER(PARTITION BY title,type ORDER BY show_id) AS row_num
FROM netflix_raw
)
SELECT show_id,type,title,CAST(date_added AS DATE) AS date_added, release_year,rating,
	CASE WHEN duration IS NULL THEN rating ELSE duration END AS duration,description
INTO netflix
FROM cte
WHERE row_num = 1;

SELECT *
FROM netflix;


--Analysis on Netflix data and answering questions--


/*For each directors count the no of movies and tv shows created by them in separate columns for directors
who have created both tv shows and movies.*/

SELECT nd.director,
COUNT(DISTINCT CASE WHEN n.type = 'Movie' THEN n.show_id END) AS no_of_movies,
COUNT(DISTINCT CASE WHEN n.type = 'Tv Show' THEN n.show_id END) AS no_of_tvshow
FROM netflix n
JOIN netflix_directors nd
ON n.show_id = nd.show_id
GROUP BY nd.director
HAVING COUNT(DISTINCT n.type)>1;

-- Which country has hightest no of comedy movies

SELECT TOP 1 nc.country,COUNT(distinct n.show_id) AS no_of_movies
FROM netflix n
JOIN netflix_genre ng ON n.show_id = ng.show_id
JOIN netflix_country nc ON ng.show_id = nc.show_id
WHERE n.type = 'Movie' AND ng.genre = 'Comedies'
GROUP BY nc.country
ORDER BY no_of_movies DESC;

-- For each year (as per date added to netflix) which director has maximum no of movies released

WITH cte AS(
SELECT nd.director, YEAR(date_added) AS date_year, COUNT(DISTINCT n.show_id) AS no_of_movies
FROM netflix n
JOIN netflix_directors nd ON n.show_id = nd.show_id
WHERE n.type = 'Movie'
GROUP BY nd.director, YEAR(date_added)
),
cte2 AS(
SELECT *,ROW_NUMBER() OVER(PARTITION BY date_year ORDER BY no_of_movies DESC) AS row_num
FROM cte
)
SELECT *
FROM cte2
WHERE row_num = 1;

-- What is the avg duration of movies in each genre

SELECT ng.genre, AVG(CAST(REPLACE(n.duration,' min','') AS int)) AS avg_duration
FROM netflix n
JOIN netflix_genre ng ON n.show_id = ng.show_id
WHERE n.type = 'Movie'
GROUP BY ng.genre;

-- Find the list of directors who have created comedy and horror movies both


SELECT nd.director,
COUNT(DISTINCT CASE WHEN ng.genre = 'Comedies' THEN n.show_id END) AS no_of_comedy,
COUNT(DISTINCT CASE WHEN ng.genre = 'Horror Movies' THEN n.show_id END) AS no_of_horror
FROM netflix n
JOIN netflix_directors nd ON n.show_id = nd.show_id
JOIN netflix_genre ng ON nd.show_id = ng.show_id
WHERE n.type = 'Movie' AND ng.genre IN ('Horror Movies','Comedies')
GROUP BY nd.director
HAVING COUNT(DISTINCT ng.genre)>=2;
