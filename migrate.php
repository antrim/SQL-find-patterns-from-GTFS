<?php

// require_once $_SERVER['DOCUMENT_ROOT'] . '/includes/config.inc.php';
require_once './includes/config.inc.php';

$live = false;
set_time_limit(7200);

$table_prefix = "play_migrate";
$agency_array = array (1, 3, 175, 267, 392);

$agency_string = implode(",", $agency_array);

// So apparently trillium_gtfs_web will never be able to run truncate on the 
// table created by aaron_super with an autoincrement counter
// http://dba.stackexchange.com/questions/58282/error-must-be-owner-of-relation-user-account-id-seq
//
// ED. Addressed via changing owner of sequence, for example:
// ALTER SEQUENCE play_migrate_blocks_block_id_seq OWNER TO trillium_gtfs_group ;

$truncate_migrate_tables_query = "TRUNCATE 
    {$table_prefix}_timed_pattern_stops_nonnormalized, {$table_prefix}_agency, 
    {$table_prefix}_pattern_stop, {$table_prefix}_timed_pattern_stop, 
    {$table_prefix}_timed_pattern, {$table_prefix}_routes, 
    {$table_prefix}_pattern, 
    {$table_prefix}_headsigns, {$table_prefix}_directions, 
    {$table_prefix}_schedule, {$table_prefix}_calendar, 
    {$table_prefix}_calendar_bounds, {$table_prefix}_stops, 
    {$table_prefix}_blocks, {$table_prefix}_feed RESTART IDENTITY;";

$truncate_migrate_tables_result = db_query($truncate_migrate_tables_query);

$migrate_timed_pattern_stops_nonnormalized_query  = "
INSERT INTO {$table_prefix}_timed_pattern_stops_nonnormalized 
    (agency_id, agency_name, route_short_name, route_long_name, 
     direction_label, direction_id, trip_headsign_id, 
     trip_headsign, stop_id, stop_order, timed_pattern_id, 
     pattern_id, arrival_time, departure_time, pickup_type, drop_off_type, 
     one_trip, trips_list, stops_pattern, arrival_time_intervals, 
     departure_time_intervals, route_id, stop_headsign_id)

WITH pattern_time_intervals AS (
    SELECT MIN(trips.trip_id) as one_trip
         , string_agg( trips.trip_id::text, ', ' ORDER BY sequences.min_arrival_time ) AS trips_list
         , sequences.stops_pattern, arrival_time_intervals, departure_time_intervals
         , trips.agency_id, trips.route_id, trips.direction_id
    FROM trips
    INNER JOIN (
        SELECT string_agg(stop_times.stop_id::text, ', ' ORDER BY stop_times.stop_sequence ASC) AS stops_pattern
             , stop_times.trip_id
             , MIN( stop_times.arrival_time ) AS min_arrival_time
        FROM stop_times -- ED 2016-06-07 added this FROM, it looks like what the SELECT wanted.
        INNER JOIN trips ON stop_times.trip_id = trips.trip_id
        WHERE stop_times.agency_id IN ($agency_string) 
              AND trips.based_on IS NULL
        GROUP BY stop_times.trip_id) AS sequences 
      ON trips.trip_id = sequences.trip_id

    INNER JOIN
        (SELECT min_arrival_time, min_departure_time, min_trip_times.trip_id
              , string_agg(CASE WHEN stop_times.arrival_time IS NOT NULL 
                               THEN (stop_times.arrival_time - min_arrival_time)::text 
                               ELSE ''
                           END
                        ,  ','  ORDER BY stop_times.stop_sequence ASC) as arrival_time_intervals
              , string_agg(CASE WHEN stop_times.arrival_time IS NOT NULL 
                           THEN (stop_times.departure_time - min_departure_time)::text 
                           ELSE ''
                           END
                        ,  ','  ORDER BY stop_times.stop_sequence ASC) as departure_time_intervals 
         FROM stop_times
         INNER JOIN trips ON stop_times.trip_id = trips.trip_id
         INNER JOIN (
                 SELECT MIN( arrival_time ) AS min_arrival_time
                      , MIN( departure_time ) AS min_departure_time
                      , stop_times.trip_id
                 FROM stop_times
                 INNER JOIN trips on stop_times.trip_id = trips.trip_id
                 WHERE stop_times.agency_id IN ($agency_string) 
                       AND trips.based_on IS NULL
                 GROUP BY stop_times.trip_id) min_trip_times 
           ON stop_times.trip_id = min_trip_times.trip_id
         WHERE stop_times.agency_id in ($agency_string) AND trips.based_on IS NULL
         GROUP BY min_trip_times.trip_id,min_arrival_time,min_departure_time
        ) AS time_intervals_result

       ON sequences.trip_id = time_intervals_result.trip_id
     WHERE trips.agency_id IN ($agency_string) AND trips.based_on IS NULL
     GROUP BY stops_pattern, arrival_time_intervals, departure_time_intervals
            , trips.agency_id, trips.route_id, trips.direction_id
   )
        
