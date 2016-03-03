<?php

$agency_array = array (1,3,267,392);
$agency_string = implode(",",$agency_array);

$migrate_agency_query  = "insert into migrate_agency (agency_id, agency_id_import, agency_url, agency_timezone, agency_lang_id, agency_name, agency_short_name, agency_phone, agency_fare_url, agency_info, query_tracking, last_modified, maintenance_start, gtfs_plus, no_frequencies) select agency_id, agency_id_import, agency_url, agency_timezone, agency_lang_id, agency_name, agency_short_name, agency_phone, agency_fare_url, agency_info, query_tracking, last_modified, maintenance_start, gtfs_plus, no_frequencies from agency where agency_id IN ($agency_string)";
$migrate_agency_result = db_query($migrate_agency_query);


// pattern_stop.sql
// done
INSERT into migrate_pattern_stop
SELECT DISTINCT  agency_id, pattern_id, stop_order, stop_id 
FROM migrate_timed_pattern_stops_nonnormalized
ORDER BY agency_id, pattern_id, stop_order

// timed_pattern_intervals.sql
// done
INSERT into migrate_timed_pattern_stop (agency_id, timed_pattern_id, stop_order, arrival_time, departure_time, pickup_type, drop_off_type, headsign_id)
SELECT DISTINCT agency_id, timed_pattern_id, stop_order, arrival_time, departure_time, pickup_type, drop_off_type, stop_headsign_id
FROM migrate_timed_pattern_stops_nonnormalized
ORDER BY agency_id, timed_pattern_id, stop_order

// timed_pattern.sql
// done
INSERT into migrate_timed_pattern (agency_id, timed_pattern_id, pattern_id)
SELECT DISTINCT agency_id, timed_pattern_id, pattern_id
FROM migrate_timed_pattern_stops_nonnormalized
ORDER BY agency_id, pattern_id, timed_pattern_id

// routes.sql
// done
insert into migrate_routes (agency_id, route_id, route_short_name, route_long_name, route_desc, route_type, route_color, route_text_color, route_url, route_bikes_allowed, route_id_import, last_modified, route_sort_order, hidden) select agency_id, route_id, route_short_name, route_long_name, route_desc, route_type, route_color, route_text_color, route_url, route_bikes_allowed, route_id_import, last_modified, route_sort_order, hidden from routes where agency_id IN ($agency_string)


// patterns.sql
// done
// solution for now is DISTINCT ON
INSERT into migrate_patterns (agency_id, pattern_id, route_id, direction_id)
SELECT DISTINCT ON (pattern_id) agency_id, pattern_id, route_id, direction_id
FROM migrate_timed_pattern_stops_nonnormalized
ORDER BY  pattern_id, agency_id, route_id, direction_id


// continuing with patterns.sql
// ALERT! Some patterns are on multiple routes. I need to figure out how to handle this.
SELECT count(distinct agency_id), pattern_id, count(distinct route_id) as route_count, count(distinct direction_id) as direction_count
FROM migrate_timed_pattern_stops_nonnormalized
group by pattern_id
ORDER BY route_count DESC, direction_count DESC


// headsigns.sql
// ALERT! There are some null headsigns to look into here.
INSERT into migrate_headsigns (agency_id, headsign_id, headsign)
SELECT DISTINCT  agency_id, trip_headsign_id as headsign_id, trip_headsign AS headsign
FROM migrate_timed_pattern_stops_nonnormalized where trip_headsign_id IS NOT NULL AND trip_headsign IS NOT NULL
UNION
SELECT DISTINCT  agency_id, stop_headsign_id as headsign_id, stop_headsign AS headsign
FROM migrate_timed_pattern_stops_nonnormalized where stop_headsign_id IS NOT NULL AND stop_headsign IS NOT NULL
ORDER BY agency_id, headsign_id

// directions.sql
// ALERT!! There are some duplicate direction_id values to look ingo
INSERT into migrate_directions (agency_id, direction_id, direction_label)
SELECT DISTINCT on (direction_id)  agency_id, direction_id, direction_label
FROM migrate_timed_pattern_stops_nonnormalized
ORDER BY direction_id, agency_id


// agency.sql


?>