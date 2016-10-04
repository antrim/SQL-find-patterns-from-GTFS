--
-- directions.sql
-- ALERT!! There are some duplicate direction_id values to look into

INSERT INTO :"DST_SCHEMA".directions 
    (agency_id, direction_id, name)
SELECT DISTINCT on (direction_id)  agency_id, direction_id, direction_name
FROM :"DST_SCHEMA".timed_pattern_stops_nonnormalized
WHERE agency_id IN (SELECT agency_id FROM :"DST_SCHEMA".agencies)
ORDER BY direction_id, agency_id;