, timed_patterns_sub AS (

    SELECT pattern_time_intervals.*, MIN( stop_times.arrival_time ) AS min_arrival_time
         , MIN( stop_times.departure_time) AS min_departure_time
    FROM pattern_time_intervals
    INNER JOIN  stop_times 
           ON pattern_time_intervals.one_trip = stop_times.trip_id 
    WHERE stop_times.agency_id IN ($agency_string)
    GROUP BY  one_trip, trips_list, stops_pattern, arrival_time_intervals
            , departure_time_intervals, pattern_time_intervals.agency_id, route_id, direction_id

)

, timed_patterns AS (
    SELECT row_number() over() AS timed_pattern_id, * 
    FROM timed_patterns_sub)

, stop_patterns AS (

    WITH unique_patterns AS(
    SELECT DISTINCT string_agg(stop_times.stop_id::text , ', ' ORDER BY stop_times.stop_sequence ASC) AS stops_pattern,trips.route_id,trips.direction_id

         FROM stop_times
         inner join trips on stop_times.trip_id = trips.trip_id
         WHERE trips.agency_id IN ($agency_string) AND trips.based_on IS NULL
         GROUP BY stop_times.trip_id,trips.route_id,trips.direction_id)
    SELECT unique_patterns.stops_pattern,route_id,direction_id,row_number() over() as pattern_id from unique_patterns
)

SELECT timed_patterns.agency_id, agency.agency_name, routes.route_short_name
     , routes.route_long_name, directions.direction_label, trips.direction_id
     , headsigns.headsign_id, headsigns.headsign, stop_times.stop_id
     , dense_rank() over (partition by timed_pattern_id order by stop_times.stop_sequence) as stop_order
     , timed_pattern_id
     , stop_patterns.pattern_id
     , CASE WHEN stop_times.arrival_time IS NOT NULL 
           THEN (stop_times.arrival_time - min_arrival_time) 
           ELSE NULL 
       END as arrival_time
     , CASE WHEN stop_times.departure_time IS NOT NULL 
           THEN (stop_times.departure_time - min_departure_time) 
           ELSE NULL
       END as departure_time
     , pickup_type, drop_off_type
     , one_trip, trips_list, stop_patterns.stops_pattern, arrival_time_intervals
     , departure_time_intervals, trips.route_id, stop_times.headsign_id as stop_headsign_id 
FROM timed_patterns
LEFT JOIN stop_times ON timed_patterns.one_trip = stop_times.trip_id
INNER JOIN stop_patterns ON (timed_patterns.stops_pattern = stop_patterns.stops_pattern 
                             AND timed_patterns.route_id = stop_patterns.route_id 
                             AND timed_patterns.direction_id = stop_patterns.direction_id)
INNER JOIN trips ON stop_times.trip_id = trips.trip_id
INNER JOIN routes ON trips.route_id = routes.route_id
LEFT JOIN directions ON trips.direction_id = directions.direction_id
LEFT JOIN headsigns ON trips.headsign_id = headsigns.headsign_id
INNER JOIN agency ON stop_times.agency_id = agency.agency_id
ORDER BY pattern_id, timed_pattern_id ASC, stop_times.stop_sequence ASC";

$migrate_timed_pattern_stops_nonnormalized_result = db_query($migrate_timed_pattern_stops_nonnormalized_query);

echo $migrate_timed_pattern_stops_nonnormalized_query;

