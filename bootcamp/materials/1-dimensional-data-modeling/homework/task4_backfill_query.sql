-- Task 4: Backfill query for actors_history_scd table
-- This query populates the entire actors_history_scd table in a single operation
-- by processing all years and creating type 2 SCD records for quality_class and is_active changes

INSERT INTO actors_history_scd (
    actor, actorid, quality_class, is_active, start_date, end_date, current_year
)
WITH actor_yearly_stats AS (
    SELECT
        actor,
        actorid,
        year,
        CASE
            WHEN AVG(rating) > 8 THEN 'star'
            WHEN AVG(rating) > 7 THEN 'good'
            WHEN AVG(rating) > 6 THEN 'average'
            ELSE 'bad'
        END::quality_class_enum AS quality_class,
        TRUE AS is_active
    FROM actor_films
    GROUP BY actor, actorid, year
),

actor_state_changes AS (
    SELECT
        actor,
        actorid,
        year,
        quality_class,
        is_active,
        LAG(quality_class)
            OVER (PARTITION BY actorid ORDER BY year)
            AS prev_quality_class,
        LAG(is_active)
            OVER (PARTITION BY actorid ORDER BY year)
            AS prev_is_active,
        LEAD(year) OVER (PARTITION BY actorid ORDER BY year) AS next_year
    FROM actor_yearly_stats
),

af_max AS (
    SELECT
        actorid,
        MAX(year) AS max_year
    FROM actor_films
    GROUP BY actorid
),

scd_records AS (
    SELECT
        actor,
        actorid,
        quality_class,
        is_active,
        year AS start_date,
        COALESCE(next_year - 1, 2021) AS end_date,
        year AS current_year
    FROM actor_state_changes
    WHERE
        -- First record for this actor OR state changed from previous year
        prev_quality_class IS NULL
        OR prev_is_active IS NULL
        OR quality_class != prev_quality_class
        OR is_active != prev_is_active

    UNION ALL

    -- Handle actors who become inactive (no films in subsequent years)
    SELECT DISTINCT
        ays.actor,
        ays.actorid,
        ays.quality_class,
        FALSE AS is_active,
        af_max.max_year + 1 AS start_date,
        2021 AS end_date,
        af_max.max_year + 1 AS current_year
    FROM actor_yearly_stats AS ays
    INNER JOIN
        af_max
        ON ays.actorid = af_max.actorid AND ays.year = af_max.max_year
    WHERE af_max.max_year < 2021
)

SELECT
    actor,
    actorid,
    quality_class,
    is_active,
    start_date,
    end_date,
    current_year
FROM scd_records
ORDER BY actorid, start_date;
