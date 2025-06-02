---
title: "Optimizing ClickHouse Join Performance" # Title of the blog post.
date: 2025-05-30T11:49:09-07:00 # Date of post creation.
summary: "ClickHouse supports a wide variety of SQL join types, but users should
  be aware of the possible performance problems that can manifest when
  querying large datasets. Understanding what gives rise to these challenges
  allows us to come up with strategies for crafting more efficient queries for
  large datasets."
description: "Examining ClickHouse SQL Join performance and how to improve slow
  join performance" # Description used for search engine.
featured: false # Sets if post is a featured post, making appear on the home page side bar.
draft: false # Sets whether to render this page. Draft of true will not be rendered.
toc: false # Controls if a table of contents should be generated for first-level links automatically.
usePageBundles: true # Set to true to group assets like images in the same folder as this post.
featureImage: "clickhouse-joins-hero.jpg" # Sets featured image on blog post.
featureImageCap: "Traffic rushes by at dusk" # Caption (optional).
featureImageAlt: "City night scene with headlights streaking by" # Alternative text for featured image.
#thumbnail: "/images/path/thumbnail.png" # Sets thumbnail image appearing inside card on homepage.
#showShare: false # Uncomment to not show share buttons on each post. Also available in each post's front matter.
#shareImage: "/images/path/share.png" # Designate a separate image for social media sharing.
#showDate: false
#showReadTime: false
#sidebar: false
#singleColumn: true
#figurePositionShow: true # Override global value for showing the figure label.
#showRelatedInArticle: false # Override global value for showing related posts in this series at the end of the content.
categories:
  - Software Engineering
tags:
  - ClickHouse
  - SQL
  - Performance
  - CTE
# comment: false # Disable comment if false.
---

ClickHouse is an amazing database engine. Want to handle billions of rows
of data? Want your queries to return in milliseconds? Want to do both of those
while still using SQL instead of some one-off query language or API? ClickHouse
ticks all of those boxes. For developers coming to ClickHouse from more
traditional OLTP databases like Postgres, MySQL or SQL Server it immediately
feels familiar and powerful. But a quick dive into the excellent
[documentation](https://clickhouse.com/docs/introduction-clickhouse) makes clear
that there are some key differences that developers and users need to understand
in order to properly use it.

The most significant differences between ClickHouse and the more familiar OLTP
databases arise from the way that data is stored as well as the algorithms
that are used to find matching records. An essential first step for new users is
to understand the importance of designing schema with well thought out
[primary keys](https://clickhouse.com/docs/best-practices/choosing-a-primary-key)
and
[compression](https://clickhouse.com/docs/data-compression/compression-in-clickhouse)
for the fields in each table. With just these few new concepts in hand it's easy to
start building systems that handle huge data loads with shockingly fast response
times. Unfortunately, the familiar SQL interface to this tool can draw an
unsuspecting user into a performance trap that can cause queries to run hundreds
or thousands of times slower than they should.

The culprit here, as I'm sure you'll have deduced from the title, is the `JOIN`
operation. This essential component of SQL needs to be handled carefully in
ClickHouse so that it won't explode execution times and memory usage. This isn't
to say that you shouldn't use joins. After all, a database with no joins isn't
very relational. Instead, you should apply what you know about your data to
carefully construct those relations in a way that works well with ClickHouse's
execution model.

{{% notice note "Note" %}}
ClickHouse is a rapidly evolving project with new features and improvements
coming out every month. The data in this post was collected using ClickHouse
version `25.5.1.2782` on a Apple M1 MacBook Pro. It's possible that much of what
is written here will not apply to future versions of ClickHouse as the team
changes the query planner and optimizer. We've seen this exact pattern with
Postgres, SQL Server, Oracle and nearly every other RDBMS that gains significant
traction in the market.
{{% /notice %}}

### A Relationship We All Know

Let's start by constructing a simple schema that we can use to explore how
problems can arise when joining tables in a query. We'll consider a parent/child
relationship with `UInt64` ID fields that we will populate with a
[snowflake ID](https://en.wikipedia.org/wiki/Snowflake_ID) which will provide
the link between child and parent:

```sql
CREATE TABLE example.parent
(
    `id` UInt64 CODEC (Delta, ZSTD), -- Snowflake ID
    `tags` Array(String), -- Denormalized metadata about parent
    -- ... Other fields can exist in columnar DB with no impact on query at hand
)
ENGINE = MergeTree
ORDER BY id;
```

```sql
CREATE TABLE example.child
(
    `id` UInt64 CODEC (Delta, ZSTD), -- Snowflake ID
    `parent` UInt64, -- Reference to parent.id
    `tags` Array(String), -- Denormalized metadata about this child entity
    -- ... Other fields can exist in columnar DB with no impact on query at hand
)
ENGINE = MergeTree
ORDER BY id;
```

The primary key/order by for each of these tables is the aforementioned
snowflake ID for each respective entity, implying that both parent and child are
time-series in some fashion. This sort of schema arises in many situations like
tracing, event monitoring or even the original use case for snowflake, Twitter's
post and comment identifiers. For those unfamiliar with snowflake IDs, one of
the big draws is that they are sortable by time such that a snowflake generated
for a later date will have a greater value than one generated for an earlier
date. Both the parent and child records have a field called tags which is an
array of strings representing some sort of denormalized metadata that we want to
search on. We also assume that each of these tables would have additional
columns, but those will make no difference to the queries that we will look at
since ClickHouse is a columnar database.

Let's start off by creating some random data that we can test against. The
following script will generate a million parent records and a hundred million
child records, which will be randomly distributed among the parents. Child
records have an ID based on a timestamp between the parent's value and one week
after. Additionally, each record, whether child or parent has a tags array
with zero to ten strings that range in length from zero to three characters.

```sql
SET param_BASE = 1000000; -- BASE determines the number of parent records that will be created
SET param_RATIO = 100; -- RATIO determines how many child records will be created with respect to the number of parent records created
SET param_MILLIDAY = 86400000; -- Milliseconds in a day

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
```

This whole dataset takes up about 2.2 GB of disk space and on my MacBook Pro
about 30 seconds to generate.

### Seems Like a Simple Question

### Left and Right - Not Just for Driving Directions

### Being More Explicit - SEMI, ANTI & ANY

### A JOIN By Any Other Name

### A Slightly Less Simple Question

### That's Great, But Could You Make It Less Ugly?

### CTEs - Building Blocks for Optimization Fences

### Be Wary of JOINs Below the Surface - Denormalization with Materialized Views

{{% contactfooter %}}
