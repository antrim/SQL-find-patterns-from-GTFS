-- headsigns.sql
-- ALERT! There are some null headsigns to look into here.

/* changing the headsign query to simply migrate everything, due to bug
 * https://github.com/trilliumtransit/GTFSManager/issues/337
 * ED 2016-08-10
$migrate_headsigns_query_original  = "
    INSERT into :"DST_SCHEMA".headsigns (agency_id, headsign_id, headsign)
    SELECT DISTINCT  agency_id, trip_headsign_id as headsign_id, trip_headsign AS headsign
    FROM :"DST_SCHEMA".timed_pattern_stops_nonnormalized 
    HERE trip_headsign_id IS NOT NULL 
          AND trip_headsign IS NOT NULL
    UNION
    SELECT DISTINCT  agency_id, stop_headsign_id as headsign_id, stop_headsign AS headsign
    FROM :"DST_SCHEMA".timed_pattern_stops_nonnormalized 
    WHERE stop_headsign_id IS NOT NULL 
          AND stop_headsign IS NOT NULL
    ORDER BY agency_id, headsign_id;
 */

    INSERT into :"DST_SCHEMA".headsigns (agency_id, headsign_id, headsign)
    SELECT DISTINCT  
        agency_id, headsign_id, headsign
    FROM :"SRC_SCHEMA".headsigns 
    WHERE 
        agency_id in (select agency_id from :"DST_SCHEMA".agencies) 
        AND headsign_id IS NOT NULL 
        AND headsign IS NOT NULL
    ORDER BY agency_id, headsign_id;

