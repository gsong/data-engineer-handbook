-- Task 3: DDL for actors_history_scd table
-- This table implements type 2 dimension modeling to track historical changes
-- in actor quality_class and is_active status over time

DROP TABLE IF EXISTS actors_history_scd;
CREATE TABLE actors_history_scd (
    actor TEXT NOT NULL,
    actorid TEXT NOT NULL,
    quality_class QUALITY_CLASS_ENUM NOT NULL,
    is_active BOOLEAN NOT NULL,
    start_date INTEGER NOT NULL,
    end_date INTEGER NOT NULL,
    current_year INTEGER NOT NULL
);
