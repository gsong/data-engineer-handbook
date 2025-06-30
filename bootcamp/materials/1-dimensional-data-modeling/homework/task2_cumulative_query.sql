INSERT INTO actors (actor, actorid, films, quality_class, is_active)
WITH current_year_films AS (
    SELECT
        actor,
        actorid,
        ARRAY_AGG(
            ROW(film, votes, rating, filmid, year)::film_struct
        ) AS films_this_year,
        CASE
            WHEN AVG(rating) > 8 THEN 'star'
            WHEN AVG(rating) > 7 THEN 'good'
            WHEN AVG(rating) > 6 THEN 'average'
            ELSE 'bad'
        END::quality_class_enum AS quality_class_this_year
    FROM actor_films
    WHERE year = 1970
    GROUP BY actor, actorid
),

actor_updates AS (
    SELECT
        COALESCE(prev.actor, new_films.actor) AS actor,
        COALESCE(prev.actorid, new_films.actorid) AS actorid,
        COALESCE(prev.films, ARRAY[]::film_struct [])
        || COALESCE(
            new_films.films_this_year, ARRAY[]::film_struct []
        ) AS films,
        COALESCE(
            new_films.quality_class_this_year, prev.quality_class
        ) AS quality_class,
        new_films.actorid IS NOT NULL AS is_active
    FROM actors AS prev
    FULL OUTER JOIN current_year_films AS new_films
        ON prev.actorid = new_films.actorid
)

SELECT
    actor,
    actorid,
    films,
    quality_class,
    is_active
FROM actor_updates
ON CONFLICT (actorid)
DO UPDATE SET
    films = excluded.films,
    quality_class = excluded.quality_class,
    is_active = excluded.is_active;
