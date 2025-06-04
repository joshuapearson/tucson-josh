---
title: "Optimizing ClickHouse Join Performance" # Title of the blog post.
date: 2025-06-04 # Date of post creation.
summary: "ClickHouse supports a wide variety of SQL join types, but users should
  be aware of the possible performance problems that can manifest when
  querying large datasets. Understanding what gives rise to these challenges
  allows us to come up with strategies for crafting more efficient queries for
  large datasets."
description: "Examining ClickHouse SQL Join performance and how to improve slow
  joins" # Description used for search engine.
featured: false # Sets if post is a featured post, making appear on the home page side bar.
draft: false # Sets whether to render this page. Draft of true will not be rendered.
toc: false # Controls if a table of contents should be generated for first-level links automatically.
usePageBundles: true # Set to true to group assets like images in the same folder as this post.
featureImage: "clickhouse-joins-hero.jpg" # Sets featured image on blog post.
featureImageCap: "Traffic rushes by at dusk" # Caption (optional).
featureImageAlt: "City night scene with headlights streaking by" # Alternative text for featured image.
thumbnail: "join-thumb.png" # Sets thumbnail image appearing inside card on homepage.
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
codeMaxLines: 25
---

ClickHouse is an amazing database engine. Want to handle billions of rows
of data? Want your queries to return in milliseconds? Want to do both of those
while still using SQL instead of some one-off query language or API? ClickHouse
ticks all of those boxes. For developers coming to ClickHouse from more
traditional OLTP databases like Postgres, MySQL or SQL Server it immediately
feels familiar and powerful. But a quick dive into the excellent
[documentation](https://clickhouse.com/docs/introduction-clickhouse) makes clear
that there are some key differences that developers and users need to understand
in order get the best out of it.

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
unsuspecting user into a performance trap that can cause queries to run far
slower than they should.

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
version `25.5.1.2782` on an Apple M1 MacBook Pro. It's possible that much of what
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
date.

Both the parent and child records have a field called `tags` which is an
array of strings representing some sort of denormalized metadata that we want to
search on. We also assume that each of these tables would have additional
columns, but those will make no difference to the queries that we'll look at
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

This whole dataset takes up about 2.2 GB of disk space and on my MacBook Pro it
takes about 30 seconds to run.

### A Simple Question

Let's start off with a straightforward query. We want to find all of the child
entities which have a parent entity with a particular tag, and we want to return
the arrays of tags for those child entities. Keeping in mind that the data in
question is randomly generated, let's verify that there's at least one matching
parent for a given tag, `'aaa'`:

```sql
SELECT count()
FROM example.parent
WHERE has(parent.tags, 'aaa');

   ┌─count()─┐
1. │       3 │
   └─────────┘

1 row in set. Elapsed: 0.093 sec. Processed 1.00 million rows, 60.52 MB (10.71 million rows/s., 647.94 MB/s.)
Peak memory usage: 21.75 MiB.
```

Okay, looks like we're good. This dataset has the tag `'aaa'` present in
three parent records. And finding those parent records is fast, taking only 93
milliseconds and 21.75 MiB of memory despite a lack of any indexing on the
column. Finding the related child records is a simple matter of joining the
child table:

```sql
SELECT child.tags
FROM example.parent
INNER JOIN example.child ON parent.id = child.parent
WHERE has(parent.tags, 'aaa');

     ┌─child.tags───────────────────────────────────────────────┐
  1. │ []                                                       │
  2. │ [',g','x`','7h','QD-','k.~','}_']                        │
  ...
308. │ ['','N`',',r\\']                                         │
309. │ ['',':9k','','X)h','#EY','w<']                           │
     └─child.tags───────────────────────────────────────────────┘

309 rows in set. Elapsed: 3.663 sec. Processed 101.00 million rows, 6.85 GB (27.31 million rows/s., 1.87 GB/s.)
Peak memory usage: 7.79 GiB.
```

This query gives us our answer and it took about 40 times longer to execute than
the previous select that only involved the parent, but considering the child
table has 100x more rows, that might not seem unreasonable. But that memory
usage should stand out as a big warning sign. We used over 7 GiB for this new
query.

### Left and Right - Not Just for Driving Directions

What's going on here to cause the memory consumption to go up so much? In the
ClickHouse
[using JOINS guide](https://clickhouse.com/docs/guides/joining-tables) the
second bullet point on the page lays it out:

> - Currently, ClickHouse does not reorder joins. Always ensure the smallest
>   table is on the right-hand side of the Join. This will be held in memory for
>   most join algorithms and will ensure the lowest memory overhead for the
>   query.

Looking at our use case, the child table has 100x more rows than the parent
table and we are using that child table on the right side of our join. Let's
see what happens if we switch the order of these two tables in the query.

```sql
SELECT child.tags
FROM example.child
INNER JOIN example.parent ON parent.id = child.parent
WHERE has(parent.tags, 'aaa');