$migrate_agency_query  = "
    INSERT INTO {$table_prefix}_agency 
        (agency_id, agency_id_import, agency_url, agency_timezone, agency_lang_id
       , agency_name, agency_short_name, agency_phone, agency_fare_url, agency_info
       , query_tracking, last_modified, maintenance_start, gtfs_plus
       , no_frequencies, feed_id) 
    SELECT DISTINCT agency.agency_id, agency_id_import, agency_url, agency_timezone, agency_lang_id
       , agency_name, agency_short_name, agency_phone, agency_fare_url, agency_info
       , query_tracking, agency.last_modified, maintenance_start, gtfs_plus
       , no_frequencies, agency_group_id as feed_id 
    FROM AGENCY
    INNER JOIN agency_group_assoc ON agency.agency_id = agency_group_assoc.agency_id 
    WHERE agency.agency_id IN ($agency_string)";

$migrate_agency_result = db_query($migrate_agency_query);

$migrate_feeds_query  = "
    INSERT INTO {$table_prefix}_feed
        (id, feed_name, contact_email
       , contact_url, license, last_modified)  
    SELECT DISTINCT agency_groups.agency_group_id, group_name, feed_contact_email
                  , feed_contact_url, feed_license, agency_groups.last_modified 
    FROM agency_groups 
    INNER JOIN agency_group_assoc 
            ON agency_group_assoc.agency_group_id = agency_groups.agency_group_id 
    WHERE agency_group_assoc.agency_id IN ($agency_string)";
$migrate_feeds_result = db_query($migrate_feeds_query);
echo "\n\n".$migrate_feeds_query."\n\n";

// pattern_stop.sql
$migrate_pattern_stop_query  = "
    INSERT into {$table_prefix}_pattern_stop
    SELECT DISTINCT  agency_id, pattern_id, stop_order, stop_id 
    FROM {$table_prefix}_timed_pattern_stops_nonnormalized
    ORDER BY agency_id, pattern_id, stop_order";
$result = db_query($migrate_pattern_stop_query);

// timed_pattern_intervals.sql
$migrate_timed_pattern_stop_query  = "
    INSERT into {$table_prefix}_timed_pattern_stop 
        (agency_id, timed_pattern_id, stop_order, arrival_time, departure_time
       , pickup_type, drop_off_type, headsign_id)
    SELECT DISTINCT agency_id, timed_pattern_id, stop_order, arrival_time, departure_time
                  , pickup_type, drop_off_type, stop_headsign_id
    FROM {$table_prefix}_timed_pattern_stops_nonnormalized
    ORDER BY agency_id, timed_pattern_id, stop_order";
$result = db_query($migrate_timed_pattern_stop_query);

// timed_pattern.sql
$migrate_timed_pattern_query  = "
    INSERT into {$table_prefix}_timed_pattern (agency_id, timed_pattern_id, pattern_id)
    SELECT DISTINCT agency_id, timed_pattern_id, pattern_id
    FROM {$table_prefix}_timed_pattern_stops_nonnormalized
    ORDER BY agency_id, pattern_id, timed_pattern_id";
$result = db_query($migrate_timed_pattern_query);

// routes.sql
$migrate_routes_stop_query  = "
    INSERT INTO {$table_prefix}_routes 
        (agency_id, route_id, route_short_name, route_long_name, route_desc, route_type
       , route_color, route_text_color, route_url, route_bikes_allowed, route_id_import
       , last_modified, route_sort_order, hidden) 
    SELECT agency_id, route_id, route_short_name, route_long_name, route_desc, route_type
         , route_color, route_text_color, route_url, route_bikes_allowed, route_id_import
         , last_modified, route_sort_order, hidden 
    FROM routes 
    WHERE agency_id IN ($agency_string)";
$result = db_query($migrate_routes_stop_query);

// patterns.sql
// some patterns may be used by multiple routes/directions!!!!
// one way to test this is: SELECT DISTINCT ON (pattern_id) agency_id, pattern_id, route_id, direction_id
$migrate_pattern_query  = "
    INSERT into {$table_prefix}_pattern (agency_id, pattern_id, route_id, direction_id)
    SELECT DISTINCT agency_id, pattern_id, route_id, direction_id
    FROM {$table_prefix}_timed_pattern_stops_nonnormalized
    ORDER BY  pattern_id, agency_id, route_id, direction_id";
$result = db_query($migrate_pattern_query);

// continuing with patterns.sql
// ALERT! Some patterns are on multiple routes. I need to figure out how to handle this. <-- come back here and play -- test results

// SELECT count(distinct agency_id), pattern_id, count(distinct route_id) as route_count, count(distinct direction_id) as direction_count
// FROM {$table_prefix}_timed_pattern_stops_nonnormalized
// group by pattern_id
// ORDER BY route_count DESC, direction_count DESC

