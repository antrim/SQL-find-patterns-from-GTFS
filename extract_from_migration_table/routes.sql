SELECT DISTINCT  agency_id, route_id, route_short_name, route_long_name
FROM migration_timed_pattern_stops_nonnormalized
ORDER BY agency_id, route_id