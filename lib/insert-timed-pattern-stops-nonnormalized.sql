
INSERT INTO :"DST_SCHEMA".timed_pattern_stops_nonnormalized 
    (agency_id, agency_name, route_short_name
    , route_long_name, direction_name, direction_id
    , trip_headsign_id, trip_headsign, stop_id
    , stop_order
    , timed_pattern_id 
    , pattern_id
    , arrival_time
    , departure_time
    , pickup_type
    , drop_off_type 
    , one_trip, trips_list, stops_pattern, arrival_time_intervals
    , departure_time_intervals, route_id, stop_headsign_id)

WITH 
  pattern_time_intervals AS (
    SELECT MIN(trips.trip_id) as one_trip
         , array_agg( trips.trip_id ORDER BY sequences.min_arrival_time ) AS trips_list
         , sequences.stops_pattern, arrival_time_intervals, departure_time_intervals
         , trips.agency_id, trips.route_id, trips.direction_id
    FROM :"SRC_SCHEMA".trips
    INNER JOIN (
        SELECT string_agg(stop_times.stop_id::text, ', ' ORDER BY stop_times.stop_sequence ASC) AS stops_pattern
             , stop_times.trip_id
             , MIN( stop_times.arrival_time ) AS min_arrival_time
        FROM :"SRC_SCHEMA".stop_times
        INNER JOIN :"SRC_SCHEMA".trips ON stop_times.trip_id = trips.trip_id
        WHERE
            stop_times.agency_id NOT IN (:SKIP_AGENCY_ID_STRING) 
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
         FROM :"SRC_SCHEMA".stop_times
         INNER JOIN :"SRC_SCHEMA".trips ON stop_times.trip_id = trips.trip_id
         INNER JOIN (
                 SELECT MIN( arrival_time )   AS min_arrival_time
                      , MIN( departure_time ) AS min_departure_time
                      , stop_times.trip_id
                 FROM :"SRC_SCHEMA".stop_times
                 INNER JOIN :"SRC_SCHEMA".trips on stop_times.trip_id = trips.trip_id
                 WHERE 
                     stop_times.agency_id NOT IN (:SKIP_AGENCY_ID_STRING) 
                     AND  trips.based_on IS NULL
                 GROUP BY stop_times.trip_id) min_trip_times 
           ON stop_times.trip_id = min_trip_times.trip_id
           WHERE 
               stop_times.agency_id not in (:SKIP_AGENCY_ID_STRING) 
               AND  trips.based_on IS NULL
         GROUP BY min_trip_times.trip_id, min_arrival_time, min_departure_time
        ) AS time_intervals_result

       ON sequences.trip_id = time_intervals_result.trip_id
       WHERE 
           trips.agency_id NOT IN (:SKIP_AGENCY_ID_STRING)
           AND trips.based_on IS NULL
     GROUP BY stops_pattern, arrival_time_intervals, departure_time_intervals
            , trips.agency_id, trips.route_id, trips.direction_id
   )
        
, timed_patterns_sub AS (

    SELECT pattern_time_intervals.*, MIN( stop_times.arrival_time ) AS min_arrival_time
         , MIN( stop_times.departure_time) AS min_departure_time
    FROM pattern_time_intervals
    INNER JOIN  :"SRC_SCHEMA".stop_times 
           ON pattern_time_intervals.one_trip = stop_times.trip_id 
           WHERE stop_times.agency_id NOT IN (:SKIP_AGENCY_ID_STRING)
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
         FROM :"SRC_SCHEMA".stop_times
         INNER JOIN :"SRC_SCHEMA".trips on stop_times.trip_id = trips.trip_id
         WHERE 
             trips.agency_id NOT IN (:SKIP_AGENCY_ID_STRING) 
             AND trips.based_on IS NULL
         GROUP BY stop_times.trip_id,trips.route_id,trips.direction_id)
    SELECT unique_patterns.stops_pattern,route_id,direction_id,row_number() over() as pattern_id 
    FROM unique_patterns
)

SELECT timed_patterns.agency_id, agency.agency_name, routes.route_short_name
     , routes.route_long_name, directions.direction_label as direction_name, trips.direction_id
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
     , COALESCE(pickup_type,0)
     , COALESCE(drop_off_type, 0)
     , one_trip, trips_list, stop_patterns.stops_pattern, arrival_time_intervals
     , departure_time_intervals, trips.route_id, stop_times.headsign_id as stop_headsign_id 
FROM timed_patterns
LEFT JOIN :"SRC_SCHEMA".stop_times ON timed_patterns.one_trip = stop_times.trip_id
INNER JOIN stop_patterns ON (timed_patterns.stops_pattern = stop_patterns.stops_pattern 
                             AND timed_patterns.route_id = stop_patterns.route_id 
                             AND timed_patterns.direction_id = stop_patterns.direction_id)
INNER JOIN :"SRC_SCHEMA".trips ON stop_times.trip_id = trips.trip_id
INNER JOIN :"SRC_SCHEMA".routes ON trips.route_id = routes.route_id
LEFT JOIN :"SRC_SCHEMA".directions ON trips.direction_id = directions.direction_id
LEFT JOIN :"SRC_SCHEMA".headsigns ON trips.headsign_id = headsigns.headsign_id
INNER JOIN :"SRC_SCHEMA".agency ON stop_times.agency_id = agency.agency_id
ORDER BY pattern_id, timed_pattern_id ASC, stop_times.stop_sequence ASC;

