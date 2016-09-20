/* patterns.sql
 some patterns may be used by multiple routes/directions!!!!
 one way to test this is: SELECT DISTINCT ON (pattern_id) agency_id, pattern_id, route_id, direction_id
 */

/*

\dn

TRUNCATE :"DST_SCHEMA".patterns, :"DST_SCHEMA".pattern_custom_shape_segments RESTART IDENTITY;

*/


INSERT INTO :"DST_SCHEMA".patterns (agency_id, pattern_id, route_id, direction_id)
SELECT DISTINCT agency_id, pattern_id, route_id, direction_id
FROM :"DST_SCHEMA".timed_pattern_stops_nonnormalized
ORDER BY  pattern_id, agency_id, route_id, direction_id;


/*
    Assign headsign_id, if available.

    Research: Which trip_headsign_id should we use from
    timed_pattern_stops_nonnormalized, if it contains more than one for a given
    pattern?

    For now, do not assign a headsign to a pattern, if there is more than one
    trip_headsign_id, since it's not clear to me right now which headsign we should use.

    Ed 2016-09-20

    Discussion here: https://github.com/trilliumtransit/GTFSManager/issues/387
*/

UPDATE :"DST_SCHEMA".patterns 
SET headsign_id = patterns_having_one_headsign.trip_headsign_id_agg[1]
FROM 
( 
    SELECT pattern_id, array_agg(DISTINCT trip_headsign_id) as trip_headsign_id_agg
    FROM :"DST_SCHEMA".timed_pattern_stops_nonnormalized
    WHERE trip_headsign_id IS NOT NULL
    GROUP BY  pattern_id, agency_id, route_id, direction_id
    HAVING COUNT(DISTINCT trip_headsign_id) = 1
) patterns_having_one_headsign
WHERE patterns.pattern_id = patterns_having_one_headsign.pattern_id;


-- continuing with patterns.sql
-- ALERT! Some patterns are on multiple routes. I need to figure out how to 
-- handle this. <-- come back here and play -- test results

-- SELECT count(distinct agency_id), pattern_id, count(distinct route_id) as 
-- route_count, count(distinct direction_id) as direction_count
-- FROM :"DST_SCHEMA".timed_pattern_stops_nonnormalized
-- group by pattern_id
-- ORDER BY route_count DESC, direction_count DESC


