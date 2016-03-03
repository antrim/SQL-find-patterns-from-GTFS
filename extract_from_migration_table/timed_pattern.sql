SELECT DISTINCT  agency_id, timed_pattern_id, pattern_id
FROM migration_timed_pattern_stops_nonnormalized
ORDER BY agency_id, pattern_id, timed_pattern_id