-- Query to convert device_activity_datelist into datelist_int representation
-- Each bit in the integer represents whether the user was active on that day
-- Bit position 0 = first day of the month, bit position 30 = 31st day

WITH user_devices_with_month AS (
    SELECT
        user_id,
        browser_type,
        device_activity_datelist,
        date AS activity_date,
        DATE_TRUNC('month', date) AS month_start
    FROM user_devices_cumulated
),

datelist_exploded AS (
    SELECT
        user_id,
        browser_type,
        activity_date,
        month_start,
        unnested_date,
        EXTRACT(DAY FROM unnested_date)::INTEGER - 1 AS day_bit_position
    FROM user_devices_with_month
    CROSS JOIN UNNEST(device_activity_datelist) AS unnested_date
    WHERE DATE_TRUNC('month', unnested_date) = month_start
),

datelist_int_calculated AS (
    SELECT
        user_id,
        browser_type,
        activity_date,
        month_start,
        SUM(POW(2, day_bit_position)::BIGINT) AS device_activity_datelist_int
    FROM datelist_exploded
    GROUP BY user_id, browser_type, activity_date, month_start
)

SELECT
    udc.user_id,
    udc.browser_type,
    udc.date AS activity_date,
    udc.device_activity_datelist,
    COALESCE(dic.device_activity_datelist_int, 0)
        AS device_activity_datelist_int
FROM user_devices_cumulated AS udc
LEFT JOIN datelist_int_calculated AS dic
    ON
        udc.user_id = dic.user_id
        AND udc.browser_type = dic.browser_type
        AND udc.date = dic.activity_date
ORDER BY udc.user_id, udc.browser_type, udc.date;
