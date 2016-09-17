
-- directions.sql
-- ALERT!! There are some duplicate direction_id values to look ingo

    INSERT INTO :"DST_SCHEMA".directions 
        (agency_id, direction_id, name)
    SELECT DISTINCT on (direction_id)  agency_id, direction_id, direction_name
    FROM :"DST_SCHEMA".timed_pattern_stops_nonnormalized
    ORDER BY direction_id, agency_id;


