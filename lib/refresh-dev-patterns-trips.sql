
TRUNCATE :"DST_SCHEMA".dev_patterns_trips;

-- combined_schedule_insert_query
WITH patterns_trips AS 
(
    SELECT DISTINCT 
        timed_pattern_id, agency_id, 
        unnest(trips_list) as trip_id
    FROM :"DST_SCHEMA".timed_pattern_stops_nonnormalized
    GROUP BY timed_pattern_id, agency_id, trips_list
) 
INSERT INTO :"DST_SCHEMA".dev_patterns_trips 
    ( timed_pattern_id, agency_id, trip_id )
SELECT
    timed_pattern_id, agency_id, trip_id
FROM patterns_trips
WHERE
    agency_id IN (select agency_id from :"DST_SCHEMA".agencies) ;


