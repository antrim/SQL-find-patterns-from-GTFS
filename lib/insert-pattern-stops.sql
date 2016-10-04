
-- pattern_stop.sql
    INSERT into :"DST_SCHEMA".pattern_stops
    SELECT DISTINCT  agency_id, pattern_id, stop_order, stop_id 
    FROM :"DST_SCHEMA".timed_pattern_stops_nonnormalized
    WHERE agency_id IN (SELECT agency_id FROM :"DST_SCHEMA".agencies) 
    ORDER BY agency_id, pattern_id, stop_order ;

