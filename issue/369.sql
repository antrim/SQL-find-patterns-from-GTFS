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
   INNER JOIN :"DST_SCHEMA".dev_patterns_trips using (trip_id);



   SELECT *
   FROM :"SRC_SCHEMA".trips 
   INNER JOIN :"SRC_SCHEMA".calendar 
      ON trips.service_id = calendar.calendar_id 
   WHERE trips.agency_id = 551;

/* for testing: */

/*

/*
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
   HAVING service_schedule_group_id IS NOT NULL 

*/
