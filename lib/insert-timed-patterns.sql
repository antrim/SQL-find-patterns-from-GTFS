-- timed_pattern.sql

INSERT into :"DST_SCHEMA".timed_patterns (agency_id, timed_pattern_id, pattern_id)
SELECT DISTINCT agency_id, timed_pattern_id, pattern_id
FROM :"DST_SCHEMA".timed_pattern_stops_nonnormalized
ORDER BY agency_id, pattern_id, timed_pattern_id;



