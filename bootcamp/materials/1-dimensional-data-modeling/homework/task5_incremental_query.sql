-- Task 5: Incremental query for actors_history_scd table
-- This query combines previous year's SCD data with new incoming data from the actors table
-- It handles both updating existing records (setting end_date) and creating new records for state changes

WITH previous_scd AS (
    -- Get the most recent SCD record for each actor
    SELECT DISTINCT ON (actorid)
        actor,
        actorid,
        quality_class,
        is_active,
        start_date,
        end_date,
        current_year
    FROM actors_history_scd
    WHERE current_year =: previous_year
    ORDER BY actorid ASC, end_date DESC
),

current_actors AS (
    -- Get current year's actor data
    SELECT
        actor,
        actorid,
        quality_class,
        is_active
    FROM actors
),

all_actors AS (
    -- Combine previous SCD data with current actors to handle both active and inactive actors
    SELECT
        c.quality_class AS current_quality_class,
        c.is_active AS current_is_active,
        p.quality_class AS previous_quality_class,
        p.is_active AS previous_is_active,
        p.start_date AS previous_start_date,
        p.end_date AS previous_end_date,
        COALESCE(c.actor, p.actor) AS actor,
        COALESCE(c.actorid, p.actorid) AS actorid
    FROM current_actors AS c
    FULL OUTER JOIN previous_scd AS p ON c.actorid = p.actorid
),

scd_updates AS (
    -- Identify records that need to be closed (state changed or actor became inactive)
    SELECT
        actor,
        actorid,
        previous_quality_class AS quality_class,
        previous_is_active AS is_active,
        previous_start_date AS start_date,
        : current_year - 1 AS end_date,
        : previous_year AS current_year
    FROM all_actors
    WHERE
        -- Actor had a previous record
        previous_quality_class IS NOT NULL
        AND (
            -- Actor is no longer active (not in current actors table)
            current_quality_class IS NULL
            -- OR quality class changed
            OR current_quality_class != previous_quality_class
            -- OR active status changed
            OR current_is_active != previous_is_active
        )
        -- AND the previous record hasn't been closed yet
        AND previous_end_date =: previous_year
),

new_records AS (
    -- Create new records for state changes and new actors
    SELECT
        actor,
        actorid,
        COALESCE(current_quality_class, previous_quality_class)
            AS quality_class,
        COALESCE(current_is_active, FALSE) AS is_active,
        : current_year AS start_date,
        : current_year AS end_date,
        : current_year AS current_year
    FROM all_actors
    WHERE
        -- New actor (no previous record)
        previous_quality_class IS NULL
        -- OR state changed from previous year
        OR (
            current_quality_class IS NOT NULL
            AND current_quality_class != previous_quality_class
        )
        OR (
            current_is_active IS NOT NULL
            AND current_is_active != previous_is_active
        )
        -- OR actor became inactive
        OR (current_quality_class IS NULL AND previous_is_active = TRUE)
),

unchanged_records AS (
    -- Carry forward unchanged records with updated end_date
    SELECT
        actor,
        actorid,
        previous_quality_class AS quality_class,
        previous_is_active AS is_active,
        previous_start_date AS start_date,
        : current_year AS end_date,
        : current_year AS current_year
    FROM all_actors
    WHERE
        -- Actor exists in both previous and current
        previous_quality_class IS NOT NULL
        AND current_quality_class IS NOT NULL
        -- AND state hasn't changed
        AND current_quality_class = previous_quality_class
        AND current_is_active = previous_is_active
        -- AND the record is still open
        AND previous_end_date =: previous_year
)

-- Combine all records: closed records, new records, and unchanged records
SELECT * FROM scd_updates
UNION ALL
SELECT * FROM new_records
UNION ALL
SELECT * FROM unchanged_records
ORDER BY actorid, start_date;
