/*
 for vim.

 let $SRC_SCHEMA = 'public'
 let $DST_SCHEMA = 'play_migrate'
 let $DST_SCHEMA = ''' oh crap --'
 let $DST_SCHEMA = 'migrate'
 let $PGHOST = 'localhost'
 let $PGUSER = 'ed'
 let $PGPORT = '5432'
 let $PGDATABASE = 'trillium_gtfs_production_2016_09_20'
 let g:simpledb_prelude_query = '\i migrate_util.sql'

 for testing connection settings.

 \l
 \dt
 select current_database();

*/

\ir migrate_util.sql

\echo SRC_SCHEMA: :"SRC_SCHEMA"
\echo DST_SCHEMA: :"DST_SCHEMA"

-- BEGIN TRANSACTION;

\ir lib/truncate-all.sql

\ir lib/insert-feeds.sql

\ir lib/insert-agencies.sql

-- this takes a long time. can we break it up into smaller parts?
\ir lib/insert-timed-pattern-stops-nonnormalized.sql

\ir lib/insert-zones.sql

\ir lib/insert-patterns.sql
\ir lib/insert-pattern-stops.sql
\ir lib/insert-timed-patterns.sql
\ir lib/insert-timed-pattern-stops.sql 


\ir lib/insert-routes.sql

\ir lib/insert-headsigns.sql

\ir lib/insert-directions.sql

\ir lib/insert-calendars.sql

\ir lib/insert-calendar-bounds.sql

\ir lib/insert-blocks.sql

\ir lib/insert-stops.sql

-- All lines in the file are commented out, this just shows the order where it
-- used to be executed. 
\ir lib/insert-patterns-old.sql

\ir lib/insert-shape-segments.sql

\ir lib/insert-calendar-dates.sql

\ir lib/insert-fare-attributes.sql

\ir lib/insert-fare-rider-categories.sql

\ir lib/insert-fare-rules.sql

\ir lib/insert-transfers.sql

\ir lib/automatically-assign-pattern-names.sql

\ir lib/automatically-assign-block-colors.sql

\ir lib/refresh-snap-first-arrivals-for-trip.sql

-- TODO: dev_patterns_trips might not be a good name for this table.
-- what naming convention can we use to indicate that this is for import use only?
-- it's the same class of table as timed_pattern_stops_nonnormalized
\ir lib/refresh-dev-patterns-trips.sql

\ir lib/insert-trips.sql

\ir lib/automatically-order-routes.sql


\ir lib/insert-users.sql

\ir lib/insert-user-permissions.sql


-- Database permissions, sequence numbers, other such metadata.
\ir migrate_addendum.sql

-- COMMIT TRANSACTION

\echo 'Migration successful'

