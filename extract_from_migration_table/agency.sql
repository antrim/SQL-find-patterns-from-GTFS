SELECT DISTINCT  agency_id, timed_pattern_id, stop_order, arrival_time, departure_time, pickup_type, drop_off_type
FROM migration_timed_pattern_stops_nonnormalized
ORDER BY agency_id, timed_pattern_id, stop_order