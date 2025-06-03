--------------------------------------------------------------------------------
-- Traditional Join --
--------------------------------------------------------------------------------
-- Parent as left
SET enable_filesystem_cache = 0;
SELECT
  -- snowflakeIDToDateTime(parent.id) AS parent_date,
  -- parent.tags AS parent_tags,
  -- snowflakeIDToDateTime(child.id) AS child_date,
  child.tags
FROM example.parent
INNER JOIN example.child ON parent.id = child.parent
WHERE has(parent.tags, 'aaa')
-- SETTINGS join_algorithm = 'full_sorting_merge';

-- Child as left
SET enable_filesystem_cache = 0;
SELECT
  -- snowflakeIDToDateTime(parent.id) AS parent_date,
  -- parent.tags AS parent_tags,
  -- snowflakeIDToDateTime(child.id) AS child_date,
  child.tags
FROM example.child
INNER JOIN example.parent ON parent.id = child.parent
WHERE has(parent.tags, 'aaa')
-- SETTINGS join_algorithm = 'full_sorting_merge';

-- Child as left and use left semi join
SET enable_filesystem_cache = 0;
SELECT
  -- snowflakeIDToDateTime(parent.id) AS parent_date,
  -- parent.tags AS parent_tags,
  snowflakeIDToDateTime(child.id) AS child_date,
  child.tags
FROM example.child
LEFT SEMI JOIN example.parent ON parent.id = child.parent
WHERE has(parent.tags, 'aaa')
-- SETTINGS join_algorithm = 'full_sorting_merge';


SET enable_filesystem_cache = 0;
SELECT
  child.tags
FROM example.child
WHERE parent IN (
  SELECT id
  FROM example.parent
  WHERE has(parent.tags, 'aaa'));

SET enable_filesystem_cache = 0;
SELECT parent_sub.tags, child_sub.tags
FROM (
  SELECT
    child.parent,
    child.tags
  FROM example.child
  WHERE parent IN (
    SELECT id
    FROM example.parent
    WHERE has(parent.tags, 'aaa'))
) AS child_sub
INNER JOIN (
  SELECT id, tags
  FROM example.parent
  WHERE has(parent.tags, 'aaa')
) AS parent_sub ON child_sub.parent = parent_sub.id;

SET enable_filesystem_cache = 0;
SELECT child.tags, parent_sub.tags
FROM example.child
INNER JOIN (
  SELECT id, tags
  FROM example.parent
  WHERE has(parent.tags, 'aaa')
) AS parent_sub ON child.parent = parent_sub.id;

--------------------------------------------------------------------------------
-- CTE Joins --
--------------------------------------------------------------------------------
-- Parent CTE used for IN clause
SET enable_filesystem_cache = 0;
WITH parent_cte AS (
  SELECT
      parent.id AS parent_id,
      parent.tags AS parent_tags
  FROM example.parent
  WHERE has(parent.tags, 'aaa')
)
SELECT --snowflakeIDToDateTime(child.id) AS child_date,
  child.tags AS child_tags
FROM example.child
WHERE child.parent in (
  SELECT parent_cte.parent_id
  FROM parent_cte
)

-- Parent as left
SET enable_filesystem_cache = 0;
WITH parent_cte AS (
  SELECT parent.id AS parent_id, parent.tags AS parent_tags
  FROM example.parent
  WHERE has(parent.tags, 'aaa')
),
child_cte AS (
  SELECT child.parent AS parent_id, child.tags AS child_tags
  FROM example.child
  WHERE child.parent IN (
    SELECT parent_id
    FROM parent_cte
  )
)
SELECT parent_tags, child_tags
FROM child_cte
INNER JOIN parent_cte ON child_cte.parent_id = parent_cte.parent_id;


SET enable_filesystem_cache = 0;
WITH parent_cte AS (
  SELECT
      parent.id AS parent_id
  FROM example.parent
  WHERE has(parent.tags, 'aaa')
)
SELECT 
  snowflakeIDToDateTime(child.parent) AS parent_date,
  snowflakeIDToDateTime(child.id) AS child_date,
  child.tags
FROM example.child
LEFT SEMI JOIN parent_cte ON (child.parent = parent_cte.parent_id)

SET enable_filesystem_cache = 0;
WITH parent_cte AS (
  SELECT
      parent.id AS parent_id
  FROM example.parent
  WHERE has(parent.tags, 'aaa')
)
SELECT 
  snowflakeIDToDateTime(child.id) AS child_date,
  child.tags
FROM example.child
WHERE child.parent IN (
  SELECT parent_id
  FROM parent_cte
)


-- set enable_filesystem_cache = 0;

-- SELECT --snowflakeIDToDateTime(parent.id) as parent_date,
--   --length(parent.tags) as parent_tag_count,
--   snowflakeIDToDateTime(child.id) as child_date,
--   child.tags
-- FROM example.parent
-- INNER JOIN example.child ON parent.id = child.parent
-- WHERE has(child.tags, 'aaa')

-- set enable_filesystem_cache = 0;

-- SELECT --snowflakeIDToDateTime(parent.id) as parent_date,
--   --length(parent.tags) as parent_tag_count,
--   snowflakeIDToDateTime(child.id) as child_date,
--   child.tags
-- FROM example.child
-- INNER JOIN example.parent ON parent.id = child.parent
-- WHERE has(child.tags, 'aaa')
