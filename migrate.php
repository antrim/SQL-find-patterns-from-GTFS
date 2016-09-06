<html><head><title>migrate.php!</title><head>
<body>
<?php

// require_once $_SERVER['DOCUMENT_ROOT'] . '/includes/config.inc.php';
require_once './includes/config.inc.php';

require_once './migrate_util.php';

# $agency_array = array (1, 3, 175, 267, 392);
#
# Fetch agency list dynamically, make sure to include 1, 3, 175, 267, and 392.
#
# Feel free to modify the LIMIT statement during testing:
#   Larger values to diagnose problems uncovered by larger collections of agencies.
#   Smaller values for quicker turnaround to debug the migration script itself.
#
/*
$how_many_agencies_to_test = "800";
$agency_string_query = "
    SELECT string_agg(agency_id::text, ', ' ORDER BY agency_id) AS agency_string
    FROM (      SELECT   1 AS agency_id
          UNION SELECT   3 AS agency_id
          UNION SELECT 175 AS agency_id
          UNION SELECT 267 AS agency_id
          UNION SELECT 392 AS agency_id
          UNION SELECT agency_id 
                FROM agency
                WHERE agency_name NOT LIKE '%DEPRECATED%' 
                ORDER BY agency_id
                LIMIT ${how_many_agencies_to_test}
            ) foo
    -- avoiding these agency ids for now:
    -- https://github.com/trilliumtransit/migrate-GTFS/issues/3#issuecomment-228157323 
    -- they have missing arrival_times for first stops in some trips.
    WHERE agency_id NOT IN (41,236,440,61,460,23,241)
    ";
    
$result = db_query_debug($agency_string_query);
$agency_string = db_fetch_array($result)[0];

echo "<br />\n agency_string $agency_string";
 */
// $agency_string  = "@@@@@@NONE@@@@@@@"; # unused: this ought to cause an error in postgres.

// So apparently trillium_gtfs_web will never be able to run truncate on the 
// table created by aaron_super with an autoincrement counter
// http://dba.stackexchange.com/questions/58282/error-must-be-owner-of-relation-user-account-id-seq
//
// ED. Addressed via changing owner of sequence, for example:
// ALTER SEQUENCE play_migrate_blocks_block_id_seq OWNER TO trillium_gtfs_group ;
//

db_query_debug("BEGIN TRANSACTION;");

$truncate_migrate_tables_query = "
    TRUNCATE {$dst_schema}.agencies
           , {$dst_schema}.blocks
           , {$dst_schema}.calendar_bounds
           , {$dst_schema}.calendar_dates
           , {$dst_schema}.calendar_date_service_exceptions
           , {$dst_schema}.calendars
           , {$dst_schema}.directions
           , {$dst_schema}.fare_attributes
           , {$dst_schema}.fare_rider_categories
           , {$dst_schema}.fare_rules
           , {$dst_schema}.feeds
           , {$dst_schema}.headsigns
           , {$dst_schema}.pattern_custom_shape_segments
           , {$dst_schema}.patterns
           , {$dst_schema}.pattern_stops
           , {$dst_schema}.routes
           , {$dst_schema}.shape_segments
           , {$dst_schema}.stops
           , {$dst_schema}.timed_patterns
           , {$dst_schema}.timed_pattern_stops
           , {$dst_schema}.timed_pattern_stops_nonnormalized
           , {$dst_schema}.transfers
           , {$dst_schema}.trips
           , {$dst_schema}.users
           , {$dst_schema}.user_permissions
           , {$dst_schema}.zones
             RESTART IDENTITY;";

$truncate_migrate_tables_result = db_query_debug($truncate_migrate_tables_query);

$migrate_agency_query  = "
    INSERT INTO {$dst_schema}.agencies
        (agency_id, agency_id_import, agency_url, agency_timezone, agency_lang_id
       , agency_name, agency_short_name, agency_phone, agency_fare_url, agency_info
       , query_tracking, last_modified
       , no_frequencies, feed_id) 
    SELECT DISTINCT agency.agency_id, agency_id_import, agency_url, agency_timezone, agency_lang_id
       , agency_name, agency_short_name, agency_phone, agency_fare_url, agency_info
       , query_tracking, agency.last_modified
       , no_frequencies, agency_group_id as feed_id 
    FROM {$src_schema}.agency
    INNER JOIN {$src_schema}.agency_group_assoc USING (agency_id)
    WHERE 
        agency_id not in ($skip_agency_id_string) 
    ";
/*
        -- agency.agency_id IN ($agency_string) 
 */


$migrate_agency_result = db_query_debug($migrate_agency_query);


/*
    alter table play_migrate.timed_pattern_stops_nonnormalized 
    alter COLUMN trips_list type integer[] 
    using (regexp_split_to_array(trips_list,',')::integer[]);

 */

$migrate_timed_pattern_stops_nonnormalized_query  = "
INSERT INTO {$dst_schema}.timed_pattern_stops_nonnormalized 
    (agency_id, agency_name, route_short_name
    , route_long_name, direction_name, direction_id
    , trip_headsign_id, trip_headsign, stop_id
    , \"stop_order\"
    , timed_pattern_id 
    , pattern_id
    , arrival_time
    , departure_time
    , pickup_type
    , drop_off_type 
    , one_trip, trips_list, stops_pattern, arrival_time_intervals
    , departure_time_intervals, route_id, stop_headsign_id)

