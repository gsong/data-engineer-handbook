-- Query to deduplicate game_details from Day 1 (2016-01-01)
-- This query removes any potential duplicates based on the logical key (game_id, player_id)
-- using ROW_NUMBER() to keep only the first occurrence

WITH day1_game_details AS (
    SELECT gd.*
    FROM game_details AS gd
    INNER JOIN games AS g ON gd.game_id = g.game_id
    WHERE g.game_date_est = '2016-01-01'
),

deduplicated_game_details AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY game_id, player_id
            ORDER BY game_id, team_id, player_id
        ) AS row_num
    FROM day1_game_details
)

SELECT
    game_id,
    team_id,
    team_abbreviation,
    team_city,
    player_id,
    player_name,
    nickname,
    start_position,
    comment,
    min,
    fgm,
    fga,
    fg_pct,
    fg3m,
    fg3a,
    fg3_pct,
    ftm,
    fta,
    ft_pct,
    oreb,
    dreb,
    reb,
    ast,
    stl,
    blk,
    "TO",
    pf,
    pts,
    plus_minus
FROM deduplicated_game_details
WHERE row_num = 1
ORDER BY game_id, team_id, player_id;
