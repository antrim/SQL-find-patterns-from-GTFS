SELECT DISTINCT agency_id, pattern_id, route_id, direction_id
FROM migration_timed_pattern_stops_nonnormalized
ORDER BY agency_id, route_id, direction_id, pattern_id