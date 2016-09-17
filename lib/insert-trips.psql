-- add_stop_time_trips_in_calendar_
   INSERT into :"DST_SCHEMA".trips
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
   FROM :"SRC_SCHEMA".trips 
   INNER JOIN :"SRC_SCHEMA".calendar 
      ON trips.service_id = calendar.calendar_id 
   INNER JOIN :"DST_SCHEMA".snap_first_arrivals_for_trip using (trip_id)
   INNER JOIN :"DST_SCHEMA".dev_patterns_trips using (trip_id)
   WHERE NOT EXISTS (SELECT NULL FROM :"SRC_SCHEMA".frequencies 
                         WHERE trips.trip_id = frequencies.trip_id) 
         AND based_on IS NULL 
         AND trips.service_id IS NOT NULL 
         AND snap_first_arrivals_for_trip.first_arrival_time IS NOT null
         AND trips.agency_id IN (select agency_id FROM :"DST_SCHEMA".agencies) 
   GROUP BY trips.agency_id, timed_pattern_id, calendar_id
          , snap_first_arrivals_for_trip.first_arrival_time
          , trips.trip_id, end_time
          , headway_secs, block_id, monday, tuesday, wednesday, thursday
          , friday, saturday, sunday, in_seat_transfer
   HAVING service_schedule_group_id IS NOT NULL /* HACK: workaround for gtfsmanager issue #370 */
       ;
/* ED: GROUP BY above, might be necessary after all. testing. 2016-08-07 */


-- strange. no rows copied here. investigate more fully?
   INSERT into :"DST_SCHEMA".trips
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
   FROM :"SRC_SCHEMA".trips 
   INNER JOIN :"DST_SCHEMA".dev_patterns_trips using (trip_id)
   INNER JOIN :"SRC_SCHEMA".calendar 
           ON trips.service_id = calendar.calendar_id 
   WHERE trips.service_id IS NOT NULL 
         AND NOT EXISTS (SELECT NULL FROM :"SRC_SCHEMA".frequencies 
                         WHERE trips.trip_id = frequencies.trip_id) 
         AND based_on IS NOT NULL
         AND trips.agency_id IN (select agency_id FROM :"DST_SCHEMA".agencies) ;

-- strange. no rows copied here. investigate more fully?
   INSERT into :"DST_SCHEMA".trips
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
   FROM :"SRC_SCHEMA".frequencies 
   INNER JOIN :"SRC_SCHEMA".trips USING (trip_id)
   INNER JOIN :"DST_SCHEMA".dev_patterns_trips using (trip_id)
   INNER JOIN :"SRC_SCHEMA".calendar 
           ON trips.service_id = calendar.calendar_id 
   WHERE trips.service_id IS NOT NULL 
         AND based_on IS NOT NULL
         AND trips.agency_id IN (select agency_id FROM :"DST_SCHEMA".agencies) ;


-- test, does this work? ED 2016-09-15
   INSERT into :"DST_SCHEMA".trips
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
   FROM :"SRC_SCHEMA".frequencies 
   INNER JOIN :"SRC_SCHEMA".trips USING (trip_id)
   INNER JOIN :"DST_SCHEMA".dev_patterns_trips using (trip_id)
   INNER JOIN calendar 
           ON trips.service_id = calendar.calendar_id 
   WHERE trips.service_id IS NOT NULL 
         AND based_on IS NULL
         AND trips.agency_id IN (select agency_id FROM :"DST_SCHEMA".agencies) ;


