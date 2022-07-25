/*
Question 1
Let's compare the combo genres "Rom-Com" and "Dramedy" by their
average rating (average of avg_vote) and # of movies. Only use
movies with at least 10,000 votes as part of this analysis.
Definitions:
"Rom-Com" = A movie with both "Comedy" and "Romance" in the genre
"Dramedy" = A movie with both "Comedy" and "Drama" in the genre
If a movie has "Comedy", "Romance" AND "Drama" in the genre, it should
count in both categories.
You will create a new field called "combo_genre" which contains either
"Rom-Com" or "Dramedy".
Provide the output sorted by "combo_genre" alphabetically.
Hint:  Calculate the two "combo_genre" in separate queries and UNION the results
together
*/

SELECT
       combo_genre,
       ROUND(avg_rating, 2) AS avg_rating,
       num_movies
FROM(
    SELECT
           'Rom-Com' AS  combo_genre,
           AVG(avg_vote) AS avg_rating,
           COUNT(original_title) AS num_movies
    FROM movies
    WHERE genre ILIKE '%comedy%' AND genre ILIKE '%romance%' AND votes >= 10000
UNION
    SELECT
           'Dramedy' AS  combo_genre,
           AVG(avg_vote) AS avg_rating,
           COUNT(original_title) AS num_movies
    FROM movies
    WHERE genre ILIKE '%comedy%' AND genre ILIKE '%drama%' AND votes >= 10000) AS sub
ORDER BY combo_genre;

/*
Question 2
Provide a list of the top 10 movies (by votes) where the cast has at least
4 members and the cast consists only of actresses (no actors).
The columns you should report are "original_title", "avg_vote" and "votes",
all from the "movies" table.
Hint: Consider writing a subquery in the WHERE clause that captures the
imdb_title_id of movies that fit this criteria.
*/


SELECT
       original_title,
       avg_vote,
       votes
FROM movies
WHERE imdb_title_id IN (
    SELECT imdb_title_id
    FROM title_principals tp
    WHERE category = 'actress'
    GROUP BY 1
    HAVING COUNT(imdb_title_id)>=4)
ORDER BY 3 DESC
LIMIT 10;


/*
Question 3
What is the consensus worst movie for each production company?
Find the movie with the most votes but with avg_vote <= 5 for each production
company.
Provide the top 10 movies ordered by votes (from highest to lowest)
Hint: Use an analytic function to find the top voted movie per production company
 */

 SELECT *
     FROM
    (SELECT original_title,
    production_company,
    avg_vote,
    votes,
    RANK() OVER (PARTITION BY production_company ORDER BY votes DESC ) rank
    FROM movies
    WHERE avg_vote <=5) a
WHERE rank=1
ORDER BY 4 DESC
LIMIT 10;

 /*
Question 4
What was the longest gap between movies published by "Marvel Studios"?
Use "date_published" as the date.
Return the gap as a field called "gap_length" that is an Interval data type
calculated by using the AGE() function.
AGE() documentation can be found here:
https://www.postgresql.org/docs/current/functions-datetime.html
Hint: Use an analytic function to align each Marvel movie with the movie
released immediately prior to it.
*/

SELECT
       original_title,
       date_published,
       prev_original_title,
       prev_date_published,
       AGE(DATE(date_published),DATE(prev_date_published)) AS gap_length
FROM (
         SELECT
                original_title,
                date_published,
                LAG(original_title, 1) OVER (ORDER BY date_published) as prev_original_title,
                LAG(date_published, 1) OVER (ORDER BY date_published) as prev_date_published
         FROM (
                  SELECT *
                  FROM movies
                  WHERE production_company ILIKE '%Marvel Studios%'
              ) as marvel_movies
     ) as a
WHERE prev_original_title IS NOT NULL
ORDER BY 5 DESC
LIMIT 1;

/*
Question 5
Of all Zoe Saldana movies (movies where she is listed in the actors column of the
movies table),
what is the % of total worldwide gross income contributed by each movie?
Round the % to 2 decimal places, sort from highest % to lowest %,
and return the top 10.
Numerator = worlwide_gross_income for each Zoe Saldana movie
Denominator = total worlwide_gross_income for all Zoe Saldana movies
Filter out any movies with null worlwide_gross_income
Hint: Use an analytic function to place the total (denominator) on each row
to make the calculation easy
*/

SELECT
    original_title,
    ROUND((CAST(LTRIM(worlwide_gross_income, '$ ') AS DECIMAL)/SUM(CAST(LTRIM(worlwide_gross_income, '$ ') AS DECIMAL)) OVER())*100.00,2) AS pct_total_gross_income
FROM  (
    SELECT *
    FROM movies
    WHERE actors ILIKE '%Zoe Saldana%' AND worlwide_gross_income IS NOT NULL AND worlwide_gross_income ILIKE '%$%'
        ) as a

ORDER BY 2 DESC
LIMIT 10;