// headsigns.sql
// ALERT! There are some null headsigns to look into here.

$migrate_headsigns_query  = "
    INSERT into {$table_prefix}_headsigns (agency_id, headsign_id, headsign)
    SELECT DISTINCT  agency_id, trip_headsign_id as headsign_id, trip_headsign AS headsign
    FROM {$table_prefix}_timed_pattern_stops_nonnormalized where trip_headsign_id IS NOT NULL AND trip_headsign IS NOT NULL
    UNION
    SELECT DISTINCT  agency_id, stop_headsign_id as headsign_id, stop_headsign AS headsign
    FROM {$table_prefix}_timed_pattern_stops_nonnormalized where stop_headsign_id IS NOT NULL AND stop_headsign IS NOT NULL
    ORDER BY agency_id, headsign_id";
$result = db_query($migrate_headsigns_query);

// directions.sql
// ALERT!! There are some duplicate direction_id values to look ingo

$migrate_directions_query  = "
    INSERT INTO {$table_prefix}_directions 
        (agency_id, direction_id, direction_label)
    SELECT DISTINCT on (direction_id)  agency_id, direction_id, direction_label
    FROM {$table_prefix}_timed_pattern_stops_nonnormalized
    ORDER BY direction_id, agency_id";
$result = db_query($migrate_directions_query);

// calendar
$migrate_calendar_query  = "
    INSERT into {$table_prefix}_calendar 
        (agency_id, calendar_id
       , label)
    SELECT agency_id, service_schedule_group_id AS calendar_id
         , service_schedule_group_label AS label 
    FROM service_schedule_groups
    WHERE agency_id IN ($agency_string) 
          AND service_schedule_group_id IS NOT NULL;";
$result = db_query($migrate_calendar_query);

// calendar
$migrate_calendar_bounds_query  = "
    INSERT into {$table_prefix}_calendar_bounds 
        (agency_id, calendar_id, start_date, end_date)
    SELECT agency_id, service_schedule_group_id as calendar_id, start_date, end_date 
    FROM service_schedule_bounds
    WHERE agency_id IN ($agency_string) 
          AND service_schedule_group_id IS NOT NULL;";
$result = db_query($migrate_calendar_bounds_query);

// blocks
$migrate_blocks_query  = "
    INSERT into {$table_prefix}_blocks 
        (agency_id, block_id, label)
    SELECT DISTINCT agency_id, block_id, block_label 
    FROM blocks
    WHERE agency_id IN ($agency_string) 
          AND block_id IS NOT NULL;";
$result = db_query($migrate_blocks_query);

// stops
$migrate_stops_query  = "
    INSERT into {$table_prefix}_stops 
        (agency_id, stop_id, stop_code, platform_code, location_type, parent_station
       , stop_desc, stop_comments, location, zone_id
       , city, direction_id, url, publish_status, timezone)
    SELECT agency_id, stop_id, stop_code, platform_code, location_type, parent_station
         , stop_desc, stop_comments, geom, zone_id
         , city, direction_id, stop_url, publish_status, stop_timezone
    FROM stops
    WHERE agency_id IN ($agency_string);";
$result = db_query($migrate_stops_query);

$patterns_nonnormalized_query = "
    SELECT DISTINCT timed_pattern_id, agency_id, trips_list 
    FROM {$table_prefix}_timed_pattern_stops_nonnormalized;";
$patterns_nonnormalized_result   = db_query($patterns_nonnormalized_query);
  
