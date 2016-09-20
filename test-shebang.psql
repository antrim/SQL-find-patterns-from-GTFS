#!/bin/bash
# /* Use sed so psql sees the same line numbers in the input file, and it is
# easier to find errors based on their line number.  */
sed '1,5s@.*@@;' $0 | psql -f -
exit 0 
-- begin psql

\echo hello world

\echo SRC_SCHEMA :SRC_SCHEMA
\echo DST_SCHEMA :DST_SCHEMA

select 'baz' as bar, 2 / 1 as foo;
select 3 / 2 as bar;
select 1 / 0 as baz;

create temp table foo (baz text);
insert into foo values ('hello');
select * from foo, (select * from generate_series(1,5)) y , (select * from generate_series(8,12)) x order by random();