-- Results snipped out for brevity

309 rows in set. Elapsed: 1.556 sec. Processed 101.00 million rows, 6.91 GB (64.90 million rows/s., 4.44 GB/s.)
Peak memory usage: 159.67 MiB.
```

Switching around the join order of this query makes an enormous difference. The
execution time improved by a factor of 2.3 and the memory consumption improved
by a factor of 48. ClickHouse isn't the only database for which join order can
be important, but many of us are used to relying on the optimizer reordering
joins in other DB engines. Many other RDBMS systems generate statistics about
data distribution in every table and column so that the optimizer can make
informed decisions about how to restructure queries for optimal performance.
For the time being, the best optimizer for your ClickHouse queries will be you
and your understanding of the data.

### Being More Explicit - SEMI JOIN

Since we are now relying on our own knowledge of the data and the intentions of
the query, perhaps we should consider a join type that more explicitly conveys
why we are using a join in the first place. `INNER JOIN` implies that we intend to
return columns from both the left and right side of the join, but in our case
the parent table is simply used as a filter for values in the child table. This
is exactly the domain of the `SEMI JOIN`. Let's try out a `SEMI LEFT JOIN` and
see how that affects performance.

```sql
SELECT child.tags
FROM example.child
SEMI LEFT JOIN example.parent ON parent.id = child.parent
WHERE has(parent.tags, 'aaa');

-- Results snipped out for brevity

309 rows in set. Elapsed: 2.949 sec. Processed 101.00 million rows, 6.92 GB (34.24 million rows/s., 2.35 GB/s.)
Peak memory usage: 198.49 MiB.
```

Looking at the results, we actually ended up with 1.9 times worse execution time
and slightly worse memory usage than our `INNER JOIN` version above. How is
that? I can't say for certain, but I suspect that there has been at least one
optimization that ClickHouse has implemented for `INNER JOIN` which has not made
it into the `SEMI LEFT JOIN`, and that optimization is to push down aspects of
the `WHERE` clause into the `ON` clause for the join criteria. Let's see what
happens if we explicitly make the check for the parent tags part of the `ON`
clause.

```sql
SELECT child.tags
FROM example.child
SEMI LEFT JOIN example.parent ON (parent.id = child.parent) AND has(parent.tags, 'aaa');

-- Results snipped out for brevity

309 rows in set. Elapsed: 1.529 sec. Processed 101.00 million rows, 6.92 GB (66.05 million rows/s., 4.52 GB/s.)
Peak memory usage: 88.75 MiB.
```

Moving the tags check into the `ON` clause seems to have done the trick and the
`INNER` and `SEMI LEFT` joins now perform very similarly in terms of both
execution time as well as memory usage. But what is actually happening to yield
the improvements in both execution time and memory consumption? As stated above,
the right hand table of a join will be held in memory for the entire join
operation. The more filtering that we can achieve in the `ON` clause, the
smaller that right table will be, reducing memory consumption, but also
improving execution time because there are fewer records to compare against the
left hand side.

Unfortunately, we are just at parity with the assumedly optimized `INNER JOIN`
rather than achieving better performance. Is this the best that we can do?

### A JOIN By Any Other Name

Fortunately we can achieve `JOIN` behavior in other ways that might help us out
further. Since our query is logically a `LEFT SEMI JOIN` with only a single join
key, that means it is equivalent to selecting records in `child` where `parent`
is in a list of `parent.id` values that we can find with a sub-query.

```sql
SELECT child.tags
FROM example.child
WHERE parent IN (
    SELECT id
    FROM example.parent
    WHERE has(parent.tags, 'aaa')
);

-- Results snipped out for brevity