while ($row = db_fetch_array($patterns_nonnormalized_result, MYSQL_ASSOC)) {
    $timed_pattern_id = $row['timed_pattern_id'];
    $agency_id = $row['agency_id'];
    $trips_list = $row['trips_list'];

    $schedule_insert_query = "
       INSERT into {$table_prefix}_schedule 
            (agency_id, timed_pattern_id, calendar_id
           , start_time
           , end_time, headway, block_id
           , monday, tuesday, wednesday, thursday, friday, saturday, sunday)
       SELECT trips.agency_id, {$timed_pattern_id} AS timed_pattern_id
            , service_schedule_group_id AS calendar_id, MIN(arrival_time)::INTERVAL AS start_time
            , NULL::INTERVAL as end_time,  NULL::integer as headway, block_id
            , monday::boolean, tuesday::boolean, wednesday::boolean, thursday::boolean
            , friday::boolean, saturday::boolean, sunday::boolean 
       FROM trips 
       INNER JOIN stop_times 
          ON trips.trip_id = stop_times.trip_id 
       INNER JOIN calendar 
          ON trips.service_id = calendar.calendar_id 
       WHERE trips.trip_id IN ({$trips_list}) 
             AND NOT EXISTS (SELECT NULL from frequencies 
                             WHERE trips.trip_id = frequencies.trip_id) 
             AND based_on IS NULL 
             AND trips.service_id IS NOT NULL 
       GROUP BY trips.agency_id, timed_pattern_id, calendar_id, end_time
              , headway, block_id, monday, tuesday, wednesday, thursday
              , friday, saturday, sunday
   UNION
       SELECT trips.agency_id, {$timed_pattern_id} AS timed_pattern_id
            , service_schedule_group_id AS calendar_id, trips.trip_start_time::INTERVAL AS start_time
            , NULL::INTERVAL as end_time, NULL::INTEGER as headway, block_id
            , monday::boolean, tuesday::boolean, wednesday::boolean, thursday::boolean
            , friday::boolean, saturday::boolean, sunday::boolean 
       FROM trips 
       INNER JOIN calendar 
               ON trips.service_id = calendar.calendar_id 
       WHERE trips.trip_id IN ({$trips_list}) 
             AND trips.service_id IS NOT NULL 
             AND NOT EXISTS (SELECT NULL from frequencies 
                             WHERE trips.trip_id = frequencies.trip_id) 
             AND based_on IS NOT NULL
   UNION
       SELECT trips.agency_id, {$timed_pattern_id} AS timed_pattern_id
            , service_schedule_group_id AS calendar_id, frequencies.start_time::INTERVAL AS start_time
            , frequencies.end_time::INTERVAL as end_time, frequencies.headway_secs AS headway, block_id
            , monday::boolean, tuesday::boolean, wednesday::boolean, thursday::boolean
            , friday::boolean, saturday::boolean, sunday::boolean 
       FROM frequencies 
       INNER JOIN trips 
               ON frequencies.trip_id = trips.trip_id 
       INNER JOIN calendar 
              ON trips.service_id = calendar.calendar_id 
       WHERE frequencies.trip_id IN ({$trips_list}) 
       AND trips.service_id IS NOT NULL 
       AND based_on IS NOT NULL
   UNION
       SELECT trips.agency_id, {$timed_pattern_id} AS timed_pattern_id
            , service_schedule_group_id AS calendar_id, frequencies.start_time::INTERVAL AS start_time
            , frequencies.end_time::INTERVAL as end_time, frequencies.headway_secs AS headway, block_id
            , monday::boolean, tuesday::boolean, wednesday::boolean, thursday::boolean
            , friday::boolean, saturday::boolean, sunday::boolean 
       FROM frequencies 
       INNER JOIN trips 
               ON frequencies.trip_id = trips.trip_id 
       INNER JOIN calendar 
               ON trips.service_id = calendar.calendar_id 
       WHERE frequencies.trip_id IN ({$trips_list}) 
             AND trips.service_id IS NOT NULL 
             AND based_on IS NULL;";

    // echo $schedule_insert_query."\n\n";
    $schedule_result = db_query($schedule_insert_query);

}

// PROPOSED PROCESS FOR MIGRATING SEGMENTS
// 1. Gather distinct actual travel segments from schedules -- not sure of the 
// best way to do this. Basically "From stop_id to (next) stop_id" denotes a 
// travel segment -- which might occur in a whole number of trips and even 
// routes.

// I'm pretty sure the below SQL will be useful and efficient for step 1.
//
// SELECT DISTINCT stop_id as stop_id_start, thenextstop as stop_id_end, agency_id
// FROM (SELECT agency_id, stop_id, lag(stop_id) over (PARTITION BY trip_id order by stop_sequence) AS thenextstop FROM stop_times WHERE agency_id = 1) s
// WHERE thenextstop IS NOT NULL order by stop_id_start
 
// 2. Then select the latest alignment for that segment (if it exists). In 
// cases where one alignment matches the start and end stop ID, I believe that 
// with the largest segment ID is the last stored, and is the one currently in 
// use.
//
// 3. Discard vertices that are within 7 feet of a previous.
//
// 4. Transfer to the migrate tables.

// Proposed tests:
// Vertices are separated by at least 7 feet.

echo "Migration successful."

?>
