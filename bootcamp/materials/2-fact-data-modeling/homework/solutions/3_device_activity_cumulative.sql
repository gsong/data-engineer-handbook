WITH yesterday AS (
    SELECT
        user_id,
        browser_type,
        device_activity_datelist,
        date AS activity_date
    FROM user_devices_cumulated
    WHERE date = DATE('2023-01-01')
),

today AS (
    SELECT
        e.user_id,
        d.browser_type,
        DATE_TRUNC('day', e.event_time::timestamp) AS today_date
    FROM events AS e
    INNER JOIN devices AS d ON e.device_id = d.device_id
    WHERE
        DATE_TRUNC('day', e.event_time::timestamp) = DATE('2023-01-02')
        AND e.user_id IS NOT NULL
    GROUP BY
        e.user_id, d.browser_type, DATE_TRUNC('day', e.event_time::timestamp)
)

INSERT INTO user_devices_cumulated
SELECT
    COALESCE(t.user_id, y.user_id) AS user_id,
    COALESCE(t.browser_type, y.browser_type) AS browser_type,
    COALESCE(y.device_activity_datelist, ARRAY[]::date [])
    || CASE
        WHEN t.user_id IS NOT NULL
            THEN ARRAY[t.today_date]
        ELSE ARRAY[]::date []
    END AS device_activity_datelist,
    COALESCE(t.today_date, y.activity_date + interval '1 day') AS date
FROM yesterday AS y
FULL OUTER JOIN today AS t
    ON y.user_id = t.user_id AND y.browser_type = t.browser_type;