309 rows in set. Elapsed: 0.148 sec. Processed 101.00 million rows, 926.96 MB (684.36 million rows/s., 6.28 GB/s.)
Peak memory usage: 29.64 MiB.
```

Wow, that's _much_ better! The execution time is 10.5 times better and memory
usage has gone down by a factor of 5.4 compared to the `INNER JOIN` that had
parent as the right table. Compared to our original `INNER JOIN` with the child
table on the right we have reduced execution time by a factor of 24.8 and memory
usage by a factor of 263. All of this was done without modifying our schema and
without adding any sort of projections or indexes.

### A Slightly Less Simple Question

What if we actually need the added features of a join and want to return data
from more than one table? Let's reformulate our original goal and say that we
still want to find all of the tags for each child record, but we also want the
full set of tags for the parent where that parent has a `'aaa'` tag present.
That's as easy as adding `parent.tags` to our `INNER JOIN`.

```sql
SELECT parent.tags AS parent_tags, child.tags AS child_tags
FROM example.child
INNER JOIN example.parent ON parent.id = child.parent AND has(parent.tags, 'aaa');

-- Results snipped out for brevity

309 rows in set. Elapsed: 1.489 sec. Processed 101.00 million rows, 6.92 GB (67.83 million rows/s., 4.65 GB/s.)
Peak memory usage: 162.55 MiB.
```

Impressively, ClickHouse is actually returning this larger set of data slightly
faster than the simpler query, but likely below the noise threshold. Similarly,
the memory usage has remained nearly the same as well. Given what we already
know about improving the performance of the simpler query, can we improve this
`INNER JOIN`? Knowing that the key to performance is reducing the size of the
tables in the join, let's try to limit just the parent set.

```sql
SELECT parent_sub.tags as parent_tags, child.tags as child_tags
FROM example.child
INNER JOIN (
  SELECT id, tags
  FROM example.parent
  WHERE has(parent.tags, 'aaa')
) AS parent_sub ON child.parent = parent_sub.id;

-- Results snipped out for brevity

309 rows in set. Elapsed: 1.561 sec. Processed 101.00 million rows, 6.92 GB (64.70 million rows/s., 4.43 GB/s.)
Peak memory usage: 164.38 MiB.
```

That looks like a wash. We don't see any improvement over the straightforward
`INNER JOIN` that we started with. What about optimizing the left side of the
join by reducing the size of that table too?

```sql
SELECT parent_sub.tags, child_sub.tags
FROM (
  SELECT child.parent, child.tags
  FROM example.child
  WHERE parent IN (
    SELECT id
    FROM example.parent
    WHERE has(parent.tags, 'aaa')
  )
) AS child_sub
INNER JOIN (
  SELECT id, tags
  FROM example.parent
  WHERE has(parent.tags, 'aaa')
) AS parent_sub ON child_sub.parent = parent_sub.id;

-- Results snipped out for brevity

309 rows in set. Elapsed: 0.159 sec. Processed 102.00 million rows, 1.02 GB (640.01 million rows/s., 6.39 GB/s.)
Peak memory usage: 54.34 MiB.
```

That seems to have done it. We are now getting comparable performance for this
inner join as we got with our `IN` clause in the simpler use case. The path to
this was thinking about how we can minimize the size of data at each step in the
query.

### That's Great, But Could You Make It Less Ugly?

Our new query is certainly more performant, but it isn't without tradeoffs from
a software engineering perspective. This approach is far less readable than the
simple `INNER JOIN` was and it also suffers from repetition in a way that could
easily lead to future bugs if only one of the parent subqueries got updated with
new requirements, like adding in a date range to the where clause (using a nice
feature of snowflake IDs).

How can we make this new query more understandable while retaining the
performance benefits that got us here? The answer is to use the
[Common Table Expression](https://clickhouse.com/docs/sql-reference/statements/select/with),
or CTE. CTEs allow the programmer to specify named subqueries using
the `WITH` clause and then refer to them later in the query. For our purposes we
will create two CTEs.

```sql
WITH parent_matches AS (
  SELECT parent.id AS parent_id, parent.tags AS parent_tags
  FROM example.parent
  WHERE has(parent.tags, 'aaa')
),
child_matches AS (
  SELECT child.parent AS parent_id, child.tags AS child_tags
  FROM example.child
  WHERE child.parent IN (
    SELECT parent_id
    FROM parent_matches
  )
)
SELECT parent_tags, child_tags
FROM child_matches
INNER JOIN parent_matches USING parent_id;

-- Results snipped out for brevity

