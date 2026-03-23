SELECT * FROM player_seasons;

-- CREATE TYPE season_stats AS (
--         season INTEGER,
--         gp INTEGER,
--         pts REAL,
--         reb REAL,
--         ast REAL
--                             );

--fields that dont really change
--  CREATE TABLE players
--  (
--      player_name    TEXT,
--      height         TEXT,
--      college        TEXT,
--      country        TEXT,
--      draft_year     TEXT,
--      draft_round    TEXT,
--      draft_number   TEXT,
--      season_stats   season_stats[], --an array
--      current_season INTEGER,      --not season because the table is going to be developed cumulatively
--      PRIMARY KEY(player_name,current_season)
--  );

--FULL OUTER JOIN LOGIC
--1) MIN SEASON 1996
SELECT MIN(season)
FROM player_seasons;
--2) --MAX SEASON 2022
SELECT MAX(season)
FROM player_seasons;

--2) CTEs of the season
INSERT INTO players
WITH yesterday AS (
    SELECT *
    FROM players
    WHERE current_season = 2021),

today AS (SELECT *
              FROM player_seasons
              WHERE season = 2022)
SELECT            -- we wanna COALESCE the temporal values, the ones that aren't changing
     COALESCE(t.player_name, y.player_name) AS player_name,
     COALESCE(t.height, y.height) AS height,
     COALESCE(t.college, y.college) AS college,
     COALESCE(t.country, y.country) AS country,
     COALESCE(t.draft_year, y.player_name) AS draft_year,
     COALESCE(t.draft_round, y.draft_round) AS draft_round,
     COALESCE(t.draft_number, y.draft_number) AS draft_number,
     CASE WHEN y.season_stats IS NULL
        THEN ARRAY[ROW( --Create an array in a row of the below season_stats
            t.season,
            t.gp,
            t.pts,
            t.reb,
            t.ast)::season_stats] --same as TRY_CAST(FIELD AS SPECIFIC DATA TYPE)
--we wanna see if the yesterday value is there, so we can make an array concat which is going
-- to slowly build up the array of values
        WHEN t.season IS NOT NULL THEN y.season_stats || ARRAY[ROW( --Create an array in a row of the below season_stats
            t.season,
            t.gp,
            t.pts,
            t.reb,
            t.ast)::season_stats] --if its not null then the array shows different stats in time,historical data
         ELSE y.season_stats
 ---we dont want to add on the array when the today value is null(exp player has retired)
    END AS season_stats,
--   2nd way of the below COALESCE,  CASE WHEN t.season IS NOT NULL THEN t.season
--     ELSE y.current_season + 1
    COALESCE(t.season, y.current_season + 1) AS current_season
FROM today t
FULL OUTER JOIN yesterday y
ON t.player_name = y.player_name;

--as expected, everything from yesterday is NULL in the OUTER JOIN table
--the first COALESCE of the yesterdays' and today's table just returns the today's data-> seed table.
--When you first run the incremented query(by using coalesce and calculating - filling the season field.
--then we want to make it like a pipeline, so INSERT INTO

SELECT * FROM players
where current_season=1998; --we changed the CTEs' values to current_season=1996 - seasn=1997,..paring until max(season).

-- 3)
SELECT * FROM players
WHERE current_season = 2022;
AND player_name = 'Michael Jordan';

--4) if you want to reverse the flattened out table created, then use UNNEST(array), then the 3 seasons JORDAN played are written in three lines and not one as before
--Explode it back out and get the columns and not three arrays
WITH UNNESTED AS (
SELECT player_name,
        UNNEST(season_stats)::season_stats AS season_stats
FROM players
WHERE current_season = 2001
AND player_name = 'Michael Jordan'
    )

--5) to do so you need add a new CTE named UNNESTED and then cast the array as season_stats
SELECT player_name,
       (season_stats::season_stats).*
FROM UNNESTED; --That's how to get back to the old schema and the run length encoding is not a problem because all are grouped --> cumulative table designs




