 /*
$patterns_nonnormalized_query = "
    SELECT DISTINCT 
        timed_pattern_id, agency_id, 
        array_to_string(trips_list, ',') as trips_list 
    FROM :"DST_SCHEMA".timed_pattern_stops_nonnormalized;;
$patterns_nonnormalized_result   = db_query_debug($patterns_nonnormalized_query);
 
while ($row = db_fetch_array($patterns_nonnormalized_result)) {
    break; // disable this in favor of a select statement.

    $timed_pattern_id = $row['timed_pattern_id'];
    $agency_id        = $row['agency_id'];
    $trips_list       = $row['trips_list'];

    $schedule_insert_query = "
       INSERT into :"DST_SCHEMA".old_trips
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
       FROM :"SRC_SCHEMA".trips 
       INNER JOIN :"SRC_SCHEMA".calendar 
          ON trips.service_id = calendar.calendar_id 
       INNER JOIN :"DST_SCHEMA".dev_first_arrivals_for_trip using (trip_id)
       WHERE trips.trip_id IN ({$trips_list}) 
             AND NOT EXISTS (SELECT NULL from frequencies 
                             WHERE trips.trip_id = frequencies.trip_id) 
             AND based_on IS NULL 
             AND trips.service_id IS NOT NULL 
-- AND views.first_arrival_time_for_trip(trips.trip_id) IS NOT NULL  
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
       FROM :"SRC_SCHEMA".trips 
       INNER JOIN :"SRC_SCHEMA".calendar 
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
       FROM :"SRC_SCHEMA".frequencies 
       INNER JOIN :"SRC_SCHEMA".trips 
               ON frequencies.trip_id = trips.trip_id 
       INNER JOIN :"SRC_SCHEMA".calendar 
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
       FROM :"SRC_SCHEMA".frequencies 
       INNER JOIN :"SRC_SCHEMA".trips 
               ON frequencies.trip_id = trips.trip_id 
       INNER JOIN :"SRC_SCHEMA".calendar 
               ON trips.service_id = calendar.calendar_id 
       WHERE frequencies.trip_id IN ({$trips_list}) 
             AND trips.service_id IS NOT NULL 
             AND based_on IS NULL;;

    // echo $schedule_insert_query."\n\n;
    $schedule_result = db_query_debug($schedule_insert_query);
}
*/