WITH pattern_time_intervals AS (
    SELECT MIN(trips.trip_id) as one_trip
         , array_agg( trips.trip_id ORDER BY sequences.min_arrival_time ) AS trips_list
         , sequences.stops_pattern, arrival_time_intervals, departure_time_intervals
         , trips.agency_id, trips.route_id, trips.direction_id
    FROM {$src_schema}.trips
    INNER JOIN (
        SELECT string_agg(stop_times.stop_id::text, ', ' ORDER BY stop_times.stop_sequence ASC) AS stops_pattern
             , stop_times.trip_id
             , MIN( stop_times.arrival_time ) AS min_arrival_time
        FROM {$src_schema}.stop_times
        INNER JOIN {$src_schema}.trips ON stop_times.trip_id = trips.trip_id
        WHERE
            stop_times.agency_id NOT IN ($skip_agency_id_string) 
            AND  trips.based_on IS NULL
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
         FROM {$src_schema}.stop_times
         INNER JOIN {$src_schema}.trips ON stop_times.trip_id = trips.trip_id
         INNER JOIN (
                 SELECT MIN( arrival_time )   AS min_arrival_time
                      , MIN( departure_time ) AS min_departure_time
                      , stop_times.trip_id
                 FROM {$src_schema}.stop_times
                 INNER JOIN {$src_schema}.trips on stop_times.trip_id = trips.trip_id
                 WHERE 
                     stop_times.agency_id NOT IN ($skip_agency_id_string) 
                     AND  trips.based_on IS NULL
                 GROUP BY stop_times.trip_id) min_trip_times 
           ON stop_times.trip_id = min_trip_times.trip_id
           WHERE 
               stop_times.agency_id not in ($skip_agency_id_string) 
               AND  trips.based_on IS NULL
         GROUP BY min_trip_times.trip_id,min_arrival_time,min_departure_time
        ) AS time_intervals_result

       ON sequences.trip_id = time_intervals_result.trip_id
       WHERE 
           trips.agency_id NOT IN ($skip_agency_id_string)
           AND trips.based_on IS NULL
     GROUP BY stops_pattern, arrival_time_intervals, departure_time_intervals
            , trips.agency_id, trips.route_id, trips.direction_id
   )
        
, timed_patterns_sub AS (

    SELECT pattern_time_intervals.*, MIN( stop_times.arrival_time ) AS min_arrival_time
         , MIN( stop_times.departure_time) AS min_departure_time
    FROM pattern_time_intervals
    INNER JOIN  {$src_schema}.stop_times 
           ON pattern_time_intervals.one_trip = stop_times.trip_id 
           WHERE stop_times.agency_id NOT IN ($skip_agency_id_string)
    GROUP BY  one_trip, trips_list, stops_pattern, arrival_time_intervals
            , departure_time_intervals, pattern_time_intervals.agency_id, route_id, direction_id

)

, timed_patterns AS (
    SELECT row_number() over() AS timed_pattern_id, * 
    FROM timed_patterns_sub)

, stop_patterns AS (

    WITH unique_patterns AS(
    SELECT DISTINCT string_agg(stop_times.stop_id::text , ', ' ORDER BY stop_times.stop_sequence ASC) AS stops_pattern,trips.route_id
                  , trips.direction_id
         FROM stop_times
         inner join trips on stop_times.trip_id = trips.trip_id
         WHERE 
             trips.agency_id NOT IN ($skip_agency_id_string) 
             AND trips.based_on IS NULL
         GROUP BY stop_times.trip_id,trips.route_id,trips.direction_id)
    SELECT unique_patterns.stops_pattern,route_id,direction_id,row_number() over() as pattern_id 
    FROM unique_patterns
)

SELECT timed_patterns.agency_id, agency.agency_name, routes.route_short_name
     , routes.route_long_name, directions.direction_label as direction_name, trips.direction_id
     , headsigns.headsign_id, headsigns.headsign, stop_times.stop_id
     , dense_rank() over (partition by timed_pattern_id order by stop_times.stop_sequence) as \"stop_order\"
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
     , COALESCE(pickup_type,0)
     , COALESCE(drop_off_type, 0)
     , one_trip, trips_list, stop_patterns.stops_pattern, arrival_time_intervals
     , departure_time_intervals, trips.route_id, stop_times.headsign_id as stop_headsign_id 
FROM timed_patterns
LEFT JOIN {$src_schema}.stop_times ON timed_patterns.one_trip = stop_times.trip_id
INNER JOIN stop_patterns ON (timed_patterns.stops_pattern = stop_patterns.stops_pattern 
                             AND timed_patterns.route_id = stop_patterns.route_id 
                             AND timed_patterns.direction_id = stop_patterns.direction_id)
