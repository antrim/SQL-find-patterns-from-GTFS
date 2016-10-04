
SELECT 
        a.feed_id, s.stop_id, s.stop_code, s.platform_code, s.location_type
    , s.parent_station, s.stop_name, s.stop_desc, s.stop_comments
    , ST_SetSRID(ST_Point(stop_lon, stop_lat), 4326)::GEOGRAPHY as point
    , z.zone_id 
    , s.city, direction_id, stop_url, publish_status AS enabled 
FROM :"SRC_SCHEMA".stops s
LEFT JOIN :"SRC_SCHEMA".zones z USING (zone_id)
JOIN :"DST_SCHEMA".agencies a ON s.agency_id = a.agency_id
WHERE 
    s.agency_id IS NOT NULL
    AND s.stop_id = 823555
    AND s.agency_id IN (SELECT agency_id FROM :"DST_SCHEMA".agencies) ;


