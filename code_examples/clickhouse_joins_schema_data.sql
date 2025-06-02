DROP TABLE IF EXISTS example.parent;
CREATE TABLE example.parent
(
    -- UInt64 to store snowflake ID
    `id` UInt64 CODEC (Delta, ZSTD),
    -- Denormalized tags about this parent entity
    `tags` Array(String),
    -- ... Other fields can exist in columnar DB with no impact on query at hand
)
ENGINE = MergeTree
ORDER BY id;

DROP TABLE IF EXISTS example.child;
CREATE TABLE example.child
(
    -- UInt64 to store snowflake ID
    `id` UInt64 CODEC (Delta, ZSTD),
    -- Reference to snowflake ID of parent
    `parent` UInt64,
    -- Denormalized tags about this parent entity
    `tags` Array(String),
    -- ... Other fields can exist in columnar DB with no impact on query at hand
)
ENGINE = MergeTree
ORDER BY id;



--------------------------------------------------------------------------------
-- Populate Data
--------------------------------------------------------------------------------

-- BASE determines the number of parent records that will be created
SET param_BASE = 1000000;
-- RATIO determines how many child records will be created with respect to the number of parent records created
SET param_RATIO = 100;
-- Milliseconds in a day
SET param_MILLIDAY = 86400000;

WITH parent_vals AS (
  -- Create records from now back through one year prior
  SELECT (now() - toIntervalMillisecond(randUniform(0, {MILLIDAY:UInt64} * 365))) AS ts, tags
  FROM generateRandom('tags Array(String)', NULL, 3, 10)
  LIMIT {BASE:UInt64}
)
INSERT INTO example.parent
SELECT
  dateTime64ToSnowflakeID(parent_vals.ts) AS id,
  parent_vals.tags AS tags
FROM parent_vals;

WITH parent_vals AS (
  SELECT row_number() OVER () AS p_row,
    id AS parent,
    snowflakeIDToDateTime(id) AS ts
  FROM example.parent
),
child_vals AS (
  -- Create child records from parent time up through a week later
  SELECT toIntervalMillisecond(randUniform(0, {MILLIDAY:UInt64} * 7)) AS ts_offset,
    -- Find random parent for each child row created by referencing row_number from above
    (rand64() % {BASE:UInt64} + 1) AS p_row,
    tags
  FROM generateRandom('tags Array(String)', NULL, 3, 10)
  LIMIT ({BASE:UInt64} * {RATIO:UInt64})
)
INSERT INTO example.child
SELECT dateTime64ToSnowflakeID(parent_vals.ts + child_vals.ts_offset) AS id,
  parent_vals.parent AS parent,
  child_vals.tags AS tags
FROM child_vals
INNER JOIN parent_vals ON parent_vals.p_row = child_vals.p_row;

-- With child as left
-- 0 rows in set. Elapsed: 25.604 sec. Processed 101.10 million rows, 6.06 GB (3.95 million rows/s., 236.85 MB/s.)
-- Peak memory usage: 662.42 MiB.

-- With parent as left
-- Received exception from server (version 25.5.1):
-- Code: 241. DB::Exception: Received from localhost:9001. DB::Exception: Query memory limit exceeded: would use 9.32 GiB (attempt to allocate chunk of 4.01 MiB bytes), maximum: 9.31 GiB.: While executing FillingRightJoinSide. (MEMORY_LIMIT_EXCEEDED)
