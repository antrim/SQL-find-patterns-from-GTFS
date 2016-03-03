SELECT DISTINCT  agency_id, pattern_id, stop_order, stop_id 
FROM migration_timed_pattern_stops_nonnormalized
ORDER BY agency_id, pattern_id, stop_order