/* 
 LEFT JOIN means z.zone_id is NULL when zone_id doesn't match zones, 
 that's what we want. Ed 2016-06-26
 https://github.com/trilliumtransit/migrate-GTFS/issues/6#issuecomment-228627399 

 Note also: we're resetting wheelchair_boarding to the default value of 0 per
 https://github.com/trilliumtransit/GTFSManager/issues/378
 */
    INSERT into :"DST_SCHEMA".stops 
        ( feed_id, stop_id, stop_code, platform_code, location_type
        , parent_station_id, name, stop_desc, stop_comments
        , point
        , zone_id
        , city, direction_id, url, enabled, timezone
        )
    SELECT 
          a.feed_id, s.stop_id, s.stop_code, s.platform_code, s.location_type
        , s.parent_station, s.stop_name, s.stop_desc, s.stop_comments
        , ST_SetSRID(ST_Point(stop_lon, stop_lat), 4326)::GEOGRAPHY as point
        , z.zone_id 
        , s.city, direction_id, stop_url, publish_status AS enabled, stop_timezone
    FROM :"SRC_SCHEMA".stops s
    LEFT JOIN :"SRC_SCHEMA".zones z USING (zone_id)
    JOIN :"DST_SCHEMA".agencies a ON s.agency_id = a.agency_id
    WHERE 
        s.agency_id IS NOT NULL
        AND s.agency_id IN (select agency_id from :"DST_SCHEMA".agencies) ;


-- Set feed_id for stops.
/*
$stops_feed_id_query = "
    update :"DST_SCHEMA".stops 
        set feed_id = agency_group_assoc.agency_group_id 
    from :"SRC_SCHEMA".agency_group_assoc 
    where stops.agency_id = agency_group_assoc.agency_id;
;
$result = db_query_debug($stops_feed_id_query);
 */


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