INNER JOIN {$src_schema}.trips ON stop_times.trip_id = trips.trip_id
INNER JOIN {$src_schema}.routes ON trips.route_id = routes.route_id
LEFT JOIN {$src_schema}.directions ON trips.direction_id = directions.direction_id
LEFT JOIN {$src_schema}.headsigns ON trips.headsign_id = headsigns.headsign_id
INNER JOIN {$src_schema}.agency ON stop_times.agency_id = agency.agency_id
ORDER BY pattern_id, timed_pattern_id ASC, stop_times.stop_sequence ASC";

$migrate_timed_pattern_stops_nonnormalized_result = db_query_debug($migrate_timed_pattern_stops_nonnormalized_query);


$migrate_feeds_query  = "
    INSERT INTO {$dst_schema}.feeds
        (feed_id
        , name, contact_email
        , contact_url, license, last_modified)  
   SELECT DISTINCT 
         agency_groups.agency_group_id as feed_id
       , group_name AS name, feed_contact_email
       , feed_contact_url, feed_license, agency_groups.last_modified 
    FROM {$src_schema}.agency_groups 
    INNER JOIN {$src_schema}.agency_group_assoc 
            ON agency_group_assoc.agency_group_id = agency_groups.agency_group_id 
    WHERE agency_group_assoc.agency_id NOT IN ($skip_agency_id_string)";
$migrate_feeds_result = db_query_debug($migrate_feeds_query);


$migrate_zones_query = "
    INSERT INTO {$dst_schema}.zones
          (zone_id, name, agency_id
         , last_modified, zone_id_import )
    SELECT zone_id, zone_name AS name, agency_id
         , last_modified, zone_id_import 
    FROM {$src_schema}.zones;
";
$result = db_query_debug($migrate_zones_query);


$all_zones_wildcard_query = "
    INSERT INTO {$dst_schema}.zones
          (zone_id, name, agency_id
         , last_modified, zone_id_import )
    VALUES (-411
          , 'Wildcard: any or all zones for this agency.'
          , -411
          , NOW()
          , '' /* Blank zone_id_import which means 'all' in GTFS. */
      );
    ";
$result = db_query_debug($all_zones_wildcard_query);

$get_least_unused_zone_id = "
    SELECT pg_catalog.setval('{$dst_schema}.zones_zone_id_seq'::regclass, 1 + MAX(zone_id))
    FROM {$dst_schema}.zones";

$result = db_query_debug($get_least_unused_zone_id);
$least_unused_zone_id = db_fetch_array($result)[0];
echo "<br />\n setval: least_unused_zone_id $least_unused_zone_id";


// pattern_stop.sql
$migrate_pattern_stop_query  = "
    INSERT into {$dst_schema}.pattern_stops
    SELECT DISTINCT  agency_id, pattern_id, \"stop_order\", stop_id 
    FROM {$dst_schema}.timed_pattern_stops_nonnormalized
    ORDER BY agency_id, pattern_id, \"stop_order\"";
$result = db_query_debug($migrate_pattern_stop_query);

// timed_pattern_intervals.sql
$migrate_timed_pattern_stop_query  = "
    INSERT into {$dst_schema}.timed_pattern_stops 
        (agency_id, timed_pattern_id, \"stop_order\", stop_id, arrival_time, departure_time
       , pickup_type, drop_off_type, headsign_id)
    SELECT DISTINCT agency_id, timed_pattern_id, \"stop_order\", stop_id, arrival_time, departure_time
                  , pickup_type, drop_off_type, stop_headsign_id
    FROM {$dst_schema}.timed_pattern_stops_nonnormalized
    ORDER BY agency_id, timed_pattern_id, \"stop_order\"";
$result = db_query_debug($migrate_timed_pattern_stop_query);

// timed_pattern.sql
$migrate_timed_pattern_query  = "
    INSERT into {$dst_schema}.timed_patterns (agency_id, timed_pattern_id, pattern_id)
    SELECT DISTINCT agency_id, timed_pattern_id, pattern_id
    FROM {$dst_schema}.timed_pattern_stops_nonnormalized
    ORDER BY agency_id, pattern_id, timed_pattern_id";
$result = db_query_debug($migrate_timed_pattern_query);

// routes.sql
$migrate_routes_stop_query  = "
    INSERT INTO {$dst_schema}.routes 
        (agency_id, route_id, route_short_name, route_long_name, route_description, route_type
       , route_color 
       , route_text_color
       , route_url, route_bikes_allowed, route_id_import
       , last_modified, route_sort_order, enabled) 
   SELECT 
         agency_id, route_id, route_short_name, route_long_name, route_desc, route_type
       , CASE WHEN route_color ~ '^[0-9a-fA-F]{6}$' 
                   THEN '#'||lower(route_color) 
                   ELSE '#ffffff' END
       , CASE WHEN route_text_color ~ '^[0-9a-fA-F]{6}$' 
                   THEN '#'||lower(route_text_color) 
                   ELSE '#000000' END
       , route_url, route_bikes_allowed, route_id_import
       , last_modified, route_sort_order, CASE WHEN hidden THEN False ELSE True END
    FROM {$src_schema}.routes 
    WHERE agency_id IN (select agency_id from {$dst_schema}.agencies)";
