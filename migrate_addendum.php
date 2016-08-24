<html><head><title>migrate_addendum.php!</title><head>
<body>
<?php

// require_once $_SERVER['DOCUMENT_ROOT'] . '/includes/config.inc.php';
require_once './includes/config.inc.php';

require_once './migrate_util.php';




# This query refreshes the first arrivals.
$refresh_first_arrivals_for_trip_query = "
    begin;
        truncate {$dst_schema}.snap_first_arrivals_for_trip;

        insert into {$dst_schema}.snap_first_arrivals_for_trip 
        select 
            trip_id, arrival_time as first_arrival_time
        from (
                select 
                    trip_id, arrival_time,
                    stop_sequence,
                    min(stop_sequence) over (partition by trip_id) as min_stop_sequence 
                from {$src_schema}.stop_times
                join {$src_schema}..trips using (trip_id)
                where stop_times.agency_id in (select agency_id from {$dst_schema}.agencies)
            ) st
        where stop_sequence = min_stop_sequence;

    commit;

    ";

db_query_debug($refresh_first_arrivals_for_trip_query);


db_query_debug("
    TRUNCATE {$dst_schema}.dev_patterns_trips;
");

// combined_schedule_insert_query
$patterns_trips_query = "
    WITH patterns_trips AS 
    (
        SELECT DISTINCT 
            timed_pattern_id, agency_id, 
            unnest(trips_list) as trip_id
        FROM {$dst_schema}.timed_pattern_stops_nonnormalized
        GROUP BY timed_pattern_id, agency_id, trips_list
    ) 
    INSERT INTO {$dst_schema}.dev_patterns_trips 
        ( timed_pattern_id, agency_id, trip_id )
    SELECT
        timed_pattern_id, agency_id, trip_id
    FROM patterns_trips
    WHERE
        agency_id IN (select agency_id from {$dst_schema}.agencies) 
";

db_query_debug($patterns_trips_query);

// db_query_debug("
//    TRUNCATE {$dst_schema}.dev_trips;
// ");

/*
db_query_debug("

    BEGIN;
    TRUNCATE play_migrate.snap_first_arrivals_for_trip;
    INSERT INTO play_migrate.snap_first_arrivals_for_trip 
    SELECT 
        trips.trip_id, 
        views.first_arrival_time_for_trip(trips.trip_id) AS first_arrival_time
    FROM public.trips;
    COMMIT;

    BEGIN;
    TRUNCATE migrate.snap_first_arrivals_for_trip;
    INSERT INTO migrate.snap_first_arrivals_for_trip 
    SELECT 
        trip_id, first_arrival_time
    FROM play_migrate.snap_first_arrivals_for_trip;
    COMMIT;

 ");
 */


$add_stop_time_trips_in_calendar_query = "
   INSERT into {$dst_schema}.trips
        (agency_id
       , timed_pattern_id
       , calendar_id
       , start_time
       , end_time, headway_secs, block_id
       , monday, tuesday, wednesday, thursday, friday, saturday, sunday
       , in_seat_transfer)

   SELECT trips.agency_id
        , dev_patterns_trips.timed_pattern_id AS timed_pattern_id
        , service_schedule_group_id AS calendar_id
        , snap_first_arrivals_for_trip.first_arrival_time AS start_time 
        , NULL::INTERVAL as end_time,  NULL::integer as headway_secs, block_id
        , monday::boolean, tuesday::boolean, wednesday::boolean, thursday::boolean
        , friday::boolean, saturday::boolean, sunday::boolean 
        , in_seat_transfer = 1
   FROM {$src_schema}.trips 
   INNER JOIN {$src_schema}.calendar 
      ON trips.service_id = calendar.calendar_id 
   INNER JOIN {$dst_schema}.snap_first_arrivals_for_trip using (trip_id)
   INNER JOIN {$dst_schema}.dev_patterns_trips using (trip_id)
   WHERE NOT EXISTS (SELECT NULL FROM {$src_schema}.frequencies 
                         WHERE trips.trip_id = frequencies.trip_id) 
         AND based_on IS NULL 
         AND trips.service_id IS NOT NULL 
         AND snap_first_arrivals_for_trip.first_arrival_time IS NOT null
         AND trips.agency_id IN (select agency_id FROM {$dst_schema}.agencies) 
   GROUP BY trips.agency_id, timed_pattern_id, calendar_id
          , snap_first_arrivals_for_trip.first_arrival_time
          , trips.trip_id, end_time
          , headway_secs, block_id, monday, tuesday, wednesday, thursday
          , friday, saturday, sunday, in_seat_transfer
   HAVING service_schedule_group_id IS NOT NULL /* HACK: workaround for gtfsmanager issue #370 */
       ";
/* ED: GROUP BY above, might be necessary after all. testing. 2016-08-07 */

db_query_debug($add_stop_time_trips_in_calendar_query);

// strange. no rows copied here. investigate more fully?
db_query_debug ("
   INSERT into {$dst_schema}.trips
        (agency_id, timed_pattern_id, calendar_id
       , start_time
       , end_time, headway_secs, block_id
       , monday, tuesday, wednesday, thursday, friday, saturday, sunday
       , in_seat_transfer)

   SELECT trips.agency_id, dev_patterns_trips.timed_pattern_id AS timed_pattern_id
        , service_schedule_group_id AS calendar_id, trips.trip_start_time::INTERVAL AS start_time
        , NULL::INTERVAL as end_time, NULL::INTEGER as headway_secs, block_id
        , monday::boolean, tuesday::boolean, wednesday::boolean, thursday::boolean
        , friday::boolean, saturday::boolean, sunday::boolean 
        , in_seat_transfer = 1
   FROM {$src_schema}.trips 
   INNER JOIN {$dst_schema}.dev_patterns_trips using (trip_id)
   INNER JOIN {$src_schema}.calendar 
           ON trips.service_id = calendar.calendar_id 
   WHERE trips.service_id IS NOT NULL 
         AND NOT EXISTS (SELECT NULL FROM {$src_schema}.frequencies 
                         WHERE trips.trip_id = frequencies.trip_id) 
         AND based_on IS NOT NULL
         AND trips.agency_id IN (select agency_id FROM {$dst_schema}.agencies) 
     ");

// strange. no rows copied here. investigate more fully?
db_query_debug ("
   INSERT into {$dst_schema}.trips
        (agency_id, timed_pattern_id, calendar_id
       , start_time
       , end_time, headway_secs, block_id
       , monday, tuesday, wednesday, thursday, friday, saturday, sunday
       , in_seat_transfer)

   SELECT trips.agency_id, dev_patterns_trips.timed_pattern_id AS timed_pattern_id
        , service_schedule_group_id AS calendar_id, frequencies.start_time::INTERVAL AS start_time
        , frequencies.end_time::INTERVAL as end_time, frequencies.headway_secs 
        , block_id
        , monday::boolean, tuesday::boolean, wednesday::boolean, thursday::boolean
        , friday::boolean, saturday::boolean, sunday::boolean 
        , in_seat_transfer = 1 
   FROM {$src_schema}.frequencies 
   INNER JOIN {$src_schema}.trips USING (trip_id)
   INNER JOIN {$dst_schema}.dev_patterns_trips using (trip_id)
   INNER JOIN {$src_schema}.calendar 
           ON trips.service_id = calendar.calendar_id 
   WHERE trips.service_id IS NOT NULL 
         AND based_on IS NOT NULL
         AND trips.agency_id IN (select agency_id FROM {$dst_schema}.agencies) 
     ");


db_query_debug("
   INSERT into {$dst_schema}.trips
        (agency_id, timed_pattern_id, calendar_id
       , start_time
       , end_time, headway_secs, block_id
       , monday, tuesday, wednesday, thursday, friday, saturday, sunday
       , in_seat_transfer)

   SELECT trips.agency_id, dev_patterns_trips.timed_pattern_id AS timed_pattern_id
        , service_schedule_group_id AS calendar_id, frequencies.start_time::INTERVAL AS start_time
        , frequencies.end_time::INTERVAL as end_time, frequencies.headway_secs AS headway, block_id
        , monday::boolean, tuesday::boolean, wednesday::boolean, thursday::boolean
        , friday::boolean, saturday::boolean, sunday::boolean 
        , in_seat_transfer = 1
   FROM {$src_schema}.frequencies 
   INNER JOIN trips USING (trip_id)
   INNER JOIN {$dst_schema}.dev_patterns_trips using (trip_id)
   INNER JOIN calendar 
           ON trips.service_id = calendar.calendar_id 
   WHERE trips.service_id IS NOT NULL 
         AND based_on IS NULL
         AND trips.agency_id IN (select agency_id FROM {$dst_schema}.agencies) 
");

# renumber routes to use alphabetical where there is no consistent ordering applied.
#
# based on view of agencies having routes with unorderd (or partially ordered) routes:
/*
 
    create view migrate.dev_agencies_having_routes_without_full_ordering 
    as select 
        agency_id 
    from migrate.routes 
    group by agency_id 
    having count(distinct route_sort_order) <> count(route_id) 

 */
#
$order_unordered_routes_alphabetically_by_route_long_name_query = "
    with 

    ordered_routes
    as
    (select 
        *, 
        row_number() 
            over (partition by agency_id order by route_long_name, route_short_name) as route_alpha_order 
    FROM {$dst_schema}.routes 
    inner join 
    {$dst_schema}.dev_agencies_having_routes_without_full_ordering using (agency_id) 
    order by agency_id, route_alpha_order)

    update {$dst_schema}.routes
        set route_sort_order = ordered_routes.route_alpha_order
    FROM ordered_routes
    where routes.route_id = ordered_routes.route_id 
    ";

db_query_debug($order_unordered_routes_alphabetically_by_route_long_name_query);


## FIXME: this won't work if dst_schema is other than migrate or play_migrate.
## Something to look at when we support "importing" agencies via this migrate script.
$fmt = '$fmt'; #HACK so I can copy/paste the expression below. Ed 2016-08-15
$update_sequences_query = "
select public.exec(format($fmt$
    select pg_catalog.setval('%s',
                             (select 1+max(%I) from %I.%I)); $fmt$,
    sequencename, columnname, schemaname, tablename))
from views.default_column_values
where schemaname = '{$dst_schema}';
    ";

db_query_debug($update_sequences_query);

echo "<br / >\n" . "Migration addendum successful.";

?>
</body></html>

