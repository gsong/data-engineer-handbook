WITH yesterday AS (
    SELECT
        month AS report_month,
        host,
        hit_array,
        unique_visitors_array
    FROM host_activity_reduced
    WHERE month = DATE_TRUNC('month', DATE('2023-01-02'))
),

today AS (
    SELECT
        host,
        DATE_TRUNC('day', event_time::timestamp) AS today_date,
        DATE_TRUNC('month', event_time::timestamp) AS month_start,
        COUNT(*) AS num_hits,
        COUNT(DISTINCT user_id) AS unique_visitors
    FROM events
    WHERE
        DATE_TRUNC('day', event_time::timestamp) = DATE('2023-01-02')
        AND host IS NOT NULL
    GROUP BY
        host,
        DATE_TRUNC('day', event_time::timestamp),
        DATE_TRUNC('month', event_time::timestamp)
)

INSERT INTO host_activity_reduced
SELECT
    COALESCE(t.month_start::date, y.report_month) AS month,
    COALESCE(t.host, y.host) AS host,
    COALESCE(
        y.hit_array,
        ARRAY_FILL(
            NULL::integer, ARRAY[EXTRACT(DAY FROM t.today_date)::integer - 1]
        )
    )
    || ARRAY[t.num_hits::integer] AS hit_array,
    COALESCE(
        y.unique_visitors_array,
        ARRAY_FILL(
            NULL::integer, ARRAY[EXTRACT(DAY FROM t.today_date)::integer - 1]
        )
    )
    || ARRAY[t.unique_visitors::integer] AS unique_visitors_array
FROM yesterday AS y
FULL OUTER JOIN today AS t
    ON y.host = t.host AND y.report_month = t.month_start::date;
