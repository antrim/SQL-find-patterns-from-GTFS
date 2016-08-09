<html><head><title>migrate_addendum.php!</title><head>
<body>
<?php

// require_once $_SERVER['DOCUMENT_ROOT'] . '/includes/config.inc.php';
require_once './includes/config.inc.php';

require_once './migrate_util.php';


# This query refreshes the first arrivals.
$refresh_first_arrivals_for_trip_query = "
    refresh materialized view play_migrate.dev_first_arrivals_for_trip ;

    begin;
        truncate play_migrate.snap_first_arrivals_for_trip;

        insert into play_migrate.snap_first_arrivals_for_trip 
            select * from play_migrate.dev_first_arrivals_for_trip;
    commit;

    begin;
        truncate migrate.snap_first_arrivals_for_trip;

        insert into migrate.snap_first_arrivals_for_trip 
            select * from play_migrate.dev_first_arrivals_for_trip;
    commit;
    ";

if (False) {
    # It takes 10 minutes, so we typically only
    # run this once per day.
    db_query_debug($refresh_first_arrivals_for_trip_query);
}



db_query_debug("
    TRUNCATE {$table_prefix}.dev_patterns_trips;
");

// combined_schedule_insert_query
$patterns_trips_query = "
    WITH patterns_trips AS 
    (
        SELECT DISTINCT 
            timed_pattern_id, agency_id, 
            unnest(trips_list) as trip_id
        FROM {$table_prefix}.timed_pattern_stops_nonnormalized
        GROUP BY timed_pattern_id, agency_id, trips_list
    ) 
    INSERT INTO {$table_prefix}.dev_patterns_trips 
        ( timed_pattern_id, agency_id, trip_id )
    SELECT
        timed_pattern_id, agency_id, trip_id
    FROM patterns_trips
    WHERE agency_id NOT IN ($skip_agency_id_string)
";

db_query_debug($patterns_trips_query);

// db_query_debug("
//    TRUNCATE {$table_prefix}.dev_trips;
// ");

/*
db_query_debug("
    refresh materialized view play_migrate.dev_first_arrivals_for_trip ;

    truncate play_migrate.snap_first_arrivals_for_trip;

    insert into play_migrate.snap_first_arrivals_for_trip 
        select * from play_migrate.dev_first_arrivals_for_trip;

    truncate migrate.snap_first_arrivals_for_trip;

    insert into migrate.snap_first_arrivals_for_trip 
        select * from play_migrate.dev_first_arrivals_for_trip;
 ");
 */


$add_stop_time_trips_in_calendar_query = "
   INSERT into {$table_prefix}.trips
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
   FROM trips 
   INNER JOIN calendar 
      ON trips.service_id = calendar.calendar_id 
   INNER JOIN {$table_prefix}.snap_first_arrivals_for_trip using (trip_id)
   INNER JOIN {$table_prefix}.dev_patterns_trips using (trip_id)
   WHERE NOT EXISTS (SELECT NULL from frequencies 
                         WHERE trips.trip_id = frequencies.trip_id) 
         AND based_on IS NULL 
         AND trips.service_id IS NOT NULL 
         AND snap_first_arrivals_for_trip.first_arrival_time IS NOT null
   GROUP BY trips.agency_id, timed_pattern_id, calendar_id
          , snap_first_arrivals_for_trip.first_arrival_time
          , trips.trip_id, end_time
          , headway_secs, block_id, monday, tuesday, wednesday, thursday
          , friday, saturday, sunday, in_seat_transfer
    /* ED: group might be necessary after all. testing. 2016-08-07
     */
       ";

db_query_debug($add_stop_time_trips_in_calendar_query);

// strange. no rows copied here. investigate more fully?
db_query_debug ("
   INSERT into {$table_prefix}.trips
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
   FROM trips 
   INNER JOIN {$table_prefix}.dev_patterns_trips using (trip_id)
   INNER JOIN calendar 
           ON trips.service_id = calendar.calendar_id 
   WHERE trips.service_id IS NOT NULL 
         AND NOT EXISTS (SELECT NULL from frequencies 
                         WHERE trips.trip_id = frequencies.trip_id) 
         AND based_on IS NOT NULL;
     ");

// strange. no rows copied here. investigate more fully?
db_query_debug ("
   INSERT into {$table_prefix}.trips
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
   FROM frequencies 
   INNER JOIN trips USING (trip_id)
   INNER JOIN {$table_prefix}.dev_patterns_trips using (trip_id)
   INNER JOIN calendar 
           ON trips.service_id = calendar.calendar_id 
   WHERE trips.service_id IS NOT NULL 
         AND based_on IS NOT NULL
     ");


db_query_debug("
   INSERT into {$table_prefix}.trips
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
   FROM frequencies 
   INNER JOIN trips USING (trip_id)
   INNER JOIN {$table_prefix}.dev_patterns_trips using (trip_id)
   INNER JOIN calendar 
           ON trips.service_id = calendar.calendar_id 
   WHERE trips.service_id IS NOT NULL 
         AND based_on IS NULL;
");

echo "<br / >\n" . "Migration addendum successful.";

?>
</body></html>