$result = db_query_debug($migrate_routes_stop_query);

/* ED 2016-06-27 On further thought, I think it's better not to include the 
 * wildcard entries into the database.
 *
 * (1) They would match entries from multiple agencies, this could potentially 
 *     complicate how we implement a security model, and exporting data.
 *
 * (2) For zones it isn't too bad, but many other tables expect very specific 
 *     data in columns such as routes.bikes_allowed and agencies.phone.
 *     We don't really want to end up with fake values in these columns, it's
 *     probably more work to avoid this problem than to just bear in mind that
 *     -411 is a shorthand for all when writing views and join code.
 */

/*
$all_routes_wildcard_query = "
    INSERT INTO {$dst_schema}.routes
        (agency_id, route_id, route_short_name, route_long_name,
        , route_desc, route_type
         , last_modified, zone_id_import )
    VALUES (-411
          , 'Wildcard: any or all routes for this agency.'
          , -411
          , NOW()
          , '' -- Blank zone_id_import which means 'all' in GTFS. 
      );
    ";
$result = db_query_debug($all_routes_wildcard_query);
 */



// patterns.sql
// some patterns may be used by multiple routes/directions!!!!
// one way to test this is: SELECT DISTINCT ON (pattern_id) agency_id, pattern_id, route_id, direction_id
$migrate_pattern_query  = "
    INSERT into {$dst_schema}.patterns (agency_id, pattern_id, route_id, direction_id)
    SELECT DISTINCT agency_id, pattern_id, route_id, direction_id
    FROM {$dst_schema}.timed_pattern_stops_nonnormalized
    ORDER BY  pattern_id, agency_id, route_id, direction_id";
$result = db_query_debug($migrate_pattern_query);


// continuing with patterns.sql
// ALERT! Some patterns are on multiple routes. I need to figure out how to 
// handle this. <-- come back here and play -- test results

// SELECT count(distinct agency_id), pattern_id, count(distinct route_id) as 
// route_count, count(distinct direction_id) as direction_count
// FROM {$dst_schema}.timed_pattern_stops_nonnormalized
// group by pattern_id
// ORDER BY route_count DESC, direction_count DESC

// headsigns.sql
// ALERT! There are some null headsigns to look into here.


/* changing the headsign query to simply migrate everything, due to bug
 * https://github.com/trilliumtransit/GTFSManager/issues/337
 * ED 2016-08-10
$migrate_headsigns_query_original  = "
    INSERT into {$dst_schema}.headsigns (agency_id, headsign_id, headsign)
    SELECT DISTINCT  agency_id, trip_headsign_id as headsign_id, trip_headsign AS headsign
    FROM {$dst_schema}.timed_pattern_stops_nonnormalized 
    WHERE trip_headsign_id IS NOT NULL 
          AND trip_headsign IS NOT NULL
    UNION
    SELECT DISTINCT  agency_id, stop_headsign_id as headsign_id, stop_headsign AS headsign
    FROM {$dst_schema}.timed_pattern_stops_nonnormalized 
    WHERE stop_headsign_id IS NOT NULL 
          AND stop_headsign IS NOT NULL
    ORDER BY agency_id, headsign_id";
 */

$migrate_headsigns_query  = "
    INSERT into {$dst_schema}.headsigns (agency_id, headsign_id, headsign)
    SELECT DISTINCT  
        agency_id, headsign_id, headsign
    FROM {$src_schema}.headsigns 
    WHERE 
        agency_id in (select agency_id from {$dst_schema}.agencies) 
        AND headsign_id IS NOT NULL 
        AND headsign IS NOT NULL
    ORDER BY agency_id, headsign_id";

$result = db_query_debug($migrate_headsigns_query);

// directions.sql
// ALERT!! There are some duplicate direction_id values to look ingo

$migrate_directions_query  = "
    INSERT INTO {$dst_schema}.directions 
        (agency_id, direction_id, name)
    SELECT DISTINCT on (direction_id)  agency_id, direction_id, direction_name
    FROM {$dst_schema}.timed_pattern_stops_nonnormalized
    ORDER BY direction_id, agency_id";
$result = db_query_debug($migrate_directions_query);

// calendar
$migrate_calendar_query  = "
    INSERT into {$dst_schema}.calendars
        (agency_id, calendar_id
       , name)
    SELECT agency_id, service_schedule_group_id AS calendar_id
         , service_schedule_group_label AS name
    FROM {$src_schema}.service_schedule_groups
    WHERE 
        agency_id IN (select agency_id from {$dst_schema}.agencies) 
        AND service_schedule_group_id IS NOT NULL;";
$result = db_query_debug($migrate_calendar_query);

// calendar
$migrate_calendar_bounds_query  = "
    INSERT into {$dst_schema}.calendar_bounds 
        (agency_id, calendar_id, start_date, end_date)
    SELECT agency_id, service_schedule_group_id as calendar_id, start_date, end_date 
    FROM {$src_schema}.service_schedule_bounds
    WHERE 
        agency_id IN (select agency_id from {$dst_schema}.agencies) 
        AND service_schedule_group_id IS NOT NULL;";