309 rows in set. Elapsed: 0.144 sec. Processed 102.00 million rows, 967.24 MB (708.30 million rows/s., 6.72 GB/s.)
Peak memory usage: 54.35 MiB.
```

The use of common table expressions has allowed us to centralize the rule that
`parent.tags` has to have a value of `'aaa'`. No more duplication of the
filtering portion of the query. Well written CTEs can also convey intention to
other developers in a way that deeply nested subqueries often obscure.

### CTEs - Building Blocks for Optimization Fences

ClickHouse handles common table expressions the same way that it does
subqueries. That is to say, it simply replaces a CTE in your query with the
corresponding query that was specified. And how does ClickHouse handle
subqueries? Right now it does so in the most straightforward manner, executing
the contained query and utilizing the result as a sort of virtual table.

The optimizer will not attempt to rewrite a subquery with knowledge from the
containing query. It will not push down expressions from a parent `WHERE` clause
into the subquery nor any other advanced techniques. Because of this,
subqueries and CTEs are often referred to as optimization fences, meaning that
the database engine will not optimize across the boundary. This isn't the case
for all database systems and some even have complex rules around when a CTE
boundary is an optimization fence. Postgres, for instance, supports the syntax
`MATERIALIZED` and `NOT MATERIALIZED` in order to specify whether a CTE should
be an optimization fence or not, allowing the user to escape the complex rules
and use their own understanding of the data to provide the best query.

Knowing that we have this tool available to us in ClickHouse provides developers
with an opportunity to construct complex queries from simpler building blocks
that are each optimized for their particular need. Simple, well-composed systems
are easier to reason about and help to reduce maintenance costs. These simpler
components also help us to achieve a goal that often gets overlooked when we
optimize: consistency. A query that executes very fast most of the time, but
which has very poor P99 values is going to cause big headaches. Comprehensible
CTEs allow us to reason about what conditions can lead to outliers.

If you find yourself in a situation where you have to utilize joins in your
query it's a pretty good idea to start off constructing CTEs that express your
intent. As your query grows more complex it will be even more important.

### Be Wary of JOINs Below the Surface - Denormalization with Materialized Views

One of the best pieces of advice for consistently achieving optimal performance
in ClickHouse as well as any other RDBMS is to eliminate joins entirely where
possible. The most prominent way to avoid joins in user-facing code is to
denormalize your data such that disparate fields from multiple tables are
brought together into a single table that is optimized for the queries that are
performance-sensitive. ClickHouse provides an easy path for this approach with
an array of options for materialized views, including
[incremental materialized views](https://clickhouse.com/docs/materialized-view/incremental-materialized-view)
that can continuously build out denormalized tables as new records are inserted
into the constituent tables. User-facing queries are then run against this
denormalized data in such a way that joins are not needed, or are at least
minimized.

It's important to realize, though, that we haven't removed joins from our
workflow, we've just moved them to another part of the data path. When we write
the query for the materialized view the join will be run in the background when
new source records are inserted. Depending on how these inserts are performed,
ClickHouse may perform all of the materialization prior to returning from an
insert.

What happens if joins present in incremental materialized views start blowing up
as data volumes increase? What if these joins exceed the allowed memory usage
per query? The answer is that inserts will start to either fall behind or fail
entirely. For many systems this is a far worse situation than poor performance
for end-user queries. Losing any input data can be catastrophic in some systems.
Worse, the warning signs for poor insert performance are often harder to spot
than similar problems for those querying the data.

Optimizing your joins in materialized views is at least as important as doing so
in your user-facing queries. Fortunately, the techniques laid out above apply
to incremental materialization in the exact same ways. The one caveat that I
would give is that you should weigh the relative importance of execution time
and memory usage slightly differently for an incremental materialization query
compared with a user-facing query. Keeping peak memory usage low is critical for
materialization because that will help to insure that inserts don't fail, even
if they are slightly slower. Fortunately, even if you are dealing with very
large datasets there are ways to constrain memory usage beyond just query
structure. ClickHouse gives you the ability to specify the
[join algorithm](https://clickhouse.com/blog/clickhouse-fully-supports-joins-how-to-choose-the-right-algorithm-part5)
that will be used and some of these will prevent excessive memory consumption as
you grow into billions of rows of data. But that's a whole new topic that
deserves a post all to itself.

{{% notice note "Note" %}}
Execution times for performance testing will always have a fair amount of
variability. This has many causes, including noisy neighbor problems, cache hit
rates and more. I've tried to minimize this as much as possible, but left out
many of those details in order to keep this piece as succinct as possible.

If you generate the test data in this and run the same queries you will rapidly
discover that ClickHouse does a lot of caching for operations like finding rows
with matching tags in `parent`. Between the first run of a query and the second
you can see very large speedups. The times reported here are always for a cold
cache. If you'd like to discuss how I did this, please feel free to reach out.
{{% /notice %}}

{{% contactfooter %}}
