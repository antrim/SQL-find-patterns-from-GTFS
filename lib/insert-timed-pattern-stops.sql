
\echo timed_pattern_stops
INSERT into :"DST_SCHEMA".timed_pattern_stops 
    (agency_id, timed_pattern_id, stop_order, stop_id, arrival_time, departure_time
    , pickup_type, drop_off_type, headsign_id)
SELECT DISTINCT agency_id, timed_pattern_id, stop_order, stop_id, arrival_time, departure_time
                , pickup_type, drop_off_type, stop_headsign_id
FROM :"DST_SCHEMA".timed_pattern_stops_nonnormalized
ORDER BY agency_id, timed_pattern_id, stop_order;