$result = db_query_debug($migrate_calendar_bounds_query);

// blocks
$migrate_blocks_query  = "
    INSERT into {$dst_schema}.blocks 
        (agency_id, block_id, name)
    SELECT DISTINCT agency_id, block_id, block_label as name
    FROM {$src_schema}.blocks
    WHERE 
        agency_id IN (select agency_id from {$dst_schema}.agencies) 
    "; 
$result = db_query_debug($migrate_blocks_query);

/* 
 LEFT JOIN means z.zone_id is NULL when zone_id doesn't match zones, 
 that's what we want. Ed 2016-06-26
 https://github.com/trilliumtransit/migrate-GTFS/issues/6#issuecomment-228627399 


 Note also: we're resetting wheelchair_boarding to the default value of 0 per
 https://github.com/trilliumtransit/GTFSManager/issues/378
 */
$migrate_stops_query  = "
    INSERT into {$dst_schema}.stops 
        (agency_id, stop_id, stop_code, platform_code, location_type
        , parent_station_id, name, stop_desc, stop_comments
        , point
        , zone_id
        , city, direction_id, url, enabled, timezone
        )
    SELECT 
          s.agency_id, s.stop_id, s.stop_code, s.platform_code, s.location_type
        , s.parent_station, s.stop_name, s.stop_desc, s.stop_comments
        , ST_SetSRID(ST_Point(stop_lon, stop_lat), 4326)::GEOGRAPHY as point
        , z.zone_id 
        , s.city, direction_id, stop_url, publish_status AS enabled, stop_timezone
    FROM {$src_schema}.stops s
    LEFT JOIN {$src_schema}.zones z USING (zone_id)
    WHERE 
        s.agency_id IS NOT NULL
        AND s.agency_id IN (select agency_id from {$dst_schema}.agencies) 
    ;
";
$result = db_query_debug($migrate_stops_query);

