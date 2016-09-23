/* 
 LEFT JOIN means z.zone_id is NULL when zone_id doesn't match zones, 
 that's what we want. Ed 2016-06-26
 https://github.com/trilliumtransit/migrate-GTFS/issues/6#issuecomment-228627399 

 Note also: we're resetting wheelchair_boarding to the default value of 0 per
 https://github.com/trilliumtransit/GTFSManager/issues/378
 */


-- SAVEPOINT insert_stops;
-- ROLLBACK TO SAVEPOINT insert_stops;
-- RELEASE SAVEPOINT insert_stops;

ALTER TABLE :"DST_SCHEMA".stops DISABLE TRIGGER  stops_timezone_trg;

INSERT into :"DST_SCHEMA".stops 
    ( feed_id, stop_id, stop_code, platform_code, location_type
    , parent_station_id, name, stop_desc, stop_comments
    , point
    , zone_id
    , city, direction_id, url, enabled 
    -- test trigger stops_timezone_trg by not including timezone in INSERT
    -- , timezone
    )
SELECT 
        a.feed_id, s.stop_id, s.stop_code, s.platform_code, s.location_type
    , s.parent_station, s.stop_name, s.stop_desc, s.stop_comments
    , ST_SetSRID(ST_Point(stop_lon, stop_lat), 4326)::GEOGRAPHY as point
    , z.zone_id 
    , s.city, direction_id, stop_url, publish_status AS enabled 
    -- test trigger stops_timezone_trg by not including timezone in INSERT
    -- , stop_timezone
FROM :"SRC_SCHEMA".stops s
LEFT JOIN :"SRC_SCHEMA".zones z USING (zone_id)
JOIN :"DST_SCHEMA".agencies a ON s.agency_id = a.agency_id
WHERE 
    s.agency_id IS NOT NULL
    AND s.agency_id IN (select agency_id from :"DST_SCHEMA".agencies) ;

-- This is faster than using trigger for each and every row.
UPDATE :"DST_SCHEMA".stops SET timezone = point_timezone(point);

ALTER TABLE :"DST_SCHEMA".stops ENABLE  TRIGGER  stops_timezone_trg;

/* 

    SELECT count(*) 
    from :"DST_SCHEMA".stops 
    where timezone is null;

    Fraction of earth covered by timezone table.
    Earth is 510072000000000 square meters according to Wikipedia "Earth" page.

    SELECT sum(ST_area(geog)) / 510072000000000 AS fraction_covered
    FROM :"DST_SCHEMA".tz_world_mp_including_territorial_waters ;


*/

/* 
Ed 2016-09-21. Deprecated in favor of stops_timezone_trg which uses geography, rather than agency settings.

UPDATE :"DST_SCHEMA".stops SET timezone = NULL 
WHERE length(timezone) = 0;

UPDATE :"DST_SCHEMA".stops SET timezone = 'America/New_York' WHERE timezone = 'US/Eastern';


UPDATE :"DST_SCHEMA".stops SET timezone = coalesce(sa.timezone, sa.agency_timezone) 
FROM
(
    SELECT
        stops.timezone, agencies.agency_timezone, stops_agencies.agency_id, stops.stop_id
    FROM :"DST_SCHEMA".stops
    JOIN :"DST_SCHEMA".stops_agencies ON stops.stop_id = stops_agencies.stop_id
    JOIN :"DST_SCHEMA".agencies ON stops_agencies.agency_id = agencies.agency_id 
) sa 
WHERE
    stops.stop_id = sa.stop_id
    AND stops.timezone IS NULL ;


*/
