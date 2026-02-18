WITH yesterday AS (
    SELECT
        host,
        host_activity_datelist,
        date AS activity_date
    FROM hosts_cumulated
    WHERE date = DATE('2023-01-01')
),

today AS (
    SELECT
        host,
        DATE_TRUNC('day', event_time::timestamp) AS today_date
    FROM events
    WHERE
        DATE_TRUNC('day', event_time::timestamp) = DATE('2023-01-02')
        AND host IS NOT NULL
    GROUP BY
        host, DATE_TRUNC('day', event_time::timestamp)
)

INSERT INTO hosts_cumulated
SELECT
    COALESCE(t.host, y.host) AS host,
    COALESCE(y.host_activity_datelist, ARRAY[]::date [])
    || CASE
        WHEN t.host IS NOT NULL
            THEN ARRAY[t.today_date::date]
        ELSE ARRAY[]::date []
    END AS host_activity_datelist,
    COALESCE(t.today_date::date, y.activity_date + interval '1 day') AS date
FROM yesterday AS y
FULL OUTER JOIN today AS t
    ON y.host = t.host;