db_query_debug("
UPDATE {$dst_schema}.stops SET timezone = NULL WHERE length(timezone) = 0;
    ");

db_query_debug("
UPDATE {$dst_schema}.stops SET timezone = 'America/New_York' WHERE timezone = 'US/Eastern';
    ");


db_query_debug("
UPDATE {$dst_schema}.stops SET timezone = coalesce(sa.timezone, sa.agency_timezone) 
FROM
(
    SELECT
        stops.timezone, agencies.agency_timezone, stops_agencies.agency_id, stops.stop_id
    FROM {$dst_schema}.stops
    JOIN {$dst_schema}.stops_agencies ON stops.stop_id = stops_agencies.stop_id
    JOIN {$dst_schema}.agencies ON stops_agencies.agency_id = agencies.agency_id 
) sa 
WHERE
    stops.stop_id = sa.stop_id
    AND stops.timezone IS NULL ;
    ");


$patterns_nonnormalized_query = "
    SELECT DISTINCT 
        timed_pattern_id, agency_id, 
        array_to_string(trips_list, ',') as trips_list 
    FROM {$dst_schema}.timed_pattern_stops_nonnormalized;";
$patterns_nonnormalized_result   = db_query_debug($patterns_nonnormalized_query);
  
while ($row = db_fetch_array($patterns_nonnormalized_result)) {
    break; // disable this in favor of a select statement.

    $timed_pattern_id = $row['timed_pattern_id'];
    $agency_id        = $row['agency_id'];
    $trips_list       = $row['trips_list'];

    $schedule_insert_query = "
       INSERT into {$dst_schema}.old_trips
            (agency_id, timed_pattern_id, calendar_id
           , start_time
           , end_time, headway_secs, block_id
           , monday, tuesday, wednesday, thursday, friday, saturday, sunday
           , in_seat_transfer)

       SELECT trips.agency_id, {$timed_pattern_id} AS timed_pattern_id
            , service_schedule_group_id AS calendar_id
            , views.first_arrival_time_for_trip(trips.trip_id) AS start_time
            , NULL::INTERVAL as end_time,  NULL::integer as headway_secs, block_id
            , monday::boolean, tuesday::boolean, wednesday::boolean, thursday::boolean
            , friday::boolean, saturday::boolean, sunday::boolean 
            , in_seat_transfer = 1
       FROM {$src_schema}.trips 
       INNER JOIN {$src_schema}.calendar 
          ON trips.service_id = calendar.calendar_id 
       INNER JOIN {$dst_schema}.dev_first_arrivals_for_trip using (trip_id)
       WHERE trips.trip_id IN ({$trips_list}) 
             AND NOT EXISTS (SELECT NULL from frequencies 
                             WHERE trips.trip_id = frequencies.trip_id) 
             AND based_on IS NULL 
             AND trips.service_id IS NOT NULL 
 /* AND views.first_arrival_time_for_trip(trips.trip_id) IS NOT NULL  */
             AND dev_first_arrivals_for_trip.first_arrival_time IS NOT null
       GROUP BY trips.agency_id, timed_pattern_id, calendar_id
              , trips.trip_id, end_time
              , headway_secs, block_id, monday, tuesday, wednesday, thursday
              , friday, saturday, sunday

   UNION
       SELECT trips.agency_id, {$timed_pattern_id} AS timed_pattern_id
            , service_schedule_group_id AS calendar_id, trips.trip_start_time::INTERVAL AS start_time
            , NULL::INTERVAL as end_time, NULL::INTEGER as headway_secs, block_id
            , monday::boolean, tuesday::boolean, wednesday::boolean, thursday::boolean
            , friday::boolean, saturday::boolean, sunday::boolean 
            , in_seat_transfer = 1
       FROM {$src_schema}.trips 
       INNER JOIN {$src_schema}.calendar 
               ON trips.service_id = calendar.calendar_id 
       WHERE trips.trip_id IN ({$trips_list}) 
             AND trips.service_id IS NOT NULL 
             AND NOT EXISTS (SELECT NULL from frequencies 
                             WHERE trips.trip_id = frequencies.trip_id) 
             AND based_on IS NOT NULL

   UNION
       SELECT trips.agency_id, {$timed_pattern_id} AS timed_pattern_id
            , service_schedule_group_id AS calendar_id, frequencies.start_time::INTERVAL AS start_time
            , frequencies.end_time::INTERVAL as end_time, frequencies.headway_secs 
            , block_id
            , monday::boolean, tuesday::boolean, wednesday::boolean, thursday::boolean
            , friday::boolean, saturday::boolean, sunday::boolean 
            , in_seat_transfer = 1 
       FROM {$src_schema}.frequencies 
       INNER JOIN {$src_schema}.trips 
               ON frequencies.trip_id = trips.trip_id 
       INNER JOIN {$src_schema}.calendar 
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
            , in_seat_transfer = 1
       FROM {$src_schema}.frequencies 
       INNER JOIN {$src_schema}.trips 
               ON frequencies.trip_id = trips.trip_id 
       INNER JOIN {$src_schema}.calendar 
               ON trips.service_id = calendar.calendar_id 
       WHERE frequencies.trip_id IN ({$trips_list}) 
             AND trips.service_id IS NOT NULL 
             AND based_on IS NULL;";

    // echo $schedule_insert_query."\n\n";
    $schedule_result = db_query_debug($schedule_insert_query);
}

// shape_segments
// Only copy the most recent segment (that with the largest shape_segment_id) 
// for every group of segments with the same (to_stop_id, from_stop_id) pair!
// "Older" segments are not used by GTFSManager anyhow.
$migrate_shape_segments_query  = "
    INSERT into {$dst_schema}.shape_segments 
        (from_stop_id, to_stop_id
       , last_modified
       , linestring )
    WITH most_recent AS (
         SELECT shape_segments.start_coordinate_id,
            shape_segments.end_coordinate_id,
            max(shape_segments.shape_segment_id) AS shape_segment_id
           FROM shape_segments
          GROUP BY shape_segments.start_coordinate_id, shape_segments.end_coordinate_id )
    SELECT ss.start_coordinate_id, ss.end_coordinate_id
         , ss.last_modified
         , st_makeline(array_agg(shape_points.geom::geography ORDER BY shape_points.shape_pt_sequence))
    FROM {$src_schema}.shape_segments ss
    INNER JOIN most_recent USING (shape_segment_id)
    INNER JOIN {$src_schema}.shape_points USING (shape_segment_id)
    WHERE ss.start_coordinate_id IS NOT NULL 
          AND ss.end_coordinate_id IS NOT NULL
    GROUP BY ss.start_coordinate_id, ss.end_coordinate_id, ss.last_modified
    ";
$result = db_query_debug($migrate_shape_segments_query);

$remove_shape_segment_orphans_query = "
    DELETE FROM {$dst_schema}.shape_segments 
    WHERE from_stop_id NOT IN (SELECT stop_id FROM {$dst_schema}.stops) 
          OR to_stop_id NOT IN (SELECT stop_id FROM {$dst_schema}.stops);
    ";
$result = db_query_debug($remove_shape_segment_orphans_query);

$calendar_dates_query = "
    INSERT INTO {$dst_schema}.calendar_dates
        (calendar_date_id, \"date\", agency_id, name, last_modified) 
    SELECT 
        calendar_date_id, \"date\", agency_id, description as name, last_modified
    FROM {$src_schema}.calendar_dates
    WHERE
        agency_id IN (select agency_id from {$dst_schema}.agencies) 
    ;
  ";
$result = db_query_debug($calendar_dates_query);

$calendar_date_service_exceptions_query = "
    INSERT INTO {$dst_schema}.calendar_date_service_exceptions
        (calendar_date_id, exception_type, calendar_id
       , monday, tuesday , wednesday
       , thursday, friday, saturday, sunday
       , agency_id
       , last_modified) 
   SELECT calendar_date_id, exception_type, service_exception as calendar_id
        , monday::boolean, tuesday::boolean, wednesday::boolean
        , thursday::boolean, friday::boolean, saturday::boolean, sunday::boolean
        , calendar_date_service_exceptions.agency_id
        , calendar_date_service_exceptions.last_modified
   FROM {$src_schema}.calendar_date_service_exceptions 
   INNER JOIN calendar
       ON calendar_date_service_exceptions.service_exception = calendar.calendar_id
   WHERE
       calendar_date_service_exceptions.agency_id IN (select agency_id from {$dst_schema}.agencies) 
  ";
$result = db_query_debug($calendar_date_service_exceptions_query);

$migrate_fare_attributes_query = "
    INSERT INTO {$dst_schema}.fare_attributes
        (agency_id, fare_id, price, currency_type, payment_method
       , transfers, transfer_duration, last_modified, fare_id_import)
    SELECT agency_id, fare_id, price, currency_type, payment_method
         , transfers, transfer_duration, last_modified, fare_id_import
    FROM {$src_schema}.fare_attributes
    WHERE
        agency_id IN (select agency_id from {$dst_schema}.agencies) 
         ";
$result = db_query_debug($migrate_fare_attributes_query);


$migrate_fare_rider_categories_query = "
    INSERT INTO {$dst_schema}.fare_rider_categories
        (fare_rider_category_id, fare_id, rider_category_custom_id 
       , price, agency_id) 
    SELECT fare_rider_category_id, fare_id, rider_category_custom_id 
         , price, agency_id
    FROM {$src_schema}.fare_rider_categories
    WHERE
        agency_id IN (select agency_id from {$dst_schema}.agencies) 
         ";
$result = db_query_debug($migrate_fare_rider_categories_query);


$migrate_fare_rules_query = "
    WITH distinct_fare_rules AS 
        (SELECT agency_id, fare_id, route_id, origin_id, destination_id, contains_id
             , max(fare_rule_id) as golden_fare_rule_id
             , array_agg(fare_rule_id) AS fare_rule_id_agg, count(*)
        FROM {$src_schema}.fare_rules
        GROUP BY agency_id, fare_id, route_id, origin_id, destination_id, contains_id)
    INSERT INTO {$dst_schema}.fare_rules 
        (fare_rule_id, fare_id, route_id, origin_id
       , destination_id, contains_id, agency_id
       , last_modified, fare_id_import, route_id_import
       , origin_id_import, destination_id_import, contains_id_import)
    SELECT fare_rule_id, fare_id, route_id, origin_id
         , destination_id, contains_id, agency_id
         , last_modified, fare_id_import, route_id_import
         , origin_id_import, destination_id_import, contains_id_import
    FROM {$src_schema}.fare_rules
    /* Require origin_id, destination_id, and contains_id to match a zone.
       https://github.com/trilliumtransit/migrate-GTFS/issues/7#issuecomment-228627448 
     */
    WHERE fare_rule_id IN (SELECT golden_fare_rule_id 
                           FROM distinct_fare_rules)
          AND (origin_id IS NULL 
               OR origin_id IN (SELECT zone_id FROM {$dst_schema}.zones))
          AND (destination_id IS NULL 
               OR destination_id IN (SELECT zone_id FROM {$dst_schema}.zones))
          AND (contains_id IS NULL 
               OR contains_id IN (SELECT zone_id FROM {$dst_schema}.zones))
          AND
              agency_id IN (select agency_id from {$dst_schema}.agencies) 
    ";
$result = db_query_debug($migrate_fare_rules_query);


$fare_rules_combinable_query = "
    UPDATE {$dst_schema}.fare_rules
        SET is_combinable = False 
    WHERE agency_id IN (42, 175)
          OR (agency_id = (19) 
              AND origin_id IS NOT NULL)
          OR (agency_id = (19) 
              AND destination_id IS NOT NULL)
  ; ";
$result = db_query_debug($fare_rules_combinable_query);

$migrate_transfers_query = "
    INSERT INTO {$dst_schema}.transfers
      ( transfer_id,
        from_stop_id,
        to_stop_id,
        transfer_type,
        min_transfer_time,
        agency_id,
        last_modified,
        from_stop_id_import,
        to_stop_id_import )

    SELECT 
        transfer_id,
        from_stop_id,
        to_stop_id,
        transfer_type,
        min_transfer_time,
        agency_id,
        last_modified,
        from_stop_id_import,
        to_stop_id_import  
    FROM {$src_schema}.transfers
    WHERE
        agency_id IN (select agency_id from {$dst_schema}.agencies) 
    ";
$result = db_query_debug($migrate_transfers_query);


// Assign names to patterns based on their first stop, last stop, and 
// number of stops. Ed 2016-07-10
// https://github.com/trilliumtransit/migrate-GTFS/issues/12
$pattern_names_method_alpha_query = "
WITH 

pattern_stop_summary AS 
( SELECT 
    pattern_id, 
    count(*) AS number_of_stops, 
    min(\"stop_order\") AS min_stop_order, 
    max(\"stop_order\") AS max_stop_order 
  FROM {$dst_schema}.pattern_stops 
  GROUP BY pattern_id), 

generated_names AS 
( SELECT p.pattern_id
  , s1.name || ' to ' || sN.name || ' x' || number_of_stops AS generated_name
  FROM {$dst_schema}.patterns p
  JOIN pattern_stop_summary ps using(pattern_id) 
  JOIN {$dst_schema}.pattern_stops ps1
       ON (ps1.pattern_id = p.pattern_id AND ps1.\"stop_order\" = min_stop_order) 
  JOIN {$dst_schema}.pattern_stops psN
       ON (psN.pattern_id = p.pattern_id AND psN.\"stop_order\" = max_stop_order) 
  JOIN {$src_schema}.stops s1 ON (s1.stop_id = ps1.stop_id)
  JOIN {$src_schema}.stops sN ON (sN.stop_id = psN.stop_id))

UPDATE ${dst_schema}_patterns SET name = generated_name 
FROM generated_names
WHERE generated_names.pattern_id = {$dst_schema}.patterns.pattern_id;
    ";


// Assign names to patterns based on the difference in which stops they visit 
// compared to the "Primary" (most-often-used) pattern for their route.
// Ed 2016-07-12
// https://github.com/trilliumtransit/migrate-GTFS/issues/11
$pattern_names_method_beta_query = "
WITH

patterns_with_stops_difference AS 
(select
    p.route_id, p.pattern_id, primary_pattern_id  
  , array_length(s_agg.stop_ids, 1) as n_stops
  , coalesce(array_length(s_agg.stop_ids - primary_s_agg.primary_stop_ids, 1), 0) as n_added_stops
  , coalesce(array_length(primary_s_agg.primary_stop_ids - s_agg.stop_ids, 1), 0) as n_removed_stops
  , s_agg.stop_ids - primary_s_agg.primary_stop_ids as added_stop_ids
  , primary_s_agg.primary_stop_ids - s_agg.stop_ids as removed_stop_ids
  , s_agg.stop_ids
from {$dst_schema}.patterns p
join {$dst_schema}.route_primary_patterns AS route_primary_patterns using (route_id, direction_id)
join
    ( select pattern_id, array_agg(stop_id order by stop_id) stop_ids
      from {$dst_schema}.pattern_stops group by pattern_id) s_agg
    using (pattern_id)
join
    ( select pattern_id, array_agg(stop_id order by stop_id) primary_stop_ids
      from {$dst_schema}.pattern_stops group by pattern_id) primary_s_agg
    on (primary_s_agg.pattern_id = route_primary_patterns.primary_pattern_id)  )

,generated_names AS
(select
    route_id
  , pattern_id
  , primary_pattern_id
  , n_added_stops
  , n_removed_stops
  , case when pattern_id = primary_pattern_id 
        then 'Primary' 
        else case when (n_added_stops > 3 or n_added_stops = 0)
                 then '+ '  || n_added_stops || ' stops'
                 else '+ '  || (SELECT string_agg(name, ' + ')
                                FROM  {$dst_schema}.stops 
                                WHERE stop_id  IN (SELECT unnest(added_stop_ids))) END
          || case when (n_removed_stops > 3 or n_removed_stops = 0)
                 then ' - ' || n_removed_stops || ' stops'
                 else ' - ' || (SELECT string_agg(name, ' - ') 
                                FROM  {$dst_schema}.stops 
                                WHERE stop_id  IN (SELECT unnest(removed_stop_ids))) END
        end
   as generated_name
from patterns_with_stops_difference
order by route_id, pattern_id)

update {$dst_schema}.patterns SET name = generated_name
from generated_names
where generated_names.pattern_id = {$dst_schema}.patterns.pattern_id
    ";

$result = db_query_debug($pattern_names_method_beta_query);


$block_colors_query = "
    update ${dst_schema}.blocks blocks 
    set color = sample_colors.color 
    from ${dst_schema}.sample_colors where sample_colors.color_id = blocks.block_id;
";
$result = db_query_debug($block_colors_query);


// Set feed_id for stops.
$stops_feed_id_query = "
    update ${dst_schema}.stops 
        set feed_id = agency_group_assoc.agency_group_id 
    from ${src_schema}.agency_group_assoc 
    where stops.agency_id = agency_group_assoc.agency_id;
";
$result = db_query_debug($stops_feed_id_query);


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
                join {$src_schema}.trips using (trip_id)
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

$migrate_user_query  = "
    INSERT INTO {$dst_schema}.users
        (user_id, email, pass, first_name, last_name, active,
        registration_date,
        read_only,
        admin,
        language_id,
        last_modified) 
    SELECT 
        user_id, email, pass, first_name, last_name, active,
        registration_date, 
        (read_only = 1)::boolean,
        (admin = 1)::boolean,
        language_id,
        last_modified
    FROM {$src_schema}.users
    ";

db_query_debug($migrate_user_query);

$migrate_user_permissions_query  = "
    INSERT INTO {$dst_schema}.user_permissions
        (permission_id, agency_id, user_id, last_modified)
    SELECT 
        up.permission_id, up.agency_id, up.user_id, up.last_modified
    FROM {$src_schema}.user_permissions up
    JOIN {$dst_schema}.agencies USING (agency_id)
    ";

db_query_debug($migrate_user_permissions_query);



db_query_debug("COMMIT TRANSACTION;");

echo "<br / >\n" . "Migration successful.";

?>
</body></html>
